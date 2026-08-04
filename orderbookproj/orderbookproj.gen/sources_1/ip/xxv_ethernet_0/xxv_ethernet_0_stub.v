// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2025.2 (win64) Build 6299465 Fri Nov 14 19:35:11 GMT 2025
// Date        : Mon Aug  3 18:21:03 2026
// Host        : DESKTOP-MB4FOM3 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               c:/Users/lskje/Desktop/FPGA_Orderbook/orderbookproj/orderbookproj.gen/sources_1/ip/xxv_ethernet_0/xxv_ethernet_0_stub.v
// Design      : xxv_ethernet_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xcu26-vsva1365-2LV-e
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* CHECK_LICENSE_TYPE = "xxv_ethernet_0,xxv_ethernet_core,{}" *) (* CORE_GENERATION_INFO = "xxv_ethernet_0,xxv_ethernet_core,{x_ipVendor=xilinx.com,x_ipLibrary=ip,x_ipName=xxv_ethernet,x_ipVersion=1.3,x_ipCoreRevision=0,x_ipLanguage=VERILOG,C_LINE_RATE= 10,C_NUM_OF_CORES= 1,C_CLOCKING= Asynchronous,C_DATA_PATH_INTERFACE= AXI Stream,C_BASE_R_KR= BASE-KR,C_XGMII_INTERFACE= 1,C_INCLUDE_FEC_LOGIC= 0,C_INCLUDE_AUTO_NEG_LT_LOGIC= None,C_INCLUDE_USER_FIFO= 1,C_ENABLE_TX_FLOW_CONTROL_LOGIC= 0,C_ENABLE_RX_FLOW_CONTROL_LOGIC= 0,C_ENABLE_TIME_STAMPING= 0,C_PTP_OPERATION_MODE= 2,C_PTP_CLOCKING_MODE= 0,C_TX_LATENCY_ADJUST= 0,C_ENABLE_VLANE_ADJUST_MODE= 0,C_GT_REF_CLK_FREQ= 156.25,C_GT_DRP_CLK= 100.00,C_GT_TYPE= GTY,C_LANE1_GT_LOC= X0Y0,C_LANE2_GT_LOC= NA,C_LANE3_GT_LOC= NA,C_LANE4_GT_LOC= NA,C_ENABLE_PIPELINE_REG= 0,C_ADD_GT_CNTRL_STS_PORTS= 1,C_INCLUDE_SHARED_LOGIC= 1}" *) (* DowngradeIPIdentifiedWarnings = "yes" *) 
module xxv_ethernet_0(rx_mac_mii_d_0, rx_mac_mii_c_0, 
  rx_mac_mii_clk_0, rx_mac_mii_reset_0, tx_mac_mii_d_0, tx_mac_mii_c_0, tx_mac_mii_clk_0, 
  tx_mac_mii_reset_0, tx_mac_mii_clk90_out_0, tx_mac_mii_clk0_out_0, mii_mac_tx_clk_0, 
  rx_reset_0, rx_axis_tvalid_0, rx_axis_tdata_0, rx_axis_tlast_0, rx_axis_tkeep_0, 
  rx_axis_tuser_0, rx_preambleout_0, ctl_rx_enable_0, ctl_rx_delete_fcs_0, 
  ctl_rx_ignore_fcs_0, ctl_rx_max_packet_len_0, ctl_rx_min_packet_len_0, 
  ctl_rx_custom_preamble_enable_0, ctl_rx_check_sfd_0, ctl_rx_check_preamble_0, 
  ctl_rx_process_lfi_0, stat_rx_bad_code_0, stat_rx_total_packets_0, 
  stat_rx_total_good_packets_0, stat_rx_total_bytes_0, stat_rx_total_good_bytes_0, 
  stat_rx_packet_small_0, stat_rx_jabber_0, stat_rx_packet_large_0, stat_rx_oversize_0, 
  stat_rx_undersize_0, stat_rx_toolong_0, stat_rx_fragment_0, stat_rx_packet_64_bytes_0, 
  stat_rx_packet_65_127_bytes_0, stat_rx_packet_128_255_bytes_0, 
  stat_rx_packet_256_511_bytes_0, stat_rx_packet_512_1023_bytes_0, 
  stat_rx_packet_1024_1518_bytes_0, stat_rx_packet_1519_1522_bytes_0, 
  stat_rx_packet_1523_1548_bytes_0, stat_rx_bad_fcs_0, stat_rx_packet_bad_fcs_0, 
  stat_rx_stomped_fcs_0, stat_rx_packet_1549_2047_bytes_0, 
  stat_rx_packet_2048_4095_bytes_0, stat_rx_packet_4096_8191_bytes_0, 
  stat_rx_packet_8192_9215_bytes_0, stat_rx_bad_preamble_0, stat_rx_bad_sfd_0, 
  stat_rx_got_signal_os_0, stat_rx_truncated_0, stat_rx_local_fault_0, 
  stat_rx_remote_fault_0, tx_reset_0, tx_axis_tready_0, tx_axis_tvalid_0, tx_axis_tdata_0, 
  tx_axis_tlast_0, tx_axis_tkeep_0, tx_axis_tuser_0, tx_preamblein_0, ctl_tx_enable_0, 
  ctl_tx_fcs_ins_enable_0, ctl_tx_ipg_value_0, ctl_tx_send_lfi_0, ctl_tx_send_rfi_0, 
  ctl_tx_send_idle_0, ctl_tx_custom_preamble_enable_0, ctl_tx_ignore_fcs_0, 
  stat_tx_total_packets_0, stat_tx_total_bytes_0, stat_tx_total_good_packets_0, 
  stat_tx_total_good_bytes_0, stat_tx_packet_64_bytes_0, stat_tx_packet_65_127_bytes_0, 
  stat_tx_packet_128_255_bytes_0, stat_tx_packet_256_511_bytes_0, 
  stat_tx_packet_512_1023_bytes_0, stat_tx_packet_1024_1518_bytes_0, 
  stat_tx_packet_1519_1522_bytes_0, stat_tx_packet_1523_1548_bytes_0, 
  stat_tx_packet_small_0, stat_tx_packet_large_0, stat_tx_packet_1549_2047_bytes_0, 
  stat_tx_packet_2048_4095_bytes_0, stat_tx_packet_4096_8191_bytes_0, 
  stat_tx_packet_8192_9215_bytes_0, stat_tx_bad_fcs_0, stat_tx_frame_error_0, 
  stat_tx_local_fault_0, stat_tx_gmii_fifo_unf_0, stat_tx_gmii_fifo_ovf_0, tx_core_clk_0, 
  rx_core_clk_0)
/* synthesis syn_black_box black_box_pad_pin="rx_mac_mii_d_0[31:0],rx_mac_mii_c_0[3:0],rx_mac_mii_clk_0,rx_mac_mii_reset_0,tx_mac_mii_d_0[31:0],tx_mac_mii_c_0[3:0],tx_mac_mii_clk_0,tx_mac_mii_reset_0,mii_mac_tx_clk_0,rx_reset_0,rx_axis_tvalid_0,rx_axis_tdata_0[63:0],rx_axis_tlast_0,rx_axis_tkeep_0[7:0],rx_axis_tuser_0,rx_preambleout_0[55:0],ctl_rx_enable_0,ctl_rx_delete_fcs_0,ctl_rx_ignore_fcs_0,ctl_rx_max_packet_len_0[14:0],ctl_rx_min_packet_len_0[7:0],ctl_rx_custom_preamble_enable_0,ctl_rx_check_sfd_0,ctl_rx_check_preamble_0,ctl_rx_process_lfi_0,stat_rx_bad_code_0,stat_rx_total_packets_0[1:0],stat_rx_total_good_packets_0,stat_rx_total_bytes_0[3:0],stat_rx_total_good_bytes_0[13:0],stat_rx_packet_small_0,stat_rx_jabber_0,stat_rx_packet_large_0,stat_rx_oversize_0,stat_rx_undersize_0,stat_rx_toolong_0,stat_rx_fragment_0,stat_rx_packet_64_bytes_0,stat_rx_packet_65_127_bytes_0,stat_rx_packet_128_255_bytes_0,stat_rx_packet_256_511_bytes_0,stat_rx_packet_512_1023_bytes_0,stat_rx_packet_1024_1518_bytes_0,stat_rx_packet_1519_1522_bytes_0,stat_rx_packet_1523_1548_bytes_0,stat_rx_bad_fcs_0[1:0],stat_rx_packet_bad_fcs_0,stat_rx_stomped_fcs_0[1:0],stat_rx_packet_1549_2047_bytes_0,stat_rx_packet_2048_4095_bytes_0,stat_rx_packet_4096_8191_bytes_0,stat_rx_packet_8192_9215_bytes_0,stat_rx_bad_preamble_0,stat_rx_bad_sfd_0,stat_rx_got_signal_os_0,stat_rx_truncated_0,stat_rx_local_fault_0,stat_rx_remote_fault_0,tx_reset_0,tx_axis_tready_0,tx_axis_tvalid_0,tx_axis_tdata_0[63:0],tx_axis_tlast_0,tx_axis_tkeep_0[7:0],tx_axis_tuser_0,tx_preamblein_0[55:0],ctl_tx_enable_0,ctl_tx_fcs_ins_enable_0,ctl_tx_ipg_value_0[3:0],ctl_tx_send_lfi_0,ctl_tx_send_rfi_0,ctl_tx_send_idle_0,ctl_tx_custom_preamble_enable_0,ctl_tx_ignore_fcs_0,stat_tx_total_packets_0,stat_tx_total_bytes_0[3:0],stat_tx_total_good_packets_0,stat_tx_total_good_bytes_0[13:0],stat_tx_packet_64_bytes_0,stat_tx_packet_65_127_bytes_0,stat_tx_packet_128_255_bytes_0,stat_tx_packet_256_511_bytes_0,stat_tx_packet_512_1023_bytes_0,stat_tx_packet_1024_1518_bytes_0,stat_tx_packet_1519_1522_bytes_0,stat_tx_packet_1523_1548_bytes_0,stat_tx_packet_small_0,stat_tx_packet_large_0,stat_tx_packet_1549_2047_bytes_0,stat_tx_packet_2048_4095_bytes_0,stat_tx_packet_4096_8191_bytes_0,stat_tx_packet_8192_9215_bytes_0,stat_tx_bad_fcs_0,stat_tx_frame_error_0,stat_tx_local_fault_0,stat_tx_gmii_fifo_unf_0,stat_tx_gmii_fifo_ovf_0" */
/* synthesis syn_force_seq_prim="tx_mac_mii_clk90_out_0" */
/* synthesis syn_force_seq_prim="tx_mac_mii_clk0_out_0" */
/* synthesis syn_force_seq_prim="tx_core_clk_0" */
/* synthesis syn_force_seq_prim="rx_core_clk_0" */;
  input [31:0]rx_mac_mii_d_0;
  input [3:0]rx_mac_mii_c_0;
  input rx_mac_mii_clk_0;
  input rx_mac_mii_reset_0;
  output [31:0]tx_mac_mii_d_0;
  output [3:0]tx_mac_mii_c_0;
  input tx_mac_mii_clk_0;
  input tx_mac_mii_reset_0;
  output tx_mac_mii_clk90_out_0 /* synthesis syn_isclock = 1 */;
  output tx_mac_mii_clk0_out_0 /* synthesis syn_isclock = 1 */;
  output mii_mac_tx_clk_0;
  input rx_reset_0;
  output rx_axis_tvalid_0;
  output [63:0]rx_axis_tdata_0;
  output rx_axis_tlast_0;
  output [7:0]rx_axis_tkeep_0;
  output rx_axis_tuser_0;
  output [55:0]rx_preambleout_0;
  input ctl_rx_enable_0;
  input ctl_rx_delete_fcs_0;
  input ctl_rx_ignore_fcs_0;
  input [14:0]ctl_rx_max_packet_len_0;
  input [7:0]ctl_rx_min_packet_len_0;
  input ctl_rx_custom_preamble_enable_0;
  input ctl_rx_check_sfd_0;
  input ctl_rx_check_preamble_0;
  input ctl_rx_process_lfi_0;
  output stat_rx_bad_code_0;
  output [1:0]stat_rx_total_packets_0;
  output stat_rx_total_good_packets_0;
  output [3:0]stat_rx_total_bytes_0;
  output [13:0]stat_rx_total_good_bytes_0;
  output stat_rx_packet_small_0;
  output stat_rx_jabber_0;
  output stat_rx_packet_large_0;
  output stat_rx_oversize_0;
  output stat_rx_undersize_0;
  output stat_rx_toolong_0;
  output stat_rx_fragment_0;
  output stat_rx_packet_64_bytes_0;
  output stat_rx_packet_65_127_bytes_0;
  output stat_rx_packet_128_255_bytes_0;
  output stat_rx_packet_256_511_bytes_0;
  output stat_rx_packet_512_1023_bytes_0;
  output stat_rx_packet_1024_1518_bytes_0;
  output stat_rx_packet_1519_1522_bytes_0;
  output stat_rx_packet_1523_1548_bytes_0;
  output [1:0]stat_rx_bad_fcs_0;
  output stat_rx_packet_bad_fcs_0;
  output [1:0]stat_rx_stomped_fcs_0;
  output stat_rx_packet_1549_2047_bytes_0;
  output stat_rx_packet_2048_4095_bytes_0;
  output stat_rx_packet_4096_8191_bytes_0;
  output stat_rx_packet_8192_9215_bytes_0;
  output stat_rx_bad_preamble_0;
  output stat_rx_bad_sfd_0;
  output stat_rx_got_signal_os_0;
  output stat_rx_truncated_0;
  output stat_rx_local_fault_0;
  output stat_rx_remote_fault_0;
  input tx_reset_0;
  output tx_axis_tready_0;
  input tx_axis_tvalid_0;
  input [63:0]tx_axis_tdata_0;
  input tx_axis_tlast_0;
  input [7:0]tx_axis_tkeep_0;
  input tx_axis_tuser_0;
  input [55:0]tx_preamblein_0;
  input ctl_tx_enable_0;
  input ctl_tx_fcs_ins_enable_0;
  input [3:0]ctl_tx_ipg_value_0;
  input ctl_tx_send_lfi_0;
  input ctl_tx_send_rfi_0;
  input ctl_tx_send_idle_0;
  input ctl_tx_custom_preamble_enable_0;
  input ctl_tx_ignore_fcs_0;
  output stat_tx_total_packets_0;
  output [3:0]stat_tx_total_bytes_0;
  output stat_tx_total_good_packets_0;
  output [13:0]stat_tx_total_good_bytes_0;
  output stat_tx_packet_64_bytes_0;
  output stat_tx_packet_65_127_bytes_0;
  output stat_tx_packet_128_255_bytes_0;
  output stat_tx_packet_256_511_bytes_0;
  output stat_tx_packet_512_1023_bytes_0;
  output stat_tx_packet_1024_1518_bytes_0;
  output stat_tx_packet_1519_1522_bytes_0;
  output stat_tx_packet_1523_1548_bytes_0;
  output stat_tx_packet_small_0;
  output stat_tx_packet_large_0;
  output stat_tx_packet_1549_2047_bytes_0;
  output stat_tx_packet_2048_4095_bytes_0;
  output stat_tx_packet_4096_8191_bytes_0;
  output stat_tx_packet_8192_9215_bytes_0;
  output stat_tx_bad_fcs_0;
  output stat_tx_frame_error_0;
  output stat_tx_local_fault_0;
  output stat_tx_gmii_fifo_unf_0;
  output stat_tx_gmii_fifo_ovf_0;
  input tx_core_clk_0 /* synthesis syn_isclock = 1 */;
  input rx_core_clk_0 /* synthesis syn_isclock = 1 */;
endmodule
