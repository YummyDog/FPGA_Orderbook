--------------------------------------------------------------------------------
-- udp_parser
--
-- Stage 3 of the market-data header parser pipeline.
--
--   AXI-Stream slave in  -> AXI-Stream master out (one register stage, data
--                           unmodified)
--   Field bus in  (Ethernet + IPv4, C_IPV4_BUS_W bits)
--   Field bus out (Ethernet + IPv4 + UDP, C_UDP_BUS_W bits)
--
-- Throughput: exactly one 8-byte beat per cycle. No buffering, no elastic
-- storage, no multi-cycle processing of any beat. s_axis_tready is tied high.
--
-- VLAN
--   Two parallel fixed-offset extraction paths, selected by vlan_present from
--   the upstream field bus. No barrel shifter, no extra cycle.
--
-- Beat map, untagged (UDP starts at byte 34)
--   beat 4  bytes 34-35  src port      bytes 36-37  dst port
--           bytes 38-39  length
--   beat 5  bytes 40-41  checksum
--
-- Beat map, single 802.1Q tag (UDP starts at byte 38, +4 on every offset)
--   beat 4  bytes 38-39  src port
--   beat 5  bytes 40-41  dst port      bytes 42-43  length
--           bytes 44-45  checksum
--
-- Both cases complete on beat 5, so the fields_valid pulse position does not
-- depend on the tag. No field straddles a beat in either case.
--
-- IPv4 options
--   These offsets assume IHL=5. If IHL>5 the UDP header sits (IHL-5)*4 bytes
--   further on and this module will latch the wrong bytes. ihl_invalid is
--   already exposed on the field bus by ipv4_parser; per the error policy
--   nothing is gated here and the downstream checker decides.
--
-- Error policy: informational only. Nothing is dropped, stalled, gated or
-- modified on the data path.
--
-- VHDL-2008
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.eth_parser_pkg.all;
use work.ipv4_parser_pkg.all;
use work.udp_parser_pkg.all;

entity udp_parser is
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
    s_fields       : in  std_logic_vector(C_IPV4_BUS_W-1 downto 0);
    m_fields       : out std_logic_vector(C_UDP_BUS_W-1 downto 0);
    m_fields_valid : out std_logic                 -- 1-cycle pulse on complete
  );
end entity udp_parser;


architecture rtl of udp_parser is

  ------------------------------------------------------------------------------
  -- Select byte lane n of a beat. n = 0 is the earliest byte on the wire.
  ------------------------------------------------------------------------------
  function bsel (d : std_logic_vector(63 downto 0); n : natural)
    return std_logic_vector is
  begin
    return d(8*n + 7 downto 8*n);
  end function;

  -- Beat position within the packet. Saturates at 6; nothing past beat 5 is
  -- of interest to this stage.
  signal beat_cnt : unsigned(2 downto 0);

  -- Tag select, straight off the upstream field bus
  signal vlan_c : std_logic;

  -- Extracted fields
  signal src_port_r : std_logic_vector(15 downto 0);
  signal dst_port_r : std_logic_vector(15 downto 0);
  signal length_r   : std_logic_vector(15 downto 0);
  signal cksum_r    : std_logic_vector(15 downto 0);

  -- Informational status
  signal len_invalid_r : std_logic;
  signal hdr_trunc_r   : std_logic;

  signal fields_valid_r : std_logic;

  -- Upstream field bus, re-registered to stay aligned with the data path
  signal s_fields_r : std_logic_vector(C_IPV4_BUS_W-1 downto 0);

  -- Data path pipeline register
  signal tdata_r  : std_logic_vector(63 downto 0);
  signal tkeep_r  : std_logic_vector(7 downto 0);
  signal tvalid_r : std_logic;
  signal tlast_r  : std_logic;

  ------------------------------------------------------------------------------
  -- The 66-bit UDP-only field vector.
  --
  -- Internal signal, deliberately NOT a port: it exists so the module can be
  -- verified standalone without unpacking the chained bus. Driven purely by
  -- registers, so it carries no combinational delay of its own.
  --
  -- Identical to m_fields(C_UDP_BUS_W-1 downto C_UDP_BASE).
  ------------------------------------------------------------------------------
  signal udp_fields : std_logic_vector(C_UDP_FIELDS_W-1 downto 0);

begin

  ------------------------------------------------------------------------------
  -- Backpressure: parsers never stall.
  ------------------------------------------------------------------------------
  s_axis_tready <= '1';

  ------------------------------------------------------------------------------
  -- Tag select from upstream. One bit, no decode.
  ------------------------------------------------------------------------------
  vlan_c <= eth_vlan_present(s_fields);

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
    variable v_len : std_logic_vector(15 downto 0);
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        beat_cnt       <= (others => '0');
        src_port_r     <= (others => '0');
        dst_port_r     <= (others => '0');
        length_r       <= (others => '0');
        cksum_r        <= (others => '0');
        len_invalid_r  <= '0';
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
          elsif beat_cnt /= 6 then
            beat_cnt <= beat_cnt + 1;
          end if;

          ----------------------------------------------------------------------
          -- Field capture
          ----------------------------------------------------------------------
          case to_integer(beat_cnt) is

            -- Beat 0 : nothing for UDP; clear per-packet status
            when 0 =>
              hdr_trunc_r <= '0';

            -- Beat 4
            when 4 =>
              if vlan_c = '0' then
                -- untagged: bytes 34-39
                src_port_r <= bsel(s_axis_tdata, 2) & bsel(s_axis_tdata, 3);
                dst_port_r <= bsel(s_axis_tdata, 4) & bsel(s_axis_tdata, 5);

                v_len         := bsel(s_axis_tdata, 6) & bsel(s_axis_tdata, 7);
                length_r      <= v_len;
                len_invalid_r <= to_sl(unsigned(v_len) < 8);
              else
                -- tagged: bytes 38-39
                src_port_r <= bsel(s_axis_tdata, 6) & bsel(s_axis_tdata, 7);
              end if;

            -- Beat 5 : header completes, both cases
            when 5 =>
              if vlan_c = '0' then
                -- untagged: bytes 40-41
                cksum_r <= bsel(s_axis_tdata, 0) & bsel(s_axis_tdata, 1);
              else
                -- tagged: bytes 40-45
                dst_port_r <= bsel(s_axis_tdata, 0) & bsel(s_axis_tdata, 1);

                v_len         := bsel(s_axis_tdata, 2) & bsel(s_axis_tdata, 3);
                length_r      <= v_len;
                len_invalid_r <= to_sl(unsigned(v_len) < 8);

                cksum_r <= bsel(s_axis_tdata, 4) & bsel(s_axis_tdata, 5);
              end if;

            when others =>
              null;

          end case;

          ----------------------------------------------------------------------
          -- Completion and truncation
          --
          -- The header needs beats 0..5. A tlast BEFORE beat 5 means it never
          -- completed: flag it, pulse anyway so downstream still gets a
          -- "bus has settled" edge, and forward the data untouched.
          --
          -- The beat_cnt < 5 guard is essential. beat_cnt saturates at 6, so
          -- without it every normal packet's tlast would fire this branch,
          -- producing a spurious second pulse and falsely setting
          -- hdr_trunc_r on a complete header.
          ----------------------------------------------------------------------
          if beat_cnt = 5 then
            fields_valid_r <= '1';
          elsif (s_axis_tlast = '1') and (beat_cnt < 5) then
            hdr_trunc_r    <= '1';
            fields_valid_r <= '1';
          end if;

        end if;
      end if;
    end if;
  end process p_parse;

  ------------------------------------------------------------------------------
  -- UDP-only field vector (internal, for standalone verification)
  ------------------------------------------------------------------------------
  udp_fields(C_UDP_SRCPORT_LOC + C_UDP_SRCPORT_W - 1 downto C_UDP_SRCPORT_LOC)
      <= src_port_r;
  udp_fields(C_UDP_DSTPORT_LOC + C_UDP_DSTPORT_W - 1 downto C_UDP_DSTPORT_LOC)
      <= dst_port_r;
  udp_fields(C_UDP_LENGTH_LOC  + C_UDP_LENGTH_W  - 1 downto C_UDP_LENGTH_LOC)
      <= length_r;
  udp_fields(C_UDP_CKSUM_LOC   + C_UDP_CKSUM_W   - 1 downto C_UDP_CKSUM_LOC)
      <= cksum_r;

  udp_fields(C_UDP_LEN_INVALID_LOC) <= len_invalid_r;
  udp_fields(C_UDP_TRUNC_LOC)       <= hdr_trunc_r;

  ------------------------------------------------------------------------------
  -- Outputs. All registered.
  ------------------------------------------------------------------------------
  m_axis_tdata  <= tdata_r;
  m_axis_tkeep  <= tkeep_r;
  m_axis_tvalid <= tvalid_r;
  m_axis_tlast  <= tlast_r;

  -- Own fields appended above the upstream bus
  m_fields <= udp_fields & s_fields_r;

  m_fields_valid <= fields_valid_r;

end architecture rtl;
