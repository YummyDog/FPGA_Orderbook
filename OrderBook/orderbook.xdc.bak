## ---- Clocks ----
# 156.25 MHz SFP+ reference clock. coreclk_out (BUFG of refclk) inherits it,
# so all of market_data_top is timed at 6.400 ns.
create_clock -period 6.400 -name gt_refclk [get_ports gt_refclk_clk_p]

# Optional: keep the margin of your old 6.210 ns OOC target
#set_clock_uncertainty -setup 0.190 [get_clocks gt_refclk]

# Do NOT create clocks for TXOUTCLK/RXOUTCLK yourself; the PCS/PMA IP's own XDC does that.

## ---- GT placement (board specific) ----
# sfp_txp/txn/rxp/rxn pins follow from the channel LOC

## ---- SFP sideband ----
set_property IOSTANDARD LVCMOS18 [get_ports sfp_tx_disable]
set_false_path -to [get_ports sfp_tx_disable]

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

## ---- GTH placement: Vivado's previous auto-placement, NOT verified against the board ----
set_property PACKAGE_PIN T6  [get_ports gt_refclk_clk_p]   ;# MGTREFCLK0P_116
set_property PACKAGE_PIN T5  [get_ports gt_refclk_clk_n]   ;# MGTREFCLK0N_116
set_property PACKAGE_PIN AC4 [get_ports sfp_rxp]           ;# MGTHRXP3_115
set_property PACKAGE_PIN AC3 [get_ports sfp_rxn]           ;# MGTHRXN3_115
set_property PACKAGE_PIN AB2 [get_ports sfp_txp]           ;# MGTHTXP3_115
set_property PACKAGE_PIN AB1 [get_ports sfp_txn]           ;# MGTHTXN3_115