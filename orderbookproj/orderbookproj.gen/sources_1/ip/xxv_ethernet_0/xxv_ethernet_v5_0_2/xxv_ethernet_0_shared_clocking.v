//-------------------------------------------------------------------------------
// File       : xxv_ethernet_0_shared_clocking.v
// Author     : AMD Inc.
//-------------------------------------------------------------------------------
// Description: This is the XGMII interface Verilog code .
// It may also  contain the Receive
// clock generation depending on the configuration options selected
// when generated.
//-------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
//   (c) Copyright 2020-2021 Advanced Micro Devices, Inc. All rights reserved.
// 
//   This file contains confidential and proprietary information
//   of Advanced Micro Devices, Inc. and is protected under U.S. and
//   international copyright and other intellectual property
//   laws.
// 
//   DISCLAIMER
//   This disclaimer is not a license and does not grant any
//   rights to the materials distributed herewith. Except as
//   otherwise provided in a valid license issued to you by
//   AMD, and to the maximum extent permitted by applicable
//   law: (1) THESE MATERIALS ARE MADE AVAILABLE \"AS IS\" AND
//   WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
//   AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
//   BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
//   INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
//   (2) AMD shall not be liable (whether in contract or tort,
//   including negligence, or under any other theory of
//   liability) for any loss or damage of any kind or nature
//   related to, arising under or in connection with these
//   materials, including for any direct, or any indirect,
//   special, incidental, or consequential loss or damage
//   (including loss of data, profits, goodwill, or any type of
//   loss or damage suffered as a result of any action brought
//   by a third party) even if such damage or loss was
//   reasonably foreseeable or AMD had been advised of the
//   possibility of the same.
// 
//   CRITICAL APPLICATIONS
//   AMD products are not designed or intended to be fail-
//   safe, or for use in any application requiring fail-safe
//   performance, such as life-support or safety devices or
//   systems, Class III medical devices, nuclear facilities,
//   applications related to the deployment of airbags, or any
//   other applications that could lead to death, personal
//   injury, or severe property or environmental damage
//   (individually and collectively, \"Critical
//   Applications\"). Customer assumes the sole risk and
//   liability of any use of AMD products in Critical
//   Applications, subject only to applicable laws and
//   regulations governing limitations on product liability.
// 
//   THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
//   PART OF THIS FILE AT ALL TIMES.
//
// 
//
//       Owner:          
//       Revision:       $Id: $
//                       $Author: $
//                       $DateTime: $
//                       $Change: $
//       Description:
//
// 
//-----------------------------------------------------------------------------

`timescale 1ps / 1ps

module xxv_ethernet_0_shared_clocking
  (
   // Inputs
   input tx_mii_clk,
   input tx_mii_reset,

   // Clock outputs
   output tx_mii_clk0,
   output tx_mii_clk90);

  // Signal declarations
  wire tx_dcm_clk0;
  wire tx_dcm_clk90;
  wire clkfbout;

   MMCME2_BASE
  #(.DIVCLK_DIVIDE        (1),
    .CLKFBOUT_MULT_F      (6.000),
    .CLKFBOUT_PHASE       (0.000),
    .CLKOUT0_DIVIDE_F     (6.000),
    .CLKOUT0_PHASE        (0.000),
    .CLKOUT0_DUTY_CYCLE   (0.5),
    .CLKOUT1_DIVIDE       (6),
    .CLKOUT1_PHASE        (90.000),
    .CLKOUT1_DUTY_CYCLE   (0.5),
    .CLKIN1_PERIOD        (6.400),
    .REF_JITTER1          (0.010))
  tx_mmcm
    // Output clocks
   (.CLKFBOUT            (clkfbout),
    .CLKOUT0             (tx_dcm_clk0),
    .CLKOUT1             (tx_dcm_clk90),
     // Input clock control
    .CLKFBIN             (clkfbout),
    .CLKIN1              (tx_mii_clk),
    // Other control and status signals
    .LOCKED              (),
    .PWRDWN              (1'b0),
    .RST                 (tx_mii_reset),
    .CLKFBOUTB           (),
    .CLKOUT0B            (),
    .CLKOUT1B            (),
    .CLKOUT2             (),
    .CLKOUT2B            (),
    .CLKOUT3             (),
    .CLKOUT3B            (),
    .CLKOUT4             (),
    .CLKOUT5             (),
    .CLKOUT6             ());

   BUFG tx_bufg0
     (
      .I(tx_dcm_clk0),
      .O(tx_mii_clk0)
      );

   BUFG tx_bufg90
     (
      .I(tx_dcm_clk90),
      .O(tx_mii_clk90)
      );

endmodule
