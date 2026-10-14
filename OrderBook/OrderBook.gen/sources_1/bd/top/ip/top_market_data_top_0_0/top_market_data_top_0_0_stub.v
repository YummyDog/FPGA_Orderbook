// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2026.1 (win64) Build 6511674 Tue Jun 16 11:02:23 MDT 2026
// Date        : Wed Oct 14 22:55:45 2026
// Host        : DESKTOP-MB4FOM3 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               c:/Users/lskje/Desktop/FPGA_Orderbook/OrderBook/OrderBook.gen/sources_1/bd/top/ip/top_market_data_top_0_0/top_market_data_top_0_0_stub.v
// Design      : top_market_data_top_0_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7vx690tffg1157-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* CHECK_LICENSE_TYPE = "top_market_data_top_0_0,market_data_top,{}" *) (* core_generation_info = "top_market_data_top_0_0,market_data_top,{x_ipProduct=Vivado 2026.1,x_ipVendor=xilinx.com,x_ipLibrary=module_ref,x_ipName=market_data_top,x_ipVersion=1.0,x_ipCoreRevision=1,x_ipLanguage=VHDL,x_ipSimLanguage=VHDL,G_TPID=0x8100,G_ORDER_BOOK_ID=85603,G_FIFO_DEPTH=16,G_MAX_ORDERS=16384,G_CHECK_PREAMBLE=true,G_TX_IPG_WORDS=2}" *) (* downgradeipidentifiedwarnings = "yes" *) 
(* ip_definition_source = "module_ref" *) (* x_core_info = "market_data_top,Vivado 2026.1" *) 
module top_market_data_top_0_0(clk, resetn, xgmii_rxd, xgmii_rxc, xgmii_txd, 
  xgmii_txc, m_axis_tdata, m_axis_tkeep, m_axis_tvalid, m_axis_tready, m_axis_tlast, 
  m_axis_tuser, base_price, test_number, m_tvalid, m_tready, m_bid_price, m_bid_qty, m_ask_price, 
  m_ask_qty, m_valid, exchange_seconds, pkt_done, pkt_msg_count, msg_status, book_busy, 
  level_busy, oor, fifo_full, fifo_overflow, stat_bad_side, stat_qty_ovf, axis_overflow, 
  fcs_pair_err, fcs_flags)
/* synthesis syn_black_box black_box_pad_pin="resetn,xgmii_rxd[63:0],xgmii_rxc[7:0],xgmii_txd[63:0],xgmii_txc[7:0],m_axis_tdata[63:0],m_axis_tkeep[7:0],m_axis_tvalid,m_axis_tready,m_axis_tlast,m_axis_tuser[0:0],base_price[31:0],test_number[4:0],m_tvalid,m_tready,m_bid_price[31:0],m_bid_qty[31:0],m_ask_price[31:0],m_ask_qty[31:0],m_valid[1:0],exchange_seconds[31:0],pkt_done,pkt_msg_count[15:0],msg_status[5:0],book_busy,level_busy,oor,fifo_full,fifo_overflow,stat_bad_side,stat_qty_ovf,axis_overflow,fcs_pair_err,fcs_flags[2:0]" */
/* synthesis syn_force_seq_prim="clk" */;
  (* x_interface_info = "xilinx.com:signal:clock:1.0 clk CLK" *) (* x_interface_mode = "slave clk" *) (* x_interface_parameter = "XIL_INTERFACENAME clk, ASSOCIATED_BUSIF m:m_axis, ASSOCIATED_RESET resetn, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, INSERT_VIP 0" *) input clk /* synthesis syn_isclock = 1 */;
  (* x_interface_info = "xilinx.com:signal:reset:1.0 resetn RST" *) (* x_interface_mode = "slave resetn" *) (* x_interface_parameter = "XIL_INTERFACENAME resetn, POLARITY ACTIVE_LOW, INSERT_VIP 0" *) input resetn;
  input [63:0]xgmii_rxd;
  input [7:0]xgmii_rxc;
  output [63:0]xgmii_txd;
  output [7:0]xgmii_txc;
  (* x_interface_info = "xilinx.com:interface:axis:1.0 m_axis TDATA" *) (* x_interface_mode = "master m_axis" *) (* x_interface_parameter = "XIL_INTERFACENAME m_axis, TDATA_NUM_BYTES 8, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 1, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 1, HAS_TLAST 1, FREQ_HZ 100000000, PHASE 0.0, LAYERED_METADATA undef, INSERT_VIP 0" *) output [63:0]m_axis_tdata;
  (* x_interface_info = "xilinx.com:interface:axis:1.0 m_axis TKEEP" *) output [7:0]m_axis_tkeep;
  (* x_interface_info = "xilinx.com:interface:axis:1.0 m_axis TVALID" *) output m_axis_tvalid;
  (* x_interface_info = "xilinx.com:interface:axis:1.0 m_axis TREADY" *) input m_axis_tready;
  (* x_interface_info = "xilinx.com:interface:axis:1.0 m_axis TLAST" *) output m_axis_tlast;
  (* x_interface_info = "xilinx.com:interface:axis:1.0 m_axis TUSER" *) output [0:0]m_axis_tuser;
  input [31:0]base_price;
  input [4:0]test_number;
  (* x_interface_info = "xilinx.com:interface:axis:1.0 m TVALID" *) (* x_interface_mode = "master m" *) (* x_interface_parameter = "XIL_INTERFACENAME m, TDATA_NUM_BYTES 0, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 100000000, PHASE 0.0, LAYERED_METADATA undef, INSERT_VIP 0" *) output m_tvalid;
  (* x_interface_info = "xilinx.com:interface:axis:1.0 m TREADY" *) input m_tready;
  output [31:0]m_bid_price;
  output [31:0]m_bid_qty;
  output [31:0]m_ask_price;
  output [31:0]m_ask_qty;
  output [1:0]m_valid;
  output [31:0]exchange_seconds;
  output pkt_done;
  output [15:0]pkt_msg_count;
  output [5:0]msg_status;
  output book_busy;
  output level_busy;
  output oor;
  output fifo_full;
  output fifo_overflow;
  output stat_bad_side;
  output stat_qty_ovf;
  output axis_overflow;
  output fcs_pair_err;
  output [2:0]fcs_flags;
endmodule
