--Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
--Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2026.1 (win64) Build 6511674 Tue Jun 16 11:02:23 MDT 2026
--Date        : Sat Nov  7 00:34:22 2026
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
    QSFP_RESET : out STD_LOGIC_VECTOR ( 0 to 0 );
    SFP_OR_OPT : out STD_LOGIC_VECTOR ( 0 to 0 );
    clk25in : in STD_LOGIC;
    fan : out STD_LOGIC;
    gt_refclk_clk_n : in STD_LOGIC;
    gt_refclk_clk_p : in STD_LOGIC;
    sfp1_rxn : in STD_LOGIC;
    sfp1_rxp : in STD_LOGIC;
    sfp1_txn : out STD_LOGIC;
    sfp1_txp : out STD_LOGIC;
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
    fan : out STD_LOGIC;
    sfp1_txp : out STD_LOGIC;
    sfp1_txn : out STD_LOGIC;
    sfp1_rxp : in STD_LOGIC;
    sfp1_rxn : in STD_LOGIC;
    QSFP_RESET : out STD_LOGIC_VECTOR ( 0 to 0 );
    SFP_OR_OPT : out STD_LOGIC_VECTOR ( 0 to 0 )
  );
  end component top;
begin
top_i: component top
     port map (
      QSFP_RESET(0) => QSFP_RESET(0),
      SFP_OR_OPT(0) => SFP_OR_OPT(0),
      clk25in => clk25in,
      fan => fan,
      gt_refclk_clk_n => gt_refclk_clk_n,
      gt_refclk_clk_p => gt_refclk_clk_p,
      sfp1_rxn => sfp1_rxn,
      sfp1_rxp => sfp1_rxp,
      sfp1_txn => sfp1_txn,
      sfp1_txp => sfp1_txp,
      sfp_rxn => sfp_rxn,
      sfp_rxp => sfp_rxp,
      sfp_txn => sfp_txn,
      sfp_txp => sfp_txp
    );
end STRUCTURE;
