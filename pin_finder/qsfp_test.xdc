## qsfp_test.xdc - pins from the reference design (rugmac.xdc) + clock/fan

## ---- Config bank (same as OrderBook / reference) ----
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

## ---- QSFP control / status (from reference) ----
set_property PACKAGE_PIN AH13 [get_ports QSFP_RESET]
set_property IOSTANDARD LVCMOS18 [get_ports QSFP_RESET]
set_property PACKAGE_PIN AC12 [get_ports SFP_OR_OPT]
set_property IOSTANDARD LVCMOS18 [get_ports SFP_OR_OPT]
set_property PACKAGE_PIN AL23 [get_ports QSFP_PRES]
set_property IOSTANDARD LVCMOS18 [get_ports QSFP_PRES]
set_property PACKAGE_PIN AK23 [get_ports SF_FLT_LOS]
set_property IOSTANDARD LVCMOS18 [get_ports SF_FLT_LOS]
set_false_path -to   [get_ports {QSFP_RESET SFP_OR_OPT}]
set_false_path -from [get_ports {QSFP_PRES SF_FLT_LOS}]

## ---- GT: quad 116, refclk MGTREFCLK1 (V6/V5), channel 0 = X1Y24 ----
set_property PACKAGE_PIN V6  [get_ports refclk_p]   ;# MGTREFCLK1P_116
set_property PACKAGE_PIN V5  [get_ports refclk_n]   ;# MGTREFCLK1N_116
set_property PACKAGE_PIN AA4 [get_ports rxp]        ;# MGTHRXP0_116
set_property PACKAGE_PIN AA3 [get_ports rxn]        ;# MGTHRXN0_116
set_property PACKAGE_PIN Y2  [get_ports txp]        ;# MGTHTXP0_116  (X1Y24 -> QSFP lane 1)
set_property PACKAGE_PIN Y1  [get_ports txn]        ;# MGTHTXN0_116

## ---- Clock-domain crossings ----
set_false_path -to   [get_cells -hier -filter {NAME =~ *sync1_reg*}]
set_false_path -from [get_cells -hier -filter {NAME =~ *rst_cores_reg*}]
