// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2026.1 (win64) Build 6511674 Tue Jun 16 11:02:23 MDT 2026
// Date        : Sun Oct 25 22:26:29 2026
// Host        : DESKTOP-MB4FOM3 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               c:/Users/lskje/Desktop/FPGA_Orderbook/OrderBook/OrderBook.gen/sources_1/bd/top/ip/top_fan_pwm_0_0/top_fan_pwm_0_0_stub.v
// Design      : top_fan_pwm_0_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7vx690tffg1157-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* CHECK_LICENSE_TYPE = "top_fan_pwm_0_0,fan_pwm,{}" *) (* core_generation_info = "top_fan_pwm_0_0,fan_pwm,{x_ipProduct=Vivado 2026.1,x_ipVendor=xilinx.com,x_ipLibrary=module_ref,x_ipName=fan_pwm,x_ipVersion=1.0,x_ipCoreRevision=1,x_ipLanguage=VHDL,x_ipSimLanguage=VHDL,G_CLK_HZ=25000000,G_PWM_HZ=25000,G_DUTY_PCT=100,G_MIN_DUTY_PCT=30,G_ACTIVE_HIGH=true}" *) (* downgradeipidentifiedwarnings = "yes" *) 
(* ip_definition_source = "module_ref" *) (* x_core_info = "fan_pwm,Vivado 2026.1" *) 
module top_fan_pwm_0_0(clk, fan)
/* synthesis syn_black_box black_box_pad_pin="clk,fan" */;
  (* x_interface_info = "xilinx.com:signal:clock:1.0 clk CLK" *) (* x_interface_mode = "slave clk" *) (* x_interface_parameter = "XIL_INTERFACENAME clk, FREQ_HZ 25000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN top_clk25in, INSERT_VIP 0" *) input clk;
  output fan;
endmodule
