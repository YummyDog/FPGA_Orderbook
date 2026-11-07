-------------------------------------------------------------------------------
-- Title      : Core level wrapper
-- Project    : 10GBASE-R
-------------------------------------------------------------------------------
-- File       : top_ten_gig_eth_pcs_pma_1_0.vhd
-------------------------------------------------------------------------------
-- Description: This file is a wrapper for the 10GBASE-R core.
-------------------------------------------------------------------------------
-- (c) Copyright 2009 - 2014 Advanced Micro Devices, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Advanced Micro Devices, Inc. and is protected under U.S. and 
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Advanced Micro Devices, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Advanced Micro Devices shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Advanced Micro Devices had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Advanced Micro Devices products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Advanced Micro Devices products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

library ten_gig_eth_pcs_pma_v6_0_33;
use ten_gig_eth_pcs_pma_v6_0_33.all;

entity top_ten_gig_eth_pcs_pma_1_0 is
  port (
      dclk               : in  std_logic;
      rxrecclk_out       : out std_logic;
      coreclk             : in  std_logic;
      txusrclk           : in  std_logic;
      txusrclk2          : in  std_logic;
      txoutclk           : out std_logic;
      areset             : in  std_logic;
      areset_coreclk      : in  std_logic;
      gttxreset          : in  std_logic;
      gtrxreset          : in  std_logic;
      sim_speedup_control: in  std_logic := '0';
      txuserrdy          : in  std_logic;
      qplllock           : in  std_logic;
      qplloutclk         : in  std_logic;
      qplloutrefclk      : in  std_logic;
      reset_counter_done : in  std_logic;
      gt0_eyescanreset     : in  std_logic;
      gt0_eyescantrigger   : in  std_logic;
      gt0_rxcdrhold        : in  std_logic;
      gt0_txprbsforceerr   : in  std_logic;
      gt0_txpolarity       : in  std_logic;
      gt0_rxpolarity       : in  std_logic;
      gt0_rxrate           : in  std_logic_vector(2 downto 0);
      gt0_txpmareset       : in  std_logic;
      gt0_rxpmareset       : in  std_logic;
      gt0_rxdfelpmreset    : in  std_logic;
      gt0_txprecursor      : in  std_logic_vector(4 downto 0);
      gt0_txpostcursor     : in  std_logic_vector(4 downto 0);
      gt0_txdiffctrl       : in  std_logic_vector(3 downto 0);
      gt0_rxlpmen          : in  std_logic;
      gt0_eyescandataerror : out std_logic;
      gt0_txbufstatus      : out std_logic_vector(1 downto 0);
      gt0_txresetdone      : out std_logic;
      gt0_rxpmaresetdone   : out std_logic;
      gt0_rxresetdone      : out std_logic;
      gt0_rxbufstatus      : out std_logic_vector(2 downto 0);
      gt0_rxprbserr        : out std_logic;
      gt0_dmonitorout      : out std_logic_vector(14 downto 0);
      xgmii_txd        : in  std_logic_vector(63 downto 0);
      xgmii_txc        : in  std_logic_vector(7 downto 0);
      xgmii_rxd        : out std_logic_vector(63 downto 0);
      xgmii_rxc        : out std_logic_vector(7 downto 0);
      txp              : out std_logic;
      txn              : out std_logic;
      rxp              : in  std_logic;
      rxn              : in  std_logic;
      mdc              : in  std_logic;
      mdio_in          : in  std_logic;
      mdio_out         : out std_logic;
      mdio_tri         : out std_logic;
      prtad            : in  std_logic_vector(4 downto 0);
      core_status      : out std_logic_vector(7 downto 0);
      tx_resetdone     : out std_logic;
      rx_resetdone     : out std_logic;
      signal_detect    : in  std_logic;
      tx_fault         : in  std_logic;
      drp_req          : out std_logic;
      drp_gnt          : in  std_logic;
      drp_den_o        : out std_logic;
      drp_dwe_o        : out std_logic;
      drp_daddr_o      : out std_logic_vector(15 downto 0);
      drp_di_o         : out std_logic_vector(15 downto 0);
      drp_drdy_i       : in  std_logic;
      drp_drpdo_i      : in  std_logic_vector(15 downto 0);
      drp_den_i        : in  std_logic;
      drp_dwe_i        : in  std_logic;
      drp_daddr_i      : in  std_logic_vector(15 downto 0);
      drp_di_i         : in  std_logic_vector(15 downto 0);
      drp_drdy_o       : out std_logic;
      drp_drpdo_o      : out std_logic_vector(15 downto 0);
      pma_pmd_type     : in std_logic_vector(2 downto 0);
      tx_disable       : out std_logic);
end top_ten_gig_eth_pcs_pma_1_0;

architecture wrapper of top_ten_gig_eth_pcs_pma_1_0 is

    attribute DowngradeIPIdentifiedWarnings: string;

    attribute DowngradeIPIdentifiedWarnings of wrapper : architecture is "yes";


  component top_ten_gig_eth_pcs_pma_1_0_block is
    port (
      coreclk          : in  std_logic;
      dclk             : in  std_logic;
      rxrecclk_out     : out std_logic;
      txusrclk         : in  std_logic;
      txusrclk2        : in  std_logic;
      txoutclk         : out std_logic;
      areset           : in  std_logic;
      areset_coreclk      : in  std_logic;
      gttxreset          : in  std_logic;
      gtrxreset          : in  std_logic;
      sim_speedup_control: in  std_logic := '0';
      txuserrdy          : in  std_logic;
      qplllock           : in  std_logic;
      qplloutclk         : in  std_logic;
      qplloutrefclk      : in  std_logic;
      reset_counter_done : in  std_logic;
      xgmii_txd        : in  std_logic_vector(63 downto 0);
      xgmii_txc        : in  std_logic_vector(7 downto 0);
      xgmii_rxd        : out std_logic_vector(63 downto 0);
      xgmii_rxc        : out std_logic_vector(7 downto 0);
      txp              : out std_logic;
      txn              : out std_logic;
      rxp              : in  std_logic;
      rxn              : in  std_logic;
      mdc              : in  std_logic;
      mdio_in          : in  std_logic;
      mdio_out         : out std_logic;
      mdio_tri         : out std_logic;
      prtad            : in  std_logic_vector(4 downto 0);
      core_status      : out std_logic_vector(7 downto 0);
      tx_resetdone     : out std_logic;
      rx_resetdone     : out std_logic;
      signal_detect    : in  std_logic;
      tx_fault         : in  std_logic;
      drp_req          : out std_logic;
      drp_gnt          : in  std_logic;
      drp_den_o        : out std_logic;
      drp_dwe_o        : out std_logic;
      drp_daddr_o      : out std_logic_vector(15 downto 0);
      drp_di_o         : out std_logic_vector(15 downto 0);
      drp_drdy_i       : in  std_logic;
      drp_drpdo_i      : in  std_logic_vector(15 downto 0);
      drp_den_i        : in  std_logic;
      drp_dwe_i        : in  std_logic;
      drp_daddr_i      : in  std_logic_vector(15 downto 0);
      drp_di_i         : in  std_logic_vector(15 downto 0);
      drp_drdy_o       : out std_logic;
      drp_drpdo_o      : out std_logic_vector(15 downto 0);
      gt0_eyescanreset     : in  std_logic;
      gt0_eyescantrigger   : in  std_logic;
      gt0_rxcdrhold        : in  std_logic;
      gt0_txprbsforceerr   : in  std_logic;
      gt0_txpolarity       : in  std_logic;
      gt0_rxpolarity       : in  std_logic;
      gt0_rxrate           : in  std_logic_vector(2 downto 0);
      gt0_txpmareset       : in  std_logic;
      gt0_rxpmareset       : in  std_logic;
      gt0_rxdfelpmreset    : in  std_logic;
      gt0_txprecursor      : in  std_logic_vector(4 downto 0);
      gt0_txpostcursor     : in  std_logic_vector(4 downto 0);
      gt0_txdiffctrl       : in  std_logic_vector(3 downto 0);
      gt0_rxlpmen          : in  std_logic;
      gt0_eyescandataerror : out std_logic;
      gt0_txbufstatus      : out std_logic_vector(1 downto 0);
      gt0_txresetdone      : out std_logic;
      gt0_rxpmaresetdone   : out std_logic;
      gt0_rxresetdone      : out std_logic;
      gt0_rxbufstatus      : out std_logic_vector(2 downto 0);
      gt0_rxprbserr        : out std_logic;
      gt0_dmonitorout      : out std_logic_vector(14 downto 0);
      pma_pmd_type     : in std_logic_vector(2 downto 0);
      tx_disable       : out std_logic);
  end component;

  ATTRIBUTE CORE_GENERATION_INFO : STRING;
  ATTRIBUTE CORE_GENERATION_INFO OF wrapper : ARCHITECTURE IS "top_ten_gig_eth_pcs_pma_1_0,ten_gig_eth_pcs_pma_v6_0_33,{x_ipProduct=Vivado 2026.1,x_ipVendor=xilinx.com,x_ipLibrary=ip,x_ipName=ten_gig_eth_pcs_pma,x_ipVersion=6.0,x_ipCoreRevision=33,x_ipLanguage=VHDL,x_ipSimLanguage=VHDL,c_family=virtex7,c_component_name=top_ten_gig_eth_pcs_pma_1_0,c_has_mdio=true,c_has_fec=false,c_has_an=false,c_is_kr=false,c_is_32bit=false,c_no_ebuff=false,c_gttype=1,c_1588=0,c_gtif_width=32,c_speed10_25=10,c_sub_core_name=top_ten_gig_eth_pcs_pma_1_0_gt,c_gt_loc=X0Y0,c_refclk=clk0,c_refclkrate=156,c_dclkrate=100.00,x_ipLicense=ten_gig_eth_pcs_pma_basekr@2015.04(hardware_evaluation)}";
  ATTRIBUTE X_CORE_INFO : STRING;
  ATTRIBUTE X_CORE_INFO OF wrapper: ARCHITECTURE IS "ten_gig_eth_pcs_pma_v6_0_33,Vivado 2026.1";
begin
--
-- Instantiate the 10Gig PCS/PMA core
--
  U0 : top_ten_gig_eth_pcs_pma_1_0_block
    port map (
      coreclk => coreclk,
      dclk => dclk,
      rxrecclk_out => rxrecclk_out,
      txusrclk => txusrclk,
      txusrclk2 => txusrclk2,
      txoutclk => txoutclk,
      areset => areset,
      areset_coreclk => areset_coreclk,
      gttxreset => gttxreset,
      gtrxreset => gtrxreset,
      sim_speedup_control => sim_speedup_control,
      txuserrdy => txuserrdy,
      qplllock => qplllock,
      qplloutclk => qplloutclk,
      qplloutrefclk => qplloutrefclk,
      reset_counter_done => reset_counter_done,
      xgmii_txd => xgmii_txd,
      xgmii_txc => xgmii_txc,
      xgmii_rxd => xgmii_rxd,
      xgmii_rxc => xgmii_rxc,
      txp => txp,
      txn => txn,
      rxp => rxp,
      rxn => rxn,
      mdc => mdc,
      mdio_in => mdio_in,
      mdio_out => mdio_out,
      mdio_tri => mdio_tri,
      prtad => prtad,
      core_status => core_status,
      tx_resetdone => tx_resetdone,
      rx_resetdone => rx_resetdone,
      signal_detect => signal_detect,
      tx_fault => tx_fault,
      drp_req => drp_req,
      drp_gnt => drp_gnt,
      drp_den_o    => drp_den_o,
      drp_dwe_o    => drp_dwe_o,
      drp_daddr_o  => drp_daddr_o,
      drp_di_o     => drp_di_o,
      drp_drdy_o   => drp_drdy_o,
      drp_drpdo_o  => drp_drpdo_o,
      drp_den_i    => drp_den_i,
      drp_dwe_i    => drp_dwe_i,
      drp_daddr_i  => drp_daddr_i,
      drp_di_i     => drp_di_i,
      drp_drdy_i   => drp_drdy_i,
      drp_drpdo_i  => drp_drpdo_i,
     gt0_eyescanreset    => gt0_eyescanreset,
     gt0_eyescantrigger  => gt0_eyescantrigger,
     gt0_rxcdrhold       => gt0_rxcdrhold,
     gt0_txprbsforceerr  => gt0_txprbsforceerr,
     gt0_txpolarity      => gt0_txpolarity,
     gt0_rxpolarity      => gt0_rxpolarity,
     gt0_rxrate          => gt0_rxrate,
     gt0_txpmareset      => gt0_txpmareset,
     gt0_rxpmareset      => gt0_rxpmareset,
     gt0_rxdfelpmreset   => gt0_rxdfelpmreset,
     gt0_rxpmaresetdone  => gt0_rxpmaresetdone,
     gt0_txresetdone     => gt0_txresetdone,
     gt0_rxresetdone     => gt0_rxresetdone,
     gt0_txprecursor     => gt0_txprecursor,
     gt0_txpostcursor    => gt0_txpostcursor,
     gt0_txdiffctrl      => gt0_txdiffctrl,
     gt0_rxlpmen         => gt0_rxlpmen,
     gt0_eyescandataerror=> gt0_eyescandataerror,
     gt0_txbufstatus     => gt0_txbufstatus,
     gt0_rxbufstatus     => gt0_rxbufstatus,
     gt0_rxprbserr       => gt0_rxprbserr,
     gt0_dmonitorout     => gt0_dmonitorout,
      pma_pmd_type => pma_pmd_type,
      tx_disable => tx_disable
      );
end wrapper;



