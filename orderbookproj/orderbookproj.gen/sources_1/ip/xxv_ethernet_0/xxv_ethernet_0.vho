-- (c) Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- (c) Copyright 2022-2026 Advanced Micro Devices, Inc. All rights reserved.
-- 
-- This file contains confidential and proprietary information
-- of AMD and is protected under U.S. and international copyright
-- and other intellectual property laws.
-- 
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- AMD, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) AMD shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or AMD had been advised of the
-- possibility of the same.
-- 
-- CRITICAL APPLICATIONS
-- AMD products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of AMD products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
-- 
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
-- 
-- DO NOT MODIFY THIS FILE.
-- IP VLNV: xilinx.com:ip:xxv_ethernet:5.0
-- IP Revision: 2

-- The following code must appear in the VHDL architecture header.

------------- Begin Cut here for COMPONENT Declaration ------ COMP_TAG
COMPONENT xxv_ethernet_0
  PORT (
    rx_core_clk_0 : IN STD_LOGIC;
    tx_core_clk_0 : IN STD_LOGIC;
    rx_mac_mii_clk_0 : IN STD_LOGIC;
    tx_mac_mii_clk_0 : IN STD_LOGIC;
    mii_mac_tx_clk_0 : OUT STD_LOGIC;
    tx_mac_mii_clk90_out_0 : OUT STD_LOGIC;
    tx_mac_mii_clk0_out_0 : OUT STD_LOGIC;
    rx_reset_0 : IN STD_LOGIC;
    rx_mac_mii_reset_0 : IN STD_LOGIC;
    tx_mac_mii_reset_0 : IN STD_LOGIC;
    rx_mac_mii_d_0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    rx_mac_mii_c_0 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    rx_axis_tvalid_0 : OUT STD_LOGIC;
    rx_axis_tdata_0 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    rx_axis_tlast_0 : OUT STD_LOGIC;
    rx_axis_tkeep_0 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    rx_axis_tuser_0 : OUT STD_LOGIC;
    ctl_rx_enable_0 : IN STD_LOGIC;
    ctl_rx_check_preamble_0 : IN STD_LOGIC;
    ctl_rx_check_sfd_0 : IN STD_LOGIC;
    ctl_rx_delete_fcs_0 : IN STD_LOGIC;
    ctl_rx_ignore_fcs_0 : IN STD_LOGIC;
    ctl_rx_max_packet_len_0 : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
    ctl_rx_min_packet_len_0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    ctl_rx_process_lfi_0 : IN STD_LOGIC;
    ctl_rx_custom_preamble_enable_0 : IN STD_LOGIC;
    stat_rx_local_fault_0 : OUT STD_LOGIC;
    stat_rx_remote_fault_0 : OUT STD_LOGIC;
    stat_rx_bad_fcs_0 : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    stat_rx_stomped_fcs_0 : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    stat_rx_truncated_0 : OUT STD_LOGIC;
    stat_rx_got_signal_os_0 : OUT STD_LOGIC;
    stat_rx_total_bytes_0 : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    stat_rx_total_packets_0 : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    stat_rx_total_good_bytes_0 : OUT STD_LOGIC_VECTOR(13 DOWNTO 0);
    stat_rx_total_good_packets_0 : OUT STD_LOGIC;
    stat_rx_packet_bad_fcs_0 : OUT STD_LOGIC;
    stat_rx_packet_64_bytes_0 : OUT STD_LOGIC;
    stat_rx_packet_65_127_bytes_0 : OUT STD_LOGIC;
    stat_rx_packet_128_255_bytes_0 : OUT STD_LOGIC;
    stat_rx_packet_256_511_bytes_0 : OUT STD_LOGIC;
    stat_rx_packet_512_1023_bytes_0 : OUT STD_LOGIC;
    stat_rx_packet_1024_1518_bytes_0 : OUT STD_LOGIC;
    stat_rx_packet_1519_1522_bytes_0 : OUT STD_LOGIC;
    stat_rx_packet_1523_1548_bytes_0 : OUT STD_LOGIC;
    stat_rx_packet_1549_2047_bytes_0 : OUT STD_LOGIC;
    stat_rx_packet_2048_4095_bytes_0 : OUT STD_LOGIC;
    stat_rx_packet_4096_8191_bytes_0 : OUT STD_LOGIC;
    stat_rx_packet_8192_9215_bytes_0 : OUT STD_LOGIC;
    stat_rx_packet_small_0 : OUT STD_LOGIC;
    stat_rx_packet_large_0 : OUT STD_LOGIC;
    stat_rx_oversize_0 : OUT STD_LOGIC;
    stat_rx_toolong_0 : OUT STD_LOGIC;
    stat_rx_undersize_0 : OUT STD_LOGIC;
    stat_rx_fragment_0 : OUT STD_LOGIC;
    stat_rx_jabber_0 : OUT STD_LOGIC;
    stat_rx_bad_code_0 : OUT STD_LOGIC;
    stat_rx_bad_sfd_0 : OUT STD_LOGIC;
    stat_rx_bad_preamble_0 : OUT STD_LOGIC;
    tx_reset_0 : IN STD_LOGIC;
    tx_mac_mii_d_0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    tx_mac_mii_c_0 : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    tx_axis_tready_0 : OUT STD_LOGIC;
    tx_axis_tvalid_0 : IN STD_LOGIC;
    tx_axis_tdata_0 : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    tx_axis_tlast_0 : IN STD_LOGIC;
    tx_axis_tkeep_0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    tx_axis_tuser_0 : IN STD_LOGIC;
    tx_preamblein_0 : IN STD_LOGIC_VECTOR(55 DOWNTO 0);
    rx_preambleout_0 : OUT STD_LOGIC_VECTOR(55 DOWNTO 0);
    stat_tx_local_fault_0 : OUT STD_LOGIC;
    stat_tx_total_bytes_0 : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    stat_tx_total_packets_0 : OUT STD_LOGIC;
    stat_tx_total_good_bytes_0 : OUT STD_LOGIC_VECTOR(13 DOWNTO 0);
    stat_tx_total_good_packets_0 : OUT STD_LOGIC;
    stat_tx_bad_fcs_0 : OUT STD_LOGIC;
    stat_tx_packet_64_bytes_0 : OUT STD_LOGIC;
    stat_tx_packet_65_127_bytes_0 : OUT STD_LOGIC;
    stat_tx_packet_128_255_bytes_0 : OUT STD_LOGIC;
    stat_tx_packet_256_511_bytes_0 : OUT STD_LOGIC;
    stat_tx_packet_512_1023_bytes_0 : OUT STD_LOGIC;
    stat_tx_packet_1024_1518_bytes_0 : OUT STD_LOGIC;
    stat_tx_packet_1519_1522_bytes_0 : OUT STD_LOGIC;
    stat_tx_packet_1523_1548_bytes_0 : OUT STD_LOGIC;
    stat_tx_packet_1549_2047_bytes_0 : OUT STD_LOGIC;
    stat_tx_packet_2048_4095_bytes_0 : OUT STD_LOGIC;
    stat_tx_packet_4096_8191_bytes_0 : OUT STD_LOGIC;
    stat_tx_packet_8192_9215_bytes_0 : OUT STD_LOGIC;
    stat_tx_packet_small_0 : OUT STD_LOGIC;
    stat_tx_packet_large_0 : OUT STD_LOGIC;
    stat_tx_frame_error_0 : OUT STD_LOGIC;
    ctl_tx_enable_0 : IN STD_LOGIC;
    ctl_tx_send_rfi_0 : IN STD_LOGIC;
    ctl_tx_send_lfi_0 : IN STD_LOGIC;
    ctl_tx_send_idle_0 : IN STD_LOGIC;
    ctl_tx_fcs_ins_enable_0 : IN STD_LOGIC;
    ctl_tx_ignore_fcs_0 : IN STD_LOGIC;
    ctl_tx_ipg_value_0 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    ctl_tx_custom_preamble_enable_0 : IN STD_LOGIC;
    stat_tx_gmii_fifo_unf_0 : OUT STD_LOGIC;
    stat_tx_gmii_fifo_ovf_0 : OUT STD_LOGIC 
  );
END COMPONENT;
-- COMP_TAG_END ------ End COMPONENT Declaration ------------

-- The following code must appear in the VHDL architecture
-- body. Substitute your own instance name and net names.

------------- Begin Cut here for INSTANTIATION Template ----- INST_TAG
your_instance_name : xxv_ethernet_0
  PORT MAP (
    rx_core_clk_0 => rx_core_clk_0,
    tx_core_clk_0 => tx_core_clk_0,
    rx_mac_mii_clk_0 => rx_mac_mii_clk_0,
    tx_mac_mii_clk_0 => tx_mac_mii_clk_0,
    mii_mac_tx_clk_0 => mii_mac_tx_clk_0,
    tx_mac_mii_clk90_out_0 => tx_mac_mii_clk90_out_0,
    tx_mac_mii_clk0_out_0 => tx_mac_mii_clk0_out_0,
    rx_reset_0 => rx_reset_0,
    rx_mac_mii_reset_0 => rx_mac_mii_reset_0,
    tx_mac_mii_reset_0 => tx_mac_mii_reset_0,
    rx_mac_mii_d_0 => rx_mac_mii_d_0,
    rx_mac_mii_c_0 => rx_mac_mii_c_0,
    rx_axis_tvalid_0 => rx_axis_tvalid_0,
    rx_axis_tdata_0 => rx_axis_tdata_0,
    rx_axis_tlast_0 => rx_axis_tlast_0,
    rx_axis_tkeep_0 => rx_axis_tkeep_0,
    rx_axis_tuser_0 => rx_axis_tuser_0,
    ctl_rx_enable_0 => ctl_rx_enable_0,
    ctl_rx_check_preamble_0 => ctl_rx_check_preamble_0,
    ctl_rx_check_sfd_0 => ctl_rx_check_sfd_0,
    ctl_rx_delete_fcs_0 => ctl_rx_delete_fcs_0,
    ctl_rx_ignore_fcs_0 => ctl_rx_ignore_fcs_0,
    ctl_rx_max_packet_len_0 => ctl_rx_max_packet_len_0,
    ctl_rx_min_packet_len_0 => ctl_rx_min_packet_len_0,
    ctl_rx_process_lfi_0 => ctl_rx_process_lfi_0,
    ctl_rx_custom_preamble_enable_0 => ctl_rx_custom_preamble_enable_0,
    stat_rx_local_fault_0 => stat_rx_local_fault_0,
    stat_rx_remote_fault_0 => stat_rx_remote_fault_0,
    stat_rx_bad_fcs_0 => stat_rx_bad_fcs_0,
    stat_rx_stomped_fcs_0 => stat_rx_stomped_fcs_0,
    stat_rx_truncated_0 => stat_rx_truncated_0,
    stat_rx_got_signal_os_0 => stat_rx_got_signal_os_0,
    stat_rx_total_bytes_0 => stat_rx_total_bytes_0,
    stat_rx_total_packets_0 => stat_rx_total_packets_0,
    stat_rx_total_good_bytes_0 => stat_rx_total_good_bytes_0,
    stat_rx_total_good_packets_0 => stat_rx_total_good_packets_0,
    stat_rx_packet_bad_fcs_0 => stat_rx_packet_bad_fcs_0,
    stat_rx_packet_64_bytes_0 => stat_rx_packet_64_bytes_0,
    stat_rx_packet_65_127_bytes_0 => stat_rx_packet_65_127_bytes_0,
    stat_rx_packet_128_255_bytes_0 => stat_rx_packet_128_255_bytes_0,
    stat_rx_packet_256_511_bytes_0 => stat_rx_packet_256_511_bytes_0,
    stat_rx_packet_512_1023_bytes_0 => stat_rx_packet_512_1023_bytes_0,
    stat_rx_packet_1024_1518_bytes_0 => stat_rx_packet_1024_1518_bytes_0,
    stat_rx_packet_1519_1522_bytes_0 => stat_rx_packet_1519_1522_bytes_0,
    stat_rx_packet_1523_1548_bytes_0 => stat_rx_packet_1523_1548_bytes_0,
    stat_rx_packet_1549_2047_bytes_0 => stat_rx_packet_1549_2047_bytes_0,
    stat_rx_packet_2048_4095_bytes_0 => stat_rx_packet_2048_4095_bytes_0,
    stat_rx_packet_4096_8191_bytes_0 => stat_rx_packet_4096_8191_bytes_0,
    stat_rx_packet_8192_9215_bytes_0 => stat_rx_packet_8192_9215_bytes_0,
    stat_rx_packet_small_0 => stat_rx_packet_small_0,
    stat_rx_packet_large_0 => stat_rx_packet_large_0,
    stat_rx_oversize_0 => stat_rx_oversize_0,
    stat_rx_toolong_0 => stat_rx_toolong_0,
    stat_rx_undersize_0 => stat_rx_undersize_0,
    stat_rx_fragment_0 => stat_rx_fragment_0,
    stat_rx_jabber_0 => stat_rx_jabber_0,
    stat_rx_bad_code_0 => stat_rx_bad_code_0,
    stat_rx_bad_sfd_0 => stat_rx_bad_sfd_0,
    stat_rx_bad_preamble_0 => stat_rx_bad_preamble_0,
    tx_reset_0 => tx_reset_0,
    tx_mac_mii_d_0 => tx_mac_mii_d_0,
    tx_mac_mii_c_0 => tx_mac_mii_c_0,
    tx_axis_tready_0 => tx_axis_tready_0,
    tx_axis_tvalid_0 => tx_axis_tvalid_0,
    tx_axis_tdata_0 => tx_axis_tdata_0,
    tx_axis_tlast_0 => tx_axis_tlast_0,
    tx_axis_tkeep_0 => tx_axis_tkeep_0,
    tx_axis_tuser_0 => tx_axis_tuser_0,
    tx_preamblein_0 => tx_preamblein_0,
    rx_preambleout_0 => rx_preambleout_0,
    stat_tx_local_fault_0 => stat_tx_local_fault_0,
    stat_tx_total_bytes_0 => stat_tx_total_bytes_0,
    stat_tx_total_packets_0 => stat_tx_total_packets_0,
    stat_tx_total_good_bytes_0 => stat_tx_total_good_bytes_0,
    stat_tx_total_good_packets_0 => stat_tx_total_good_packets_0,
    stat_tx_bad_fcs_0 => stat_tx_bad_fcs_0,
    stat_tx_packet_64_bytes_0 => stat_tx_packet_64_bytes_0,
    stat_tx_packet_65_127_bytes_0 => stat_tx_packet_65_127_bytes_0,
    stat_tx_packet_128_255_bytes_0 => stat_tx_packet_128_255_bytes_0,
    stat_tx_packet_256_511_bytes_0 => stat_tx_packet_256_511_bytes_0,
    stat_tx_packet_512_1023_bytes_0 => stat_tx_packet_512_1023_bytes_0,
    stat_tx_packet_1024_1518_bytes_0 => stat_tx_packet_1024_1518_bytes_0,
    stat_tx_packet_1519_1522_bytes_0 => stat_tx_packet_1519_1522_bytes_0,
    stat_tx_packet_1523_1548_bytes_0 => stat_tx_packet_1523_1548_bytes_0,
    stat_tx_packet_1549_2047_bytes_0 => stat_tx_packet_1549_2047_bytes_0,
    stat_tx_packet_2048_4095_bytes_0 => stat_tx_packet_2048_4095_bytes_0,
    stat_tx_packet_4096_8191_bytes_0 => stat_tx_packet_4096_8191_bytes_0,
    stat_tx_packet_8192_9215_bytes_0 => stat_tx_packet_8192_9215_bytes_0,
    stat_tx_packet_small_0 => stat_tx_packet_small_0,
    stat_tx_packet_large_0 => stat_tx_packet_large_0,
    stat_tx_frame_error_0 => stat_tx_frame_error_0,
    ctl_tx_enable_0 => ctl_tx_enable_0,
    ctl_tx_send_rfi_0 => ctl_tx_send_rfi_0,
    ctl_tx_send_lfi_0 => ctl_tx_send_lfi_0,
    ctl_tx_send_idle_0 => ctl_tx_send_idle_0,
    ctl_tx_fcs_ins_enable_0 => ctl_tx_fcs_ins_enable_0,
    ctl_tx_ignore_fcs_0 => ctl_tx_ignore_fcs_0,
    ctl_tx_ipg_value_0 => ctl_tx_ipg_value_0,
    ctl_tx_custom_preamble_enable_0 => ctl_tx_custom_preamble_enable_0,
    stat_tx_gmii_fifo_unf_0 => stat_tx_gmii_fifo_unf_0,
    stat_tx_gmii_fifo_ovf_0 => stat_tx_gmii_fifo_ovf_0
  );
-- INST_TAG_END ------ End INSTANTIATION Template ---------

-- You must compile the wrapper file xxv_ethernet_0.vhd when simulating
-- the core, xxv_ethernet_0. When compiling the wrapper file, be sure to
-- reference the VHDL simulation library.



