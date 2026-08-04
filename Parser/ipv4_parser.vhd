--------------------------------------------------------------------------------
-- ipv4_parser
--
-- Stage 2 of the market-data header parser pipeline.
--
--   AXI-Stream slave in  -> AXI-Stream master out (one register stage, data
--                           unmodified)
--   Field bus in  (Ethernet, C_ETH_FIELDS_W bits)
--   Field bus out (Ethernet + IPv4, C_IPV4_BUS_W bits)
--
-- Throughput: exactly one 8-byte beat per cycle. No buffering, no elastic
-- storage, no multi-cycle processing of any beat. s_axis_tready is tied high.
--
-- VLAN
--   Two parallel fixed-offset extraction paths, selected by vlan_present from
--   the upstream field bus. No barrel shifter, no extra cycle.
--
--   vlan_present is safe to use combinationally here: eth_parser registers it
--   at its beat 1, and the data path picks up exactly one register stage per
--   module, so vlan_present and the beat it describes arrive together.
--
-- Beat map, untagged (IPv4 starts at byte 14)
--   beat 1  byte 14      ver/IHL       byte 15      DSCP/ECN
--   beat 2  bytes 16-17  total length  bytes 18-19  identification
--           bytes 20-21  flags/frag    byte  22     TTL
--           byte  23     protocol
--   beat 3  bytes 24-25  checksum      bytes 26-29  src IP
--           bytes 30-31  dst IP[31:16]
--   beat 4  bytes 32-33  dst IP[15:0]
--
-- Beat map, single 802.1Q tag (IPv4 starts at byte 18, +4 on every offset)
--   beat 2  byte 18      ver/IHL       byte 19      DSCP/ECN
--           bytes 20-21  total length  bytes 22-23  identification
--   beat 3  bytes 24-25  flags/frag    byte  26     TTL
--           byte  27     protocol      bytes 28-29  checksum
--           bytes 30-31  src IP[31:16]
--   beat 4  bytes 32-33  src IP[15:0]  bytes 34-37  dst IP
--
-- Both cases complete on beat 4, so the fields_valid pulse position does not
-- depend on the tag. Only the lane selections differ.
--
-- IPv4 options: NOT SUPPORTED. IHL is checked and ihl_invalid exposed as an
-- informational bit, but parsing continues on the IHL=5 assumption. Nothing
-- downstream of this module is shifted by a non-5 IHL.
--
-- Error policy: informational only. Nothing is dropped, stalled, gated or
-- modified on the data path.
--
-- VHDL-2008
--------------------------------------------------------------------------------
--NOTES

-- Vlan present and hdr truncated bits from eth parser casues entire field vectors nibbles to be skewed - MAY NEED TO BE ACCOUNTED FOR

--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.eth_parser_pkg.all;
use work.ipv4_parser_pkg.all;

entity ipv4_parser is
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
    s_fields       : in  std_logic_vector(C_ETH_FIELDS_W-1 downto 0);
    m_fields       : out std_logic_vector(C_IPV4_BUS_W-1 downto 0);
    m_fields_valid : out std_logic                 -- 1-cycle pulse on complete
  );
end entity ipv4_parser;


architecture rtl of ipv4_parser is

  ------------------------------------------------------------------------------
  -- Select byte lane n of a beat. n = 0 is the earliest byte on the wire.
  ------------------------------------------------------------------------------
  function bsel (d : std_logic_vector(63 downto 0); n : natural)
    return std_logic_vector is
  begin
    return d(8*n + 7 downto 8*n);
  end function;

  -- Beat position within the packet. Saturates at 5; nothing past beat 4 is
  -- of interest to this stage.
  signal beat_cnt : unsigned(2 downto 0);

  -- Tag select, straight off the upstream field bus
  signal vlan_c : std_logic;

  -- Extracted fields
  signal ver_ihl_r      : std_logic_vector(7 downto 0);
  signal dscp_ecn_r     : std_logic_vector(7 downto 0);
  signal total_len_r    : std_logic_vector(15 downto 0);
  signal ident_r        : std_logic_vector(15 downto 0);
  signal flags_frag_r   : std_logic_vector(15 downto 0);
  signal ttl_r          : std_logic_vector(7 downto 0);
  signal protocol_r     : std_logic_vector(7 downto 0);
  signal cksum_r        : std_logic_vector(15 downto 0);
  signal src_ip_r       : std_logic_vector(31 downto 0);
  signal dst_ip_r       : std_logic_vector(31 downto 0);

  -- Informational status
  signal ihl_invalid_r  : std_logic;
  signal ver_invalid_r  : std_logic;
  signal frag_present_r : std_logic;
  signal hdr_trunc_r    : std_logic;

  signal fields_valid_r : std_logic;

  -- Upstream field bus, re-registered to stay aligned with the data path
  signal s_fields_r : std_logic_vector(C_ETH_FIELDS_W-1 downto 0);

  -- Data path pipeline register
  signal tdata_r  : std_logic_vector(63 downto 0);
  signal tkeep_r  : std_logic_vector(7 downto 0);
  signal tvalid_r : std_logic;
  signal tlast_r  : std_logic;

  ------------------------------------------------------------------------------
  -- The 164-bit IPv4-only field vector.
  --
  -- Internal signal, deliberately NOT a port: it exists so the module can be
  -- verified standalone without unpacking the chained bus. It is driven purely
  -- by registers, so it carries no combinational delay of its own.
  --
  -- Identical to m_fields(C_IPV4_BUS_W-1 downto C_IPV4_BASE).
  ------------------------------------------------------------------------------
  signal ipv4_fields : std_logic_vector(C_IPV4_FIELDS_W-1 downto 0);

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
    variable v_verihl   : std_logic_vector(7 downto 0);
    variable v_flagfrag : std_logic_vector(15 downto 0);
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        beat_cnt       <= (others => '0');
        ver_ihl_r      <= (others => '0');
        dscp_ecn_r     <= (others => '0');
        total_len_r    <= (others => '0');
        ident_r        <= (others => '0');
        flags_frag_r   <= (others => '0');
        ttl_r          <= (others => '0');
        protocol_r     <= (others => '0');
        cksum_r        <= (others => '0');
        src_ip_r       <= (others => '0');
        dst_ip_r       <= (others => '0');
        ihl_invalid_r  <= '0';
        ver_invalid_r  <= '0';
        frag_present_r <= '0';
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
          elsif beat_cnt /= 5 then
            beat_cnt <= beat_cnt + 1;
          end if;

          ----------------------------------------------------------------------
          -- Field capture
          ----------------------------------------------------------------------
          case to_integer(beat_cnt) is

            -- Beat 0 : nothing for IPv4; clear per-packet status
            when 0 =>
              hdr_trunc_r <= '0';

            -- Beat 1 : untagged only, bytes 14-15
            when 1 =>
              if vlan_c = '0' then
                v_verihl      := bsel(s_axis_tdata, 6);
                ver_ihl_r     <= v_verihl;
                ver_invalid_r <= to_sl(v_verihl(7 downto 4) /= x"4");
                ihl_invalid_r <= to_sl(v_verihl(3 downto 0) /= x"5");
                dscp_ecn_r    <= bsel(s_axis_tdata, 7);
              end if;

            -- Beat 2
            when 2 =>
              if vlan_c = '0' then
                -- untagged: bytes 16-23
                total_len_r <= bsel(s_axis_tdata, 0) & bsel(s_axis_tdata, 1);
                ident_r     <= bsel(s_axis_tdata, 2) & bsel(s_axis_tdata, 3);

                v_flagfrag     := bsel(s_axis_tdata, 4) & bsel(s_axis_tdata, 5);
                flags_frag_r   <= v_flagfrag;
                frag_present_r <= to_sl((v_flagfrag(13) = '1') or
                                        (unsigned(v_flagfrag(12 downto 0)) /= 0));

                ttl_r      <= bsel(s_axis_tdata, 6);
                protocol_r <= bsel(s_axis_tdata, 7);
              else
                -- tagged: bytes 18-23
                v_verihl      := bsel(s_axis_tdata, 2);
                ver_ihl_r     <= v_verihl;
                ver_invalid_r <= to_sl(v_verihl(7 downto 4) /= x"4");
                ihl_invalid_r <= to_sl(v_verihl(3 downto 0) /= x"5");
                dscp_ecn_r    <= bsel(s_axis_tdata, 3);
                total_len_r   <= bsel(s_axis_tdata, 4) & bsel(s_axis_tdata, 5);
                ident_r       <= bsel(s_axis_tdata, 6) & bsel(s_axis_tdata, 7);
              end if;

            -- Beat 3
            when 3 =>
              if vlan_c = '0' then
                -- untagged: bytes 24-31
                cksum_r  <= bsel(s_axis_tdata, 0) & bsel(s_axis_tdata, 1);
                src_ip_r <= bsel(s_axis_tdata, 2) & bsel(s_axis_tdata, 3) &
                            bsel(s_axis_tdata, 4) & bsel(s_axis_tdata, 5);
                dst_ip_r(31 downto 16) <= bsel(s_axis_tdata, 6) &
                                          bsel(s_axis_tdata, 7);
              else
                -- tagged: bytes 24-31
                v_flagfrag     := bsel(s_axis_tdata, 0) & bsel(s_axis_tdata, 1);
                flags_frag_r   <= v_flagfrag;
                frag_present_r <= to_sl((v_flagfrag(13) = '1') or
                                        (unsigned(v_flagfrag(12 downto 0)) /= 0));

                ttl_r      <= bsel(s_axis_tdata, 2);
                protocol_r <= bsel(s_axis_tdata, 3);
                cksum_r    <= bsel(s_axis_tdata, 4) & bsel(s_axis_tdata, 5);
                src_ip_r(31 downto 16) <= bsel(s_axis_tdata, 6) &
                                          bsel(s_axis_tdata, 7);
              end if;

            -- Beat 4 : header completes, both cases
            when 4 =>
              if vlan_c = '0' then
                dst_ip_r(15 downto 0) <= bsel(s_axis_tdata, 0) &
                                         bsel(s_axis_tdata, 1);
              else
                src_ip_r(15 downto 0) <= bsel(s_axis_tdata, 0) &
                                         bsel(s_axis_tdata, 1);
                dst_ip_r <= bsel(s_axis_tdata, 2) & bsel(s_axis_tdata, 3) &
                            bsel(s_axis_tdata, 4) & bsel(s_axis_tdata, 5);
              end if;

            when others =>
              null;

          end case;

          ----------------------------------------------------------------------
          -- Completion and truncation
          --
          -- The header needs beats 0..4. A tlast BEFORE beat 4 means it never
          -- completed: flag it, pulse anyway so downstream still gets a
          -- "bus has settled" edge, and forward the data untouched.
          --
          -- The beat_cnt < 4 guard is essential. beat_cnt saturates at 5, so
          -- without it every normal packet's tlast would fire this branch,
          -- producing a spurious second pulse and falsely setting
          -- hdr_trunc_r on a complete header.
          ----------------------------------------------------------------------
          if beat_cnt = 4 then
            fields_valid_r <= '1';
          elsif (s_axis_tlast = '1') and (beat_cnt < 4) then
            hdr_trunc_r    <= '1';
            fields_valid_r <= '1';
          end if;

        end if;
      end if;
    end if;
  end process p_parse;

  ------------------------------------------------------------------------------
  -- IPv4-only field vector (internal, for standalone verification)
  ------------------------------------------------------------------------------
  ipv4_fields(C_IP_VERSION_LOC + C_IP_VERSION_W - 1 downto C_IP_VERSION_LOC)
      <= ver_ihl_r(7 downto 4);
  ipv4_fields(C_IP_IHL_LOC     + C_IP_IHL_W     - 1 downto C_IP_IHL_LOC)
      <= ver_ihl_r(3 downto 0);
  ipv4_fields(C_IP_DSCPECN_LOC + C_IP_DSCPECN_W - 1 downto C_IP_DSCPECN_LOC)
      <= dscp_ecn_r;
  ipv4_fields(C_IP_TOTLEN_LOC  + C_IP_TOTLEN_W  - 1 downto C_IP_TOTLEN_LOC)
      <= total_len_r;
  ipv4_fields(C_IP_ID_LOC      + C_IP_ID_W      - 1 downto C_IP_ID_LOC)
      <= ident_r;
  ipv4_fields(C_IP_FLAGS_LOC   + C_IP_FLAGS_W   - 1 downto C_IP_FLAGS_LOC)
      <= flags_frag_r(15 downto 13);
  ipv4_fields(C_IP_FRAGOFF_LOC + C_IP_FRAGOFF_W - 1 downto C_IP_FRAGOFF_LOC)
      <= flags_frag_r(12 downto 0);
  ipv4_fields(C_IP_TTL_LOC     + C_IP_TTL_W     - 1 downto C_IP_TTL_LOC)
      <= ttl_r;
  ipv4_fields(C_IP_PROTO_LOC   + C_IP_PROTO_W   - 1 downto C_IP_PROTO_LOC)
      <= protocol_r;
  ipv4_fields(C_IP_CKSUM_LOC   + C_IP_CKSUM_W   - 1 downto C_IP_CKSUM_LOC)
      <= cksum_r;
  ipv4_fields(C_IP_SRCIP_LOC   + C_IP_SRCIP_W   - 1 downto C_IP_SRCIP_LOC)
      <= src_ip_r;
  ipv4_fields(C_IP_DSTIP_LOC   + C_IP_DSTIP_W   - 1 downto C_IP_DSTIP_LOC)
      <= dst_ip_r;

  ipv4_fields(C_IP_IHL_INVALID_LOC)  <= ihl_invalid_r;
  ipv4_fields(C_IP_VER_INVALID_LOC)  <= ver_invalid_r;
  ipv4_fields(C_IP_FRAG_PRESENT_LOC) <= frag_present_r;
  ipv4_fields(C_IP_TRUNC_LOC)        <= hdr_trunc_r;

  ------------------------------------------------------------------------------
  -- Outputs. All registered.
  ------------------------------------------------------------------------------
  m_axis_tdata  <= tdata_r;
  m_axis_tkeep  <= tkeep_r;
  m_axis_tvalid <= tvalid_r;
  m_axis_tlast  <= tlast_r;

  -- Own fields appended above the upstream bus
  m_fields <= ipv4_fields & s_fields_r;

  m_fields_valid <= fields_valid_r;

end architecture rtl;
