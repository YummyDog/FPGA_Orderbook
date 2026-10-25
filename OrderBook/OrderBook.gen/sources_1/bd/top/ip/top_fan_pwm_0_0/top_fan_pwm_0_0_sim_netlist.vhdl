-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2026.1 (win64) Build 6511674 Tue Jun 16 11:02:23 MDT 2026
-- Date        : Sun Oct 25 22:26:29 2026
-- Host        : DESKTOP-MB4FOM3 running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode funcsim
--               c:/Users/lskje/Desktop/FPGA_Orderbook/OrderBook/OrderBook.gen/sources_1/bd/top/ip/top_fan_pwm_0_0/top_fan_pwm_0_0_sim_netlist.vhdl
-- Design      : top_fan_pwm_0_0
-- Purpose     : This VHDL netlist is a functional simulation representation of the design and should not be modified or
--               synthesized. This netlist cannot be used for SDF annotated simulation.
-- Device      : xc7vx690tffg1157-2
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity top_fan_pwm_0_0 is
  port (
    clk : in STD_LOGIC;
    fan : out STD_LOGIC
  );
  attribute NotValidForBitStream : boolean;
  attribute NotValidForBitStream of top_fan_pwm_0_0 : entity is true;
  attribute CHECK_LICENSE_TYPE : string;
  attribute CHECK_LICENSE_TYPE of top_fan_pwm_0_0 : entity is "top_fan_pwm_0_0,fan_pwm,{}";
  attribute downgradeipidentifiedwarnings : string;
  attribute downgradeipidentifiedwarnings of top_fan_pwm_0_0 : entity is "yes";
  attribute ip_definition_source : string;
  attribute ip_definition_source of top_fan_pwm_0_0 : entity is "module_ref";
  attribute x_core_info : string;
  attribute x_core_info of top_fan_pwm_0_0 : entity is "fan_pwm,Vivado 2026.1";
end top_fan_pwm_0_0;

architecture STRUCTURE of top_fan_pwm_0_0 is
  signal \<const1>\ : STD_LOGIC;
  attribute x_interface_info : string;
  attribute x_interface_info of clk : signal is "xilinx.com:signal:clock:1.0 clk CLK";
  attribute x_interface_mode : string;
  attribute x_interface_mode of clk : signal is "slave clk";
  attribute x_interface_parameter : string;
  attribute x_interface_parameter of clk : signal is "XIL_INTERFACENAME clk, FREQ_HZ 25000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN top_clk25in, INSERT_VIP 0";
begin
  fan <= \<const1>\;
VCC: unisim.vcomponents.VCC
     port map (
      P => \<const1>\
    );
end STRUCTURE;
