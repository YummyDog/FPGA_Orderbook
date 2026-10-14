-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2026.1 (win64) Build 6511674 Tue Jun 16 11:02:23 MDT 2026
-- Date        : Wed Oct 14 22:55:47 2026
-- Host        : DESKTOP-MB4FOM3 running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               c:/Users/lskje/Desktop/FPGA_Orderbook/OrderBook/OrderBook.gen/sources_1/bd/top/ip/top_market_data_top_0_0/top_market_data_top_0_0_stub.vhdl
-- Design      : top_market_data_top_0_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7vx690tffg1157-2
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top_market_data_top_0_0 is
  Port ( 
    clk : in STD_LOGIC;
    resetn : in STD_LOGIC;
    xgmii_rxd : in STD_LOGIC_VECTOR ( 63 downto 0 );
    xgmii_rxc : in STD_LOGIC_VECTOR ( 7 downto 0 );
    xgmii_txd : out STD_LOGIC_VECTOR ( 63 downto 0 );
    xgmii_txc : out STD_LOGIC_VECTOR ( 7 downto 0 );
    m_axis_tdata : out STD_LOGIC_VECTOR ( 63 downto 0 );
    m_axis_tkeep : out STD_LOGIC_VECTOR ( 7 downto 0 );
    m_axis_tvalid : out STD_LOGIC;
    m_axis_tready : in STD_LOGIC;
    m_axis_tlast : out STD_LOGIC;
    m_axis_tuser : out STD_LOGIC_VECTOR ( 0 to 0 );
    base_price : in STD_LOGIC_VECTOR ( 31 downto 0 );
    test_number : in STD_LOGIC_VECTOR ( 4 downto 0 );
    m_tvalid : out STD_LOGIC;
    m_tready : in STD_LOGIC;
    m_bid_price : out STD_LOGIC_VECTOR ( 31 downto 0 );
    m_bid_qty : out STD_LOGIC_VECTOR ( 31 downto 0 );
    m_ask_price : out STD_LOGIC_VECTOR ( 31 downto 0 );
    m_ask_qty : out STD_LOGIC_VECTOR ( 31 downto 0 );
    m_valid : out STD_LOGIC_VECTOR ( 1 downto 0 );
    exchange_seconds : out STD_LOGIC_VECTOR ( 31 downto 0 );
    pkt_done : out STD_LOGIC;
    pkt_msg_count : out STD_LOGIC_VECTOR ( 15 downto 0 );
    msg_status : out STD_LOGIC_VECTOR ( 5 downto 0 );
    book_busy : out STD_LOGIC;
    level_busy : out STD_LOGIC;
    oor : out STD_LOGIC;
    fifo_full : out STD_LOGIC;
    fifo_overflow : out STD_LOGIC;
    stat_bad_side : out STD_LOGIC;
    stat_qty_ovf : out STD_LOGIC;
    axis_overflow : out STD_LOGIC;
    fcs_pair_err : out STD_LOGIC;
    fcs_flags : out STD_LOGIC_VECTOR ( 2 downto 0 )
  );

  attribute CHECK_LICENSE_TYPE : string;
  attribute CHECK_LICENSE_TYPE of top_market_data_top_0_0 : entity is "top_market_data_top_0_0,market_data_top,{}";
  attribute core_generation_info : string;
  attribute core_generation_info of top_market_data_top_0_0 : entity is "top_market_data_top_0_0,market_data_top,{x_ipProduct=Vivado 2026.1,x_ipVendor=xilinx.com,x_ipLibrary=module_ref,x_ipName=market_data_top,x_ipVersion=1.0,x_ipCoreRevision=1,x_ipLanguage=VHDL,x_ipSimLanguage=VHDL,G_TPID=0x8100,G_ORDER_BOOK_ID=85603,G_FIFO_DEPTH=16,G_MAX_ORDERS=16384,G_CHECK_PREAMBLE=true,G_TX_IPG_WORDS=2}";
  attribute downgradeipidentifiedwarnings : string;
  attribute downgradeipidentifiedwarnings of top_market_data_top_0_0 : entity is "yes";
  attribute ip_definition_source : string;
  attribute ip_definition_source of top_market_data_top_0_0 : entity is "module_ref";
end top_market_data_top_0_0;

architecture stub of top_market_data_top_0_0 is
  attribute syn_black_box : boolean;
  attribute black_box_pad_pin : string;
  attribute syn_black_box of stub : architecture is true;
  attribute black_box_pad_pin of stub : architecture is "clk,resetn,xgmii_rxd[63:0],xgmii_rxc[7:0],xgmii_txd[63:0],xgmii_txc[7:0],m_axis_tdata[63:0],m_axis_tkeep[7:0],m_axis_tvalid,m_axis_tready,m_axis_tlast,m_axis_tuser[0:0],base_price[31:0],test_number[4:0],m_tvalid,m_tready,m_bid_price[31:0],m_bid_qty[31:0],m_ask_price[31:0],m_ask_qty[31:0],m_valid[1:0],exchange_seconds[31:0],pkt_done,pkt_msg_count[15:0],msg_status[5:0],book_busy,level_busy,oor,fifo_full,fifo_overflow,stat_bad_side,stat_qty_ovf,axis_overflow,fcs_pair_err,fcs_flags[2:0]";
  attribute x_interface_info : string;
  attribute x_interface_info of clk : signal is "xilinx.com:signal:clock:1.0 clk CLK";
  attribute x_interface_mode : string;
  attribute x_interface_mode of clk : signal is "slave clk";
  attribute x_interface_parameter : string;
  attribute x_interface_parameter of clk : signal is "XIL_INTERFACENAME clk, ASSOCIATED_BUSIF m:m_axis, ASSOCIATED_RESET resetn, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, INSERT_VIP 0";
  attribute x_interface_info of resetn : signal is "xilinx.com:signal:reset:1.0 resetn RST";
  attribute x_interface_mode of resetn : signal is "slave resetn";
  attribute x_interface_parameter of resetn : signal is "XIL_INTERFACENAME resetn, POLARITY ACTIVE_LOW, INSERT_VIP 0";
  attribute x_interface_info of m_axis_tdata : signal is "xilinx.com:interface:axis:1.0 m_axis TDATA";
  attribute x_interface_mode of m_axis_tdata : signal is "master m_axis";
  attribute x_interface_parameter of m_axis_tdata : signal is "XIL_INTERFACENAME m_axis, TDATA_NUM_BYTES 8, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 1, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 1, HAS_TLAST 1, FREQ_HZ 100000000, PHASE 0.0, LAYERED_METADATA undef, INSERT_VIP 0";
  attribute x_interface_info of m_axis_tkeep : signal is "xilinx.com:interface:axis:1.0 m_axis TKEEP";
  attribute x_interface_info of m_axis_tvalid : signal is "xilinx.com:interface:axis:1.0 m_axis TVALID";
  attribute x_interface_info of m_axis_tready : signal is "xilinx.com:interface:axis:1.0 m_axis TREADY";
  attribute x_interface_info of m_axis_tlast : signal is "xilinx.com:interface:axis:1.0 m_axis TLAST";
  attribute x_interface_info of m_axis_tuser : signal is "xilinx.com:interface:axis:1.0 m_axis TUSER";
  attribute x_interface_info of m_tvalid : signal is "xilinx.com:interface:axis:1.0 m TVALID";
  attribute x_interface_mode of m_tvalid : signal is "master m";
  attribute x_interface_parameter of m_tvalid : signal is "XIL_INTERFACENAME m, TDATA_NUM_BYTES 0, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 100000000, PHASE 0.0, LAYERED_METADATA undef, INSERT_VIP 0";
  attribute x_interface_info of m_tready : signal is "xilinx.com:interface:axis:1.0 m TREADY";
  attribute x_core_info : string;
  attribute x_core_info of stub : architecture is "market_data_top,Vivado 2026.1";
begin
end;
