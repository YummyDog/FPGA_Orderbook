--------------------------------------------------------------------------------
-- market_data_top
--
-- Final top: XGMII in, order book out, timestamp events out on XGMII.
--
--   input_top -> fullparser -> order_book_engine_top -> tx_top
--
-- input_top holds the XGMII-to-AXI-Stream converter, the FCS checker and the
-- pulse extender. The raw XGMII bus feeds the converter and the checker in
-- parallel; the converter strips preamble and SFD and hands the frame, FCS
-- included, to the parser chain.
--
-- The FCS result is stretched to the packet's MoldUDP64 message count, which
-- comes back out of fullparser's mold stage, and lands in order_fifo where it
-- is registered and nothing more. That flop exists so the path can be timed.
--
-- tx_top frames each timestamp event the engine produces as one UDP/IPv4/
-- Ethernet frame and drives it out on xgmii_txd / xgmii_txc. The event stream
-- is a valid/ready link: the transmitter is busy for a whole frame per event,
-- and the engine's event FIFO holds the rest. Nothing on the transmit side
-- pushes back into the book.
--
-- Single clock. No CDC anywhere - the transmit XGMII is on clk as well.
--
-- VHDL-2008
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use work.itch_parser_pkg.all;

entity market_data_top is
  generic (
    G_TPID           : std_logic_vector(15 downto 0) := x"8100";
    G_ORDER_BOOK_ID  : natural                       := 85603;
    G_FIFO_DEPTH     : positive                      := 16;
    G_MAX_ORDERS     : natural                       := 16384;
    G_CHECK_PREAMBLE : boolean                       := true;
    G_TX_IPG_WORDS   : positive                      := 2
  );
  port (
    clk              : in    std_logic;
    resetn           : in    std_logic;

    ----------------------------------------------------------------------------
    -- Slave: 64-bit XGMII from the PCS
    ----------------------------------------------------------------------------
    xgmii_rxd        : in    std_logic_vector(63 downto 0);
    xgmii_rxc        : in    std_logic_vector(7 downto 0);

    ----------------------------------------------------------------------------
    -- Master: 64-bit XGMII to the PCS, one frame per timestamp event
    ----------------------------------------------------------------------------
    xgmii_txd        : out   std_logic_vector(63 downto 0);
    xgmii_txc        : out   std_logic_vector(7 downto 0);

    ----------------------------------------------------------------------------
    -- Master: packet passthrough, taken from the input stage
    ----------------------------------------------------------------------------
    m_axis_tdata     : out   std_logic_vector(63 downto 0);
    m_axis_tkeep     : out   std_logic_vector(7 downto 0);
    m_axis_tvalid    : out   std_logic;
    m_axis_tready    : in    std_logic;
    m_axis_tlast     : out   std_logic;
    m_axis_tuser     : out   std_logic_vector(0 downto 0);

    ----------------------------------------------------------------------------
    -- Price window
    ----------------------------------------------------------------------------
    base_price       : in    std_logic_vector(31 downto 0);

    --FOR TESTING
    test_number : in std_logic_vector(4 downto 0);

    ----------------------------------------------------------------------------
    -- Master: top of book
    ----------------------------------------------------------------------------
    m_tvalid         : out   std_logic;
    m_tready         : in    std_logic;

    m_bid_price      : out   std_logic_vector(31 downto 0);
    m_bid_qty        : out   std_logic_vector(31 downto 0);
    m_ask_price      : out   std_logic_vector(31 downto 0);
    m_ask_qty        : out   std_logic_vector(31 downto 0);
    m_valid          : out   std_logic_vector(1 downto 0);

    ----------------------------------------------------------------------------
    -- Status
    ----------------------------------------------------------------------------
    exchange_seconds : out   std_logic_vector(31 downto 0);
    pkt_done         : out   std_logic;
    pkt_msg_count    : out   std_logic_vector(15 downto 0);
    msg_status       : out   std_logic_vector(C_MSG_STATUS_W - 1 downto 0);

    book_busy        : out   std_logic;
    level_busy       : out   std_logic;
    oor              : out   std_logic;
    fifo_full        : out   std_logic;
    fifo_overflow    : out   std_logic;
    stat_bad_side    : out   std_logic;
    stat_qty_ovf     : out   std_logic;

    ----------------------------------------------------------------------------
    -- Input stage status
    ----------------------------------------------------------------------------
    axis_overflow    : out   std_logic;
    fcs_pair_err     : out   std_logic;
    fcs_flags        : out   std_logic_vector(2 downto 0)
  );
end entity market_data_top;

architecture rtl of market_data_top is

  ------------------------------------------------------------------------------
  -- input_top -> fullparser
  ------------------------------------------------------------------------------
  signal p_tdata  : std_logic_vector(63 downto 0);
  signal p_tkeep  : std_logic_vector(7 downto 0);
  signal p_tvalid : std_logic;
  signal p_tready : std_logic;
  signal p_tlast  : std_logic;
  signal p_tuser  : std_logic_vector(0 downto 0);

  ------------------------------------------------------------------------------
  -- fullparser -> input_top (message count) and -> engine
  ------------------------------------------------------------------------------
  signal mold_cnt     : std_logic_vector(15 downto 0);
  signal mold_cnt_v   : std_logic;

  signal msg_type_i   : std_logic_vector(7 downto 0);
  signal msg_fields_i : std_logic_vector(C_MSG_FIELDS_W - 1 downto 0);
  signal msg_status_i : std_logic_vector(C_MSG_STATUS_W - 1 downto 0);
  signal eng_valid    : std_logic;

  ------------------------------------------------------------------------------
  -- input_top -> engine
  ------------------------------------------------------------------------------
  signal fcs_complete_i : std_logic;
  signal fcs_true_i     : std_logic;
  signal fcs_false_i    : std_logic;

  ------------------------------------------------------------------------------
  -- engine -> tx_top : timestamp event stream
  --
  -- payload (MSB first): event_type(2) op(2) data(64) side(1) ts(18)
  --
  -- 87 bits, the event FIFO's own width. tx_top takes C_PAYLOAD_BITS from
  -- order_tx_pkg, so a mismatch between the two stops elaboration here.
  ------------------------------------------------------------------------------
  signal ev_valid_i   : std_logic;
  signal ev_ready_i   : std_logic;
  signal ev_payload_i : std_logic_vector(86 downto 0);

begin

  ------------------------------------------------------------------------------
  -- Stage 0 : XGMII to AXI-Stream, FCS check, pulse extension
  ------------------------------------------------------------------------------
  u_input : entity work.input_top
    generic map (
      G_CHECK_PREAMBLE => G_CHECK_PREAMBLE,
      G_COUNT_W        => 16,
      G_ZERO_AS_ONE    => true
    )
    port map (
      clk             => clk,
      resetn          => resetn,

      xgmii_rxd       => xgmii_rxd,
      xgmii_rxc       => xgmii_rxc,

      m_axis_tdata    => p_tdata,
      m_axis_tkeep    => p_tkeep,
      m_axis_tvalid   => p_tvalid,
      m_axis_tready   => p_tready,
      m_axis_tlast    => p_tlast,
      m_axis_tuser    => p_tuser,

      msg_count       => mold_cnt,
      msg_count_valid => mold_cnt_v,

      fcs_complete    => fcs_complete_i,
      fcs_true        => fcs_true_i,
      fcs_false       => fcs_false_i,

      axis_overflow   => axis_overflow,
      fcs_pair_err    => fcs_pair_err
    );

  -- Packet passthrough, straight off the input stage
  m_axis_tdata  <= p_tdata;
  m_axis_tkeep  <= p_tkeep;
  m_axis_tvalid <= p_tvalid;
  m_axis_tlast  <= p_tlast;
  m_axis_tuser  <= p_tuser;

  ------------------------------------------------------------------------------
  -- Stage 1-5 : packet parsing
  ------------------------------------------------------------------------------
  u_fullparser : entity work.fullparser
    generic map (
      G_TPID => G_TPID
    )
    port map (
      clk               => clk,
      resetn            => resetn,

      s_axis_tdata      => p_tdata,
      s_axis_tkeep      => p_tkeep,
      s_axis_tvalid     => p_tvalid,
      s_axis_tready     => p_tready,
      s_axis_tlast      => p_tlast,

      msg_valid         => eng_valid,
      msg_index         => open,
      msg_seqnum        => open,
      msg_type          => msg_type_i,
      msg_length        => open,
      msg_fields        => msg_fields_i,
      msg_status        => msg_status_i,
      pkt_fields        => open,

      exchange_seconds  => exchange_seconds,

      pkt_done          => pkt_done,
      pkt_msg_count     => pkt_msg_count,

      mold_msgcnt       => mold_cnt,

      eth_fields_valid  => open,
      ipv4_fields_valid => open,
      udp_fields_valid  => open,
      mold_fields_valid => mold_cnt_v
    );

  msg_status <= msg_status_i;

  ------------------------------------------------------------------------------
  -- Order book engine
  ------------------------------------------------------------------------------
  u_engine : entity work.order_book_engine_top
    generic map (
      G_ORDER_BOOK_ID => G_ORDER_BOOK_ID,
      G_FIFO_DEPTH    => G_FIFO_DEPTH,
      G_MAX_ORDERS    => G_MAX_ORDERS
    )
    port map (
      clk           => clk,
      resetn        => resetn,

      s_valid       => eng_valid,
      s_type        => msg_type_i,
      s_fields      => msg_fields_i,

      fcs_complete  => fcs_complete_i,
      fcs_true      => fcs_true_i,
      fcs_false     => fcs_false_i,
      fcs_flags     => fcs_flags,

      base_price    => base_price,

      m_tvalid      => m_tvalid,
      m_tready      => m_tready,
      m_bid_price   => m_bid_price,
      m_bid_qty     => m_bid_qty,
      m_ask_price   => m_ask_price,
      m_ask_qty     => m_ask_qty,
      m_valid       => m_valid,

      ev_valid      => ev_valid_i,
      ev_ready      => ev_ready_i,
      ev_payload    => ev_payload_i,

      book_busy     => book_busy,
      level_busy    => level_busy,
      oor           => oor,
      fifo_full     => fifo_full,
      fifo_overflow => fifo_overflow,
      stat_bad_side => stat_bad_side,
      stat_qty_ovf  => stat_qty_ovf
    );

  ------------------------------------------------------------------------------
  -- Transmit : one frame per timestamp event
  ------------------------------------------------------------------------------
  u_tx : entity work.tx_top
    generic map (
      G_IPG_WORDS => G_TX_IPG_WORDS
    )
    port map (
      clk       => clk,
      resetn    => resetn,

      s_valid   => ev_valid_i,
      s_ready   => ev_ready_i,
      s_payload => ev_payload_i,

      xgmii_txd => xgmii_txd,
      xgmii_txc => xgmii_txc
    );

end architecture rtl;
