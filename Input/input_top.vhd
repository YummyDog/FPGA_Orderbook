--------------------------------------------------------------------------------
-- input_top
--
-- Front end of the receive path. Structural, same style as fullparser and
-- order_book_engine_top.
--
--   xgmii -> xgmii64_to_axis   -> AXI-Stream to the parser chain
--         -> xgmii_crc32_rx64  -> fcs_msg_extend_sync -> FCS flags
--
-- The raw XGMII bus feeds both children: the converter strips preamble/SFD and
-- presents the frame as a packet, the checker sees the whole frame including
-- preamble and FCS.
--
-- Single clock throughout, so no CDC. msg_count comes from the MoldUDP64 stage
-- downstream and is paired with the FCS result for this packet by arrival
-- order; msg_count_valid is mold_parser's m_fields_valid pulse.
--
-- resetn is active low here to match the rest of the design; the children take
-- active-high resets.
--
-- VHDL-2008
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity input_top is
  generic (
    G_CHECK_PREAMBLE : boolean  := true;
    G_COUNT_W        : positive := 16;
    G_ZERO_AS_ONE    : boolean  := true
  );
  port (
    clk             : in    std_logic;
    resetn          : in    std_logic;   -- synchronous, active low

    ----------------------------------------------------------------------------
    -- 64-bit XGMII from the PCS. /S/ is assumed to be in lane 0.
    ----------------------------------------------------------------------------
    xgmii_rxd       : in    std_logic_vector(63 downto 0);
    xgmii_rxc       : in    std_logic_vector(7 downto 0);

    ----------------------------------------------------------------------------
    -- Master: frame without preamble/SFD, FCS still attached
    ----------------------------------------------------------------------------
    m_axis_tdata    : out   std_logic_vector(63 downto 0);
    m_axis_tkeep    : out   std_logic_vector(7 downto 0);
    m_axis_tvalid   : out   std_logic;
    m_axis_tready   : in    std_logic;   -- monitored only, nothing can stall
    m_axis_tlast    : out   std_logic;
    m_axis_tuser    : out   std_logic_vector(0 downto 0);

    ----------------------------------------------------------------------------
    -- Message count for this packet, from mold_parser
    ----------------------------------------------------------------------------
    msg_count       : in    std_logic_vector(G_COUNT_W - 1 downto 0);
    msg_count_valid : in    std_logic;

    ----------------------------------------------------------------------------
    -- FCS result, stretched to msg_count cycles
    ----------------------------------------------------------------------------
    fcs_complete    : out   std_logic;
    fcs_true        : out   std_logic;
    fcs_false       : out   std_logic;

    ----------------------------------------------------------------------------
    -- Status
    ----------------------------------------------------------------------------
    axis_overflow   : out   std_logic;   -- a beat was presented with tready low
    fcs_pair_err    : out   std_logic    -- result/count pairing lost a packet
  );
end entity input_top;

architecture rtl of input_top is

  signal rst      : std_logic;

  signal crc_done : std_logic;
  signal crc_ok   : std_logic;
  signal crc_bad  : std_logic;

begin

  rst <= not resetn;

  ------------------------------------------------------------------------------
  -- XGMII to AXI-Stream, preamble and SFD stripped
  ------------------------------------------------------------------------------
  u_axis : entity work.xgmii64_to_axis
    generic map (
      G_CHECK_PREAMBLE => G_CHECK_PREAMBLE
    )
    port map (
      clk           => clk,
      rst           => rst,

      xgmii_rxd     => xgmii_rxd,
      xgmii_rxc     => xgmii_rxc,

      m_axis_tdata  => m_axis_tdata,
      m_axis_tkeep  => m_axis_tkeep,
      m_axis_tvalid => m_axis_tvalid,
      m_axis_tready => m_axis_tready,
      m_axis_tlast  => m_axis_tlast,
      m_axis_tuser  => m_axis_tuser,

      overflow      => axis_overflow
    );

  ------------------------------------------------------------------------------
  -- FCS check on the raw XGMII bus
  ------------------------------------------------------------------------------
  u_crc : entity work.xgmii_crc32_rx64
    generic map (
      G_CHECK_PREAMBLE => G_CHECK_PREAMBLE
    )
    port map (
      clk          => clk,
      rst          => rst,

      xgmii_rxd    => xgmii_rxd,
      xgmii_rxc    => xgmii_rxc,

      crc_complete => crc_done,
      fcs_true     => crc_ok,
      fcs_false    => crc_bad
    );

  ------------------------------------------------------------------------------
  -- Stretch the result to the packet's message count
  ------------------------------------------------------------------------------
  u_extend : entity work.fcs_msg_extend_sync
    generic map (
      G_COUNT_W     => G_COUNT_W,
      G_ZERO_AS_ONE => G_ZERO_AS_ONE
    )
    port map (
      clk             => clk,
      rst             => rst,

      crc_complete    => crc_done,
      fcs_true        => crc_ok,
      fcs_false       => crc_bad,

      msg_count       => msg_count,
      msg_count_valid => msg_count_valid,

      ext_complete    => fcs_complete,
      ext_fcs_true    => fcs_true,
      ext_fcs_false   => fcs_false,
      pair_err        => fcs_pair_err
    );

end architecture rtl;
