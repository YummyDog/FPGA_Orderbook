## pin_finder.xdc - fixed constraints. GT / refclk pins are generated per
## build by pin_finder_build.tcl into pins_chX_refY.xdc.

## ---- Config bank (same as OrderBook) ----
set_property CFGBVS GND [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]

## ---- 25 MHz board oscillator ----
set_property PACKAGE_PIN AH9 [get_ports clk25in]
set_property IOSTANDARD LVCMOS18 [get_ports clk25in]
create_clock -period 40.000 -name clk25 [get_ports clk25in]

## ---- Fan (same as OrderBook) ----
set_property PACKAGE_PIN AL33 [get_ports fan]
set_property IOSTANDARD LVCMOS18 [get_ports fan]
set_property DRIVE 4 [get_ports fan]
set_false_path -to [get_ports fan]

## ---- Clock-domain crossings (status into sysclk, reset into the cores) ----
set_false_path -to   [get_cells -hier -filter {NAME =~ *sync1_reg*}]
set_false_path -from [get_cells -hier -filter {NAME =~ *rst_cores_reg*}]
