// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
// -------------------------------------------------------------------------------
// This file contains confidential and proprietary information
// of AMD and is protected under U.S. and international copyright
// and other intellectual property laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// AMD, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) AMD shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or AMD had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// AMD products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of AMD products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
// DO NOT MODIFY THIS FILE.

// MODULE VLNV: xilinx.com:ip:ten_gig_eth_pcs_pma:6.0

`timescale 1ps / 1ps

`include "vivado_interfaces.svh"

module tg_pcs_pma_sv (
  (* X_INTERFACE_IGNORE = "true" *)
  input wire refclk_p,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire refclk_n,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire reset,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire resetdone_out,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire coreclk_out,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire rxrecclk_out,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire dclk,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire txp,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire txn,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire rxp,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire rxn,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire sim_speedup_control,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire txusrclk_out,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire txusrclk2_out,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire areset_datapathclk_out,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire gttxreset_out,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire gtrxreset_out,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire txuserrdy_out,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire reset_counter_done_out,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire qplllock_out,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire qplloutclk_out,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire qplloutrefclk_out,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire [63:0] xgmii_txd,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire [7:0] xgmii_txc,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire [63:0] xgmii_rxd,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire [7:0] xgmii_rxc,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire mdc,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire mdio_in,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire mdio_out,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire mdio_tri,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire [4:0] prtad,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire [7:0] core_status,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire signal_detect,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire tx_fault,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire drp_req,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire drp_gnt,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire drp_den_o,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire drp_dwe_o,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire [15:0] drp_daddr_o,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire [15:0] drp_di_o,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire drp_drdy_o,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire [15:0] drp_drpdo_o,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire drp_den_i,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire drp_dwe_i,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire [15:0] drp_daddr_i,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire [15:0] drp_di_i,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire drp_drdy_i,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire [15:0] drp_drpdo_i,
  (* X_INTERFACE_IGNORE = "true" *)
  output wire tx_disable,
  (* X_INTERFACE_IGNORE = "true" *)
  input wire [2:0] pma_pmd_type
);

  tg_pcs_pma inst (
    .refclk_p(refclk_p),
    .refclk_n(refclk_n),
    .reset(reset),
    .resetdone_out(resetdone_out),
    .coreclk_out(coreclk_out),
    .rxrecclk_out(rxrecclk_out),
    .dclk(dclk),
    .txp(txp),
    .txn(txn),
    .rxp(rxp),
    .rxn(rxn),
    .sim_speedup_control(sim_speedup_control),
    .txusrclk_out(txusrclk_out),
    .txusrclk2_out(txusrclk2_out),
    .areset_datapathclk_out(areset_datapathclk_out),
    .gttxreset_out(gttxreset_out),
    .gtrxreset_out(gtrxreset_out),
    .txuserrdy_out(txuserrdy_out),
    .reset_counter_done_out(reset_counter_done_out),
    .qplllock_out(qplllock_out),
    .qplloutclk_out(qplloutclk_out),
    .qplloutrefclk_out(qplloutrefclk_out),
    .xgmii_txd(xgmii_txd),
    .xgmii_txc(xgmii_txc),
    .xgmii_rxd(xgmii_rxd),
    .xgmii_rxc(xgmii_rxc),
    .mdc(mdc),
    .mdio_in(mdio_in),
    .mdio_out(mdio_out),
    .mdio_tri(mdio_tri),
    .prtad(prtad),
    .core_status(core_status),
    .signal_detect(signal_detect),
    .tx_fault(tx_fault),
    .drp_req(drp_req),
    .drp_gnt(drp_gnt),
    .drp_den_o(drp_den_o),
    .drp_dwe_o(drp_dwe_o),
    .drp_daddr_o(drp_daddr_o),
    .drp_di_o(drp_di_o),
    .drp_drdy_o(drp_drdy_o),
    .drp_drpdo_o(drp_drpdo_o),
    .drp_den_i(drp_den_i),
    .drp_dwe_i(drp_dwe_i),
    .drp_daddr_i(drp_daddr_i),
    .drp_di_i(drp_di_i),
    .drp_drdy_i(drp_drdy_i),
    .drp_drpdo_i(drp_drpdo_i),
    .tx_disable(tx_disable),
    .pma_pmd_type(pma_pmd_type)
  );

endmodule
