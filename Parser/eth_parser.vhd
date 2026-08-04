--------------------------------------------------------------------------------
-- eth_parser
--
-- Stage 1 of the market-data header parser pipeline.
-- Ethernet II header extraction with optional single 802.1Q tag.
--
--   AXI-Stream slave in  -> AXI-Stream master out (one register stage, data
--                           unmodified)
--   Flat registered field bus out, C_ETH_FIELDS_W bits
--
-- Throughput: exactly one 8-byte beat per cycle. No buffering, no elastic
-- storage, no multi-cycle processing of any beat. s_axis_tready is tied high.
--
-- Byte lane convention (standard AXI4-Stream):
--   byte 0 of the frame (first on the wire) is tdata(7 downto 0)
--   byte 7                                   is tdata(63 downto 56)
--
-- Header layout, untagged:
--   bytes  0..5   dst MAC          -> beat 0
--   bytes  6..11  src MAC          -> beat 0 (hi 2) + beat 1 (lo 4)
--   bytes 12..13  ethertype        -> beat 1
--
-- Header layout, single 802.1Q tag:
--   bytes 12..13  TPID (0x8100)    -> beat 1
--   bytes 14..15  TCI              -> beat 1
--   bytes 16..17  ethertype        -> beat 2
--
-- Header completes on beat 1 (untagged) or beat 2 (tagged). Field values are
-- held from completion until the first beat of the next packet, so they are
-- valid alongside tlast.
--
-- Error policy: informational only. Nothing is dropped, stalled, gated or
-- modified on the data path. A short frame that ends before the header
-- completes sets eth_hdr_truncated on the field bus and is forwarded intact.
--
-- VHDL-2008
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.eth_parser_pkg.all;

entity eth_parser is
  generic (
    -- TPID matched to detect a VLAN tag. 0x8100 is the C-tag. Set to 0x88A8
    -- for an S-tag deployment. QinQ (two stacked tags) is NOT supported.
    G_TPID : std_logic_vector(15 downto 0) := x"8100"
  );
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
    m_axis_tready  : in  std_logic;                -- UNUSED, see note below
    m_axis_tlast   : out std_logic;

    -- Field bus --------------------------------------------------------------
    m_fields       : out std_logic_vector(C_ETH_FIELDS_W-1 downto 0);
    m_fields_valid : out std_logic                 -- 1-cycle pulse on complete
  );
end entity eth_parser;


architecture rtl of eth_parser is

  ------------------------------------------------------------------------------
  -- Select byte lane n of a beat. n = 0 is the earliest byte on the wire.
  ------------------------------------------------------------------------------
  function bsel (d : std_logic_vector(63 downto 0); n : natural)
    return std_logic_vector is
  begin
    return d(8*n + 7 downto 8*n);
  end function;

  -- Beat position within the packet. Saturates at 3; nothing past beat 2 is
  -- of interest to this stage.
  signal beat_cnt : unsigned(1 downto 0);

  -- Combinational decode of the current input beat
  signal tpid_c    : std_logic_vector(15 downto 0);
  signal is_vlan_c : std_logic;

  -- Extracted fields
  signal dst_mac_r      : std_logic_vector(47 downto 0);
  signal src_mac_r      : std_logic_vector(47 downto 0);
  signal ethertype_r    : std_logic_vector(15 downto 0);
  signal vlan_tci_r     : std_logic_vector(15 downto 0);
  signal vlan_present_r : std_logic;
  signal hdr_trunc_r    : std_logic;
  signal fields_valid_r : std_logic;

  -- Data path pipeline register
  signal tdata_r  : std_logic_vector(63 downto 0);
  signal tkeep_r  : std_logic_vector(7 downto 0);
  signal tvalid_r : std_logic;
  signal tlast_r  : std_logic;

begin

  ------------------------------------------------------------------------------
  -- Backpressure: parsers never stall. m_axis_tready is deliberately ignored;
  -- the order book engine handles backpressure downstream. Expect an unused
  -- port warning from synthesis.
  ------------------------------------------------------------------------------
  s_axis_tready <= '1';

  ------------------------------------------------------------------------------
  -- VLAN detect. 16-bit equality on bytes 12..13, meaningful on beat 1 only.
  -- One compare plus one mux level, so this does not gate timing.
  ------------------------------------------------------------------------------
  tpid_c    <= bsel(s_axis_tdata, 4) & bsel(s_axis_tdata, 5);
  is_vlan_c <= '1' when tpid_c = G_TPID else '0';

  ------------------------------------------------------------------------------
  -- Data path: straight passthrough, one register stage. Matches the single
  -- register stage on the field bus so the two stay aligned through the chain.
  ------------------------------------------------------------------------------
  p_datapath : process (clk)
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        tdata_r  <= (others => '0');
        tkeep_r  <= (others => '0');
        tvalid_r <= '0';
        tlast_r  <= '0';
      else
        tdata_r  <= s_axis_tdata;
        tkeep_r  <= s_axis_tkeep;
        tvalid_r <= s_axis_tvalid;
        tlast_r  <= s_axis_tlast and s_axis_tvalid;
      end if;
    end if;
  end process p_datapath;

  ------------------------------------------------------------------------------
  -- Header extraction. Fixed-offset latching, one beat per cycle.
  ------------------------------------------------------------------------------
  p_parse : process (clk)
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        beat_cnt       <= (others => '0');
        dst_mac_r      <= (others => '0');
        src_mac_r      <= (others => '0');
        ethertype_r    <= (others => '0');
        vlan_tci_r     <= (others => '0');
        vlan_present_r <= '0';
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
          elsif beat_cnt /= 3 then
            beat_cnt <= beat_cnt + 1;
          end if;

          ----------------------------------------------------------------------
          -- Field capture
          ----------------------------------------------------------------------
          case to_integer(beat_cnt) is

            -- Beat 0 : bytes 0..7
            when 0 =>
              dst_mac_r <= bsel(s_axis_tdata, 0) & bsel(s_axis_tdata, 1) &
                           bsel(s_axis_tdata, 2) & bsel(s_axis_tdata, 3) &
                           bsel(s_axis_tdata, 4) & bsel(s_axis_tdata, 5);

              src_mac_r(47 downto 32) <= bsel(s_axis_tdata, 6) &
                                         bsel(s_axis_tdata, 7);

              -- new packet: clear per-packet status
              vlan_present_r <= '0';
              hdr_trunc_r    <= s_axis_tlast;   -- frame ended inside beat 0

              if s_axis_tlast = '1' then
                fields_valid_r <= '1';          -- truncated, but settled
              end if;

            -- Beat 1 : bytes 8..15
            when 1 =>
              src_mac_r(31 downto 0) <= bsel(s_axis_tdata, 0) &
                                        bsel(s_axis_tdata, 1) &
                                        bsel(s_axis_tdata, 2) &
                                        bsel(s_axis_tdata, 3);

              vlan_present_r <= is_vlan_c;

              if is_vlan_c = '1' then
                -- tagged: TCI here, real ethertype arrives on beat 2
                vlan_tci_r  <= bsel(s_axis_tdata, 6) & bsel(s_axis_tdata, 7);
                hdr_trunc_r <= s_axis_tlast;    -- frame ended before beat 2
                if s_axis_tlast = '1' then
                  fields_valid_r <= '1';
                end if;
              else
                -- untagged: header complete
                vlan_tci_r     <= (others => '0');
                ethertype_r    <= bsel(s_axis_tdata, 4) & bsel(s_axis_tdata, 5);
                fields_valid_r <= '1';
              end if;

            -- Beat 2 : bytes 16..23, tagged frames only
            when 2 =>
              if vlan_present_r = '1' then
                ethertype_r    <= bsel(s_axis_tdata, 0) & bsel(s_axis_tdata, 1);
                fields_valid_r <= '1';
              end if;

            when others =>
              null;

          end case;

        end if;
      end if;
    end if;
  end process p_parse;

  ------------------------------------------------------------------------------
  -- Outputs. All registered.
  ------------------------------------------------------------------------------
  m_axis_tdata  <= tdata_r;
  m_axis_tkeep  <= tkeep_r;
  m_axis_tvalid <= tvalid_r;
  m_axis_tlast  <= tlast_r;

  m_fields(C_DST_MAC_LO   + C_DST_MAC_W   - 1 downto C_DST_MAC_LO)   <= dst_mac_r;
  m_fields(C_SRC_MAC_LO   + C_SRC_MAC_W   - 1 downto C_SRC_MAC_LO)   <= src_mac_r;
  m_fields(C_ETHERTYPE_LO + C_ETHERTYPE_W - 1 downto C_ETHERTYPE_LO) <= ethertype_r;
  m_fields(C_VLAN_TCI_LO  + C_VLAN_TCI_W  - 1 downto C_VLAN_TCI_LO)  <= vlan_tci_r;
  m_fields(C_VLAN_PRESENT_LO)                                        <= vlan_present_r;
  m_fields(C_ETH_TRUNC_LO)                                           <= hdr_trunc_r;

  m_fields_valid <= fields_valid_r;

end architecture rtl;
