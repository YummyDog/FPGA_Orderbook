// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2026.1 (win64) Build 6511674 Tue Jun 16 11:02:23 MDT 2026
// Date        : Fri Nov  6 22:37:08 2026
// Host        : DESKTOP-MB4FOM3 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub -rename_top decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix -prefix
//               decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_ top_ten_gig_eth_pcs_pma_1_0_stub.v
// Design      : top_ten_gig_eth_pcs_pma_1_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7vx690tffg1157-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* core_generation_info = "top_ten_gig_eth_pcs_pma_1_0,ten_gig_eth_pcs_pma_v6_0_33,{x_ipProduct=Vivado 2026.1,x_ipVendor=xilinx.com,x_ipLibrary=ip,x_ipName=ten_gig_eth_pcs_pma,x_ipVersion=6.0,x_ipCoreRevision=33,x_ipLanguage=VHDL,x_ipSimLanguage=VHDL,c_family=virtex7,c_component_name=top_ten_gig_eth_pcs_pma_1_0,c_has_mdio=true,c_has_fec=false,c_has_an=false,c_is_kr=false,c_is_32bit=false,c_no_ebuff=false,c_gttype=1,c_1588=0,c_gtif_width=32,c_speed10_25=10,c_sub_core_name=top_ten_gig_eth_pcs_pma_1_0_gt,c_gt_loc=X0Y0,c_refclk=clk0,c_refclkrate=156,c_dclkrate=100.00,x_ipLicense=ten_gig_eth_pcs_pma_basekr@2015.04(hardware_evaluation)}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "ten_gig_eth_pcs_pma_v6_0_33,Vivado 2026.1" *) 
module decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix(dclk, rxrecclk_out, coreclk, txusrclk, txusrclk2, 
  txoutclk, areset, areset_coreclk, gttxreset, gtrxreset, sim_speedup_control, txuserrdy, 
  qplllock, qplloutclk, qplloutrefclk, reset_counter_done, gt0_eyescanreset, 
  gt0_eyescantrigger, gt0_rxcdrhold, gt0_txprbsforceerr, gt0_txpolarity, gt0_rxpolarity, 
  gt0_rxrate, gt0_txpmareset, gt0_rxpmareset, gt0_rxdfelpmreset, gt0_txprecursor, 
  gt0_txpostcursor, gt0_txdiffctrl, gt0_rxlpmen, gt0_eyescandataerror, gt0_txbufstatus, 
  gt0_txresetdone, gt0_rxpmaresetdone, gt0_rxresetdone, gt0_rxbufstatus, gt0_rxprbserr, 
  gt0_dmonitorout, xgmii_txd, xgmii_txc, xgmii_rxd, xgmii_rxc, txp, txn, rxp, rxn, mdc, mdio_in, 
  mdio_out, mdio_tri, prtad, core_status, tx_resetdone, rx_resetdone, signal_detect, tx_fault, 
  drp_req, drp_gnt, drp_den_o, drp_dwe_o, drp_daddr_o, drp_di_o, drp_drdy_i, drp_drpdo_i, 
  drp_den_i, drp_dwe_i, drp_daddr_i, drp_di_i, drp_drdy_o, drp_drpdo_o, pma_pmd_type, tx_disable)
/* synthesis syn_black_box black_box_pad_pin="txoutclk,areset,areset_coreclk,gttxreset,gtrxreset,sim_speedup_control,txuserrdy,qplllock,qplloutrefclk,reset_counter_done,gt0_eyescanreset,gt0_eyescantrigger,gt0_rxcdrhold,gt0_txprbsforceerr,gt0_txpolarity,gt0_rxpolarity,gt0_rxrate[2:0],gt0_txpmareset,gt0_rxpmareset,gt0_rxdfelpmreset,gt0_txprecursor[4:0],gt0_txpostcursor[4:0],gt0_txdiffctrl[3:0],gt0_rxlpmen,gt0_eyescandataerror,gt0_txbufstatus[1:0],gt0_txresetdone,gt0_rxpmaresetdone,gt0_rxresetdone,gt0_rxbufstatus[2:0],gt0_rxprbserr,gt0_dmonitorout[14:0],xgmii_txd[63:0],xgmii_txc[7:0],xgmii_rxd[63:0],xgmii_rxc[7:0],txp,txn,rxp,rxn,mdc,mdio_in,mdio_out,mdio_tri,prtad[4:0],core_status[7:0],tx_resetdone,rx_resetdone,signal_detect,tx_fault,drp_req,drp_gnt,drp_den_o,drp_dwe_o,drp_daddr_o[15:0],drp_di_o[15:0],drp_drdy_i,drp_drpdo_i[15:0],drp_den_i,drp_dwe_i,drp_daddr_i[15:0],drp_di_i[15:0],drp_drdy_o,drp_drpdo_o[15:0],pma_pmd_type[2:0],tx_disable" */
/* synthesis syn_force_seq_prim="dclk" */
/* synthesis syn_force_seq_prim="rxrecclk_out" */
/* synthesis syn_force_seq_prim="coreclk" */
/* synthesis syn_force_seq_prim="txusrclk" */
/* synthesis syn_force_seq_prim="txusrclk2" */
/* synthesis syn_force_seq_prim="qplloutclk" */;
  input dclk /* synthesis syn_isclock = 1 */;
  output rxrecclk_out /* synthesis syn_isclock = 1 */;
  input coreclk /* synthesis syn_isclock = 1 */;
  input txusrclk /* synthesis syn_isclock = 1 */;
  input txusrclk2 /* synthesis syn_isclock = 1 */;
  output txoutclk;
  input areset;
  input areset_coreclk;
  input gttxreset;
  input gtrxreset;
  input sim_speedup_control;
  input txuserrdy;
  input qplllock;
  input qplloutclk /* synthesis syn_isclock = 1 */;
  input qplloutrefclk;
  input reset_counter_done;
  input gt0_eyescanreset;
  input gt0_eyescantrigger;
  input gt0_rxcdrhold;
  input gt0_txprbsforceerr;
  input gt0_txpolarity;
  input gt0_rxpolarity;
  input [2:0]gt0_rxrate;
  input gt0_txpmareset;
  input gt0_rxpmareset;
  input gt0_rxdfelpmreset;
  input [4:0]gt0_txprecursor;
  input [4:0]gt0_txpostcursor;
  input [3:0]gt0_txdiffctrl;
  input gt0_rxlpmen;
  output gt0_eyescandataerror;
  output [1:0]gt0_txbufstatus;
  output gt0_txresetdone;
  output gt0_rxpmaresetdone;
  output gt0_rxresetdone;
  output [2:0]gt0_rxbufstatus;
  output gt0_rxprbserr;
  output [14:0]gt0_dmonitorout;
  input [63:0]xgmii_txd;
  input [7:0]xgmii_txc;
  output [63:0]xgmii_rxd;
  output [7:0]xgmii_rxc;
  output txp;
  output txn;
  input rxp;
  input rxn;
  input mdc;
  input mdio_in;
  output mdio_out;
  output mdio_tri;
  input [4:0]prtad;
  output [7:0]core_status;
  output tx_resetdone;
  output rx_resetdone;
  input signal_detect;
  input tx_fault;
  output drp_req;
  input drp_gnt;
  output drp_den_o;
  output drp_dwe_o;
  output [15:0]drp_daddr_o;
  output [15:0]drp_di_o;
  input drp_drdy_i;
  input [15:0]drp_drpdo_i;
  input drp_den_i;
  input drp_dwe_i;
  input [15:0]drp_daddr_i;
  input [15:0]drp_di_i;
  output drp_drdy_o;
  output [15:0]drp_drpdo_o;
  input [2:0]pma_pmd_type;
  output tx_disable;
endmodule
