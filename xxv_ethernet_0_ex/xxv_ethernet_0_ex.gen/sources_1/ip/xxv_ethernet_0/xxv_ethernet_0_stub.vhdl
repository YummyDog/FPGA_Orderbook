-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2025.2 (win64) Build 6299465 Fri Nov 14 19:35:11 GMT 2025
-- Date        : Mon Aug  3 18:21:03 2026
-- Host        : DESKTOP-MB4FOM3 running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               c:/Users/lskje/Desktop/FPGA_Orderbook/orderbookproj/orderbookproj.gen/sources_1/ip/xxv_ethernet_0/xxv_ethernet_0_stub.vhdl
-- Design      : xxv_ethernet_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xcu26-vsva1365-2LV-e
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity xxv_ethernet_0 is
  Port ( 
    rx_mac_mii_d_0 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    rx_mac_mii_c_0 : in STD_LOGIC_VECTOR ( 3 downto 0 );
    rx_mac_mii_clk_0 : in STD_LOGIC;
    rx_mac_mii_reset_0 : in STD_LOGIC;
    tx_mac_mii_d_0 : out STD_LOGIC_VECTOR ( 31 downto 0 );
    tx_mac_mii_c_0 : out STD_LOGIC_VECTOR ( 3 downto 0 );
    tx_mac_mii_clk_0 : in STD_LOGIC;
    tx_mac_mii_reset_0 : in STD_LOGIC;
    tx_mac_mii_clk90_out_0 : out STD_LOGIC;
    tx_mac_mii_clk0_out_0 : out STD_LOGIC;
    mii_mac_tx_clk_0 : out STD_LOGIC;
    rx_reset_0 : in STD_LOGIC;
    rx_axis_tvalid_0 : out STD_LOGIC;
    rx_axis_tdata_0 : out STD_LOGIC_VECTOR ( 63 downto 0 );
    rx_axis_tlast_0 : out STD_LOGIC;
    rx_axis_tkeep_0 : out STD_LOGIC_VECTOR ( 7 downto 0 );
    rx_axis_tuser_0 : out STD_LOGIC;
    rx_preambleout_0 : out STD_LOGIC_VECTOR ( 55 downto 0 );
    ctl_rx_enable_0 : in STD_LOGIC;
    ctl_rx_delete_fcs_0 : in STD_LOGIC;
    ctl_rx_ignore_fcs_0 : in STD_LOGIC;
    ctl_rx_max_packet_len_0 : in STD_LOGIC_VECTOR ( 14 downto 0 );
    ctl_rx_min_packet_len_0 : in STD_LOGIC_VECTOR ( 7 downto 0 );
    ctl_rx_custom_preamble_enable_0 : in STD_LOGIC;
    ctl_rx_check_sfd_0 : in STD_LOGIC;
    ctl_rx_check_preamble_0 : in STD_LOGIC;
    ctl_rx_process_lfi_0 : in STD_LOGIC;
    stat_rx_bad_code_0 : out STD_LOGIC;
    stat_rx_total_packets_0 : out STD_LOGIC_VECTOR ( 1 downto 0 );
    stat_rx_total_good_packets_0 : out STD_LOGIC;
    stat_rx_total_bytes_0 : out STD_LOGIC_VECTOR ( 3 downto 0 );
    stat_rx_total_good_bytes_0 : out STD_LOGIC_VECTOR ( 13 downto 0 );
    stat_rx_packet_small_0 : out STD_LOGIC;
    stat_rx_jabber_0 : out STD_LOGIC;
    stat_rx_packet_large_0 : out STD_LOGIC;
    stat_rx_oversize_0 : out STD_LOGIC;
    stat_rx_undersize_0 : out STD_LOGIC;
    stat_rx_toolong_0 : out STD_LOGIC;
    stat_rx_fragment_0 : out STD_LOGIC;
    stat_rx_packet_64_bytes_0 : out STD_LOGIC;
    stat_rx_packet_65_127_bytes_0 : out STD_LOGIC;
    stat_rx_packet_128_255_bytes_0 : out STD_LOGIC;
    stat_rx_packet_256_511_bytes_0 : out STD_LOGIC;
    stat_rx_packet_512_1023_bytes_0 : out STD_LOGIC;
    stat_rx_packet_1024_1518_bytes_0 : out STD_LOGIC;
    stat_rx_packet_1519_1522_bytes_0 : out STD_LOGIC;
    stat_rx_packet_1523_1548_bytes_0 : out STD_LOGIC;
    stat_rx_bad_fcs_0 : out STD_LOGIC_VECTOR ( 1 downto 0 );
    stat_rx_packet_bad_fcs_0 : out STD_LOGIC;
    stat_rx_stomped_fcs_0 : out STD_LOGIC_VECTOR ( 1 downto 0 );
    stat_rx_packet_1549_2047_bytes_0 : out STD_LOGIC;
    stat_rx_packet_2048_4095_bytes_0 : out STD_LOGIC;
    stat_rx_packet_4096_8191_bytes_0 : out STD_LOGIC;
    stat_rx_packet_8192_9215_bytes_0 : out STD_LOGIC;
    stat_rx_bad_preamble_0 : out STD_LOGIC;
    stat_rx_bad_sfd_0 : out STD_LOGIC;
    stat_rx_got_signal_os_0 : out STD_LOGIC;
    stat_rx_truncated_0 : out STD_LOGIC;
    stat_rx_local_fault_0 : out STD_LOGIC;
    stat_rx_remote_fault_0 : out STD_LOGIC;
    tx_reset_0 : in STD_LOGIC;
    tx_axis_tready_0 : out STD_LOGIC;
    tx_axis_tvalid_0 : in STD_LOGIC;
    tx_axis_tdata_0 : in STD_LOGIC_VECTOR ( 63 downto 0 );
    tx_axis_tlast_0 : in STD_LOGIC;
    tx_axis_tkeep_0 : in STD_LOGIC_VECTOR ( 7 downto 0 );
    tx_axis_tuser_0 : in STD_LOGIC;
    tx_preamblein_0 : in STD_LOGIC_VECTOR ( 55 downto 0 );
    ctl_tx_enable_0 : in STD_LOGIC;
    ctl_tx_fcs_ins_enable_0 : in STD_LOGIC;
    ctl_tx_ipg_value_0 : in STD_LOGIC_VECTOR ( 3 downto 0 );
    ctl_tx_send_lfi_0 : in STD_LOGIC;
    ctl_tx_send_rfi_0 : in STD_LOGIC;
    ctl_tx_send_idle_0 : in STD_LOGIC;
    ctl_tx_custom_preamble_enable_0 : in STD_LOGIC;
    ctl_tx_ignore_fcs_0 : in STD_LOGIC;
    stat_tx_total_packets_0 : out STD_LOGIC;
    stat_tx_total_bytes_0 : out STD_LOGIC_VECTOR ( 3 downto 0 );
    stat_tx_total_good_packets_0 : out STD_LOGIC;
    stat_tx_total_good_bytes_0 : out STD_LOGIC_VECTOR ( 13 downto 0 );
    stat_tx_packet_64_bytes_0 : out STD_LOGIC;
    stat_tx_packet_65_127_bytes_0 : out STD_LOGIC;
    stat_tx_packet_128_255_bytes_0 : out STD_LOGIC;
    stat_tx_packet_256_511_bytes_0 : out STD_LOGIC;
    stat_tx_packet_512_1023_bytes_0 : out STD_LOGIC;
    stat_tx_packet_1024_1518_bytes_0 : out STD_LOGIC;
    stat_tx_packet_1519_1522_bytes_0 : out STD_LOGIC;
    stat_tx_packet_1523_1548_bytes_0 : out STD_LOGIC;
    stat_tx_packet_small_0 : out STD_LOGIC;
    stat_tx_packet_large_0 : out STD_LOGIC;
    stat_tx_packet_1549_2047_bytes_0 : out STD_LOGIC;
    stat_tx_packet_2048_4095_bytes_0 : out STD_LOGIC;
    stat_tx_packet_4096_8191_bytes_0 : out STD_LOGIC;
    stat_tx_packet_8192_9215_bytes_0 : out STD_LOGIC;
    stat_tx_bad_fcs_0 : out STD_LOGIC;
    stat_tx_frame_error_0 : out STD_LOGIC;
    stat_tx_local_fault_0 : out STD_LOGIC;
    stat_tx_gmii_fifo_unf_0 : out STD_LOGIC;
    stat_tx_gmii_fifo_ovf_0 : out STD_LOGIC;
    tx_core_clk_0 : in STD_LOGIC;
    rx_core_clk_0 : in STD_LOGIC
  );

  attribute CHECK_LICENSE_TYPE : string;
  attribute CHECK_LICENSE_TYPE of xxv_ethernet_0 : entity is "xxv_ethernet_0,xxv_ethernet_core,{}";
  attribute CORE_GENERATION_INFO : string;
  attribute CORE_GENERATION_INFO of xxv_ethernet_0 : entity is "xxv_ethernet_0,xxv_ethernet_core,{x_ipVendor=xilinx.com,x_ipLibrary=ip,x_ipName=xxv_ethernet,x_ipVersion=1.3,x_ipCoreRevision=0,x_ipLanguage=VERILOG,C_LINE_RATE= 10,C_NUM_OF_CORES= 1,C_CLOCKING= Asynchronous,C_DATA_PATH_INTERFACE= AXI Stream,C_BASE_R_KR= BASE-KR,C_XGMII_INTERFACE= 1,C_INCLUDE_FEC_LOGIC= 0,C_INCLUDE_AUTO_NEG_LT_LOGIC= None,C_INCLUDE_USER_FIFO= 1,C_ENABLE_TX_FLOW_CONTROL_LOGIC= 0,C_ENABLE_RX_FLOW_CONTROL_LOGIC= 0,C_ENABLE_TIME_STAMPING= 0,C_PTP_OPERATION_MODE= 2,C_PTP_CLOCKING_MODE= 0,C_TX_LATENCY_ADJUST= 0,C_ENABLE_VLANE_ADJUST_MODE= 0,C_GT_REF_CLK_FREQ= 156.25,C_GT_DRP_CLK= 100.00,C_GT_TYPE= GTY,C_LANE1_GT_LOC= X0Y0,C_LANE2_GT_LOC= NA,C_LANE3_GT_LOC= NA,C_LANE4_GT_LOC= NA,C_ENABLE_PIPELINE_REG= 0,C_ADD_GT_CNTRL_STS_PORTS= 1,C_INCLUDE_SHARED_LOGIC= 1}";
  attribute DowngradeIPIdentifiedWarnings : string;
  attribute DowngradeIPIdentifiedWarnings of xxv_ethernet_0 : entity is "yes";
end xxv_ethernet_0;

architecture stub of xxv_ethernet_0 is
  attribute syn_black_box : boolean;
  attribute black_box_pad_pin : string;
  attribute syn_black_box of stub : architecture is true;
  attribute black_box_pad_pin of stub : architecture is "rx_mac_mii_d_0[31:0],rx_mac_mii_c_0[3:0],rx_mac_mii_clk_0,rx_mac_mii_reset_0,tx_mac_mii_d_0[31:0],tx_mac_mii_c_0[3:0],tx_mac_mii_clk_0,tx_mac_mii_reset_0,tx_mac_mii_clk90_out_0,tx_mac_mii_clk0_out_0,mii_mac_tx_clk_0,rx_reset_0,rx_axis_tvalid_0,rx_axis_tdata_0[63:0],rx_axis_tlast_0,rx_axis_tkeep_0[7:0],rx_axis_tuser_0,rx_preambleout_0[55:0],ctl_rx_enable_0,ctl_rx_delete_fcs_0,ctl_rx_ignore_fcs_0,ctl_rx_max_packet_len_0[14:0],ctl_rx_min_packet_len_0[7:0],ctl_rx_custom_preamble_enable_0,ctl_rx_check_sfd_0,ctl_rx_check_preamble_0,ctl_rx_process_lfi_0,stat_rx_bad_code_0,stat_rx_total_packets_0[1:0],stat_rx_total_good_packets_0,stat_rx_total_bytes_0[3:0],stat_rx_total_good_bytes_0[13:0],stat_rx_packet_small_0,stat_rx_jabber_0,stat_rx_packet_large_0,stat_rx_oversize_0,stat_rx_undersize_0,stat_rx_toolong_0,stat_rx_fragment_0,stat_rx_packet_64_bytes_0,stat_rx_packet_65_127_bytes_0,stat_rx_packet_128_255_bytes_0,stat_rx_packet_256_511_bytes_0,stat_rx_packet_512_1023_bytes_0,stat_rx_packet_1024_1518_bytes_0,stat_rx_packet_1519_1522_bytes_0,stat_rx_packet_1523_1548_bytes_0,stat_rx_bad_fcs_0[1:0],stat_rx_packet_bad_fcs_0,stat_rx_stomped_fcs_0[1:0],stat_rx_packet_1549_2047_bytes_0,stat_rx_packet_2048_4095_bytes_0,stat_rx_packet_4096_8191_bytes_0,stat_rx_packet_8192_9215_bytes_0,stat_rx_bad_preamble_0,stat_rx_bad_sfd_0,stat_rx_got_signal_os_0,stat_rx_truncated_0,stat_rx_local_fault_0,stat_rx_remote_fault_0,tx_reset_0,tx_axis_tready_0,tx_axis_tvalid_0,tx_axis_tdata_0[63:0],tx_axis_tlast_0,tx_axis_tkeep_0[7:0],tx_axis_tuser_0,tx_preamblein_0[55:0],ctl_tx_enable_0,ctl_tx_fcs_ins_enable_0,ctl_tx_ipg_value_0[3:0],ctl_tx_send_lfi_0,ctl_tx_send_rfi_0,ctl_tx_send_idle_0,ctl_tx_custom_preamble_enable_0,ctl_tx_ignore_fcs_0,stat_tx_total_packets_0,stat_tx_total_bytes_0[3:0],stat_tx_total_good_packets_0,stat_tx_total_good_bytes_0[13:0],stat_tx_packet_64_bytes_0,stat_tx_packet_65_127_bytes_0,stat_tx_packet_128_255_bytes_0,stat_tx_packet_256_511_bytes_0,stat_tx_packet_512_1023_bytes_0,stat_tx_packet_1024_1518_bytes_0,stat_tx_packet_1519_1522_bytes_0,stat_tx_packet_1523_1548_bytes_0,stat_tx_packet_small_0,stat_tx_packet_large_0,stat_tx_packet_1549_2047_bytes_0,stat_tx_packet_2048_4095_bytes_0,stat_tx_packet_4096_8191_bytes_0,stat_tx_packet_8192_9215_bytes_0,stat_tx_bad_fcs_0,stat_tx_frame_error_0,stat_tx_local_fault_0,stat_tx_gmii_fifo_unf_0,stat_tx_gmii_fifo_ovf_0,tx_core_clk_0,rx_core_clk_0";
begin
end;
