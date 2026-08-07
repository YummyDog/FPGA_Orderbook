--------------------------------------------------------------------------------
-- mold_parser
--
-- Stage 4 of the market-data header parser pipeline.
--
--   AXI-Stream slave in  -> AXI-Stream master out (one register stage, data
--                           unmodified)
--   Field bus in  (Ethernet + IPv4 + UDP, C_UDP_BUS_W bits)
--   Field bus out (+ MoldUDP64, C_MOLD_BUS_W bits)
--
-- Throughput: exactly one 8-byte beat per cycle. No buffering, no elastic
-- storage, no multi-cycle processing of any beat. s_axis_tready is tied high.
--
-- VLAN
--   Two parallel fixed-offset extraction paths, selected by vlan_present from
--   the upstream field bus. No barrel shifter, no extra cycle.
--
-- Beat map, untagged (Mold starts at byte 42)
--   beat 5  bytes 42-47  session[9:4]
--   beat 6  bytes 48-51  session[3:0]     bytes 52-55  seqnum[7:4]
--   beat 7  bytes 56-59  seqnum[3:0]      bytes 60-61  message count
--
-- Beat map, single 802.1Q tag (Mold starts at byte 46, +4 on every offset)
--   beat 5  bytes 46-47  session[9:8]
--   beat 6  bytes 48-55  session[7:0]
--   beat 7  bytes 56-63  seqnum[7:0]
--   beat 8  bytes 64-65  message count
--
-- *** COMPLETION IS TAG-DEPENDENT IN THIS MODULE ***
--   untagged completes on beat 7, tagged on beat 8. Unlike ipv4_parser and
--   udp_parser, whose completion beat was the same either way, a tag pushes
--   the message count past a beat boundary here. The fields_valid pulse
--   position therefore depends on vlan_present.
--
-- IPv4 options
--   These offsets assume IHL=5. With options present everything below IPv4
--   shifts and this module latches the wrong bytes. ihl_invalid is already
--   on the field bus; per the error policy nothing is gated here.
--
-- Error policy: informational only. Nothing is dropped, stalled, gated or
-- modified on the data path.
--
-- Scope note: the first ITCH message length (bytes 62-63 untagged) is NOT
-- extracted here. It belongs to ITCH framing, and the ITCH parser sees the
-- same beat on its own input.
--
-- VHDL-2008
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.eth_parser_pkg.all;
use work.ipv4_parser_pkg.all;
use work.udp_parser_pkg.all;
use work.mold_parser_pkg.all;

entity mold_parser is
  port (
    clk    : in  std_logic;
    resetn : in  std_logic;                        -- synchronous, active low

    -- AXI-Stream slave -------------------------------------------------------
    s_axis_tdata   : in  std_logic_vector(63 downto 0);
    s_axis_tkeep   : in  std_logic_vector(7 downto 0);
    s_axis_tvalid  : in  std_logic;
    s_axis_tready  : out std_logic;                -- tied high, never stalls
    s_axis_tlast   : in  std_logic;

    -- AXI-Stream master ------------------------------------------------------
    m_axis_tdata   : out std_logic_vector(63 downto 0);
    m_axis_tkeep   : out std_logic_vector(7 downto 0);
    m_axis_tvalid  : out std_logic;
    m_axis_tready  : in  std_logic;                -- UNUSED, parsers never stall
    m_axis_tlast   : out std_logic;

    -- Field bus --------------------------------------------------------------
    s_fields       : in  std_logic_vector(C_UDP_BUS_W-1 downto 0);
    m_fields       : out std_logic_vector(C_MOLD_BUS_W-1 downto 0);
    m_fields_valid : out std_logic                 -- 1-cycle pulse on complete
  );
end entity mold_parser;


architecture rtl of mold_parser is

  ------------------------------------------------------------------------------
  -- Select byte lane n of a beat. n = 0 is the earliest byte on the wire.
  ------------------------------------------------------------------------------
  function bsel (d : std_logic_vector(63 downto 0); n : natural)
    return std_logic_vector is
  begin
    return d(8*n + 7 downto 8*n);
  end function;

  -- Beat position within the packet. Saturates at 9; nothing past beat 8 is
  -- of interest to this stage.
  signal beat_cnt : unsigned(3 downto 0);

  -- Tag select, straight off the upstream field bus
  signal vlan_c : std_logic;

  -- The beat on which this module's header completes. Tag-dependent, unlike
  -- every earlier stage.
  signal last_beat_c : unsigned(3 downto 0);

  -- Extracted fields
  signal session_r  : std_logic_vector(79 downto 0);
  signal seqnum_r   : std_logic_vector(63 downto 0);
  signal msgcnt_r   : std_logic_vector(15 downto 0);

  -- Informational status
  signal heartbeat_r : std_logic;
  signal eos_r       : std_logic;
  signal hdr_trunc_r : std_logic;

  signal fields_valid_r : std_logic;

  -- Upstream field bus, re-registered to stay aligned with the data path
  signal s_fields_r : std_logic_vector(C_UDP_BUS_W-1 downto 0);

  -- Data path pipeline register
  signal tdata_r  : std_logic_vector(63 downto 0);
  signal tkeep_r  : std_logic_vector(7 downto 0);
  signal tvalid_r : std_logic;
  signal tlast_r  : std_logic;

  ------------------------------------------------------------------------------
  -- The 163-bit Mold-only field vector.
  --
  -- Internal signal, deliberately NOT a port: it exists so the module can be
  -- verified standalone without unpacking the chained bus. Driven purely by
  -- registers, so it carries no combinational delay of its own.
  --
  -- Identical to m_fields(C_MOLD_BUS_W-1 downto C_MOLD_BASE).
  ------------------------------------------------------------------------------
  signal mold_fields : std_logic_vector(C_MOLD_FIELDS_W-1 downto 0);

begin

  ------------------------------------------------------------------------------
  -- Backpressure: parsers never stall.
  ------------------------------------------------------------------------------
  s_axis_tready <= '1';

  ------------------------------------------------------------------------------
  -- Tag select, and the resulting completion beat
  ------------------------------------------------------------------------------
  vlan_c <= eth_vlan_present(s_fields);

  last_beat_c <= to_unsigned(8, last_beat_c'length) when vlan_c = '1'
            else to_unsigned(7, last_beat_c'length);

  ------------------------------------------------------------------------------
  -- Data path and upstream field bus: one register stage each, so the two
  -- advance in lockstep through the whole chain.
  ------------------------------------------------------------------------------
  p_datapath : process (clk)
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        tdata_r    <= (others => '0');
        tkeep_r    <= (others => '0');
        tvalid_r   <= '0';
        tlast_r    <= '0';
        s_fields_r <= (others => '0');
      else
        tdata_r    <= s_axis_tdata;
        tkeep_r    <= s_axis_tkeep;
        tvalid_r   <= s_axis_tvalid;
        tlast_r    <= s_axis_tlast and s_axis_tvalid;
        s_fields_r <= s_fields;
      end if;
    end if;
  end process p_datapath;

  ------------------------------------------------------------------------------
  -- Header extraction. Fixed-offset latching, one beat per cycle.
  ------------------------------------------------------------------------------
  p_parse : process (clk)
    variable v_cnt : std_logic_vector(15 downto 0);
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        beat_cnt       <= (others => '0');
        session_r      <= (others => '0');
        seqnum_r       <= (others => '0');
        msgcnt_r       <= (others => '0');
        heartbeat_r    <= '0';
        eos_r          <= '0';
        hdr_trunc_r    <= '0';
        fields_valid_r <= '0';
      else

        -- default: fields_valid is a single-cycle pulse
        fields_valid_r <= '0';

        if s_axis_tvalid = '1' then

          ----------------------------------------------------------------------
          -- Beat position tracking
          ----------------------------------------------------------------------
          if s_axis_tlast = '1' then
            beat_cnt <= (others => '0');
          elsif beat_cnt /= 9 then
            beat_cnt <= beat_cnt + 1;
          end if;

          ----------------------------------------------------------------------
          -- Field capture
          ----------------------------------------------------------------------
          case to_integer(beat_cnt) is

            -- Beat 0 : nothing for Mold; clear per-packet status
            when 0 =>
              hdr_trunc_r <= '0';

            -- Beat 5
            when 5 =>
              if vlan_c = '0' then
                -- untagged: bytes 42-47 -> session[9:4]
                session_r(79 downto 32) <=
                  bsel(s_axis_tdata, 2) & bsel(s_axis_tdata, 3) &
                  bsel(s_axis_tdata, 4) & bsel(s_axis_tdata, 5) &
                  bsel(s_axis_tdata, 6) & bsel(s_axis_tdata, 7);
              else
                -- tagged: bytes 46-47 -> session[9:8]
                session_r(79 downto 64) <=
                  bsel(s_axis_tdata, 6) & bsel(s_axis_tdata, 7);
              end if;

            -- Beat 6
            when 6 =>
              if vlan_c = '0' then
                -- untagged: bytes 48-51 -> session[3:0], 52-55 -> seqnum[7:4]
                session_r(31 downto 0) <=
                  bsel(s_axis_tdata, 0) & bsel(s_axis_tdata, 1) &
                  bsel(s_axis_tdata, 2) & bsel(s_axis_tdata, 3);
                seqnum_r(63 downto 32) <=
                  bsel(s_axis_tdata, 4) & bsel(s_axis_tdata, 5) &
                  bsel(s_axis_tdata, 6) & bsel(s_axis_tdata, 7);
              else
                -- tagged: bytes 48-55 -> session[7:0]
                session_r(63 downto 0) <=
                  bsel(s_axis_tdata, 0) & bsel(s_axis_tdata, 1) &
                  bsel(s_axis_tdata, 2) & bsel(s_axis_tdata, 3) &
                  bsel(s_axis_tdata, 4) & bsel(s_axis_tdata, 5) &
                  bsel(s_axis_tdata, 6) & bsel(s_axis_tdata, 7);
              end if;

            -- Beat 7 : untagged completes here
            when 7 =>
              if vlan_c = '0' then
                -- untagged: bytes 56-59 -> seqnum[3:0], 60-61 -> message count
                seqnum_r(31 downto 0) <=
                  bsel(s_axis_tdata, 0) & bsel(s_axis_tdata, 1) &
                  bsel(s_axis_tdata, 2) & bsel(s_axis_tdata, 3);

                v_cnt       := bsel(s_axis_tdata, 4) & bsel(s_axis_tdata, 5);
                msgcnt_r    <= v_cnt;
                heartbeat_r <= to_sl(unsigned(v_cnt) = 0);
                eos_r       <= to_sl(v_cnt = x"FFFF");
              else
                -- tagged: bytes 56-63 -> seqnum[7:0]
                seqnum_r <=
                  bsel(s_axis_tdata, 0) & bsel(s_axis_tdata, 1) &
                  bsel(s_axis_tdata, 2) & bsel(s_axis_tdata, 3) &
                  bsel(s_axis_tdata, 4) & bsel(s_axis_tdata, 5) &
                  bsel(s_axis_tdata, 6) & bsel(s_axis_tdata, 7);
              end if;

            -- Beat 8 : tagged completes here
            when 8 =>
              if vlan_c = '1' then
                -- tagged: bytes 64-65 -> message count
                v_cnt       := bsel(s_axis_tdata, 0) & bsel(s_axis_tdata, 1);
                msgcnt_r    <= v_cnt;
                heartbeat_r <= to_sl(unsigned(v_cnt) = 0);
                eos_r       <= to_sl(v_cnt = x"FFFF");
              end if;

            when others =>
              null;

          end case;

          ----------------------------------------------------------------------
          -- Completion and truncation
          --
          -- last_beat_c is 7 untagged, 8 tagged. A tlast BEFORE that beat
          -- means the header never completed: flag it, pulse anyway so
          -- downstream still gets a "bus has settled" edge, and forward the
          -- data untouched.
          --
          -- The beat_cnt < last_beat_c guard is essential. beat_cnt saturates
          -- at 9, so without it every normal packet's tlast would fire this
          -- branch, producing a spurious second pulse and falsely setting
          -- hdr_trunc_r on a complete header.
          ----------------------------------------------------------------------
          if beat_cnt = last_beat_c then
            fields_valid_r <= '1';
          elsif (s_axis_tlast = '1') and (beat_cnt < last_beat_c) then
            hdr_trunc_r    <= '1';
            fields_valid_r <= '1';
          end if;

        end if;
      end if;
    end if;
  end process p_parse;

  ------------------------------------------------------------------------------
  -- Mold-only field vector (internal, for standalone verification)
  ------------------------------------------------------------------------------
  mold_fields(C_MOLD_SESSION_LOC + C_MOLD_SESSION_W - 1 downto C_MOLD_SESSION_LOC)
      <= session_r;
  mold_fields(C_MOLD_SEQNUM_LOC  + C_MOLD_SEQNUM_W  - 1 downto C_MOLD_SEQNUM_LOC)
      <= seqnum_r;
  mold_fields(C_MOLD_MSGCNT_LOC  + C_MOLD_MSGCNT_W  - 1 downto C_MOLD_MSGCNT_LOC)
      <= msgcnt_r;

  mold_fields(C_MOLD_HEARTBEAT_LOC) <= heartbeat_r;
  mold_fields(C_MOLD_EOS_LOC)       <= eos_r;
  mold_fields(C_MOLD_TRUNC_LOC)     <= hdr_trunc_r;

  ------------------------------------------------------------------------------
  -- Outputs. All registered.
  ------------------------------------------------------------------------------
  m_axis_tdata  <= tdata_r;
  m_axis_tkeep  <= tkeep_r;
  m_axis_tvalid <= tvalid_r;
  m_axis_tlast  <= tlast_r;

  -- Own fields appended above the upstream bus
  m_fields <= mold_fields & s_fields_r;

  m_fields_valid <= fields_valid_r;

end architecture rtl;
