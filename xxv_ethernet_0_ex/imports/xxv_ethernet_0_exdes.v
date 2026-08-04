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
////------------------------------------------------------------------------------


`timescale 1fs/1fs

(* DowngradeIPIdentifiedWarnings="yes" *)
module xxv_ethernet_0_exdes
(

    input  wire          rx_mac_mii_clk_0,
    input  wire [32-1:0] rx_mac_mii_d_0,
    input  wire [3:0]    rx_mac_mii_c_0,
    input  wire          tx_mac_mii_clk_0,
    output wire [32-1:0] tx_mac_mii_d_0,
    output wire [3:0]    tx_mac_mii_c_0,
    input  wire  restart_tx_rx_0,
    output wire [4:0] completion_status,

    input             sys_reset,
    input             dclk,
    input             clk
);

  parameter PKT_NUM         = 20;    //// Many Internal Counters are based on PKT_NUM = 20

  

  wire rx_clk_out_0;

//// RX_0 Signals
  wire rx_reset_0;
  wire rxrecclkout_0;

//// RX_0 User Interface Signals
  wire rx_axis_tvalid_0;
  wire [63:0] rx_axis_tdata_0;
  wire rx_axis_tlast_0;
  wire [7:0] rx_axis_tkeep_0;
  wire rx_axis_tuser_0;
  wire [55:0] rx_preambleout_0;

//// RX_0 Control Signals
  wire ctl_rx_enable_0;
  wire ctl_rx_delete_fcs_0;
  wire ctl_rx_ignore_fcs_0;
  wire [14:0] ctl_rx_max_packet_len_0;
  wire [7:0] ctl_rx_min_packet_len_0;
  wire ctl_rx_custom_preamble_enable_0;
  wire ctl_rx_check_sfd_0;
  wire ctl_rx_check_preamble_0;
  wire ctl_rx_process_lfi_0;


//// RX_0 Stats Signals
  wire stat_rx_bad_code_0;
  wire [1:0] stat_rx_total_packets_0;
  wire stat_rx_total_good_packets_0;
  wire [3:0] stat_rx_total_bytes_0;
  wire [13:0] stat_rx_total_good_bytes_0;
  wire stat_rx_packet_small_0;
  wire stat_rx_jabber_0;
  wire stat_rx_packet_large_0;
  wire stat_rx_oversize_0;
  wire stat_rx_undersize_0;
  wire stat_rx_toolong_0;
  wire stat_rx_fragment_0;
  wire stat_rx_packet_64_bytes_0;
  wire stat_rx_packet_65_127_bytes_0;
  wire stat_rx_packet_128_255_bytes_0;
  wire stat_rx_packet_256_511_bytes_0;
  wire stat_rx_packet_512_1023_bytes_0;
  wire stat_rx_packet_1024_1518_bytes_0;
  wire stat_rx_packet_1519_1522_bytes_0;
  wire stat_rx_packet_1523_1548_bytes_0;
  wire [1:0] stat_rx_bad_fcs_0;
  wire stat_rx_packet_bad_fcs_0;
  wire [1:0] stat_rx_stomped_fcs_0;
  wire stat_rx_packet_1549_2047_bytes_0;
  wire stat_rx_packet_2048_4095_bytes_0;
  wire stat_rx_packet_4096_8191_bytes_0;
  wire stat_rx_packet_8192_9215_bytes_0;
  wire stat_rx_bad_preamble_0;
  wire stat_rx_bad_sfd_0;
  wire stat_rx_got_signal_os_0;
  wire stat_rx_truncated_0;
  wire stat_rx_local_fault_0;
  wire stat_rx_remote_fault_0;


//// TX_0 Signals
  wire tx_reset_0;

//// TX_0 User Interface Signals
  wire tx_axis_tready_0;
  wire tx_axis_tvalid_0;
  wire [63:0] tx_axis_tdata_0;
  wire tx_axis_tlast_0;
  wire [7:0] tx_axis_tkeep_0;
  wire tx_axis_tuser_0;
  wire [55:0] tx_preamblein_0;

//// TX_0 Control Signals
  wire ctl_tx_enable_0;
  wire ctl_tx_fcs_ins_enable_0;
  wire [3:0] ctl_tx_ipg_value_0;
  wire ctl_tx_send_lfi_0;
  wire ctl_tx_send_rfi_0;
  wire ctl_tx_send_idle_0;
  wire ctl_tx_custom_preamble_enable_0;
  wire ctl_tx_ignore_fcs_0;


//// TX_0 Stats Signals
  wire stat_tx_total_packets_0;
  wire [3:0] stat_tx_total_bytes_0;
  wire stat_tx_total_good_packets_0;
  wire [13:0] stat_tx_total_good_bytes_0;
  wire stat_tx_packet_64_bytes_0;
  wire stat_tx_packet_65_127_bytes_0;
  wire stat_tx_packet_128_255_bytes_0;
  wire stat_tx_packet_256_511_bytes_0;
  wire stat_tx_packet_512_1023_bytes_0;
  wire stat_tx_packet_1024_1518_bytes_0;
  wire stat_tx_packet_1519_1522_bytes_0;
  wire stat_tx_packet_1523_1548_bytes_0;
  wire stat_tx_packet_small_0;
  wire stat_tx_packet_large_0;
  wire stat_tx_packet_1549_2047_bytes_0;
  wire stat_tx_packet_2048_4095_bytes_0;
  wire stat_tx_packet_4096_8191_bytes_0;
  wire stat_tx_packet_8192_9215_bytes_0;
  wire stat_tx_bad_fcs_0;
  wire stat_tx_frame_error_0;
  wire stat_tx_local_fault_0;
  wire stat_tx_gmii_fifo_unf_0;
  wire stat_tx_gmii_fifo_ovf_0;


  wire  [4:0 ]completion_status_0;


xxv_ethernet_0 DUT
(
    .tx_mac_mii_d_0     (tx_mac_mii_d_0),
    .tx_mac_mii_c_0     (tx_mac_mii_c_0),
    .tx_mac_mii_clk_0   (tx_mac_mii_clk_0),
    .tx_mac_mii_reset_0 (sys_reset),
    .rx_mac_mii_d_0     (rx_mac_mii_d_0),
    .rx_mac_mii_c_0     (rx_mac_mii_c_0),
    .rx_mac_mii_clk_0   (rx_mac_mii_clk_0),
    .rx_mac_mii_reset_0 (sys_reset),
    .tx_mac_mii_clk90_out_0 (),
    .tx_mac_mii_clk0_out_0  (),
    .mii_mac_tx_clk_0       (),

    .rx_reset_0 (rx_reset_0),

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


    .tx_reset_0 (tx_reset_0),
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


    .tx_core_clk_0 (clk),
    .rx_core_clk_0 (clk)
);

xxv_ethernet_0_pkt_gen_mon #(
.PKT_NUM (PKT_NUM))i_xxv_ethernet_0_pkt_gen_mon_0
(
  .gen_clk (clk),
  .mon_clk (clk),
  .dclk (dclk),
  .sys_reset (sys_reset),
  //// User Interface signals
  .completion_status (completion_status_0),
  .restart_tx_rx (restart_tx_rx_0),
//// RX Signals
  .rx_reset(rx_reset_0),
  .rx_axis_tvalid (rx_axis_tvalid_0),
  .rx_axis_tdata (rx_axis_tdata_0),
  .rx_axis_tlast (rx_axis_tlast_0),
  .rx_axis_tkeep (rx_axis_tkeep_0),
  .rx_axis_tuser (rx_axis_tuser_0),
  .rx_preambleout (rx_preambleout_0),

//// RX Control Signals
  .ctl_rx_enable (ctl_rx_enable_0),
  .ctl_rx_delete_fcs (ctl_rx_delete_fcs_0),
  .ctl_rx_ignore_fcs (ctl_rx_ignore_fcs_0),
  .ctl_rx_max_packet_len (ctl_rx_max_packet_len_0),
  .ctl_rx_min_packet_len (ctl_rx_min_packet_len_0),
  .ctl_rx_custom_preamble_enable (ctl_rx_custom_preamble_enable_0),
  .ctl_rx_check_sfd (ctl_rx_check_sfd_0),
  .ctl_rx_check_preamble (ctl_rx_check_preamble_0),
  .ctl_rx_process_lfi (ctl_rx_process_lfi_0),


//// RX Stats Signals
  .stat_rx_bad_code (stat_rx_bad_code_0),
  .stat_rx_total_packets (stat_rx_total_packets_0),
  .stat_rx_total_good_packets (stat_rx_total_good_packets_0),
  .stat_rx_total_bytes (stat_rx_total_bytes_0),
  .stat_rx_total_good_bytes (stat_rx_total_good_bytes_0),
  .stat_rx_packet_small (stat_rx_packet_small_0),
  .stat_rx_jabber (stat_rx_jabber_0),
  .stat_rx_packet_large (stat_rx_packet_large_0),
  .stat_rx_oversize (stat_rx_oversize_0),
  .stat_rx_undersize (stat_rx_undersize_0),
  .stat_rx_toolong (stat_rx_toolong_0),
  .stat_rx_fragment (stat_rx_fragment_0),
  .stat_rx_packet_64_bytes (stat_rx_packet_64_bytes_0),
  .stat_rx_packet_65_127_bytes (stat_rx_packet_65_127_bytes_0),
  .stat_rx_packet_128_255_bytes (stat_rx_packet_128_255_bytes_0),
  .stat_rx_packet_256_511_bytes (stat_rx_packet_256_511_bytes_0),
  .stat_rx_packet_512_1023_bytes (stat_rx_packet_512_1023_bytes_0),
  .stat_rx_packet_1024_1518_bytes (stat_rx_packet_1024_1518_bytes_0),
  .stat_rx_packet_1519_1522_bytes (stat_rx_packet_1519_1522_bytes_0),
  .stat_rx_packet_1523_1548_bytes (stat_rx_packet_1523_1548_bytes_0),
  .stat_rx_bad_fcs (stat_rx_bad_fcs_0),
  .stat_rx_packet_bad_fcs (stat_rx_packet_bad_fcs_0),
  .stat_rx_stomped_fcs (stat_rx_stomped_fcs_0),
  .stat_rx_packet_1549_2047_bytes (stat_rx_packet_1549_2047_bytes_0),
  .stat_rx_packet_2048_4095_bytes (stat_rx_packet_2048_4095_bytes_0),
  .stat_rx_packet_4096_8191_bytes (stat_rx_packet_4096_8191_bytes_0),
  .stat_rx_packet_8192_9215_bytes (stat_rx_packet_8192_9215_bytes_0),
  .stat_rx_bad_preamble (stat_rx_bad_preamble_0),
  .stat_rx_bad_sfd (stat_rx_bad_sfd_0),
  .stat_rx_got_signal_os (stat_rx_got_signal_os_0),
  .stat_rx_truncated (stat_rx_truncated_0),
  .stat_rx_local_fault (stat_rx_local_fault_0),
  .stat_rx_remote_fault (stat_rx_remote_fault_0),


  .tx_reset(tx_reset_0),
//// TX LBUS Signals
  .tx_axis_tready (tx_axis_tready_0),
  .tx_axis_tvalid (tx_axis_tvalid_0),
  .tx_axis_tdata (tx_axis_tdata_0),
  .tx_axis_tlast (tx_axis_tlast_0),
  .tx_axis_tkeep (tx_axis_tkeep_0),
  .tx_axis_tuser (tx_axis_tuser_0),
  .tx_preamblein (tx_preamblein_0),

//// TX Control Signals
  .ctl_tx_enable (ctl_tx_enable_0),
  .ctl_tx_fcs_ins_enable (ctl_tx_fcs_ins_enable_0),
  .ctl_tx_ipg_value (ctl_tx_ipg_value_0),
  .ctl_tx_send_lfi (ctl_tx_send_lfi_0),
  .ctl_tx_send_rfi (ctl_tx_send_rfi_0),
  .ctl_tx_send_idle (ctl_tx_send_idle_0),
  .ctl_tx_custom_preamble_enable (ctl_tx_custom_preamble_enable_0),
  .ctl_tx_ignore_fcs (ctl_tx_ignore_fcs_0),


//// TX Stats Signals
  .stat_tx_total_packets (stat_tx_total_packets_0),
  .stat_tx_total_bytes (stat_tx_total_bytes_0),
  .stat_tx_total_good_packets (stat_tx_total_good_packets_0),
  .stat_tx_total_good_bytes (stat_tx_total_good_bytes_0),
  .stat_tx_packet_64_bytes (stat_tx_packet_64_bytes_0),
  .stat_tx_packet_65_127_bytes (stat_tx_packet_65_127_bytes_0),
  .stat_tx_packet_128_255_bytes (stat_tx_packet_128_255_bytes_0),
  .stat_tx_packet_256_511_bytes (stat_tx_packet_256_511_bytes_0),
  .stat_tx_packet_512_1023_bytes (stat_tx_packet_512_1023_bytes_0),
  .stat_tx_packet_1024_1518_bytes (stat_tx_packet_1024_1518_bytes_0),
  .stat_tx_packet_1519_1522_bytes (stat_tx_packet_1519_1522_bytes_0),
  .stat_tx_packet_1523_1548_bytes (stat_tx_packet_1523_1548_bytes_0),
  .stat_tx_packet_small (stat_tx_packet_small_0),
  .stat_tx_packet_large (stat_tx_packet_large_0),
  .stat_tx_packet_1549_2047_bytes (stat_tx_packet_1549_2047_bytes_0),
  .stat_tx_packet_2048_4095_bytes (stat_tx_packet_2048_4095_bytes_0),
  .stat_tx_packet_4096_8191_bytes (stat_tx_packet_4096_8191_bytes_0),
  .stat_tx_packet_8192_9215_bytes (stat_tx_packet_8192_9215_bytes_0),
  .stat_tx_bad_fcs (stat_tx_bad_fcs_0),
  .stat_tx_frame_error (stat_tx_frame_error_0),
  .stat_tx_local_fault (stat_tx_local_fault_0),
  .stat_tx_gmii_fifo_unf (stat_tx_gmii_fifo_unf_0),
  .stat_tx_gmii_fifo_ovf (stat_tx_gmii_fifo_ovf_0),

   
  .rx_gt_locked_led (),
  .rx_block_lock_led ()
    );

assign completion_status = completion_status_0;


endmodule
