-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2026.1 (win64) Build 6511674 Tue Jun 16 11:02:23 MDT 2026
-- Date        : Fri Nov  6 22:37:08 2026
-- Host        : DESKTOP-MB4FOM3 running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub -rename_top decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix -prefix
--               decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_ top_ten_gig_eth_pcs_pma_1_0_stub.vhdl
-- Design      : top_ten_gig_eth_pcs_pma_1_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7vx690tffg1157-2
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix is
  Port ( 
    dclk : in STD_LOGIC;
    rxrecclk_out : out STD_LOGIC;
    coreclk : in STD_LOGIC;
    txusrclk : in STD_LOGIC;
    txusrclk2 : in STD_LOGIC;
    txoutclk : out STD_LOGIC;
    areset : in STD_LOGIC;
    areset_coreclk : in STD_LOGIC;
    gttxreset : in STD_LOGIC;
    gtrxreset : in STD_LOGIC;
    sim_speedup_control : in STD_LOGIC;
    txuserrdy : in STD_LOGIC;
    qplllock : in STD_LOGIC;
    qplloutclk : in STD_LOGIC;
    qplloutrefclk : in STD_LOGIC;
    reset_counter_done : in STD_LOGIC;
    gt0_eyescanreset : in STD_LOGIC;
    gt0_eyescantrigger : in STD_LOGIC;
    gt0_rxcdrhold : in STD_LOGIC;
    gt0_txprbsforceerr : in STD_LOGIC;
    gt0_txpolarity : in STD_LOGIC;
    gt0_rxpolarity : in STD_LOGIC;
    gt0_rxrate : in STD_LOGIC_VECTOR ( 2 downto 0 );
    gt0_txpmareset : in STD_LOGIC;
    gt0_rxpmareset : in STD_LOGIC;
    gt0_rxdfelpmreset : in STD_LOGIC;
    gt0_txprecursor : in STD_LOGIC_VECTOR ( 4 downto 0 );
    gt0_txpostcursor : in STD_LOGIC_VECTOR ( 4 downto 0 );
    gt0_txdiffctrl : in STD_LOGIC_VECTOR ( 3 downto 0 );
    gt0_rxlpmen : in STD_LOGIC;
    gt0_eyescandataerror : out STD_LOGIC;
    gt0_txbufstatus : out STD_LOGIC_VECTOR ( 1 downto 0 );
    gt0_txresetdone : out STD_LOGIC;
    gt0_rxpmaresetdone : out STD_LOGIC;
    gt0_rxresetdone : out STD_LOGIC;
    gt0_rxbufstatus : out STD_LOGIC_VECTOR ( 2 downto 0 );
    gt0_rxprbserr : out STD_LOGIC;
    gt0_dmonitorout : out STD_LOGIC_VECTOR ( 14 downto 0 );
    xgmii_txd : in STD_LOGIC_VECTOR ( 63 downto 0 );
    xgmii_txc : in STD_LOGIC_VECTOR ( 7 downto 0 );
    xgmii_rxd : out STD_LOGIC_VECTOR ( 63 downto 0 );
    xgmii_rxc : out STD_LOGIC_VECTOR ( 7 downto 0 );
    txp : out STD_LOGIC;
    txn : out STD_LOGIC;
    rxp : in STD_LOGIC;
    rxn : in STD_LOGIC;
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
    drp_drdy_i : in STD_LOGIC;
    drp_drpdo_i : in STD_LOGIC_VECTOR ( 15 downto 0 );
    drp_den_i : in STD_LOGIC;
    drp_dwe_i : in STD_LOGIC;
    drp_daddr_i : in STD_LOGIC_VECTOR ( 15 downto 0 );
    drp_di_i : in STD_LOGIC_VECTOR ( 15 downto 0 );
    drp_drdy_o : out STD_LOGIC;
    drp_drpdo_o : out STD_LOGIC_VECTOR ( 15 downto 0 );
    pma_pmd_type : in STD_LOGIC_VECTOR ( 2 downto 0 );
    tx_disable : out STD_LOGIC
  );

  attribute core_generation_info : string;
  attribute core_generation_info of decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix : entity is "top_ten_gig_eth_pcs_pma_1_0,ten_gig_eth_pcs_pma_v6_0_33,{x_ipProduct=Vivado 2026.1,x_ipVendor=xilinx.com,x_ipLibrary=ip,x_ipName=ten_gig_eth_pcs_pma,x_ipVersion=6.0,x_ipCoreRevision=33,x_ipLanguage=VHDL,x_ipSimLanguage=VHDL,c_family=virtex7,c_component_name=top_ten_gig_eth_pcs_pma_1_0,c_has_mdio=true,c_has_fec=false,c_has_an=false,c_is_kr=false,c_is_32bit=false,c_no_ebuff=false,c_gttype=1,c_1588=0,c_gtif_width=32,c_speed10_25=10,c_sub_core_name=top_ten_gig_eth_pcs_pma_1_0_gt,c_gt_loc=X0Y0,c_refclk=clk0,c_refclkrate=156,c_dclkrate=100.00,x_ipLicense=ten_gig_eth_pcs_pma_basekr@2015.04(hardware_evaluation)}";
  attribute downgradeipidentifiedwarnings : string;
  attribute downgradeipidentifiedwarnings of decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix : entity is "yes";
end decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix;

architecture stub of decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix is
  attribute syn_black_box : boolean;
  attribute black_box_pad_pin : string;
  attribute syn_black_box of stub : architecture is true;
  attribute black_box_pad_pin of stub : architecture is "dclk,rxrecclk_out,coreclk,txusrclk,txusrclk2,txoutclk,areset,areset_coreclk,gttxreset,gtrxreset,sim_speedup_control,txuserrdy,qplllock,qplloutclk,qplloutrefclk,reset_counter_done,gt0_eyescanreset,gt0_eyescantrigger,gt0_rxcdrhold,gt0_txprbsforceerr,gt0_txpolarity,gt0_rxpolarity,gt0_rxrate[2:0],gt0_txpmareset,gt0_rxpmareset,gt0_rxdfelpmreset,gt0_txprecursor[4:0],gt0_txpostcursor[4:0],gt0_txdiffctrl[3:0],gt0_rxlpmen,gt0_eyescandataerror,gt0_txbufstatus[1:0],gt0_txresetdone,gt0_rxpmaresetdone,gt0_rxresetdone,gt0_rxbufstatus[2:0],gt0_rxprbserr,gt0_dmonitorout[14:0],xgmii_txd[63:0],xgmii_txc[7:0],xgmii_rxd[63:0],xgmii_rxc[7:0],txp,txn,rxp,rxn,mdc,mdio_in,mdio_out,mdio_tri,prtad[4:0],core_status[7:0],tx_resetdone,rx_resetdone,signal_detect,tx_fault,drp_req,drp_gnt,drp_den_o,drp_dwe_o,drp_daddr_o[15:0],drp_di_o[15:0],drp_drdy_i,drp_drpdo_i[15:0],drp_den_i,drp_dwe_i,drp_daddr_i[15:0],drp_di_i[15:0],drp_drdy_o,drp_drpdo_o[15:0],pma_pmd_type[2:0],tx_disable";
  attribute x_core_info : string;
  attribute x_core_info of stub : architecture is "ten_gig_eth_pcs_pma_v6_0_33,Vivado 2026.1";
begin
end;
