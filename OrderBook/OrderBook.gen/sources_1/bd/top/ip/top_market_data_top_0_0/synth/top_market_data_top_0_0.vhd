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

-- IP VLNV: xilinx.com:module_ref:market_data_top:1.0
-- IP Revision: 1

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY top_market_data_top_0_0 IS
  PORT (
    clk : IN STD_LOGIC;
    resetn : IN STD_LOGIC;
    xgmii_rxd : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    xgmii_rxc : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    xgmii_txd : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    xgmii_txc : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    m_axis_tdata : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    m_axis_tkeep : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    m_axis_tvalid : OUT STD_LOGIC;
    m_axis_tready : IN STD_LOGIC;
    m_axis_tlast : OUT STD_LOGIC;
    m_axis_tuser : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    base_price : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    test_number : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
    m_tvalid : OUT STD_LOGIC;
    m_tready : IN STD_LOGIC;
    m_bid_price : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_bid_qty : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_ask_price : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_ask_qty : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_valid : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    exchange_seconds : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    pkt_done : OUT STD_LOGIC;
    pkt_msg_count : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    msg_status : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    book_busy : OUT STD_LOGIC;
    level_busy : OUT STD_LOGIC;
    oor : OUT STD_LOGIC;
    fifo_full : OUT STD_LOGIC;
    fifo_overflow : OUT STD_LOGIC;
    stat_bad_side : OUT STD_LOGIC;
    stat_qty_ovf : OUT STD_LOGIC;
    axis_overflow : OUT STD_LOGIC;
    fcs_pair_err : OUT STD_LOGIC;
    fcs_flags : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
  );
END top_market_data_top_0_0;

ARCHITECTURE top_market_data_top_0_0_arch OF top_market_data_top_0_0 IS
  ATTRIBUTE DowngradeIPIdentifiedWarnings : STRING;
  ATTRIBUTE DowngradeIPIdentifiedWarnings OF top_market_data_top_0_0_arch: ARCHITECTURE IS "yes";
  COMPONENT market_data_top IS
    GENERIC (
      G_TPID : STD_LOGIC_VECTOR(15 DOWNTO 0);
      G_ORDER_BOOK_ID : INTEGER;
      G_FIFO_DEPTH : INTEGER;
      G_MAX_ORDERS : INTEGER;
      G_CHECK_PREAMBLE : BOOLEAN;
      G_TX_IPG_WORDS : INTEGER
    );
    PORT (
      clk : IN STD_LOGIC;
      resetn : IN STD_LOGIC;
      xgmii_rxd : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
      xgmii_rxc : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      xgmii_txd : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
      xgmii_txc : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      m_axis_tdata : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
      m_axis_tkeep : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      m_axis_tvalid : OUT STD_LOGIC;
      m_axis_tready : IN STD_LOGIC;
      m_axis_tlast : OUT STD_LOGIC;
      m_axis_tuser : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      base_price : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      test_number : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
      m_tvalid : OUT STD_LOGIC;
      m_tready : IN STD_LOGIC;
      m_bid_price : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      m_bid_qty : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      m_ask_price : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      m_ask_qty : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      m_valid : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      exchange_seconds : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      pkt_done : OUT STD_LOGIC;
      pkt_msg_count : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
      msg_status : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
      book_busy : OUT STD_LOGIC;
      level_busy : OUT STD_LOGIC;
      oor : OUT STD_LOGIC;
      fifo_full : OUT STD_LOGIC;
      fifo_overflow : OUT STD_LOGIC;
      stat_bad_side : OUT STD_LOGIC;
      stat_qty_ovf : OUT STD_LOGIC;
      axis_overflow : OUT STD_LOGIC;
      fcs_pair_err : OUT STD_LOGIC;
      fcs_flags : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
    );
  END COMPONENT market_data_top;
  ATTRIBUTE X_CORE_INFO : STRING;
  ATTRIBUTE X_CORE_INFO OF top_market_data_top_0_0_arch: ARCHITECTURE IS "market_data_top,Vivado 2026.1";
  ATTRIBUTE CHECK_LICENSE_TYPE : STRING;
  ATTRIBUTE CHECK_LICENSE_TYPE OF top_market_data_top_0_0_arch : ARCHITECTURE IS "top_market_data_top_0_0,market_data_top,{}";
  ATTRIBUTE CORE_GENERATION_INFO : STRING;
  ATTRIBUTE CORE_GENERATION_INFO OF top_market_data_top_0_0_arch: ARCHITECTURE IS "top_market_data_top_0_0,market_data_top,{x_ipProduct=Vivado 2026.1,x_ipVendor=xilinx.com,x_ipLibrary=module_ref,x_ipName=market_data_top,x_ipVersion=1.0,x_ipCoreRevision=1,x_ipLanguage=VHDL,x_ipSimLanguage=VHDL,G_TPID=0x8100,G_ORDER_BOOK_ID=85603,G_FIFO_DEPTH=16,G_MAX_ORDERS=16384,G_CHECK_PREAMBLE=true,G_TX_IPG_WORDS=2}";
  ATTRIBUTE IP_DEFINITION_SOURCE : STRING;
  ATTRIBUTE IP_DEFINITION_SOURCE OF top_market_data_top_0_0_arch: ARCHITECTURE IS "module_ref";
  ATTRIBUTE X_INTERFACE_INFO : STRING;
  ATTRIBUTE X_INTERFACE_MODE : STRING;
  ATTRIBUTE X_INTERFACE_PARAMETER : STRING;
  ATTRIBUTE X_INTERFACE_INFO OF clk: SIGNAL IS "xilinx.com:signal:clock:1.0 clk CLK";
  ATTRIBUTE X_INTERFACE_MODE OF clk: SIGNAL IS "slave clk";
  ATTRIBUTE X_INTERFACE_PARAMETER OF clk: SIGNAL IS "XIL_INTERFACENAME clk, ASSOCIATED_BUSIF m:m_axis, ASSOCIATED_RESET resetn, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, INSERT_VIP 0";
  ATTRIBUTE X_INTERFACE_INFO OF m_axis_tdata: SIGNAL IS "xilinx.com:interface:axis:1.0 m_axis TDATA";
  ATTRIBUTE X_INTERFACE_MODE OF m_axis_tdata: SIGNAL IS "master m_axis";
  ATTRIBUTE X_INTERFACE_PARAMETER OF m_axis_tdata: SIGNAL IS "XIL_INTERFACENAME m_axis, TDATA_NUM_BYTES 8, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 1, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 1, HAS_TLAST 1, FREQ_HZ 100000000, PHASE 0.0, LAYERED_METADATA undef, INSERT_VIP 0";
  ATTRIBUTE X_INTERFACE_INFO OF m_axis_tkeep: SIGNAL IS "xilinx.com:interface:axis:1.0 m_axis TKEEP";
  ATTRIBUTE X_INTERFACE_INFO OF m_axis_tlast: SIGNAL IS "xilinx.com:interface:axis:1.0 m_axis TLAST";
  ATTRIBUTE X_INTERFACE_INFO OF m_axis_tready: SIGNAL IS "xilinx.com:interface:axis:1.0 m_axis TREADY";
  ATTRIBUTE X_INTERFACE_INFO OF m_axis_tuser: SIGNAL IS "xilinx.com:interface:axis:1.0 m_axis TUSER";
  ATTRIBUTE X_INTERFACE_INFO OF m_axis_tvalid: SIGNAL IS "xilinx.com:interface:axis:1.0 m_axis TVALID";
  ATTRIBUTE X_INTERFACE_INFO OF m_tready: SIGNAL IS "xilinx.com:interface:axis:1.0 m TREADY";
  ATTRIBUTE X_INTERFACE_INFO OF m_tvalid: SIGNAL IS "xilinx.com:interface:axis:1.0 m TVALID";
  ATTRIBUTE X_INTERFACE_MODE OF m_tvalid: SIGNAL IS "master m";
  ATTRIBUTE X_INTERFACE_PARAMETER OF m_tvalid: SIGNAL IS "XIL_INTERFACENAME m, TDATA_NUM_BYTES 0, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 100000000, PHASE 0.0, LAYERED_METADATA undef, INSERT_VIP 0";
  ATTRIBUTE X_INTERFACE_INFO OF resetn: SIGNAL IS "xilinx.com:signal:reset:1.0 resetn RST";
  ATTRIBUTE X_INTERFACE_MODE OF resetn: SIGNAL IS "slave resetn";
  ATTRIBUTE X_INTERFACE_PARAMETER OF resetn: SIGNAL IS "XIL_INTERFACENAME resetn, POLARITY ACTIVE_LOW, INSERT_VIP 0";
BEGIN
  U0 : market_data_top
    GENERIC MAP (
      G_TPID => X"8100",
      G_ORDER_BOOK_ID => 85603,
      G_FIFO_DEPTH => 16,
      G_MAX_ORDERS => 16384,
      G_CHECK_PREAMBLE => true,
      G_TX_IPG_WORDS => 2
    )
    PORT MAP (
      clk => clk,
      resetn => resetn,
      xgmii_rxd => xgmii_rxd,
      xgmii_rxc => xgmii_rxc,
      xgmii_txd => xgmii_txd,
      xgmii_txc => xgmii_txc,
      m_axis_tdata => m_axis_tdata,
      m_axis_tkeep => m_axis_tkeep,
      m_axis_tvalid => m_axis_tvalid,
      m_axis_tready => m_axis_tready,
      m_axis_tlast => m_axis_tlast,
      m_axis_tuser => m_axis_tuser,
      base_price => base_price,
      test_number => test_number,
      m_tvalid => m_tvalid,
      m_tready => m_tready,
      m_bid_price => m_bid_price,
      m_bid_qty => m_bid_qty,
      m_ask_price => m_ask_price,
      m_ask_qty => m_ask_qty,
      m_valid => m_valid,
      exchange_seconds => exchange_seconds,
      pkt_done => pkt_done,
      pkt_msg_count => pkt_msg_count,
      msg_status => msg_status,
      book_busy => book_busy,
      level_busy => level_busy,
      oor => oor,
      fifo_full => fifo_full,
      fifo_overflow => fifo_overflow,
      stat_bad_side => stat_bad_side,
      stat_qty_ovf => stat_qty_ovf,
      axis_overflow => axis_overflow,
      fcs_pair_err => fcs_pair_err,
      fcs_flags => fcs_flags
    );
END top_market_data_top_0_0_arch;
