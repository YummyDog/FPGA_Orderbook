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
module xxv_ethernet_0_top #(
  parameter SERDES_WIDTH = 64
)(
  //// #-------------------
  //// # Clocks and Resets
  //// #-------------------
  input  wire tx_core_clk,
  input  wire rx_core_clk,
  input  wire tx_reset,
  input  wire rx_reset,

  //// #----------------------
  //// # Control Interface
  //// #----------------------
  input  wire ctl_rx_enable,
  input  wire ctl_rx_delete_fcs,
  input  wire ctl_rx_ignore_fcs,
  input  wire [14:0] ctl_rx_max_packet_len,
  input  wire [7:0] ctl_rx_min_packet_len,
  input  wire ctl_rx_custom_preamble_enable,
  input  wire ctl_rx_check_sfd,
  input  wire ctl_rx_check_preamble,
  input  wire ctl_rx_process_lfi,
  input  wire ctl_tx_enable,
  input  wire ctl_tx_fcs_ins_enable,
  input  wire [3:0] ctl_tx_ipg_value,
  input  wire ctl_tx_send_lfi,
  input  wire ctl_tx_send_rfi,
  input  wire ctl_tx_send_idle,
  input  wire ctl_tx_custom_preamble_enable,
  input  wire ctl_tx_ignore_fcs,


  //// #---------------------
  //// # Stats Interface
  //// #---------------------
  output wire stat_rx_bad_code,
  output wire [1:0] stat_rx_total_packets,
  output wire stat_rx_total_good_packets,
  output wire [3:0] stat_rx_total_bytes,
  output wire [13:0] stat_rx_total_good_bytes,
  output wire stat_rx_packet_small,
  output wire stat_rx_jabber,
  output wire stat_rx_packet_large,
  output wire stat_rx_oversize,
  output wire stat_rx_undersize,
  output wire stat_rx_toolong,
  output wire stat_rx_fragment,
  output wire stat_rx_packet_64_bytes,
  output wire stat_rx_packet_65_127_bytes,
  output wire stat_rx_packet_128_255_bytes,
  output wire stat_rx_packet_256_511_bytes,
  output wire stat_rx_packet_512_1023_bytes,
  output wire stat_rx_packet_1024_1518_bytes,
  output wire stat_rx_packet_1519_1522_bytes,
  output wire stat_rx_packet_1523_1548_bytes,
  output wire [1:0] stat_rx_bad_fcs,
  output wire stat_rx_packet_bad_fcs,
  output wire [1:0] stat_rx_stomped_fcs,
  output wire stat_rx_packet_1549_2047_bytes,
  output wire stat_rx_packet_2048_4095_bytes,
  output wire stat_rx_packet_4096_8191_bytes,
  output wire stat_rx_packet_8192_9215_bytes,
  output wire stat_rx_bad_preamble,
  output wire stat_rx_bad_sfd,
  output wire stat_rx_got_signal_os,
  output wire stat_rx_truncated,
  output wire stat_rx_local_fault,
  output wire stat_rx_remote_fault,
  output wire stat_tx_total_packets,
  output wire [3:0] stat_tx_total_bytes,
  output wire stat_tx_total_good_packets,
  output wire [13:0] stat_tx_total_good_bytes,
  output wire stat_tx_packet_64_bytes,
  output wire stat_tx_packet_65_127_bytes,
  output wire stat_tx_packet_128_255_bytes,
  output wire stat_tx_packet_256_511_bytes,
  output wire stat_tx_packet_512_1023_bytes,
  output wire stat_tx_packet_1024_1518_bytes,
  output wire stat_tx_packet_1519_1522_bytes,
  output wire stat_tx_packet_1523_1548_bytes,
  output wire stat_tx_packet_small,
  output wire stat_tx_packet_large,
  output wire stat_tx_packet_1549_2047_bytes,
  output wire stat_tx_packet_2048_4095_bytes,
  output wire stat_tx_packet_4096_8191_bytes,
  output wire stat_tx_packet_8192_9215_bytes,
  output wire stat_tx_bad_fcs,
  output wire stat_tx_frame_error,
  output wire stat_tx_local_fault,
  output wire stat_tx_gmii_fifo_unf,
  output wire stat_tx_gmii_fifo_ovf,


  //// #-------------------
  //// # User Interface
  //// #-------------------
  output wire rx_axis_tvalid,
  output wire [63:0] rx_axis_tdata,
  output wire rx_axis_tlast,
  output wire [7:0] rx_axis_tkeep,
  output wire rx_axis_tuser,
  output wire [55:0] rx_preambleout,
  output wire tx_axis_tready,
  input  wire tx_axis_tvalid,
  input  wire [63:0] tx_axis_tdata,
  input  wire tx_axis_tlast,
  input  wire [7:0] tx_axis_tkeep,
  input  wire tx_axis_tuser,
  input  wire [55:0] tx_preamblein,

  //// #---------------------
  //// # Tx XGMII Interface
  //// #---------------------
  output wire [32-1:0] tx_mii_d,
  output wire [3:0]    tx_mii_c,
  input  wire tx_mii_reset,
  input  wire tx_mii_clk,
  output wire tx_mii_clk90_out,
  output wire tx_mii_clk0_out,
  output wire mii_tx_clk,
  //// #---------------------
  //// # Rx XGMII Interface
  //// #---------------------
  input  wire [32-1:0] rx_mii_d,
  input  wire [3:0]    rx_mii_c,
  input  wire rx_mii_clk,
  input  wire rx_mii_reset
);


  wire stat_rx_unicast;
  wire stat_rx_multicast;
  wire stat_rx_broadcast;
  wire stat_rx_vlan;
  wire stat_rx_pause;
  wire stat_rx_user_pause;
  wire stat_rx_inrangeerr;
  wire [8:0] stat_rx_pause_valid;
  wire [15:0] stat_rx_pause_quanta0;
  wire [15:0] stat_rx_pause_quanta1;
  wire [15:0] stat_rx_pause_quanta2;
  wire [15:0] stat_rx_pause_quanta3;
  wire [15:0] stat_rx_pause_quanta4;
  wire [15:0] stat_rx_pause_quanta5;
  wire [15:0] stat_rx_pause_quanta6;
  wire [15:0] stat_rx_pause_quanta7;
  wire [15:0] stat_rx_pause_quanta8;
  wire [8:0] stat_rx_pause_req;
  wire [8:0] stat_tx_pause_valid;
  wire stat_tx_unicast;
  wire stat_tx_multicast;
  wire stat_tx_broadcast;
  wire stat_tx_vlan;
  wire stat_tx_pause;
  wire stat_tx_user_pause;


  wire [64-1:0] my_rx_mii_d;
  wire [7:0] my_rx_mii_c;
  wire [64-1:0] my_tx_mii_d;
  wire [7:0] my_tx_mii_c;
  wire       mii_rx_clk;
  wire       tx_mii_reset_c;
  wire       rx_mii_reset_c;
  wire       tx_mii_clk0;
  wire       tx_mii_clk0_sel;
  wire       tx_mii_clk90_sel;




  //// #---------------------------------------------------------
  //// #                      Core
  //// #---------------------------------------------------------
  xxv_ethernet_v5_0_2_mac_hsec_cores #(
    .SERDES_WIDTH (SERDES_WIDTH)
  ) i_xxv_ethernet_0_CORE (
    //// #----------------------
    //// # Tx Clocks and Resets
    //// #----------------------
    .tx_core_clk (tx_core_clk),
    .rx_core_clk (rx_core_clk),
    .tx_reset (tx_reset ),
    //// #----------------------
    //// # Rx Clocks and Resets
    //// #----------------------
    .rx_reset (rx_reset),
    //// #----------------------
    //// # Control Interface
    //// #----------------------
    .ctl_tx_enable (ctl_tx_enable),
    .ctl_tx_fcs_ins_enable (ctl_tx_fcs_ins_enable),
    .ctl_tx_ipg_value (ctl_tx_ipg_value),
    .ctl_tx_send_lfi (ctl_tx_send_lfi),
    .ctl_tx_send_rfi (ctl_tx_send_rfi),
    .ctl_tx_send_idle (ctl_tx_send_idle),
    .ctl_tx_custom_preamble_enable (ctl_tx_custom_preamble_enable),
    .ctl_tx_ignore_fcs (ctl_tx_ignore_fcs),

    .ctl_tx_pause_req('b0),
    .ctl_tx_pause_enable('b0),
    .ctl_tx_resend_pause('b0),
    .ctl_tx_pause_quanta0('b0),
    .ctl_tx_pause_refresh_timer0('b0),
    .ctl_tx_pause_quanta1('b0),
    .ctl_tx_pause_refresh_timer1('b0),
    .ctl_tx_pause_quanta2('b0),
    .ctl_tx_pause_refresh_timer2('b0),
    .ctl_tx_pause_quanta3('b0),
    .ctl_tx_pause_refresh_timer3('b0),
    .ctl_tx_pause_quanta4('b0),
    .ctl_tx_pause_refresh_timer4('b0),
    .ctl_tx_pause_quanta5('b0),
    .ctl_tx_pause_refresh_timer5('b0),
    .ctl_tx_pause_quanta6('b0),
    .ctl_tx_pause_refresh_timer6('b0),
    .ctl_tx_pause_quanta7('b0),
    .ctl_tx_pause_refresh_timer7('b0),
    .ctl_tx_pause_quanta8('b0),
    .ctl_tx_pause_refresh_timer8('b0),
    .ctl_tx_da_gpp('b0),
    .ctl_tx_sa_gpp('b0),
    .ctl_tx_ethertype_gpp('b0),
    .ctl_tx_opcode_gpp('b0),
    .ctl_tx_da_ppp('b0),
    .ctl_tx_sa_ppp('b0),
    .ctl_tx_ethertype_ppp('b0),
    .ctl_tx_opcode_ppp('b0),
    .ctl_rx_enable (ctl_rx_enable),
    .ctl_rx_delete_fcs (ctl_rx_delete_fcs),
    .ctl_rx_ignore_fcs (ctl_rx_ignore_fcs),
    .ctl_rx_max_packet_len (ctl_rx_max_packet_len),
    .ctl_rx_min_packet_len (ctl_rx_min_packet_len),
    .ctl_rx_custom_preamble_enable (ctl_rx_custom_preamble_enable),
    .ctl_rx_check_sfd (ctl_rx_check_sfd),
    .ctl_rx_check_preamble (ctl_rx_check_preamble),
    .ctl_rx_process_lfi (ctl_rx_process_lfi),
    .ctl_rx_forward_control('b0),
    .ctl_rx_pause_ack('b0),
    .ctl_rx_check_ack('b0),
    .ctl_rx_pause_enable('b0),
    .ctl_rx_enable_gcp('b0),
    .ctl_rx_check_mcast_gcp('b0),
    .ctl_rx_check_ucast_gcp('b0),
    .ctl_rx_pause_da_ucast('b0),
    .ctl_rx_check_sa_gcp('b0),
    .ctl_rx_pause_sa('b0),
    .ctl_rx_check_etype_gcp('b0),
    .ctl_rx_etype_gcp('b0),
    .ctl_rx_check_opcode_gcp('b0),
    .ctl_rx_opcode_min_gcp('b0),
    .ctl_rx_opcode_max_gcp('b0),
    .ctl_rx_enable_pcp('b0),
    .ctl_rx_check_mcast_pcp('b0),
    .ctl_rx_check_ucast_pcp('b0),
    .ctl_rx_pause_da_mcast('b0),
    .ctl_rx_check_sa_pcp('b0),
    .ctl_rx_check_etype_pcp('b0),
    .ctl_rx_etype_pcp('b0),
    .ctl_rx_check_opcode_pcp('b0),
    .ctl_rx_opcode_min_pcp('b0),
    .ctl_rx_opcode_max_pcp('b0),
    .ctl_rx_enable_gpp('b0),
    .ctl_rx_check_mcast_gpp('b0),
    .ctl_rx_check_ucast_gpp('b0),
    .ctl_rx_check_sa_gpp('b0),
    .ctl_rx_check_etype_gpp('b0),
    .ctl_rx_etype_gpp('b0),
    .ctl_rx_check_opcode_gpp('b0),
    .ctl_rx_opcode_gpp('b0),
    .ctl_rx_enable_ppp('b0),
    .ctl_rx_check_mcast_ppp('b0),
    .ctl_rx_check_ucast_ppp('b0),
    .ctl_rx_check_sa_ppp('b0),
    .ctl_rx_check_etype_ppp('b0),
    .ctl_rx_etype_ppp('b0),
    .ctl_rx_check_opcode_ppp('b0),
    .ctl_rx_opcode_ppp('b0),

    //// #----------------------
    //// # Rx User Interface
    //// #----------------------
    .rx_axis_tvalid (rx_axis_tvalid),
    .rx_axis_tdata (rx_axis_tdata),
    .rx_axis_tlast (rx_axis_tlast),
    .rx_axis_tkeep (rx_axis_tkeep),
    .rx_axis_tuser (rx_axis_tuser),
    .rx_preambleout (rx_preambleout),

    //// #----------------------
    //// # Tx User Interface
    //// #----------------------
    .tx_axis_tready (tx_axis_tready),
    .tx_axis_tvalid (tx_axis_tvalid),
    .tx_axis_tdata (tx_axis_tdata),
    .tx_axis_tlast (tx_axis_tlast),
    .tx_axis_tkeep (tx_axis_tkeep),
    .tx_axis_tuser (tx_axis_tuser),
    .tx_preamblein (tx_preamblein),
    //// #--------------------
    //// # Stats Interface
    //// #--------------------
    .stat_tx_total_packets (stat_tx_total_packets),
    .stat_tx_total_bytes (stat_tx_total_bytes),
    .stat_tx_total_good_packets (stat_tx_total_good_packets),
    .stat_tx_total_good_bytes (stat_tx_total_good_bytes),
    .stat_tx_packet_64_bytes (stat_tx_packet_64_bytes),
    .stat_tx_packet_65_127_bytes (stat_tx_packet_65_127_bytes),
    .stat_tx_packet_128_255_bytes (stat_tx_packet_128_255_bytes),
    .stat_tx_packet_256_511_bytes (stat_tx_packet_256_511_bytes),
    .stat_tx_packet_512_1023_bytes (stat_tx_packet_512_1023_bytes),
    .stat_tx_packet_1024_1518_bytes (stat_tx_packet_1024_1518_bytes),
    .stat_tx_packet_1519_1522_bytes (stat_tx_packet_1519_1522_bytes),
    .stat_tx_packet_1523_1548_bytes (stat_tx_packet_1523_1548_bytes),
    .stat_tx_packet_small (stat_tx_packet_small),
    .stat_tx_packet_large (stat_tx_packet_large),
    .stat_tx_packet_1549_2047_bytes (stat_tx_packet_1549_2047_bytes),
    .stat_tx_packet_2048_4095_bytes (stat_tx_packet_2048_4095_bytes),
    .stat_tx_packet_4096_8191_bytes (stat_tx_packet_4096_8191_bytes),
    .stat_tx_packet_8192_9215_bytes (stat_tx_packet_8192_9215_bytes),
    .stat_tx_bad_fcs (stat_tx_bad_fcs),
    .stat_tx_frame_error (stat_tx_frame_error),
    .stat_tx_local_fault (stat_tx_local_fault),
    .stat_tx_gmii_fifo_unf (stat_tx_gmii_fifo_unf),
    .stat_tx_gmii_fifo_ovf (stat_tx_gmii_fifo_ovf),
    .stat_tx_pause_valid (stat_tx_pause_valid),
    .stat_tx_unicast (stat_tx_unicast),
    .stat_tx_multicast (stat_tx_multicast),
    .stat_tx_broadcast (stat_tx_broadcast),
    .stat_tx_vlan (stat_tx_vlan),
    .stat_tx_pause (stat_tx_pause),
    .stat_tx_user_pause (stat_tx_user_pause),
    .stat_rx_bad_code (stat_rx_bad_code),
    .stat_rx_total_packets (stat_rx_total_packets),
    .stat_rx_total_good_packets (stat_rx_total_good_packets),
    .stat_rx_total_bytes (stat_rx_total_bytes),
    .stat_rx_total_good_bytes (stat_rx_total_good_bytes),
    .stat_rx_packet_small (stat_rx_packet_small),
    .stat_rx_jabber (stat_rx_jabber),
    .stat_rx_packet_large (stat_rx_packet_large),
    .stat_rx_oversize (stat_rx_oversize),
    .stat_rx_undersize (stat_rx_undersize),
    .stat_rx_toolong (stat_rx_toolong),
    .stat_rx_fragment (stat_rx_fragment),
    .stat_rx_packet_64_bytes (stat_rx_packet_64_bytes),
    .stat_rx_packet_65_127_bytes (stat_rx_packet_65_127_bytes),
    .stat_rx_packet_128_255_bytes (stat_rx_packet_128_255_bytes),
    .stat_rx_packet_256_511_bytes (stat_rx_packet_256_511_bytes),
    .stat_rx_packet_512_1023_bytes (stat_rx_packet_512_1023_bytes),
    .stat_rx_packet_1024_1518_bytes (stat_rx_packet_1024_1518_bytes),
    .stat_rx_packet_1519_1522_bytes (stat_rx_packet_1519_1522_bytes),
    .stat_rx_packet_1523_1548_bytes (stat_rx_packet_1523_1548_bytes),
    .stat_rx_bad_fcs (stat_rx_bad_fcs),
    .stat_rx_packet_bad_fcs (stat_rx_packet_bad_fcs),
    .stat_rx_stomped_fcs (stat_rx_stomped_fcs),
    .stat_rx_packet_1549_2047_bytes (stat_rx_packet_1549_2047_bytes),
    .stat_rx_packet_2048_4095_bytes (stat_rx_packet_2048_4095_bytes),
    .stat_rx_packet_4096_8191_bytes (stat_rx_packet_4096_8191_bytes),
    .stat_rx_packet_8192_9215_bytes (stat_rx_packet_8192_9215_bytes),
    .stat_rx_bad_preamble (stat_rx_bad_preamble),
    .stat_rx_bad_sfd (stat_rx_bad_sfd),
    .stat_rx_got_signal_os (stat_rx_got_signal_os),
    .stat_rx_truncated (stat_rx_truncated),
    .stat_rx_local_fault (stat_rx_local_fault),
    .stat_rx_remote_fault (stat_rx_remote_fault),
    .stat_rx_unicast (stat_rx_unicast),
    .stat_rx_multicast (stat_rx_multicast),
    .stat_rx_broadcast (stat_rx_broadcast),
    .stat_rx_vlan (stat_rx_vlan),
    .stat_rx_pause (stat_rx_pause),
    .stat_rx_user_pause (stat_rx_user_pause),
    .stat_rx_inrangeerr (stat_rx_inrangeerr),
    .stat_rx_pause_valid (stat_rx_pause_valid),
    .stat_rx_pause_quanta0 (stat_rx_pause_quanta0),
    .stat_rx_pause_quanta1 (stat_rx_pause_quanta1),
    .stat_rx_pause_quanta2 (stat_rx_pause_quanta2),
    .stat_rx_pause_quanta3 (stat_rx_pause_quanta3),
    .stat_rx_pause_quanta4 (stat_rx_pause_quanta4),
    .stat_rx_pause_quanta5 (stat_rx_pause_quanta5),
    .stat_rx_pause_quanta6 (stat_rx_pause_quanta6),
    .stat_rx_pause_quanta7 (stat_rx_pause_quanta7),
    .stat_rx_pause_quanta8 (stat_rx_pause_quanta8),
    .stat_rx_pause_req (stat_rx_pause_req),

    //// #---------------------
    //// # Tx Serdes Interface
    //// #---------------------
    .tx_mii_re       (1'b1),
    .tx_mii_d        (my_tx_mii_d),
    .tx_mii_c        (my_tx_mii_c),
    .tx_mii_clk      (tx_mii_clk0_sel),
    .tx_mii_reset    (tx_mii_reset_c),

    // #---------------------
    // # Rx Serdes Interface
    // #---------------------
    .rx_mii_wr       (1'b1),
    .rx_mii_d        (my_rx_mii_d),
    .rx_mii_c        (my_rx_mii_c),
    .rx_mii_clk      (mii_rx_clk),
    .rx_mii_reset    (rx_mii_reset_c)

  ); //// i_HSEC_CORES

wire [31:0] my_tx_mii_d_32;
wire [3:0]  my_tx_mii_c_32;
 xxv_ethernet_0_xgmii_if i_XGMII_IF (
   // Port declarations

   .tx_reset (tx_mii_reset),
   .rx_reset (rx_mii_reset),
   .tx_clk0  (tx_mii_clk0_sel),
   .tx_clk90 (tx_mii_clk90_sel),
   .xgmii_txd_core (my_tx_mii_d),
   .xgmii_txc_core (my_tx_mii_c),
   .xgmii_txd (my_tx_mii_d_32),
   .xgmii_txc (my_tx_mii_c_32),
   .xgmii_tx_clk (mii_tx_clk),
   .rx_clk0 (mii_rx_clk),
   .xgmii_rx_clk (rx_mii_clk),
   .xgmii_rxd (rx_mii_d),
   .xgmii_rxc (rx_mii_c),
   .xgmii_rxd_core (my_rx_mii_d),
   .xgmii_rxc_core (my_rx_mii_c)
  );

  assign tx_mii_d =  my_tx_mii_d_32;
  assign tx_mii_c = my_tx_mii_c_32 ;

  xxv_ethernet_0_mac_only64_syncer_reset i_xxv_ethernet_0_tx_mii_reset (
    .clk             ( tx_mii_clk0_sel ),
    .reset_async     ( tx_mii_reset ),
    .reset           ( tx_mii_reset_c )
  ) ;

  xxv_ethernet_0_mac_only64_syncer_reset i_xxv_ethernet_0_rx_mii_reset (
    .clk             ( mii_rx_clk ),
    .reset_async     ( rx_mii_reset ),
    .reset           ( rx_mii_reset_c )
  ) ;



  wire       tx_mii_clk90;
 xxv_ethernet_0_shared_clocking i_SHARED_CLOCKING  (
   .tx_mii_clk   (tx_mii_clk),
   .tx_mii_reset (tx_mii_reset),
   .tx_mii_clk0  (tx_mii_clk0),
   .tx_mii_clk90 (tx_mii_clk90)
 );

assign tx_mii_clk0_sel = tx_mii_clk0;
assign tx_mii_clk90_sel = tx_mii_clk90;
assign tx_mii_clk0_out = tx_mii_clk0;
assign tx_mii_clk90_out = tx_mii_clk90;



endmodule


module xxv_ethernet_0_mac_only64_syncer_reset
#(
  parameter RESET_PIPE_LEN = 3
 )
(
  input  wire clk,
  input  wire reset_async,
  output wire reset
);

  (* ASYNC_REG = "TRUE" *) reg  [2:0] reset_pipe_stretch;
  (* ASYNC_REG = "TRUE" *) reg  [RESET_PIPE_LEN-1:0] reset_pipe_retime;
  (* max_fanout = 500 *) reg  reset_pipe_out;

// pragma translate_off

  initial reset_pipe_stretch = {2{1'b1}};
  initial reset_pipe_retime  = {RESET_PIPE_LEN{1'b1}};
  initial reset_pipe_out     = 1'b1;

// pragma translate_on

  always @(posedge clk or posedge reset_async)
    begin
      if (reset_async == 1'b1)
        begin
          reset_pipe_stretch <= {3{1'b1}};
        end
      else
        begin
          reset_pipe_stretch <= {reset_pipe_stretch[1:0], 1'b0};
        end
    end

  always @(posedge clk)
    begin
      reset_pipe_retime <= {reset_pipe_retime[RESET_PIPE_LEN-2:0], reset_pipe_stretch[2]};
      reset_pipe_out    <= reset_pipe_retime[RESET_PIPE_LEN-1];
    end

  assign reset = reset_pipe_out;

endmodule

