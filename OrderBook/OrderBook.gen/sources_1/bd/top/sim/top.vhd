--Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
--Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2026.1 (win64) Build 6511674 Tue Jun 16 11:02:23 MDT 2026
--Date        : Sat Nov  7 00:34:22 2026
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
  port (
    QSFP_RESET : out STD_LOGIC_VECTOR ( 0 to 0 );
    SFP_OR_OPT : out STD_LOGIC_VECTOR ( 0 to 0 );
    clk25in : in STD_LOGIC;
    fan : out STD_LOGIC;
    gt_refclk_clk_n : in STD_LOGIC;
    gt_refclk_clk_p : in STD_LOGIC;
    sfp1_rxn : in STD_LOGIC;
    sfp1_rxp : in STD_LOGIC;
    sfp1_txn : out STD_LOGIC;
    sfp1_txp : out STD_LOGIC;
    sfp_rxn : in STD_LOGIC;
    sfp_rxp : in STD_LOGIC;
    sfp_txn : out STD_LOGIC;
    sfp_txp : out STD_LOGIC
  );
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
    pma_pmd_type : in STD_LOGIC_VECTOR ( 2 downto 0 );
    gt0_eyescanreset : in STD_LOGIC;
    gt0_eyescandataerror : out STD_LOGIC;
    gt0_txbufstatus : out STD_LOGIC_VECTOR ( 1 downto 0 );
    gt0_rxbufstatus : out STD_LOGIC_VECTOR ( 2 downto 0 );
    gt0_eyescantrigger : in STD_LOGIC;
    gt0_rxcdrhold : in STD_LOGIC;
    gt0_txprbsforceerr : in STD_LOGIC;
    gt0_txpolarity : in STD_LOGIC;
    gt0_rxpolarity : in STD_LOGIC;
    gt0_rxprbserr : out STD_LOGIC;
    gt0_txpmareset : in STD_LOGIC;
    gt0_rxpmareset : in STD_LOGIC;
    gt0_txresetdone : out STD_LOGIC;
    gt0_rxresetdone : out STD_LOGIC;
    gt0_rxpmaresetdone : out STD_LOGIC;
    gt0_rxdfelpmreset : in STD_LOGIC;
    gt0_rxlpmen : in STD_LOGIC;
    gt0_dmonitorout : out STD_LOGIC_VECTOR ( 14 downto 0 );
    gt0_rxrate : in STD_LOGIC_VECTOR ( 2 downto 0 );
    gt0_txprecursor : in STD_LOGIC_VECTOR ( 4 downto 0 );
    gt0_txpostcursor : in STD_LOGIC_VECTOR ( 4 downto 0 );
    gt0_txdiffctrl : in STD_LOGIC_VECTOR ( 3 downto 0 )
  );
  end component top_ten_gig_eth_pcs_pma_0_0;
  component top_const_one_1 is
  port (
    dout : out STD_LOGIC_VECTOR ( 0 to 0 )
  );
  end component top_const_one_1;
  component top_fan_pwm_0_0 is
  port (
    clk : in STD_LOGIC;
    fan : out STD_LOGIC
  );
  end component top_fan_pwm_0_0;
  component top_xlconstant_0_0 is
  port (
    dout : out STD_LOGIC_VECTOR ( 0 to 0 )
  );
  end component top_xlconstant_0_0;
  component top_xlconstant_1_0 is
  port (
    dout : out STD_LOGIC_VECTOR ( 0 to 0 )
  );
  end component top_xlconstant_1_0;
  component top_ten_gig_eth_pcs_pma_1_0 is
  port (
    rxrecclk_out : out STD_LOGIC;
    coreclk : in STD_LOGIC;
    dclk : in STD_LOGIC;
    txusrclk : in STD_LOGIC;
    txusrclk2 : in STD_LOGIC;
    areset : in STD_LOGIC;
    txoutclk : out STD_LOGIC;
    areset_coreclk : in STD_LOGIC;
    gttxreset : in STD_LOGIC;
    gtrxreset : in STD_LOGIC;
    txuserrdy : in STD_LOGIC;
    qplllock : in STD_LOGIC;
    qplloutclk : in STD_LOGIC;
    qplloutrefclk : in STD_LOGIC;
    reset_counter_done : in STD_LOGIC;
    txp : out STD_LOGIC;
    txn : out STD_LOGIC;
    rxp : in STD_LOGIC;
    rxn : in STD_LOGIC;
    sim_speedup_control : in STD_LOGIC;
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
    tx_resetdone : out STD_LOGIC;
    rx_resetdone : out STD_LOGIC;
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
    pma_pmd_type : in STD_LOGIC_VECTOR ( 2 downto 0 );
    gt0_eyescanreset : in STD_LOGIC;
    gt0_eyescandataerror : out STD_LOGIC;
    gt0_txbufstatus : out STD_LOGIC_VECTOR ( 1 downto 0 );
    gt0_rxbufstatus : out STD_LOGIC_VECTOR ( 2 downto 0 );
    gt0_eyescantrigger : in STD_LOGIC;
    gt0_rxcdrhold : in STD_LOGIC;
    gt0_txprbsforceerr : in STD_LOGIC;
    gt0_txpolarity : in STD_LOGIC;
    gt0_rxpolarity : in STD_LOGIC;
    gt0_rxprbserr : out STD_LOGIC;
    gt0_txpmareset : in STD_LOGIC;
    gt0_rxpmareset : in STD_LOGIC;
    gt0_txresetdone : out STD_LOGIC;
    gt0_rxresetdone : out STD_LOGIC;
    gt0_rxpmaresetdone : out STD_LOGIC;
    gt0_rxdfelpmreset : in STD_LOGIC;
    gt0_rxlpmen : in STD_LOGIC;
    gt0_dmonitorout : out STD_LOGIC_VECTOR ( 14 downto 0 );
    gt0_rxrate : in STD_LOGIC_VECTOR ( 2 downto 0 );
    gt0_txprecursor : in STD_LOGIC_VECTOR ( 4 downto 0 );
    gt0_txpostcursor : in STD_LOGIC_VECTOR ( 4 downto 0 );
    gt0_txdiffctrl : in STD_LOGIC_VECTOR ( 3 downto 0 )
  );
  end component top_ten_gig_eth_pcs_pma_1_0;
  component top_vio_link_0 is
  port (
    clk : in STD_LOGIC;
    probe_in0 : in STD_LOGIC_VECTOR ( 7 downto 0 );
    probe_in1 : in STD_LOGIC_VECTOR ( 7 downto 0 );
    probe_in2 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe_in3 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe_in4 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe_in5 : in STD_LOGIC_VECTOR ( 7 downto 0 );
    probe_in6 : in STD_LOGIC_VECTOR ( 63 downto 0 );
    probe_out0 : out STD_LOGIC_VECTOR ( 0 to 0 );
    probe_out1 : out STD_LOGIC_VECTOR ( 0 to 0 );
    probe_out2 : out STD_LOGIC_VECTOR ( 0 to 0 )
  );
  end component top_vio_link_0;
  component top_por_0_0 is
  port (
    clk : in STD_LOGIC;
    force_rst : in STD_LOGIC;
    rst_out : out STD_LOGIC
  );
  end component top_por_0_0;
  signal \^sfp_or_opt\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal const_one_dout : STD_LOGIC_VECTOR ( 0 to 0 );
  signal market_data_top_0_xgmii_txc : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal market_data_top_0_xgmii_txd : STD_LOGIC_VECTOR ( 63 downto 0 );
  signal por_0_rst_out : STD_LOGIC;
  signal ten_gig_eth_pcs_pma_0_areset_datapathclk_out : STD_LOGIC;
  signal ten_gig_eth_pcs_pma_0_core_gt_drp_interface_DADDR : STD_LOGIC_VECTOR ( 15 downto 0 );
  signal ten_gig_eth_pcs_pma_0_core_gt_drp_interface_DEN : STD_LOGIC;
  signal ten_gig_eth_pcs_pma_0_core_gt_drp_interface_DI : STD_LOGIC_VECTOR ( 15 downto 0 );
  signal ten_gig_eth_pcs_pma_0_core_gt_drp_interface_DO : STD_LOGIC_VECTOR ( 15 downto 0 );
  signal ten_gig_eth_pcs_pma_0_core_gt_drp_interface_DRDY : STD_LOGIC;
  signal ten_gig_eth_pcs_pma_0_core_gt_drp_interface_DWE : STD_LOGIC;
  signal ten_gig_eth_pcs_pma_0_core_status : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal ten_gig_eth_pcs_pma_0_coreclk_out : STD_LOGIC;
  signal ten_gig_eth_pcs_pma_0_drp_req : STD_LOGIC;
  signal ten_gig_eth_pcs_pma_0_gtrxreset_out : STD_LOGIC;
  signal ten_gig_eth_pcs_pma_0_gttxreset_out : STD_LOGIC;
  signal ten_gig_eth_pcs_pma_0_qplllock_out : STD_LOGIC;
  signal ten_gig_eth_pcs_pma_0_qplloutclk_out : STD_LOGIC;
  signal ten_gig_eth_pcs_pma_0_qplloutrefclk_out : STD_LOGIC;
  signal ten_gig_eth_pcs_pma_0_reset_counter_done_out : STD_LOGIC;
  signal ten_gig_eth_pcs_pma_0_resetdone_out : STD_LOGIC;
  signal ten_gig_eth_pcs_pma_0_txuserrdy_out : STD_LOGIC;
  signal ten_gig_eth_pcs_pma_0_txusrclk2_out : STD_LOGIC;
  signal ten_gig_eth_pcs_pma_0_txusrclk_out : STD_LOGIC;
  signal ten_gig_eth_pcs_pma_1_core_gt_drp_interface_DADDR : STD_LOGIC_VECTOR ( 15 downto 0 );
  signal ten_gig_eth_pcs_pma_1_core_gt_drp_interface_DEN : STD_LOGIC;
  signal ten_gig_eth_pcs_pma_1_core_gt_drp_interface_DI : STD_LOGIC_VECTOR ( 15 downto 0 );
  signal ten_gig_eth_pcs_pma_1_core_gt_drp_interface_DO : STD_LOGIC_VECTOR ( 15 downto 0 );
  signal ten_gig_eth_pcs_pma_1_core_gt_drp_interface_DRDY : STD_LOGIC;
  signal ten_gig_eth_pcs_pma_1_core_gt_drp_interface_DWE : STD_LOGIC;
  signal ten_gig_eth_pcs_pma_1_core_status : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal ten_gig_eth_pcs_pma_1_drp_req : STD_LOGIC;
  signal ten_gig_eth_pcs_pma_1_gt0_rxresetdone : STD_LOGIC;
  signal ten_gig_eth_pcs_pma_1_xgmii_rxc : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal ten_gig_eth_pcs_pma_1_xgmii_rxd : STD_LOGIC_VECTOR ( 63 downto 0 );
  signal vio_link_probe_out0 : STD_LOGIC_VECTOR ( 0 to 0 );
  signal vio_link_probe_out1 : STD_LOGIC_VECTOR ( 0 to 0 );
  signal vio_link_probe_out2 : STD_LOGIC_VECTOR ( 0 to 0 );
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
  signal NLW_ten_gig_eth_pcs_pma_0_gt0_eyescandataerror_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_0_gt0_rxpmaresetdone_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_0_gt0_rxprbserr_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_0_gt0_rxresetdone_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_0_gt0_txresetdone_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_0_mdio_out_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_0_mdio_tri_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_0_rxrecclk_out_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_0_tx_disable_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_0_gt0_dmonitorout_UNCONNECTED : STD_LOGIC_VECTOR ( 14 downto 0 );
  signal NLW_ten_gig_eth_pcs_pma_0_gt0_rxbufstatus_UNCONNECTED : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal NLW_ten_gig_eth_pcs_pma_0_gt0_txbufstatus_UNCONNECTED : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal NLW_ten_gig_eth_pcs_pma_0_xgmii_rxc_UNCONNECTED : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal NLW_ten_gig_eth_pcs_pma_0_xgmii_rxd_UNCONNECTED : STD_LOGIC_VECTOR ( 63 downto 0 );
  signal NLW_ten_gig_eth_pcs_pma_1_gt0_eyescandataerror_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_1_gt0_rxpmaresetdone_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_1_gt0_rxprbserr_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_1_gt0_txresetdone_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_1_mdio_out_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_1_mdio_tri_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_1_rx_resetdone_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_1_rxrecclk_out_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_1_tx_disable_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_1_tx_resetdone_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_1_txoutclk_UNCONNECTED : STD_LOGIC;
  signal NLW_ten_gig_eth_pcs_pma_1_gt0_dmonitorout_UNCONNECTED : STD_LOGIC_VECTOR ( 14 downto 0 );
  signal NLW_ten_gig_eth_pcs_pma_1_gt0_rxbufstatus_UNCONNECTED : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal NLW_ten_gig_eth_pcs_pma_1_gt0_txbufstatus_UNCONNECTED : STD_LOGIC_VECTOR ( 1 downto 0 );
  attribute X_INTERFACE_INFO : string;
  attribute X_INTERFACE_INFO of clk25in : signal is "xilinx.com:signal:clock:1.0 CLK.CLK25IN CLK";
  attribute X_INTERFACE_PARAMETER : string;
  attribute X_INTERFACE_PARAMETER of clk25in : signal is "XIL_INTERFACENAME CLK.CLK25IN, CLK_DOMAIN top_clk25in, FREQ_HZ 25000000, FREQ_TOLERANCE_HZ 0, INSERT_VIP 0, PHASE 0.0";
  attribute X_INTERFACE_INFO of gt_refclk_clk_n : signal is "xilinx.com:interface:diff_clock:1.0 gt_refclk CLK_N";
  attribute X_INTERFACE_MODE : string;
  attribute X_INTERFACE_MODE of gt_refclk_clk_n : signal is "Slave";
  attribute X_INTERFACE_PARAMETER of gt_refclk_clk_n : signal is "XIL_INTERFACENAME gt_refclk, CAN_DEBUG false, FREQ_HZ 156250000";
  attribute X_INTERFACE_INFO of gt_refclk_clk_p : signal is "xilinx.com:interface:diff_clock:1.0 gt_refclk CLK_P";
begin
  SFP_OR_OPT(0) <= \^sfp_or_opt\(0);
const_one: component top_const_one_1
     port map (
      dout(0) => const_one_dout(0)
    );
fan_pwm_0: component top_fan_pwm_0_0
     port map (
      clk => clk25in,
      fan => fan
    );
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
      resetn => const_one_dout(0),
      stat_bad_side => NLW_market_data_top_0_stat_bad_side_UNCONNECTED,
      stat_qty_ovf => NLW_market_data_top_0_stat_qty_ovf_UNCONNECTED,
      test_number(4 downto 0) => B"00000",
      xgmii_rxc(7 downto 0) => ten_gig_eth_pcs_pma_1_xgmii_rxc(7 downto 0),
      xgmii_rxd(63 downto 0) => ten_gig_eth_pcs_pma_1_xgmii_rxd(63 downto 0),
      xgmii_txc(7 downto 0) => market_data_top_0_xgmii_txc(7 downto 0),
      xgmii_txd(63 downto 0) => market_data_top_0_xgmii_txd(63 downto 0)
    );
por_0: component top_por_0_0
     port map (
      clk => clk25in,
      force_rst => vio_link_probe_out2(0),
      rst_out => por_0_rst_out
    );
ten_gig_eth_pcs_pma_0: component top_ten_gig_eth_pcs_pma_0_0
     port map (
      areset_datapathclk_out => ten_gig_eth_pcs_pma_0_areset_datapathclk_out,
      core_status(7 downto 0) => ten_gig_eth_pcs_pma_0_core_status(7 downto 0),
      coreclk_out => ten_gig_eth_pcs_pma_0_coreclk_out,
      dclk => ten_gig_eth_pcs_pma_0_coreclk_out,
      drp_daddr_i(15 downto 0) => ten_gig_eth_pcs_pma_0_core_gt_drp_interface_DADDR(15 downto 0),
      drp_daddr_o(15 downto 0) => ten_gig_eth_pcs_pma_0_core_gt_drp_interface_DADDR(15 downto 0),
      drp_den_i => ten_gig_eth_pcs_pma_0_core_gt_drp_interface_DEN,
      drp_den_o => ten_gig_eth_pcs_pma_0_core_gt_drp_interface_DEN,
      drp_di_i(15 downto 0) => ten_gig_eth_pcs_pma_0_core_gt_drp_interface_DI(15 downto 0),
      drp_di_o(15 downto 0) => ten_gig_eth_pcs_pma_0_core_gt_drp_interface_DI(15 downto 0),
      drp_drdy_i => ten_gig_eth_pcs_pma_0_core_gt_drp_interface_DRDY,
      drp_drdy_o => ten_gig_eth_pcs_pma_0_core_gt_drp_interface_DRDY,
      drp_drpdo_i(15 downto 0) => ten_gig_eth_pcs_pma_0_core_gt_drp_interface_DO(15 downto 0),
      drp_drpdo_o(15 downto 0) => ten_gig_eth_pcs_pma_0_core_gt_drp_interface_DO(15 downto 0),
      drp_dwe_i => ten_gig_eth_pcs_pma_0_core_gt_drp_interface_DWE,
      drp_dwe_o => ten_gig_eth_pcs_pma_0_core_gt_drp_interface_DWE,
      drp_gnt => ten_gig_eth_pcs_pma_0_drp_req,
      drp_req => ten_gig_eth_pcs_pma_0_drp_req,
      gt0_dmonitorout(14 downto 0) => NLW_ten_gig_eth_pcs_pma_0_gt0_dmonitorout_UNCONNECTED(14 downto 0),
      gt0_eyescandataerror => NLW_ten_gig_eth_pcs_pma_0_gt0_eyescandataerror_UNCONNECTED,
      gt0_eyescanreset => '0',
      gt0_eyescantrigger => '0',
      gt0_rxbufstatus(2 downto 0) => NLW_ten_gig_eth_pcs_pma_0_gt0_rxbufstatus_UNCONNECTED(2 downto 0),
      gt0_rxcdrhold => '0',
      gt0_rxdfelpmreset => '0',
      gt0_rxlpmen => '0',
      gt0_rxpmareset => '0',
      gt0_rxpmaresetdone => NLW_ten_gig_eth_pcs_pma_0_gt0_rxpmaresetdone_UNCONNECTED,
      gt0_rxpolarity => \^sfp_or_opt\(0),
      gt0_rxprbserr => NLW_ten_gig_eth_pcs_pma_0_gt0_rxprbserr_UNCONNECTED,
      gt0_rxrate(2 downto 0) => B"000",
      gt0_rxresetdone => NLW_ten_gig_eth_pcs_pma_0_gt0_rxresetdone_UNCONNECTED,
      gt0_txbufstatus(1 downto 0) => NLW_ten_gig_eth_pcs_pma_0_gt0_txbufstatus_UNCONNECTED(1 downto 0),
      gt0_txdiffctrl(3 downto 0) => B"1110",
      gt0_txpmareset => '0',
      gt0_txpolarity => vio_link_probe_out0(0),
      gt0_txpostcursor(4 downto 0) => B"00000",
      gt0_txprbsforceerr => '0',
      gt0_txprecursor(4 downto 0) => B"00000",
      gt0_txresetdone => NLW_ten_gig_eth_pcs_pma_0_gt0_txresetdone_UNCONNECTED,
      gtrxreset_out => ten_gig_eth_pcs_pma_0_gtrxreset_out,
      gttxreset_out => ten_gig_eth_pcs_pma_0_gttxreset_out,
      mdc => '0',
      mdio_in => '0',
      mdio_out => NLW_ten_gig_eth_pcs_pma_0_mdio_out_UNCONNECTED,
      mdio_tri => NLW_ten_gig_eth_pcs_pma_0_mdio_tri_UNCONNECTED,
      pma_pmd_type(2 downto 0) => B"000",
      prtad(4 downto 0) => B"00000",
      qplllock_out => ten_gig_eth_pcs_pma_0_qplllock_out,
      qplloutclk_out => ten_gig_eth_pcs_pma_0_qplloutclk_out,
      qplloutrefclk_out => ten_gig_eth_pcs_pma_0_qplloutrefclk_out,
      refclk_n => gt_refclk_clk_n,
      refclk_p => gt_refclk_clk_p,
      reset => por_0_rst_out,
      reset_counter_done_out => ten_gig_eth_pcs_pma_0_reset_counter_done_out,
      resetdone_out => ten_gig_eth_pcs_pma_0_resetdone_out,
      rxn => sfp_rxn,
      rxp => sfp_rxp,
      rxrecclk_out => NLW_ten_gig_eth_pcs_pma_0_rxrecclk_out_UNCONNECTED,
      signal_detect => '1',
      sim_speedup_control => '0',
      tx_disable => NLW_ten_gig_eth_pcs_pma_0_tx_disable_UNCONNECTED,
      tx_fault => '0',
      txn => sfp_txn,
      txp => sfp_txp,
      txuserrdy_out => ten_gig_eth_pcs_pma_0_txuserrdy_out,
      txusrclk2_out => ten_gig_eth_pcs_pma_0_txusrclk2_out,
      txusrclk_out => ten_gig_eth_pcs_pma_0_txusrclk_out,
      xgmii_rxc(7 downto 0) => NLW_ten_gig_eth_pcs_pma_0_xgmii_rxc_UNCONNECTED(7 downto 0),
      xgmii_rxd(63 downto 0) => NLW_ten_gig_eth_pcs_pma_0_xgmii_rxd_UNCONNECTED(63 downto 0),
      xgmii_txc(7 downto 0) => market_data_top_0_xgmii_txc(7 downto 0),
      xgmii_txd(63 downto 0) => market_data_top_0_xgmii_txd(63 downto 0)
    );
ten_gig_eth_pcs_pma_1: component top_ten_gig_eth_pcs_pma_1_0
     port map (
      areset => por_0_rst_out,
      areset_coreclk => ten_gig_eth_pcs_pma_0_areset_datapathclk_out,
      core_status(7 downto 0) => ten_gig_eth_pcs_pma_1_core_status(7 downto 0),
      coreclk => ten_gig_eth_pcs_pma_0_coreclk_out,
      dclk => ten_gig_eth_pcs_pma_0_coreclk_out,
      drp_daddr_i(15 downto 0) => ten_gig_eth_pcs_pma_1_core_gt_drp_interface_DADDR(15 downto 0),
      drp_daddr_o(15 downto 0) => ten_gig_eth_pcs_pma_1_core_gt_drp_interface_DADDR(15 downto 0),
      drp_den_i => ten_gig_eth_pcs_pma_1_core_gt_drp_interface_DEN,
      drp_den_o => ten_gig_eth_pcs_pma_1_core_gt_drp_interface_DEN,
      drp_di_i(15 downto 0) => ten_gig_eth_pcs_pma_1_core_gt_drp_interface_DI(15 downto 0),
      drp_di_o(15 downto 0) => ten_gig_eth_pcs_pma_1_core_gt_drp_interface_DI(15 downto 0),
      drp_drdy_i => ten_gig_eth_pcs_pma_1_core_gt_drp_interface_DRDY,
      drp_drdy_o => ten_gig_eth_pcs_pma_1_core_gt_drp_interface_DRDY,
      drp_drpdo_i(15 downto 0) => ten_gig_eth_pcs_pma_1_core_gt_drp_interface_DO(15 downto 0),
      drp_drpdo_o(15 downto 0) => ten_gig_eth_pcs_pma_1_core_gt_drp_interface_DO(15 downto 0),
      drp_dwe_i => ten_gig_eth_pcs_pma_1_core_gt_drp_interface_DWE,
      drp_dwe_o => ten_gig_eth_pcs_pma_1_core_gt_drp_interface_DWE,
      drp_gnt => ten_gig_eth_pcs_pma_1_drp_req,
      drp_req => ten_gig_eth_pcs_pma_1_drp_req,
      gt0_dmonitorout(14 downto 0) => NLW_ten_gig_eth_pcs_pma_1_gt0_dmonitorout_UNCONNECTED(14 downto 0),
      gt0_eyescandataerror => NLW_ten_gig_eth_pcs_pma_1_gt0_eyescandataerror_UNCONNECTED,
      gt0_eyescanreset => '0',
      gt0_eyescantrigger => '0',
      gt0_rxbufstatus(2 downto 0) => NLW_ten_gig_eth_pcs_pma_1_gt0_rxbufstatus_UNCONNECTED(2 downto 0),
      gt0_rxcdrhold => '0',
      gt0_rxdfelpmreset => '0',
      gt0_rxlpmen => '0',
      gt0_rxpmareset => '0',
      gt0_rxpmaresetdone => NLW_ten_gig_eth_pcs_pma_1_gt0_rxpmaresetdone_UNCONNECTED,
      gt0_rxpolarity => vio_link_probe_out1(0),
      gt0_rxprbserr => NLW_ten_gig_eth_pcs_pma_1_gt0_rxprbserr_UNCONNECTED,
      gt0_rxrate(2 downto 0) => B"000",
      gt0_rxresetdone => ten_gig_eth_pcs_pma_1_gt0_rxresetdone,
      gt0_txbufstatus(1 downto 0) => NLW_ten_gig_eth_pcs_pma_1_gt0_txbufstatus_UNCONNECTED(1 downto 0),
      gt0_txdiffctrl(3 downto 0) => B"1110",
      gt0_txpmareset => '0',
      gt0_txpolarity => \^sfp_or_opt\(0),
      gt0_txpostcursor(4 downto 0) => B"00000",
      gt0_txprbsforceerr => '0',
      gt0_txprecursor(4 downto 0) => B"00000",
      gt0_txresetdone => NLW_ten_gig_eth_pcs_pma_1_gt0_txresetdone_UNCONNECTED,
      gtrxreset => ten_gig_eth_pcs_pma_0_gtrxreset_out,
      gttxreset => ten_gig_eth_pcs_pma_0_gttxreset_out,
      mdc => '0',
      mdio_in => '0',
      mdio_out => NLW_ten_gig_eth_pcs_pma_1_mdio_out_UNCONNECTED,
      mdio_tri => NLW_ten_gig_eth_pcs_pma_1_mdio_tri_UNCONNECTED,
      pma_pmd_type(2 downto 0) => B"000",
      prtad(4 downto 0) => B"00000",
      qplllock => ten_gig_eth_pcs_pma_0_qplllock_out,
      qplloutclk => ten_gig_eth_pcs_pma_0_qplloutclk_out,
      qplloutrefclk => ten_gig_eth_pcs_pma_0_qplloutrefclk_out,
      reset_counter_done => ten_gig_eth_pcs_pma_0_reset_counter_done_out,
      rx_resetdone => NLW_ten_gig_eth_pcs_pma_1_rx_resetdone_UNCONNECTED,
      rxn => sfp1_rxn,
      rxp => sfp1_rxp,
      rxrecclk_out => NLW_ten_gig_eth_pcs_pma_1_rxrecclk_out_UNCONNECTED,
      signal_detect => '1',
      sim_speedup_control => '0',
      tx_disable => NLW_ten_gig_eth_pcs_pma_1_tx_disable_UNCONNECTED,
      tx_fault => '0',
      tx_resetdone => NLW_ten_gig_eth_pcs_pma_1_tx_resetdone_UNCONNECTED,
      txn => sfp1_txn,
      txoutclk => NLW_ten_gig_eth_pcs_pma_1_txoutclk_UNCONNECTED,
      txp => sfp1_txp,
      txuserrdy => ten_gig_eth_pcs_pma_0_txuserrdy_out,
      txusrclk => ten_gig_eth_pcs_pma_0_txusrclk_out,
      txusrclk2 => ten_gig_eth_pcs_pma_0_txusrclk2_out,
      xgmii_rxc(7 downto 0) => ten_gig_eth_pcs_pma_1_xgmii_rxc(7 downto 0),
      xgmii_rxd(63 downto 0) => ten_gig_eth_pcs_pma_1_xgmii_rxd(63 downto 0),
      xgmii_txc(7 downto 0) => B"00000000",
      xgmii_txd(63 downto 0) => B"0000000000000000000000000000000000000000000000000000000000000000"
    );
vio_link: component top_vio_link_0
     port map (
      clk => ten_gig_eth_pcs_pma_0_coreclk_out,
      probe_in0(7 downto 0) => ten_gig_eth_pcs_pma_0_core_status(7 downto 0),
      probe_in1(7 downto 0) => ten_gig_eth_pcs_pma_1_core_status(7 downto 0),
      probe_in2(0) => ten_gig_eth_pcs_pma_0_resetdone_out,
      probe_in3(0) => ten_gig_eth_pcs_pma_0_qplllock_out,
      probe_in4(0) => ten_gig_eth_pcs_pma_1_gt0_rxresetdone,
      probe_in5(7 downto 0) => ten_gig_eth_pcs_pma_1_xgmii_rxc(7 downto 0),
      probe_in6(63 downto 0) => ten_gig_eth_pcs_pma_1_xgmii_rxd(63 downto 0),
      probe_out0(0) => vio_link_probe_out0(0),
      probe_out1(0) => vio_link_probe_out1(0),
      probe_out2(0) => vio_link_probe_out2(0)
    );
xlconstant_0: component top_xlconstant_0_0
     port map (
      dout(0) => QSFP_RESET(0)
    );
xlconstant_1: component top_xlconstant_1_0
     port map (
      dout(0) => \^sfp_or_opt\(0)
    );
end STRUCTURE;
