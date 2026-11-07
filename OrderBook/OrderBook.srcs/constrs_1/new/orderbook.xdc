## ---- Clocks ----
# 156.25 MHz SFP+ reference clock. coreclk_out (BUFG of refclk) inherits it,
# so all of market_data_top is timed at 6.400 ns.
create_clock -period 6.400 -name gt_refclk [get_ports gt_refclk_clk_p]

# Optional: keep the margin of your old 6.210 ns OOC target
#set_clock_uncertainty -setup 0.190 [get_clocks gt_refclk]

# Do NOT create clocks for TXOUTCLK/RXOUTCLK yourself; the PCS/PMA IP's own XDC does that.


## ---- Config bank (7-series DRC) ----
set_property CFGBVS GND [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]

#set_clock_uncertainty -setup 0.190 [get_clocks -of_objects [get_ports gt_refclk_clk_p]]

#set_clock_uncertainty -setup 0.190 [get_clocks -of_objects [get_ports gt_refclk_clk_p]]
set_max_delay -datapath_only -from [get_clocks -of_objects [get_ports gt_refclk_clk_p]] -to [get_clocks -of_objects [get_pins -hier -filter {NAME =~ *gthe2_i/RXOUTCLK}]] 3.100

## ---- Fan (fan_pwm on the 25 MHz board oscillator) ----
set_property PACKAGE_PIN AH9 [get_ports clk25in]
set_property IOSTANDARD LVCMOS18 [get_ports clk25in]
create_clock -period 40.000 -name clk25 [get_ports clk25in]

set_property PACKAGE_PIN AL33 [get_ports fan]
set_property IOSTANDARD LVCMOS18 [get_ports fan]
set_property DRIVE 4 [get_ports fan]
# Static/slow output to a fan driver: no output timing requirement
set_false_path -to [get_ports fan]

## ---- GTH: quad 116, refclk MGTREFCLK1 (found with IBERT + reference rugmac.xdc) ----
set_property PACKAGE_PIN V6  [get_ports gt_refclk_clk_p]   ;# MGTREFCLK1P_116
set_property PACKAGE_PIN V5  [get_ports gt_refclk_clk_n]   ;# MGTREFCLK1N_116

## Core A (ten_gig_eth_pcs_pma_0) = X1Y24 / ch0: TX -> QSFP lane 1 (TX polarity inverted)
## (its RX receives QSFP lane 3 - unused)
set_property PACKAGE_PIN Y2  [get_ports sfp_txp]           ;# MGTHTXP0_116
set_property PACKAGE_PIN Y1  [get_ports sfp_txn]           ;# MGTHTXN0_116
set_property PACKAGE_PIN AA4 [get_ports sfp_rxp]           ;# MGTHRXP0_116
set_property PACKAGE_PIN AA3 [get_ports sfp_rxn]           ;# MGTHRXN0_116

## Core B (ten_gig_eth_pcs_pma_1) = X1Y26 / ch2: RX <- QSFP lane 1 (RX polarity inverted)
## (its TX drives QSFP lane 3 - unused)
set_property PACKAGE_PIN T2  [get_ports sfp1_txp]          ;# MGTHTXP2_116
set_property PACKAGE_PIN T1  [get_ports sfp1_txn]          ;# MGTHTXN2_116
set_property PACKAGE_PIN U4  [get_ports sfp1_rxp]          ;# MGTHRXP2_116
set_property PACKAGE_PIN U3  [get_ports sfp1_rxn]          ;# MGTHRXN2_116

## ---- QSFP module control (pins from reference rugmac.xdc) ----
## QSFP_RESET = 1 releases the module from reset; SFP_OR_OPT = 0
set_property PACKAGE_PIN AH13 [get_ports QSFP_RESET]
set_property IOSTANDARD LVCMOS18 [get_ports QSFP_RESET]
set_property PACKAGE_PIN AC12 [get_ports SFP_OR_OPT]
set_property IOSTANDARD LVCMOS18 [get_ports SFP_OR_OPT]
set_false_path -to [get_ports {QSFP_RESET SFP_OR_OPT}]

## ---- Debug VIO (vio_link): quasi-static control/status, not timed ----
## probe_out* -> GT TX/RX polarity pins, probe_in* <- GT/core status bits
set_false_path -through [get_pins -quiet {top_i/vio_link/probe_out*}]
set_false_path -through [get_pins -quiet {top_i/vio_link/probe_in*}]

## ---- Power-on reset (por_0, 25 MHz domain) into the 10G cores' async resets ----
set_false_path -through [get_pins -quiet {top_i/por_0/rst_out}]
