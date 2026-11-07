# orderbook_qsfp_bd.tcl - block-design changes for the board's QSFP lane 1
#
# Run ONCE in the Vivado Tcl Console with the OrderBook project open:
#   source C:/Users/lskje/Desktop/FPGA_Orderbook/OrderBook/orderbook_qsfp_bd.tcl
#
# Found with IBERT + reference rugmac.xdc:
#   refclk  MGTREFCLK1_116 (V6/V5)                 -> core A RefClk = clk1
#   TX  -> QSFP lane 1 : X1Y24 (core A), TX polarity inverted
#   RX <- QSFP lane 1  : X1Y26 (core B), RX polarity inverted
#   QSFP_RESET (AH13) = 1, SFP_OR_OPT (AC12) = 0
#
# Existing cells used:  ten_gig_eth_pcs_pma_0 (A, shared logic in core)
#                       ten_gig_eth_pcs_pma_1 (B, shared logic in example)
#                       xlconstant_0 = 1, xlconstant_1 = 0, market_data_top_0

set A ten_gig_eth_pcs_pma_0
set B ten_gig_eth_pcs_pma_1

open_bd_design [get_files top.bd]

if {[llength [get_bd_ports -quiet sfp1_txp]]} {
  error "sfp1_txp already exists - this script has already been applied"
}

# ---- 1. Core A: use reference clock 1 (MGTREFCLK1_116 = V6/V5) ----
set_property CONFIG.RefClk {clk1} [get_bd_cells $A]

# ---- 2. Polarity -------------------------------------------------------
# A: txpolarity = 1 (xlconstant_0), rxpolarity = 0 (xlconstant_1)  - already so
# B: rxpolarity must be 1, txpolarity 0 (B's TX is unused) - swap B's two pins
disconnect_bd_net [get_bd_nets xlconstant_1_dout] [get_bd_pins $B/gt0_rxpolarity]
disconnect_bd_net [get_bd_nets xlconstant_0_dout] [get_bd_pins $B/gt0_txpolarity]
connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins $B/gt0_rxpolarity]
connect_bd_net [get_bd_pins xlconstant_1/dout] [get_bd_pins $B/gt0_txpolarity]

# ---- 3. Core B shared-logic inputs from core A -------------------------
# (B/coreclk is already on A/coreclk_out)
foreach {a b} {
  txusrclk_out           txusrclk
  txusrclk2_out          txusrclk2
  areset_datapathclk_out areset_coreclk
  gttxreset_out          gttxreset
  gtrxreset_out          gtrxreset
  txuserrdy_out          txuserrdy
  reset_counter_done_out reset_counter_done
  qplllock_out           qplllock
  qplloutclk_out         qplloutclk
  qplloutrefclk_out      qplloutrefclk
} {
  connect_bd_net [get_bd_pins $A/$a] [get_bd_pins $B/$b]
}

# B's DRP clock = same as A's (coreclk_out)
connect_bd_net [get_bd_pins $A/coreclk_out] [get_bd_pins $B/dclk]

# B's DRP looped back to itself, same as A
connect_bd_intf_net [get_bd_intf_pins $B/core_gt_drp_interface] [get_bd_intf_pins $B/user_gt_drp_interface]
connect_bd_net [get_bd_pins $B/drp_req] [get_bd_pins $B/drp_gnt]

# ---- 4. XGMII receive path: market_data_top now gets RX from core B ----
delete_bd_objs [get_bd_nets ten_gig_eth_pcs_pma_0_xgmii_rxd] [get_bd_nets ten_gig_eth_pcs_pma_0_xgmii_rxc]
connect_bd_net [get_bd_pins $B/xgmii_rxd] [get_bd_pins market_data_top_0/xgmii_rxd]
connect_bd_net [get_bd_pins $B/xgmii_rxc] [get_bd_pins market_data_top_0/xgmii_rxc]
# (market_data_top TX stays on core A; B's xgmii_txd/txc and A's xgmii_rxd/rxc
#  are unused and left unconnected)

# ---- 5. Core B serial pins -> new external ports sfp1_* ----------------
create_bd_port -dir O sfp1_txp
create_bd_port -dir O sfp1_txn
create_bd_port -dir I sfp1_rxp
create_bd_port -dir I sfp1_rxn
connect_bd_net [get_bd_ports sfp1_txp] [get_bd_pins $B/txp]
connect_bd_net [get_bd_ports sfp1_txn] [get_bd_pins $B/txn]
connect_bd_net [get_bd_ports sfp1_rxp] [get_bd_pins $B/rxp]
connect_bd_net [get_bd_ports sfp1_rxn] [get_bd_pins $B/rxn]

# ---- 6. QSFP control outputs -------------------------------------------
create_bd_port -dir O QSFP_RESET
create_bd_port -dir O SFP_OR_OPT
connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_ports QSFP_RESET]   ;# 1
connect_bd_net [get_bd_pins xlconstant_1/dout] [get_bd_ports SFP_OR_OPT]   ;# 0

# ---- 7. Validate, save, regenerate ---------------------------------------
validate_bd_design
save_bd_design
generate_target all [get_files top.bd]

puts "=== Block design updated. Next: reset_run synth_1; launch_runs impl_1 -to_step write_bitstream -jobs 4 ==="
