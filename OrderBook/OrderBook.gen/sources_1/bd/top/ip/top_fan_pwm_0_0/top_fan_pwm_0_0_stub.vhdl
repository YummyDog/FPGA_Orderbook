-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2026.1 (win64) Build 6511674 Tue Jun 16 11:02:23 MDT 2026
-- Date        : Sun Oct 25 22:26:29 2026
-- Host        : DESKTOP-MB4FOM3 running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               c:/Users/lskje/Desktop/FPGA_Orderbook/OrderBook/OrderBook.gen/sources_1/bd/top/ip/top_fan_pwm_0_0/top_fan_pwm_0_0_stub.vhdl
-- Design      : top_fan_pwm_0_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7vx690tffg1157-2
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top_fan_pwm_0_0 is
  Port ( 
    clk : in STD_LOGIC;
    fan : out STD_LOGIC
  );

  attribute CHECK_LICENSE_TYPE : string;
  attribute CHECK_LICENSE_TYPE of top_fan_pwm_0_0 : entity is "top_fan_pwm_0_0,fan_pwm,{}";
  attribute core_generation_info : string;
  attribute core_generation_info of top_fan_pwm_0_0 : entity is "top_fan_pwm_0_0,fan_pwm,{x_ipProduct=Vivado 2026.1,x_ipVendor=xilinx.com,x_ipLibrary=module_ref,x_ipName=fan_pwm,x_ipVersion=1.0,x_ipCoreRevision=1,x_ipLanguage=VHDL,x_ipSimLanguage=VHDL,G_CLK_HZ=25000000,G_PWM_HZ=25000,G_DUTY_PCT=100,G_MIN_DUTY_PCT=30,G_ACTIVE_HIGH=true}";
  attribute downgradeipidentifiedwarnings : string;
  attribute downgradeipidentifiedwarnings of top_fan_pwm_0_0 : entity is "yes";
  attribute ip_definition_source : string;
  attribute ip_definition_source of top_fan_pwm_0_0 : entity is "module_ref";
end top_fan_pwm_0_0;

architecture stub of top_fan_pwm_0_0 is
  attribute syn_black_box : boolean;
  attribute black_box_pad_pin : string;
  attribute syn_black_box of stub : architecture is true;
  attribute black_box_pad_pin of stub : architecture is "clk,fan";
  attribute x_interface_info : string;
  attribute x_interface_info of clk : signal is "xilinx.com:signal:clock:1.0 clk CLK";
  attribute x_interface_mode : string;
  attribute x_interface_mode of clk : signal is "slave clk";
  attribute x_interface_parameter : string;
  attribute x_interface_parameter of clk : signal is "XIL_INTERFACENAME clk, FREQ_HZ 25000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN top_clk25in, INSERT_VIP 0";
  attribute x_core_info : string;
  attribute x_core_info of stub : architecture is "fan_pwm,Vivado 2026.1";
begin
end;
