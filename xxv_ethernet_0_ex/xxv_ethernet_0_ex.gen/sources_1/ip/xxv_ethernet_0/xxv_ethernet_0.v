// ------------------------------------------------------------------------------
//   (c) Copyright 2020-2021 Advanced Micro Devices, Inc. All rights reserved.
// 
//   This file contains confidential and proprietary information
//   of Advanced Micro Devices, Inc. and is protected under U.S. and
//   international copyright and other intellectual property
//   laws.
// 
//   DISCLAIMER
//   This disclaimer is not a license and does not grant any
//   rights to the materials distributed herewith. Except as
//   otherwise provided in a valid license issued to you by
//   AMD, and to the maximum extent permitted by applicable
//   law: (1) THESE MATERIALS ARE MADE AVAILABLE \"AS IS\" AND
//   WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
//   AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
//   BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
//   INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
//   (2) AMD shall not be liable (whether in contract or tort,
//   including negligence, or under any other theory of
//   liability) for any loss or damage of any kind or nature
//   related to, arising under or in connection with these
//   materials, including for any direct, or any indirect,
//   special, incidental, or consequential loss or damage
//   (including loss of data, profits, goodwill, or any type of
//   loss or damage suffered as a result of any action brought
//   by a third party) even if such damage or loss was
//   reasonably foreseeable or AMD had been advised of the
//   possibility of the same.
// 
//   CRITICAL APPLICATIONS
//   AMD products are not designed or intended to be fail-
//   safe, or for use in any application requiring fail-safe
//   performance, such as life-support or safety devices or
//   systems, Class III medical devices, nuclear facilities,
//   applications related to the deployment of airbags, or any
//   other applications that could lead to death, personal
//   injury, or severe property or environmental damage
//   (individually and collectively, \"Critical
//   Applications\"). Customer assumes the sole risk and
//   liability of any use of AMD products in Critical
//   Applications, subject only to applicable laws and
//   regulations governing limitations on product liability.
// 
//   THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
//   PART OF THIS FILE AT ALL TIMES.
//
// 
//
//       Owner:          
//       Revision:       $Id: $
//                       $Author: $
//                       $DateTime: $
//                       $Change: $
//       Description:
//
// 
//------------------------------------------------------------------------------
`timescale 1fs/1fs


(* CHECK_LICENSE_TYPE = "xxv_ethernet_0,xxv_ethernet_core,{}" *)
(* CORE_GENERATION_INFO = "xxv_ethernet_0,xxv_ethernet_core,{x_ipVendor=xilinx.com,x_ipLibrary=ip,x_ipName=xxv_ethernet,x_ipVersion=1.3,x_ipCoreRevision=0,x_ipLanguage=VERILOG,C_LINE_RATE= 10,C_NUM_OF_CORES= 1,C_CLOCKING= Asynchronous,C_DATA_PATH_INTERFACE= AXI Stream,C_BASE_R_KR= BASE-KR,C_XGMII_INTERFACE= 1,C_INCLUDE_FEC_LOGIC= 0,C_INCLUDE_AUTO_NEG_LT_LOGIC= None,C_INCLUDE_USER_FIFO= 1,C_ENABLE_TX_FLOW_CONTROL_LOGIC= 0,C_ENABLE_RX_FLOW_CONTROL_LOGIC= 0,C_ENABLE_TIME_STAMPING= 0,C_PTP_OPERATION_MODE= 2,C_PTP_CLOCKING_MODE= 0,C_TX_LATENCY_ADJUST= 0,C_ENABLE_VLANE_ADJUST_MODE= 0,C_GT_REF_CLK_FREQ= 156.25,C_GT_DRP_CLK= 100.00,C_GT_TYPE= GTY,C_LANE1_GT_LOC= X0Y0,C_LANE2_GT_LOC= NA,C_LANE3_GT_LOC= NA,C_LANE4_GT_LOC= NA,C_ENABLE_PIPELINE_REG= 0,C_ADD_GT_CNTRL_STS_PORTS= 1,C_INCLUDE_SHARED_LOGIC= 1}" *)
(* DowngradeIPIdentifiedWarnings = "yes" *)

module xxv_ethernet_0 (
  rx_mac_mii_d_0,
  rx_mac_mii_c_0,
  rx_mac_mii_clk_0,
  rx_mac_mii_reset_0,
  tx_mac_mii_d_0,
  tx_mac_mii_c_0,
  //**
  tx_mac_mii_clk_0,
  tx_mac_mii_reset_0,
  tx_mac_mii_clk90_out_0,
  tx_mac_mii_clk0_out_0,
  mii_mac_tx_clk_0,
//// RX_0 Signals
  rx_reset_0,
//// RX_0 User Interface  Signals
  rx_axis_tvalid_0,
  rx_axis_tdata_0,
  rx_axis_tlast_0,
  rx_axis_tkeep_0,
  rx_axis_tuser_0,
  rx_preambleout_0,



//// RX_0 Control Signals
  ctl_rx_enable_0,
  ctl_rx_delete_fcs_0,
  ctl_rx_ignore_fcs_0,
  ctl_rx_max_packet_len_0,
  ctl_rx_min_packet_len_0,
  ctl_rx_custom_preamble_enable_0,
  ctl_rx_check_sfd_0,
  ctl_rx_check_preamble_0,
  ctl_rx_process_lfi_0,


//// RX_0 Stats Signals
  stat_rx_bad_code_0,
  stat_rx_total_packets_0,
  stat_rx_total_good_packets_0,
  stat_rx_total_bytes_0,
  stat_rx_total_good_bytes_0,
  stat_rx_packet_small_0,
  stat_rx_jabber_0,
  stat_rx_packet_large_0,
  stat_rx_oversize_0,
  stat_rx_undersize_0,
  stat_rx_toolong_0,
  stat_rx_fragment_0,
  stat_rx_packet_64_bytes_0,
  stat_rx_packet_65_127_bytes_0,
  stat_rx_packet_128_255_bytes_0,
  stat_rx_packet_256_511_bytes_0,
  stat_rx_packet_512_1023_bytes_0,
  stat_rx_packet_1024_1518_bytes_0,
  stat_rx_packet_1519_1522_bytes_0,
  stat_rx_packet_1523_1548_bytes_0,
  stat_rx_bad_fcs_0,
  stat_rx_packet_bad_fcs_0,
  stat_rx_stomped_fcs_0,
  stat_rx_packet_1549_2047_bytes_0,
  stat_rx_packet_2048_4095_bytes_0,
  stat_rx_packet_4096_8191_bytes_0,
  stat_rx_packet_8192_9215_bytes_0,
  stat_rx_bad_preamble_0,
  stat_rx_bad_sfd_0,
  stat_rx_got_signal_os_0,
  stat_rx_truncated_0,
  stat_rx_local_fault_0,
  stat_rx_remote_fault_0,

//// TX_0 Signals
  tx_reset_0,

//// TX_0 User Interface  Signals
  tx_axis_tready_0,
  tx_axis_tvalid_0,
  tx_axis_tdata_0,
  tx_axis_tlast_0,
  tx_axis_tkeep_0,
  tx_axis_tuser_0,
  tx_preamblein_0,

//// TX_0 Control Signals
  ctl_tx_enable_0,
  ctl_tx_fcs_ins_enable_0,
  ctl_tx_ipg_value_0,
  ctl_tx_send_lfi_0,
  ctl_tx_send_rfi_0,
  ctl_tx_send_idle_0,
  ctl_tx_custom_preamble_enable_0,
  ctl_tx_ignore_fcs_0,




//// TX_0 Stats Signals
  stat_tx_total_packets_0,
  stat_tx_total_bytes_0,
  stat_tx_total_good_packets_0,
  stat_tx_total_good_bytes_0,
  stat_tx_packet_64_bytes_0,
  stat_tx_packet_65_127_bytes_0,
  stat_tx_packet_128_255_bytes_0,
  stat_tx_packet_256_511_bytes_0,
  stat_tx_packet_512_1023_bytes_0,
  stat_tx_packet_1024_1518_bytes_0,
  stat_tx_packet_1519_1522_bytes_0,
  stat_tx_packet_1523_1548_bytes_0,
  stat_tx_packet_small_0,
  stat_tx_packet_large_0,
  stat_tx_packet_1549_2047_bytes_0,
  stat_tx_packet_2048_4095_bytes_0,
  stat_tx_packet_4096_8191_bytes_0,
  stat_tx_packet_8192_9215_bytes_0,
  stat_tx_bad_fcs_0,
  stat_tx_frame_error_0,
  stat_tx_local_fault_0,
  stat_tx_gmii_fifo_unf_0,
  stat_tx_gmii_fifo_ovf_0,

  tx_core_clk_0,
  rx_core_clk_0

);
  input  wire [32-1:0] rx_mac_mii_d_0;
  input  wire [3:0]    rx_mac_mii_c_0;
  input  wire          rx_mac_mii_clk_0;
  input  wire          rx_mac_mii_reset_0;
  output wire [32-1:0] tx_mac_mii_d_0;
  output wire [3:0]    tx_mac_mii_c_0;
  input  wire          tx_mac_mii_clk_0;
  input  wire          tx_mac_mii_reset_0;
  output wire          tx_mac_mii_clk90_out_0;
  output wire          tx_mac_mii_clk0_out_0;
  output wire          mii_mac_tx_clk_0;
//// RX_0 Signals
  input  wire rx_reset_0;
//// RX_0 User Interface Signals
  output wire rx_axis_tvalid_0;
  output wire [63:0] rx_axis_tdata_0;
  output wire rx_axis_tlast_0;
  output wire [7:0] rx_axis_tkeep_0;
  output wire rx_axis_tuser_0;
  output wire [55:0] rx_preambleout_0;



//// RX_0 Control Signals
  input  wire ctl_rx_enable_0;
  input  wire ctl_rx_delete_fcs_0;
  input  wire ctl_rx_ignore_fcs_0;
  input  wire [14:0] ctl_rx_max_packet_len_0;
  input  wire [7:0] ctl_rx_min_packet_len_0;
  input  wire ctl_rx_custom_preamble_enable_0;
  input  wire ctl_rx_check_sfd_0;
  input  wire ctl_rx_check_preamble_0;
  input  wire ctl_rx_process_lfi_0;



//// RX_0 Stats Signals
  output wire stat_rx_bad_code_0;
  output wire [1:0] stat_rx_total_packets_0;
  output wire stat_rx_total_good_packets_0;
  output wire [3:0] stat_rx_total_bytes_0;
  output wire [13:0] stat_rx_total_good_bytes_0;
  output wire stat_rx_packet_small_0;
  output wire stat_rx_jabber_0;
  output wire stat_rx_packet_large_0;
  output wire stat_rx_oversize_0;
  output wire stat_rx_undersize_0;
  output wire stat_rx_toolong_0;
  output wire stat_rx_fragment_0;
  output wire stat_rx_packet_64_bytes_0;
  output wire stat_rx_packet_65_127_bytes_0;
  output wire stat_rx_packet_128_255_bytes_0;
  output wire stat_rx_packet_256_511_bytes_0;
  output wire stat_rx_packet_512_1023_bytes_0;
  output wire stat_rx_packet_1024_1518_bytes_0;
  output wire stat_rx_packet_1519_1522_bytes_0;
  output wire stat_rx_packet_1523_1548_bytes_0;
  output wire [1:0] stat_rx_bad_fcs_0;
  output wire stat_rx_packet_bad_fcs_0;
  output wire [1:0] stat_rx_stomped_fcs_0;
  output wire stat_rx_packet_1549_2047_bytes_0;
  output wire stat_rx_packet_2048_4095_bytes_0;
  output wire stat_rx_packet_4096_8191_bytes_0;
  output wire stat_rx_packet_8192_9215_bytes_0;
  output wire stat_rx_bad_preamble_0;
  output wire stat_rx_bad_sfd_0;
  output wire stat_rx_got_signal_os_0;
  output wire stat_rx_truncated_0;
  output wire stat_rx_local_fault_0;
  output wire stat_rx_remote_fault_0;


//// TX_0 Signals
  input  wire tx_reset_0;

//// TX_0 User Interface Signals
  output wire tx_axis_tready_0;
  input  wire tx_axis_tvalid_0;
  input  wire [63:0] tx_axis_tdata_0;
  input  wire tx_axis_tlast_0;
  input  wire [7:0] tx_axis_tkeep_0;
  input  wire tx_axis_tuser_0;
  input  wire [55:0] tx_preamblein_0;

//// TX_0 Control Signals
  input  wire ctl_tx_enable_0;
  input  wire ctl_tx_fcs_ins_enable_0;
  input  wire [3:0] ctl_tx_ipg_value_0;
  input  wire ctl_tx_send_lfi_0;
  input  wire ctl_tx_send_rfi_0;
  input  wire ctl_tx_send_idle_0;
  input  wire ctl_tx_custom_preamble_enable_0;
  input  wire ctl_tx_ignore_fcs_0;


//// TX_0 Stats Signals
  output wire stat_tx_total_packets_0;
  output wire [3:0] stat_tx_total_bytes_0;
  output wire stat_tx_total_good_packets_0;
  output wire [13:0] stat_tx_total_good_bytes_0;
  output wire stat_tx_packet_64_bytes_0;
  output wire stat_tx_packet_65_127_bytes_0;
  output wire stat_tx_packet_128_255_bytes_0;
  output wire stat_tx_packet_256_511_bytes_0;
  output wire stat_tx_packet_512_1023_bytes_0;
  output wire stat_tx_packet_1024_1518_bytes_0;
  output wire stat_tx_packet_1519_1522_bytes_0;
  output wire stat_tx_packet_1523_1548_bytes_0;
  output wire stat_tx_packet_small_0;
  output wire stat_tx_packet_large_0;
  output wire stat_tx_packet_1549_2047_bytes_0;
  output wire stat_tx_packet_2048_4095_bytes_0;
  output wire stat_tx_packet_4096_8191_bytes_0;
  output wire stat_tx_packet_8192_9215_bytes_0;
  output wire stat_tx_bad_fcs_0;
  output wire stat_tx_frame_error_0;
  output wire stat_tx_local_fault_0;
  output wire stat_tx_gmii_fifo_unf_0;
  output wire stat_tx_gmii_fifo_ovf_0;

  input  wire tx_core_clk_0;
  input  wire rx_core_clk_0;

  xxv_ethernet_0_wrapper #(
    .C_LINE_RATE(10),
    .C_NUM_OF_CORES(1),
    .C_CLOCKING("Asynchronous"),
    .C_DATA_PATH_INTERFACE("AXI Stream"),
    .C_BASE_R_KR("BASE-KR"),
    .C_INCLUDE_FEC_LOGIC("0"),
    .C_INCLUDE_AUTO_NEG_LT_LOGIC("None"),
    .C_INCLUDE_USER_FIFO("1"),
    .C_ENABLE_TX_FLOW_CONTROL_LOGIC(0),
    .C_ENABLE_RX_FLOW_CONTROL_LOGIC(0),
    .C_ENABLE_TIME_STAMPING(0),
    .C_PTP_OPERATION_MODE(2),
    .C_PTP_CLOCKING_MODE(0),
    .C_TX_LATENCY_ADJUST(0),
    .C_ENABLE_VLANE_ADJUST_MODE(0),
    .C_ENABLE_PIPELINE_REG(0),
    .C_RUNTIME_SWITCH(0)
  ) inst (
   .tx_reset_0     (tx_reset_0),
   .rx_reset_0     (rx_reset_0),
   .tx_mac_mii_d_0     (tx_mac_mii_d_0),
   .tx_mac_mii_c_0     (tx_mac_mii_c_0),
   //**
   .tx_mac_mii_clk_0   (tx_mac_mii_clk_0),
   .tx_mac_mii_reset_0 (tx_mac_mii_reset_0),
   .rx_mac_mii_d_0     (rx_mac_mii_d_0),
   .rx_mac_mii_c_0     (rx_mac_mii_c_0),
   .rx_mac_mii_clk_0   (rx_mac_mii_clk_0),
   .rx_mac_mii_reset_0 (rx_mac_mii_reset_0),
   .tx_mac_mii_clk90_out_0 (tx_mac_mii_clk90_out_0),
   .tx_mac_mii_clk0_out_0  (tx_mac_mii_clk0_out_0),
   .mii_mac_tx_clk_0       (mii_mac_tx_clk_0),

//// RX User Interface Signals
    .rx_axis_tvalid_0 (rx_axis_tvalid_0),
    .rx_axis_tdata_0 (rx_axis_tdata_0),
    .rx_axis_tlast_0 (rx_axis_tlast_0),
    .rx_axis_tkeep_0 (rx_axis_tkeep_0),
    .rx_axis_tuser_0 (rx_axis_tuser_0),
    .rx_preambleout_0 (rx_preambleout_0),

//// RX Control Signals
    .ctl_rx_enable_0 (ctl_rx_enable_0),
    .ctl_rx_delete_fcs_0 (ctl_rx_delete_fcs_0),
    .ctl_rx_ignore_fcs_0 (ctl_rx_ignore_fcs_0),
    .ctl_rx_max_packet_len_0 (ctl_rx_max_packet_len_0),
    .ctl_rx_min_packet_len_0 (ctl_rx_min_packet_len_0),
    .ctl_rx_custom_preamble_enable_0 (ctl_rx_custom_preamble_enable_0),
    .ctl_rx_check_sfd_0 (ctl_rx_check_sfd_0),
    .ctl_rx_check_preamble_0 (ctl_rx_check_preamble_0),
    .ctl_rx_process_lfi_0 (ctl_rx_process_lfi_0),



//// RX Stats Signals
    .stat_rx_bad_code_0 (stat_rx_bad_code_0),
    .stat_rx_total_packets_0 (stat_rx_total_packets_0),
    .stat_rx_total_good_packets_0 (stat_rx_total_good_packets_0),
    .stat_rx_total_bytes_0 (stat_rx_total_bytes_0),
    .stat_rx_total_good_bytes_0 (stat_rx_total_good_bytes_0),
    .stat_rx_packet_small_0 (stat_rx_packet_small_0),
    .stat_rx_jabber_0 (stat_rx_jabber_0),
    .stat_rx_packet_large_0 (stat_rx_packet_large_0),
    .stat_rx_oversize_0 (stat_rx_oversize_0),
    .stat_rx_undersize_0 (stat_rx_undersize_0),
    .stat_rx_toolong_0 (stat_rx_toolong_0),
    .stat_rx_fragment_0 (stat_rx_fragment_0),
    .stat_rx_packet_64_bytes_0 (stat_rx_packet_64_bytes_0),
    .stat_rx_packet_65_127_bytes_0 (stat_rx_packet_65_127_bytes_0),
    .stat_rx_packet_128_255_bytes_0 (stat_rx_packet_128_255_bytes_0),
    .stat_rx_packet_256_511_bytes_0 (stat_rx_packet_256_511_bytes_0),
    .stat_rx_packet_512_1023_bytes_0 (stat_rx_packet_512_1023_bytes_0),
    .stat_rx_packet_1024_1518_bytes_0 (stat_rx_packet_1024_1518_bytes_0),
    .stat_rx_packet_1519_1522_bytes_0 (stat_rx_packet_1519_1522_bytes_0),
    .stat_rx_packet_1523_1548_bytes_0 (stat_rx_packet_1523_1548_bytes_0),
    .stat_rx_bad_fcs_0 (stat_rx_bad_fcs_0),
    .stat_rx_packet_bad_fcs_0 (stat_rx_packet_bad_fcs_0),
    .stat_rx_stomped_fcs_0 (stat_rx_stomped_fcs_0),
    .stat_rx_packet_1549_2047_bytes_0 (stat_rx_packet_1549_2047_bytes_0),
    .stat_rx_packet_2048_4095_bytes_0 (stat_rx_packet_2048_4095_bytes_0),
    .stat_rx_packet_4096_8191_bytes_0 (stat_rx_packet_4096_8191_bytes_0),
    .stat_rx_packet_8192_9215_bytes_0 (stat_rx_packet_8192_9215_bytes_0),
    .stat_rx_bad_preamble_0 (stat_rx_bad_preamble_0),
    .stat_rx_bad_sfd_0 (stat_rx_bad_sfd_0),
    .stat_rx_got_signal_os_0 (stat_rx_got_signal_os_0),
    .stat_rx_truncated_0 (stat_rx_truncated_0),
    .stat_rx_local_fault_0 (stat_rx_local_fault_0),
    .stat_rx_remote_fault_0 (stat_rx_remote_fault_0),


//// TX User Interface Signals
    .tx_axis_tready_0 (tx_axis_tready_0),
    .tx_axis_tvalid_0 (tx_axis_tvalid_0),
    .tx_axis_tdata_0 (tx_axis_tdata_0),
    .tx_axis_tlast_0 (tx_axis_tlast_0),
    .tx_axis_tkeep_0 (tx_axis_tkeep_0),
    .tx_axis_tuser_0 (tx_axis_tuser_0),
    .tx_preamblein_0 (tx_preamblein_0),


//// TX Control Signals
    .ctl_tx_enable_0 (ctl_tx_enable_0),
    .ctl_tx_fcs_ins_enable_0 (ctl_tx_fcs_ins_enable_0),
    .ctl_tx_ipg_value_0 (ctl_tx_ipg_value_0),
    .ctl_tx_send_lfi_0 (ctl_tx_send_lfi_0),
    .ctl_tx_send_rfi_0 (ctl_tx_send_rfi_0),
    .ctl_tx_send_idle_0 (ctl_tx_send_idle_0),
    .ctl_tx_custom_preamble_enable_0 (ctl_tx_custom_preamble_enable_0),
    .ctl_tx_ignore_fcs_0 (ctl_tx_ignore_fcs_0),


//// TX Stats Signals
    .stat_tx_total_packets_0 (stat_tx_total_packets_0),
    .stat_tx_total_bytes_0 (stat_tx_total_bytes_0),
    .stat_tx_total_good_packets_0 (stat_tx_total_good_packets_0),
    .stat_tx_total_good_bytes_0 (stat_tx_total_good_bytes_0),
    .stat_tx_packet_64_bytes_0 (stat_tx_packet_64_bytes_0),
    .stat_tx_packet_65_127_bytes_0 (stat_tx_packet_65_127_bytes_0),
    .stat_tx_packet_128_255_bytes_0 (stat_tx_packet_128_255_bytes_0),
    .stat_tx_packet_256_511_bytes_0 (stat_tx_packet_256_511_bytes_0),
    .stat_tx_packet_512_1023_bytes_0 (stat_tx_packet_512_1023_bytes_0),
    .stat_tx_packet_1024_1518_bytes_0 (stat_tx_packet_1024_1518_bytes_0),
    .stat_tx_packet_1519_1522_bytes_0 (stat_tx_packet_1519_1522_bytes_0),
    .stat_tx_packet_1523_1548_bytes_0 (stat_tx_packet_1523_1548_bytes_0),
    .stat_tx_packet_small_0 (stat_tx_packet_small_0),
    .stat_tx_packet_large_0 (stat_tx_packet_large_0),
    .stat_tx_packet_1549_2047_bytes_0 (stat_tx_packet_1549_2047_bytes_0),
    .stat_tx_packet_2048_4095_bytes_0 (stat_tx_packet_2048_4095_bytes_0),
    .stat_tx_packet_4096_8191_bytes_0 (stat_tx_packet_4096_8191_bytes_0),
    .stat_tx_packet_8192_9215_bytes_0 (stat_tx_packet_8192_9215_bytes_0),
    .stat_tx_bad_fcs_0 (stat_tx_bad_fcs_0),
    .stat_tx_frame_error_0 (stat_tx_frame_error_0),
    .stat_tx_local_fault_0 (stat_tx_local_fault_0),
    .stat_tx_gmii_fifo_unf_0 (stat_tx_gmii_fifo_unf_0),
    .stat_tx_gmii_fifo_ovf_0 (stat_tx_gmii_fifo_ovf_0),

   .tx_core_clk_0 (tx_core_clk_0),
    .rx_core_clk_0 (rx_core_clk_0)
  );
endmodule



