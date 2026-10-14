--Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
--Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2026.1 (win64) Build 6511674 Tue Jun 16 11:02:23 MDT 2026
--Date        : Wed Oct 14 23:06:06 2026
--Host        : DESKTOP-MB4FOM3 running 64-bit major release  (build 9200)
--Command     : generate_target top.bd
--Design      : top
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity top is
  attribute CORE_GENERATION_INFO : string;
  attribute CORE_GENERATION_INFO of top : entity is "top,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=top,x_ipVersion=1.00.a,x_ipLanguage=VHDL}";
  attribute HW_HANDOFF : string;
  attribute HW_HANDOFF of top : entity is "top.hwdef";
end top;

architecture STRUCTURE of top is
  component top_market_data_top_0_0 is
  port (
    clk : in STD_LOGIC;
    resetn : in STD_LOGIC;
    xgmii_rxd : in STD_LOGIC_VECTOR ( 63 downto 0 );
    xgmii_rxc : in STD_LOGIC_VECTOR ( 7 downto 0 );
    xgmii_txd : out STD_LOGIC_VECTOR ( 63 downto 0 );
    xgmii_txc : out STD_LOGIC_VECTOR ( 7 downto 0 );
    m_axis_tdata : out STD_LOGIC_VECTOR ( 63 downto 0 );
    m_axis_tkeep : out STD_LOGIC_VECTOR ( 7 downto 0 );
    m_axis_tvalid : out STD_LOGIC;
    m_axis_tready : in STD_LOGIC;
    m_axis_tlast : out STD_LOGIC;
    m_axis_tuser : out STD_LOGIC_VECTOR ( 0 to 0 );
    base_price : in STD_LOGIC_VECTOR ( 31 downto 0 );
    test_number : in STD_LOGIC_VECTOR ( 4 downto 0 );
    m_tvalid : out STD_LOGIC;
    m_tready : in STD_LOGIC;
    m_bid_price : out STD_LOGIC_VECTOR ( 31 downto 0 );
    m_bid_qty : out STD_LOGIC_VECTOR ( 31 downto 0 );
    m_ask_price : out STD_LOGIC_VECTOR ( 31 downto 0 );
    m_ask_qty : out STD_LOGIC_VECTOR ( 31 downto 0 );
    m_valid : out STD_LOGIC_VECTOR ( 1 downto 0 );
    exchange_seconds : out STD_LOGIC_VECTOR ( 31 downto 0 );
    pkt_done : out STD_LOGIC;
    pkt_msg_count : out STD_LOGIC_VECTOR ( 15 downto 0 );
    msg_status : out STD_LOGIC_VECTOR ( 5 downto 0 );
    book_busy : out STD_LOGIC;
    level_busy : out STD_LOGIC;
    oor : out STD_LOGIC;
    fifo_full : out STD_LOGIC;
    fifo_overflow : out STD_LOGIC;
    stat_bad_side : out STD_LOGIC;
    stat_qty_ovf : out STD_LOGIC;
    axis_overflow : out STD_LOGIC;
    fcs_pair_err : out STD_LOGIC;
    fcs_flags : out STD_LOGIC_VECTOR ( 2 downto 0 )
  );
  end component top_market_data_top_0_0;
  component top_ten_gig_eth_pcs_pma_0_0 is
  port (
    refclk_p : in STD_LOGIC;
    refclk_n : in STD_LOGIC;
    reset : in STD_LOGIC;
    resetdone_out : out STD_LOGIC;
    coreclk_out : out STD_LOGIC;
    rxrecclk_out : out STD_LOGIC;
    dclk : in STD_LOGIC;
    txp : out STD_LOGIC;
    txn : out STD_LOGIC;
    rxp : in STD_LOGIC;
    rxn : in STD_LOGIC;
    sim_speedup_control : in STD_LOGIC;
    txusrclk_out : out STD_LOGIC;
    txusrclk2_out : out STD_LOGIC;
    areset_datapathclk_out : out STD_LOGIC;
    gttxreset_out : out STD_LOGIC;
    gtrxreset_out : out STD_LOGIC;
    txuserrdy_out : out STD_LOGIC;
    reset_counter_done_out : out STD_LOGIC;
    qplllock_out : out STD_LOGIC;
    qplloutclk_out : out STD_LOGIC;
    qplloutrefclk_out : out STD_LOGIC;
    xgmii_txd : in STD_LOGIC_VECTOR ( 63 downto 0 );
    xgmii_txc : in STD_LOGIC_VECTOR ( 7 downto 0 );
    xgmii_rxd : out STD_LOGIC_VECTOR ( 63 downto 0 );
    xgmii_rxc : out STD_LOGIC_VECTOR ( 7 downto 0 );
    mdc : in STD_LOGIC;
    mdio_in : in STD_LOGIC;
    mdio_out : out STD_LOGIC;
    mdio_tri : out STD_LOGIC;
    prtad : in STD_LOGIC_VECTOR ( 4 downto 0 );
    core_status : out STD_LOGIC_VECTOR ( 7 downto 0 );
    signal_detect : in STD_LOGIC;
    tx_fault : in STD_LOGIC;
    drp_req : out STD_LOGIC;
    drp_gnt : in STD_LOGIC;
    drp_den_o : out STD_LOGIC;
    drp_dwe_o : out STD_LOGIC;
    drp_daddr_o : out STD_LOGIC_VECTOR ( 15 downto 0 );
    drp_di_o : out STD_LOGIC_VECTOR ( 15 downto 0 );
    drp_drdy_o : out STD_LOGIC;
    drp_drpdo_o : out STD_LOGIC_VECTOR ( 15 downto 0 );
    drp_den_i : in STD_LOGIC;
    drp_dwe_i : in STD_LOGIC;
    drp_daddr_i : in STD_LOGIC_VECTOR ( 15 downto 0 );
    drp_di_i : in STD_LOGIC_VECTOR ( 15 downto 0 );
    drp_drdy_i : in STD_LOGIC;
    drp_drpdo_i : in STD_LOGIC_VECTOR ( 15 downto 0 );
    tx_disable : out STD_LOGIC;
    pma_pmd_type : in STD_LOGIC_VECTOR ( 2 downto 0 )
  );
  end component top_ten_gig_eth_pcs_pma_0_0;
  signal market_data_top_0_xgmii_txc : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal market_data_top_0_xgmii_txd : STD_LOGIC_VECTOR ( 63 downto 0 );
  signal ten_gig_eth_pcs_pma_0_coreclk_out : STD_LOGIC;
  signal ten_gig_eth_pcs_pma_0_xgmii_rxc : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal ten_gig_eth_pcs_pma_0_xgmii_rxd : STD_LOGIC_VECTOR ( 63 downto 0 );
  signal NLW_market_data_top_0_axis_overflow_UNCONNECTED : STD_LOGIC;
  signal NLW_market_data_top_0_book_busy_UNCONNECTED : STD_LOGIC;
  signal NLW_market_data_top_0_fcs_pair_err_UNCONNECTED : STD_LOGIC;
  signal NLW_market_data_top_0_fifo_full_UNCONNECTED : STD_LOGIC;
  signal NLW_market_data_top_0_fifo_overflow_UNCONNECTED : STD_LOGIC;
  signal NLW_market_data_top_0_level_busy_UNCONNECTED : STD_LOGIC;
  signal NLW_market_data_top_0_m_axis_tlast_UNCONNECTED : STD_LOGIC;
  signal NLW_market_data_top_0_m_axis_tvalid_UNCONNECTED : STD_LOGIC;
  signal NLW_market_data_top_0_m_tvalid_UNCONNECTED : STD_LOGIC;
  signal NLW_market_data_top_0_oor_UNCONNECTED : STD_LOGIC;
  signal NLW_market_data_top_0_pkt_done_UNCONNECTED : STD_LOGIC;
  signal NLW_market_data_top_0_stat_bad_side_UNCONNECTED : STD_LOGIC;
  signal NLW_market_data_top_0_stat_qty_ovf_UNCONNECTED : STD_LOGIC;
  signal NLW_market_data_top_0_exchange_seconds_UNCONNECTED : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal NLW_market_data_top_0_fcs_flags_UNCONNECTED : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal NLW_market_data_top_0_m_ask_price_UNCONNECTED : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal NLW_market_data_top_0_m_ask_qty_UNCONNECTED : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal NLW_market_data_top_0_m_axis_tdata_UNCONNECTED : STD_LOGIC_VECTOR ( 63 downto 0 );
  signal NLW_market_data_top_0_m_axis_tkeep_UNCONNECTED : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal NLW_market_data_top_0_m_axis_tuser_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_market_data_top_0_m_bid_price_UNCONNECTED : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal NLW_market_data_top_0_m_bid_qty_UNCONNECTED : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal NLW_market_data_top_0_m_valid_UNCONNECTED : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal NLW_market_data_top_0_msg_status_UNCONNECTED : STD_LOGIC_VECTOR ( 5 downto 0 );
  signal NLW_market_data_top_0_pkt_msg_count_UNCONNECTED : STD_LOGIC_VECTOR ( 15 downto 0 );
  signal NLW_ten_gig_eth_pcs_pma_0_areset_datapathclk_out_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_0_drp_den_o_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_0_drp_drdy_o_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_0_drp_dwe_o_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_0_drp_req_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_0_gtrxreset_out_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_0_gttxreset_out_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_0_mdio_out_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_0_mdio_tri_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_0_qplllock_out_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_0_qplloutclk_out_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_0_qplloutrefclk_out_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_0_reset_counter_done_out_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_0_resetdone_out_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_0_rxrecclk_out_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_0_tx_disable_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_0_txn_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_0_txp_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_0_txuserrdy_out_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_0_txusrclk2_out_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_0_txusrclk_out_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_0_core_status_UNCONNECTED : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal NLW_ten_gig_eth_pcs_pma_0_drp_daddr_o_UNCONNECTED : STD_LOGIC_VECTOR ( 15 downto 0 );
  signal NLW_ten_gig_eth_pcs_pma_0_drp_di_o_UNCONNECTED : STD_LOGIC_VECTOR ( 15 downto 0 );
  signal NLW_ten_gig_eth_pcs_pma_0_drp_drpdo_o_UNCONNECTED : STD_LOGIC_VECTOR ( 15 downto 0 );
begin
market_data_top_0: component top_market_data_top_0_0
     port map (
      axis_overflow => NLW_market_data_top_0_axis_overflow_UNCONNECTED,
      base_price(31 downto 0) => B"00000000000000000000000000000000",
      book_busy => NLW_market_data_top_0_book_busy_UNCONNECTED,
      clk => ten_gig_eth_pcs_pma_0_coreclk_out,
      exchange_seconds(31 downto 0) => NLW_market_data_top_0_exchange_seconds_UNCONNECTED(31 downto 0),
      fcs_flags(2 downto 0) => NLW_market_data_top_0_fcs_flags_UNCONNECTED(2 downto 0),
      fcs_pair_err => NLW_market_data_top_0_fcs_pair_err_UNCONNECTED,
      fifo_full => NLW_market_data_top_0_fifo_full_UNCONNECTED,
      fifo_overflow => NLW_market_data_top_0_fifo_overflow_UNCONNECTED,
      level_busy => NLW_market_data_top_0_level_busy_UNCONNECTED,
      m_ask_price(31 downto 0) => NLW_market_data_top_0_m_ask_price_UNCONNECTED(31 downto 0),
      m_ask_qty(31 downto 0) => NLW_market_data_top_0_m_ask_qty_UNCONNECTED(31 downto 0),
      m_axis_tdata(63 downto 0) => NLW_market_data_top_0_m_axis_tdata_UNCONNECTED(63 downto 0),
      m_axis_tkeep(7 downto 0) => NLW_market_data_top_0_m_axis_tkeep_UNCONNECTED(7 downto 0),
      m_axis_tlast => NLW_market_data_top_0_m_axis_tlast_UNCONNECTED,
      m_axis_tready => '1',
      m_axis_tuser(0) => NLW_market_data_top_0_m_axis_tuser_UNCONNECTED(0),
      m_axis_tvalid => NLW_market_data_top_0_m_axis_tvalid_UNCONNECTED,
      m_bid_price(31 downto 0) => NLW_market_data_top_0_m_bid_price_UNCONNECTED(31 downto 0),
      m_bid_qty(31 downto 0) => NLW_market_data_top_0_m_bid_qty_UNCONNECTED(31 downto 0),
      m_tready => '1',
      m_tvalid => NLW_market_data_top_0_m_tvalid_UNCONNECTED,
      m_valid(1 downto 0) => NLW_market_data_top_0_m_valid_UNCONNECTED(1 downto 0),
      msg_status(5 downto 0) => NLW_market_data_top_0_msg_status_UNCONNECTED(5 downto 0),
      oor => NLW_market_data_top_0_oor_UNCONNECTED,
      pkt_done => NLW_market_data_top_0_pkt_done_UNCONNECTED,
      pkt_msg_count(15 downto 0) => NLW_market_data_top_0_pkt_msg_count_UNCONNECTED(15 downto 0),
      resetn => '0',
      stat_bad_side => NLW_market_data_top_0_stat_bad_side_UNCONNECTED,
      stat_qty_ovf => NLW_market_data_top_0_stat_qty_ovf_UNCONNECTED,
      test_number(4 downto 0) => B"00000",
      xgmii_rxc(7 downto 0) => ten_gig_eth_pcs_pma_0_xgmii_rxc(7 downto 0),
      xgmii_rxd(63 downto 0) => ten_gig_eth_pcs_pma_0_xgmii_rxd(63 downto 0),
      xgmii_txc(7 downto 0) => market_data_top_0_xgmii_txc(7 downto 0),
      xgmii_txd(63 downto 0) => market_data_top_0_xgmii_txd(63 downto 0)
    );
ten_gig_eth_pcs_pma_0: component top_ten_gig_eth_pcs_pma_0_0
     port map (
      areset_datapathclk_out => NLW_ten_gig_eth_pcs_pma_0_areset_datapathclk_out_UNCONNECTED,
      core_status(7 downto 0) => NLW_ten_gig_eth_pcs_pma_0_core_status_UNCONNECTED(7 downto 0),
      coreclk_out => ten_gig_eth_pcs_pma_0_coreclk_out,
      dclk => ten_gig_eth_pcs_pma_0_coreclk_out,
      drp_daddr_i(15 downto 0) => B"0000000000000000",
      drp_daddr_o(15 downto 0) => NLW_ten_gig_eth_pcs_pma_0_drp_daddr_o_UNCONNECTED(15 downto 0),
      drp_den_i => '0',
      drp_den_o => NLW_ten_gig_eth_pcs_pma_0_drp_den_o_UNCONNECTED,
      drp_di_i(15 downto 0) => B"0000000000000000",
      drp_di_o(15 downto 0) => NLW_ten_gig_eth_pcs_pma_0_drp_di_o_UNCONNECTED(15 downto 0),
      drp_drdy_i => '0',
      drp_drdy_o => NLW_ten_gig_eth_pcs_pma_0_drp_drdy_o_UNCONNECTED,
      drp_drpdo_i(15 downto 0) => B"0000000000000000",
      drp_drpdo_o(15 downto 0) => NLW_ten_gig_eth_pcs_pma_0_drp_drpdo_o_UNCONNECTED(15 downto 0),
      drp_dwe_i => '0',
      drp_dwe_o => NLW_ten_gig_eth_pcs_pma_0_drp_dwe_o_UNCONNECTED,
      drp_gnt => '0',
      drp_req => NLW_ten_gig_eth_pcs_pma_0_drp_req_UNCONNECTED,
      gtrxreset_out => NLW_ten_gig_eth_pcs_pma_0_gtrxreset_out_UNCONNECTED,
      gttxreset_out => NLW_ten_gig_eth_pcs_pma_0_gttxreset_out_UNCONNECTED,
      mdc => '0',
      mdio_in => '0',
      mdio_out => NLW_ten_gig_eth_pcs_pma_0_mdio_out_UNCONNECTED,
      mdio_tri => NLW_ten_gig_eth_pcs_pma_0_mdio_tri_UNCONNECTED,
      pma_pmd_type(2 downto 0) => B"000",
      prtad(4 downto 0) => B"00000",
      qplllock_out => NLW_ten_gig_eth_pcs_pma_0_qplllock_out_UNCONNECTED,
      qplloutclk_out => NLW_ten_gig_eth_pcs_pma_0_qplloutclk_out_UNCONNECTED,
      qplloutrefclk_out => NLW_ten_gig_eth_pcs_pma_0_qplloutrefclk_out_UNCONNECTED,
      refclk_n => ten_gig_eth_pcs_pma_0_coreclk_out,
      refclk_p => '0',
      reset => '0',
      reset_counter_done_out => NLW_ten_gig_eth_pcs_pma_0_reset_counter_done_out_UNCONNECTED,
      resetdone_out => NLW_ten_gig_eth_pcs_pma_0_resetdone_out_UNCONNECTED,
      rxn => '0',
      rxp => '0',
      rxrecclk_out => NLW_ten_gig_eth_pcs_pma_0_rxrecclk_out_UNCONNECTED,
      signal_detect => '1',
      sim_speedup_control => '0',
      tx_disable => NLW_ten_gig_eth_pcs_pma_0_tx_disable_UNCONNECTED,
      tx_fault => '0',
      txn => NLW_ten_gig_eth_pcs_pma_0_txn_UNCONNECTED,
      txp => NLW_ten_gig_eth_pcs_pma_0_txp_UNCONNECTED,
      txuserrdy_out => NLW_ten_gig_eth_pcs_pma_0_txuserrdy_out_UNCONNECTED,
      txusrclk2_out => NLW_ten_gig_eth_pcs_pma_0_txusrclk2_out_UNCONNECTED,
      txusrclk_out => NLW_ten_gig_eth_pcs_pma_0_txusrclk_out_UNCONNECTED,
      xgmii_rxc(7 downto 0) => ten_gig_eth_pcs_pma_0_xgmii_rxc(7 downto 0),
      xgmii_rxd(63 downto 0) => ten_gig_eth_pcs_pma_0_xgmii_rxd(63 downto 0),
      xgmii_txc(7 downto 0) => market_data_top_0_xgmii_txc(7 downto 0),
      xgmii_txd(63 downto 0) => market_data_top_0_xgmii_txd(63 downto 0)
    );
end STRUCTURE;
