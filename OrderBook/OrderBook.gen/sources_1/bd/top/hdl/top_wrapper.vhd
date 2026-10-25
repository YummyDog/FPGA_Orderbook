--Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
--Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2026.1 (win64) Build 6511674 Tue Jun 16 11:02:23 MDT 2026
--Date        : Sun Oct 25 23:21:49 2026
--Host        : DESKTOP-MB4FOM3 running 64-bit major release  (build 9200)
--Command     : generate_target top_wrapper.bd
--Design      : top_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity top_wrapper is
  port (
    clk25in : in STD_LOGIC;
    fan : out STD_LOGIC;
    gt_refclk_clk_n : in STD_LOGIC;
    gt_refclk_clk_p : in STD_LOGIC;
    sfp_rxn : in STD_LOGIC;
    sfp_rxp : in STD_LOGIC;
    sfp_txn : out STD_LOGIC;
    sfp_txp : out STD_LOGIC
  );
end top_wrapper;

architecture STRUCTURE of top_wrapper is
  component top is
  port (
    gt_refclk_clk_n : in STD_LOGIC;
    gt_refclk_clk_p : in STD_LOGIC;
    sfp_rxp : in STD_LOGIC;
    sfp_rxn : in STD_LOGIC;
    sfp_txp : out STD_LOGIC;
    sfp_txn : out STD_LOGIC;
    clk25in : in STD_LOGIC;
    fan : out STD_LOGIC
  );
  end component top;
begin
top_i: component top
     port map (
      clk25in => clk25in,
      fan => fan,
      gt_refclk_clk_n => gt_refclk_clk_n,
      gt_refclk_clk_p => gt_refclk_clk_p,
      sfp_rxn => sfp_rxn,
      sfp_rxp => sfp_rxp,
      sfp_txn => sfp_txn,
      sfp_txp => sfp_txp
    );
end STRUCTURE;
