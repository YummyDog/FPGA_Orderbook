// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
// -------------------------------------------------------------------------------
// This file contains confidential and proprietary information
// of AMD and is protected under U.S. and international copyright
// and other intellectual property laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// AMD, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) AMD shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or AMD had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// AMD products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of AMD products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
// DO NOT MODIFY THIS FILE.

// MODULE VLNV: xilinx.com:ip:xxv_ethernet:5.0

`timescale 1ps / 1ps

`include "vivado_interfaces.svh"

module xxv_ethernet_0_sv (
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 axis_rx_0" *)
  (* X_INTERFACE_MODE = "master axis_rx_0" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME axis_rx_0, TDATA_NUM_BYTES 8, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 1, HAS_TREADY 0, HAS_TSTRB 0, HAS_TKEEP 1, HAS_TLAST 1, FREQ_HZ 100000000, PHASE 0.0, LAYERED_METADATA undef, INSERT_VIP 0" *)
  vivado_axis_v1_0.master axis_rx_0,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 axis_tx_0" *)
  (* X_INTERFACE_MODE = "slave axis_tx_0" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME axis_tx_0, TDATA_NUM_BYTES 8, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 1, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 1, HAS_TLAST 1, FREQ_HZ 100000000, PHASE 0.0, LAYERED_METADATA undef, INSERT_VIP 0" *)
  vivado_axis_v1_0.slave axis_tx_0,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire rx_core_clk_0,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire tx_core_clk_0,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire rx_mac_mii_clk_0,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire tx_mac_mii_clk_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire mii_mac_tx_clk_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire tx_mac_mii_clk90_out_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire tx_mac_mii_clk0_out_0,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire rx_reset_0,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire rx_mac_mii_reset_0,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire tx_mac_mii_reset_0,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire [31:0] rx_mac_mii_d_0,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire [3:0] rx_mac_mii_c_0,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire ctl_rx_enable_0,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire ctl_rx_check_preamble_0,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire ctl_rx_check_sfd_0,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire ctl_rx_delete_fcs_0,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire ctl_rx_ignore_fcs_0,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire [14:0] ctl_rx_max_packet_len_0,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire [7:0] ctl_rx_min_packet_len_0,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire ctl_rx_process_lfi_0,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire ctl_rx_custom_preamble_enable_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_rx_local_fault_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_rx_remote_fault_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire [1:0] stat_rx_bad_fcs_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire [1:0] stat_rx_stomped_fcs_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_rx_truncated_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_rx_got_signal_os_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire [3:0] stat_rx_total_bytes_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire [1:0] stat_rx_total_packets_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire [13:0] stat_rx_total_good_bytes_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_rx_total_good_packets_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_rx_packet_bad_fcs_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_rx_packet_64_bytes_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_rx_packet_65_127_bytes_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_rx_packet_128_255_bytes_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_rx_packet_256_511_bytes_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_rx_packet_512_1023_bytes_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_rx_packet_1024_1518_bytes_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_rx_packet_1519_1522_bytes_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_rx_packet_1523_1548_bytes_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_rx_packet_1549_2047_bytes_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_rx_packet_2048_4095_bytes_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_rx_packet_4096_8191_bytes_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_rx_packet_8192_9215_bytes_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_rx_packet_small_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_rx_packet_large_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_rx_oversize_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_rx_toolong_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_rx_undersize_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_rx_fragment_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_rx_jabber_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_rx_bad_code_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_rx_bad_sfd_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_rx_bad_preamble_0,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire tx_reset_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire [31:0] tx_mac_mii_d_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire [3:0] tx_mac_mii_c_0,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire [55:0] tx_preamblein_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire [55:0] rx_preambleout_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_tx_local_fault_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire [3:0] stat_tx_total_bytes_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_tx_total_packets_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire [13:0] stat_tx_total_good_bytes_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_tx_total_good_packets_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_tx_bad_fcs_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_tx_packet_64_bytes_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_tx_packet_65_127_bytes_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_tx_packet_128_255_bytes_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_tx_packet_256_511_bytes_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_tx_packet_512_1023_bytes_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_tx_packet_1024_1518_bytes_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_tx_packet_1519_1522_bytes_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_tx_packet_1523_1548_bytes_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_tx_packet_1549_2047_bytes_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_tx_packet_2048_4095_bytes_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_tx_packet_4096_8191_bytes_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_tx_packet_8192_9215_bytes_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_tx_packet_small_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_tx_packet_large_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_tx_frame_error_0,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire ctl_tx_enable_0,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire ctl_tx_send_rfi_0,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire ctl_tx_send_lfi_0,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire ctl_tx_send_idle_0,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire ctl_tx_fcs_ins_enable_0,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire ctl_tx_ignore_fcs_0,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire [3:0] ctl_tx_ipg_value_0,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire ctl_tx_custom_preamble_enable_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_tx_gmii_fifo_unf_0,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire stat_tx_gmii_fifo_ovf_0
);

  // interface wire assignments
  assign axis_rx_0.TDEST = 0;
  assign axis_rx_0.TID = 0;
  assign axis_rx_0.TSTRB = 0;

  xxv_ethernet_0 inst (
    .rx_core_clk_0(rx_core_clk_0),
    .tx_core_clk_0(tx_core_clk_0),
    .rx_mac_mii_clk_0(rx_mac_mii_clk_0),
    .tx_mac_mii_clk_0(tx_mac_mii_clk_0),
    .mii_mac_tx_clk_0(mii_mac_tx_clk_0),
    .tx_mac_mii_clk90_out_0(tx_mac_mii_clk90_out_0),
    .tx_mac_mii_clk0_out_0(tx_mac_mii_clk0_out_0),
    .rx_reset_0(rx_reset_0),
    .rx_mac_mii_reset_0(rx_mac_mii_reset_0),
    .tx_mac_mii_reset_0(tx_mac_mii_reset_0),
    .rx_mac_mii_d_0(rx_mac_mii_d_0),
    .rx_mac_mii_c_0(rx_mac_mii_c_0),
    .rx_axis_tvalid_0(axis_rx_0.TVALID),
    .rx_axis_tdata_0(axis_rx_0.TDATA),
    .rx_axis_tlast_0(axis_rx_0.TLAST),
    .rx_axis_tkeep_0(axis_rx_0.TKEEP),
    .rx_axis_tuser_0(axis_rx_0.TUSER),
    .ctl_rx_enable_0(ctl_rx_enable_0),
    .ctl_rx_check_preamble_0(ctl_rx_check_preamble_0),
    .ctl_rx_check_sfd_0(ctl_rx_check_sfd_0),
    .ctl_rx_delete_fcs_0(ctl_rx_delete_fcs_0),
    .ctl_rx_ignore_fcs_0(ctl_rx_ignore_fcs_0),
    .ctl_rx_max_packet_len_0(ctl_rx_max_packet_len_0),
    .ctl_rx_min_packet_len_0(ctl_rx_min_packet_len_0),
    .ctl_rx_process_lfi_0(ctl_rx_process_lfi_0),
    .ctl_rx_custom_preamble_enable_0(ctl_rx_custom_preamble_enable_0),
    .stat_rx_local_fault_0(stat_rx_local_fault_0),
    .stat_rx_remote_fault_0(stat_rx_remote_fault_0),
    .stat_rx_bad_fcs_0(stat_rx_bad_fcs_0),
    .stat_rx_stomped_fcs_0(stat_rx_stomped_fcs_0),
    .stat_rx_truncated_0(stat_rx_truncated_0),
    .stat_rx_got_signal_os_0(stat_rx_got_signal_os_0),
    .stat_rx_total_bytes_0(stat_rx_total_bytes_0),
    .stat_rx_total_packets_0(stat_rx_total_packets_0),
    .stat_rx_total_good_bytes_0(stat_rx_total_good_bytes_0),
    .stat_rx_total_good_packets_0(stat_rx_total_good_packets_0),
    .stat_rx_packet_bad_fcs_0(stat_rx_packet_bad_fcs_0),
    .stat_rx_packet_64_bytes_0(stat_rx_packet_64_bytes_0),
    .stat_rx_packet_65_127_bytes_0(stat_rx_packet_65_127_bytes_0),
    .stat_rx_packet_128_255_bytes_0(stat_rx_packet_128_255_bytes_0),
    .stat_rx_packet_256_511_bytes_0(stat_rx_packet_256_511_bytes_0),
    .stat_rx_packet_512_1023_bytes_0(stat_rx_packet_512_1023_bytes_0),
    .stat_rx_packet_1024_1518_bytes_0(stat_rx_packet_1024_1518_bytes_0),
    .stat_rx_packet_1519_1522_bytes_0(stat_rx_packet_1519_1522_bytes_0),
    .stat_rx_packet_1523_1548_bytes_0(stat_rx_packet_1523_1548_bytes_0),
    .stat_rx_packet_1549_2047_bytes_0(stat_rx_packet_1549_2047_bytes_0),
    .stat_rx_packet_2048_4095_bytes_0(stat_rx_packet_2048_4095_bytes_0),
    .stat_rx_packet_4096_8191_bytes_0(stat_rx_packet_4096_8191_bytes_0),
    .stat_rx_packet_8192_9215_bytes_0(stat_rx_packet_8192_9215_bytes_0),
    .stat_rx_packet_small_0(stat_rx_packet_small_0),
    .stat_rx_packet_large_0(stat_rx_packet_large_0),
    .stat_rx_oversize_0(stat_rx_oversize_0),
    .stat_rx_toolong_0(stat_rx_toolong_0),
    .stat_rx_undersize_0(stat_rx_undersize_0),
    .stat_rx_fragment_0(stat_rx_fragment_0),
    .stat_rx_jabber_0(stat_rx_jabber_0),
    .stat_rx_bad_code_0(stat_rx_bad_code_0),
    .stat_rx_bad_sfd_0(stat_rx_bad_sfd_0),
    .stat_rx_bad_preamble_0(stat_rx_bad_preamble_0),
    .tx_reset_0(tx_reset_0),
    .tx_mac_mii_d_0(tx_mac_mii_d_0),
    .tx_mac_mii_c_0(tx_mac_mii_c_0),
    .tx_axis_tready_0(axis_tx_0.TREADY),
    .tx_axis_tvalid_0(axis_tx_0.TVALID),
    .tx_axis_tdata_0(axis_tx_0.TDATA),
    .tx_axis_tlast_0(axis_tx_0.TLAST),
    .tx_axis_tkeep_0(axis_tx_0.TKEEP),
    .tx_axis_tuser_0(axis_tx_0.TUSER),
    .tx_preamblein_0(tx_preamblein_0),
    .rx_preambleout_0(rx_preambleout_0),
    .stat_tx_local_fault_0(stat_tx_local_fault_0),
    .stat_tx_total_bytes_0(stat_tx_total_bytes_0),
    .stat_tx_total_packets_0(stat_tx_total_packets_0),
    .stat_tx_total_good_bytes_0(stat_tx_total_good_bytes_0),
    .stat_tx_total_good_packets_0(stat_tx_total_good_packets_0),
    .stat_tx_bad_fcs_0(stat_tx_bad_fcs_0),
    .stat_tx_packet_64_bytes_0(stat_tx_packet_64_bytes_0),
    .stat_tx_packet_65_127_bytes_0(stat_tx_packet_65_127_bytes_0),
    .stat_tx_packet_128_255_bytes_0(stat_tx_packet_128_255_bytes_0),
    .stat_tx_packet_256_511_bytes_0(stat_tx_packet_256_511_bytes_0),
    .stat_tx_packet_512_1023_bytes_0(stat_tx_packet_512_1023_bytes_0),
    .stat_tx_packet_1024_1518_bytes_0(stat_tx_packet_1024_1518_bytes_0),
    .stat_tx_packet_1519_1522_bytes_0(stat_tx_packet_1519_1522_bytes_0),
    .stat_tx_packet_1523_1548_bytes_0(stat_tx_packet_1523_1548_bytes_0),
    .stat_tx_packet_1549_2047_bytes_0(stat_tx_packet_1549_2047_bytes_0),
    .stat_tx_packet_2048_4095_bytes_0(stat_tx_packet_2048_4095_bytes_0),
    .stat_tx_packet_4096_8191_bytes_0(stat_tx_packet_4096_8191_bytes_0),
    .stat_tx_packet_8192_9215_bytes_0(stat_tx_packet_8192_9215_bytes_0),
    .stat_tx_packet_small_0(stat_tx_packet_small_0),
    .stat_tx_packet_large_0(stat_tx_packet_large_0),
    .stat_tx_frame_error_0(stat_tx_frame_error_0),
    .ctl_tx_enable_0(ctl_tx_enable_0),
    .ctl_tx_send_rfi_0(ctl_tx_send_rfi_0),
    .ctl_tx_send_lfi_0(ctl_tx_send_lfi_0),
    .ctl_tx_send_idle_0(ctl_tx_send_idle_0),
    .ctl_tx_fcs_ins_enable_0(ctl_tx_fcs_ins_enable_0),
    .ctl_tx_ignore_fcs_0(ctl_tx_ignore_fcs_0),
    .ctl_tx_ipg_value_0(ctl_tx_ipg_value_0),
    .ctl_tx_custom_preamble_enable_0(ctl_tx_custom_preamble_enable_0),
    .stat_tx_gmii_fifo_unf_0(stat_tx_gmii_fifo_unf_0),
    .stat_tx_gmii_fifo_ovf_0(stat_tx_gmii_fifo_ovf_0)
  );

endmodule
