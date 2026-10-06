--------------------------------------------------------------------------------
-- tx_top
--
-- Top for the transmit side: one UDP/IPv4/Ethernet frame per timestamp event,
-- driven out on 64-bit XGMII.
--
--   time_event_fifo (in the engine) -> order_tx_xgmii -> XGMII to the PCS
--
-- Nothing but wiring lives here. The frame contents - addresses, ports, payload
-- width - are in order_tx_pkg.
--
-- The slave port is the event FIFO's master side, taken as it comes:
--
--   s_payload (MSB first): event_type(2) op(2) data(64) side(1) ts(18)
--
-- Its width is C_PAYLOAD_BITS from order_tx_pkg. If that and the event FIFO's
-- m_payload ever disagree, the port map in market_data_top fails to elaborate,
-- which is the intended check.
--
-- order_tx_xgmii takes an active-high synchronous reset; the rest of the design
-- is active low, so it is inverted here and nowhere else.
--
-- One frame occupies the transmitter for 10 + G_IPG_WORDS cycles, and s_ready
-- is low for all of them. The event FIFO upstream has to absorb whatever
-- arrives in that time.
--
-- VHDL-2008
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use work.order_tx_pkg.all;

entity tx_top is
  generic (
    G_IPG_WORDS : positive := 2            -- idle beats after the terminate beat
  );
  port (
    clk       : in    std_logic;
    resetn    : in    std_logic;           -- synchronous, active low

    ----------------------------------------------------------------------------
    -- Slave: one timestamp event per transfer
    ----------------------------------------------------------------------------
    s_valid   : in    std_logic;
    s_ready   : out   std_logic;
    s_payload : in    std_logic_vector(C_PAYLOAD_BITS - 1 downto 0);

    ----------------------------------------------------------------------------
    -- Master: 64-bit XGMII to the PCS
    ----------------------------------------------------------------------------
    xgmii_txd : out   std_logic_vector(63 downto 0);
    xgmii_txc : out   std_logic_vector(7 downto 0)
  );
end entity tx_top;

architecture rtl of tx_top is

  signal rst : std_logic;

begin

  rst <= not resetn;

  u_order_tx_xgmii : entity work.order_tx_xgmii
    generic map (
      G_IPG_WORDS => G_IPG_WORDS
    )
    port map (
      clk           => clk,
      rst           => rst,

      s_axis_tvalid => s_valid,
      s_axis_tready => s_ready,
      s_axis_tdata  => s_payload,

      xgmii_txd     => xgmii_txd,
      xgmii_txc     => xgmii_txc
    );

end architecture rtl;
