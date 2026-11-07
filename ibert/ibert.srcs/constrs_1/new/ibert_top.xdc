## ibert_top.xdc - IBERT 7 Series GTH sweep of all 5 GTH quads (114-118)
## Pin numbers taken from the OrderBook io_placed report for xc7vx690t-ffg1157.

## ---- Config bank (same as OrderBook) ----
set_property CFGBVS GND [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]

## ---- 25 MHz board oscillator -> MMCM -> 100 MHz IBERT system clock ----
set_property PACKAGE_PIN AH9 [get_ports clk25in]
set_property IOSTANDARD LVCMOS18 [get_ports clk25in]
create_clock -period 40.000 -name clk25 [get_ports clk25in]

## ---- Fan: same as OrderBook (fan_pwm at 100% duty, active-high = held high) ----
set_property PACKAGE_PIN AL33 [get_ports fan]
set_property IOSTANDARD LVCMOS18 [get_ports fan]
set_property DRIVE 4 [get_ports fan]
set_false_path -to [get_ports fan]

## ---- GT reference clocks: MGTREFCLK0 of each quad, assumed 156.25 MHz ----
## index 0..4 = quad 114..118
set_property PACKAGE_PIN AH6 [get_ports {refclk0_p[0]}]   ;# MGTREFCLK0P_114
set_property PACKAGE_PIN AH5 [get_ports {refclk0_n[0]}]   ;# MGTREFCLK0N_114
create_clock -period 6.400 -name refclk0_q114 [get_ports {refclk0_p[0]}]
set_property PACKAGE_PIN AB6 [get_ports {refclk0_p[1]}]   ;# MGTREFCLK0P_115
set_property PACKAGE_PIN AB5 [get_ports {refclk0_n[1]}]   ;# MGTREFCLK0N_115
create_clock -period 6.400 -name refclk0_q115 [get_ports {refclk0_p[1]}]
set_property PACKAGE_PIN T6 [get_ports {refclk0_p[2]}]   ;# MGTREFCLK0P_116
set_property PACKAGE_PIN T5 [get_ports {refclk0_n[2]}]   ;# MGTREFCLK0N_116
create_clock -period 6.400 -name refclk0_q116 [get_ports {refclk0_p[2]}]
set_property PACKAGE_PIN M6 [get_ports {refclk0_p[3]}]   ;# MGTREFCLK0P_117
set_property PACKAGE_PIN M5 [get_ports {refclk0_n[3]}]   ;# MGTREFCLK0N_117
create_clock -period 6.400 -name refclk0_q117 [get_ports {refclk0_p[3]}]
set_property PACKAGE_PIN F6 [get_ports {refclk0_p[4]}]   ;# MGTREFCLK0P_118
set_property PACKAGE_PIN F5 [get_ports {refclk0_n[4]}]   ;# MGTREFCLK0N_118
create_clock -period 6.400 -name refclk0_q118 [get_ports {refclk0_p[4]}]

## ---- GTH serial pins: index = 4*(quad-114) + channel ----
set_property PACKAGE_PIN AP2  [get_ports {txp[0]}]  ;# MGTHTXP0_114
set_property PACKAGE_PIN AP1  [get_ports {txn[0]}]  ;# MGTHTXN0_114
set_property PACKAGE_PIN AP6  [get_ports {rxp[0]}]  ;# MGTHRXP0_114
set_property PACKAGE_PIN AP5  [get_ports {rxn[0]}]  ;# MGTHRXN0_114
set_property PACKAGE_PIN AN4  [get_ports {txp[1]}]  ;# MGTHTXP1_114
set_property PACKAGE_PIN AN3  [get_ports {txn[1]}]  ;# MGTHTXN1_114
set_property PACKAGE_PIN AM6  [get_ports {rxp[1]}]  ;# MGTHRXP1_114
set_property PACKAGE_PIN AM5  [get_ports {rxn[1]}]  ;# MGTHRXN1_114
set_property PACKAGE_PIN AM2  [get_ports {txp[2]}]  ;# MGTHTXP2_114
set_property PACKAGE_PIN AM1  [get_ports {txn[2]}]  ;# MGTHTXN2_114
set_property PACKAGE_PIN AL4  [get_ports {rxp[2]}]  ;# MGTHRXP2_114
set_property PACKAGE_PIN AL3  [get_ports {rxn[2]}]  ;# MGTHRXN2_114
set_property PACKAGE_PIN AK2  [get_ports {txp[3]}]  ;# MGTHTXP3_114
set_property PACKAGE_PIN AK1  [get_ports {txn[3]}]  ;# MGTHTXN3_114
set_property PACKAGE_PIN AJ4  [get_ports {rxp[3]}]  ;# MGTHRXP3_114
set_property PACKAGE_PIN AJ3  [get_ports {rxn[3]}]  ;# MGTHRXN3_114
set_property PACKAGE_PIN AH2  [get_ports {txp[4]}]  ;# MGTHTXP0_115
set_property PACKAGE_PIN AH1  [get_ports {txn[4]}]  ;# MGTHTXN0_115
set_property PACKAGE_PIN AG4  [get_ports {rxp[4]}]  ;# MGTHRXP0_115
set_property PACKAGE_PIN AG3  [get_ports {rxn[4]}]  ;# MGTHRXN0_115
set_property PACKAGE_PIN AF2  [get_ports {txp[5]}]  ;# MGTHTXP1_115
set_property PACKAGE_PIN AF1  [get_ports {txn[5]}]  ;# MGTHTXN1_115
set_property PACKAGE_PIN AF6  [get_ports {rxp[5]}]  ;# MGTHRXP1_115
set_property PACKAGE_PIN AF5  [get_ports {rxn[5]}]  ;# MGTHRXN1_115
set_property PACKAGE_PIN AD2  [get_ports {txp[6]}]  ;# MGTHTXP2_115
set_property PACKAGE_PIN AD1  [get_ports {txn[6]}]  ;# MGTHTXN2_115
set_property PACKAGE_PIN AE4  [get_ports {rxp[6]}]  ;# MGTHRXP2_115
set_property PACKAGE_PIN AE3  [get_ports {rxn[6]}]  ;# MGTHRXN2_115
set_property PACKAGE_PIN AB2  [get_ports {txp[7]}]  ;# MGTHTXP3_115
set_property PACKAGE_PIN AB1  [get_ports {txn[7]}]  ;# MGTHTXN3_115
set_property PACKAGE_PIN AC4  [get_ports {rxp[7]}]  ;# MGTHRXP3_115
set_property PACKAGE_PIN AC3  [get_ports {rxn[7]}]  ;# MGTHRXN3_115
set_property PACKAGE_PIN Y2   [get_ports {txp[8]}]  ;# MGTHTXP0_116
set_property PACKAGE_PIN Y1   [get_ports {txn[8]}]  ;# MGTHTXN0_116
set_property PACKAGE_PIN AA4  [get_ports {rxp[8]}]  ;# MGTHRXP0_116
set_property PACKAGE_PIN AA3  [get_ports {rxn[8]}]  ;# MGTHRXN0_116
set_property PACKAGE_PIN V2   [get_ports {txp[9]}]  ;# MGTHTXP1_116
set_property PACKAGE_PIN V1   [get_ports {txn[9]}]  ;# MGTHTXN1_116
set_property PACKAGE_PIN W4   [get_ports {rxp[9]}]  ;# MGTHRXP1_116
set_property PACKAGE_PIN W3   [get_ports {rxn[9]}]  ;# MGTHRXN1_116
set_property PACKAGE_PIN T2   [get_ports {txp[10]}]  ;# MGTHTXP2_116
set_property PACKAGE_PIN T1   [get_ports {txn[10]}]  ;# MGTHTXN2_116
set_property PACKAGE_PIN U4   [get_ports {rxp[10]}]  ;# MGTHRXP2_116
set_property PACKAGE_PIN U3   [get_ports {rxn[10]}]  ;# MGTHRXN2_116
set_property PACKAGE_PIN P2   [get_ports {txp[11]}]  ;# MGTHTXP3_116
set_property PACKAGE_PIN P1   [get_ports {txn[11]}]  ;# MGTHTXN3_116
set_property PACKAGE_PIN R4   [get_ports {rxp[11]}]  ;# MGTHRXP3_116
set_property PACKAGE_PIN R3   [get_ports {rxn[11]}]  ;# MGTHRXN3_116
set_property PACKAGE_PIN M2   [get_ports {txp[12]}]  ;# MGTHTXP0_117
set_property PACKAGE_PIN M1   [get_ports {txn[12]}]  ;# MGTHTXN0_117
set_property PACKAGE_PIN N4   [get_ports {rxp[12]}]  ;# MGTHRXP0_117
set_property PACKAGE_PIN N3   [get_ports {rxn[12]}]  ;# MGTHRXN0_117
set_property PACKAGE_PIN K2   [get_ports {txp[13]}]  ;# MGTHTXP1_117
set_property PACKAGE_PIN K1   [get_ports {txn[13]}]  ;# MGTHTXN1_117
set_property PACKAGE_PIN L4   [get_ports {rxp[13]}]  ;# MGTHRXP1_117
set_property PACKAGE_PIN L3   [get_ports {rxn[13]}]  ;# MGTHRXN1_117
set_property PACKAGE_PIN H2   [get_ports {txp[14]}]  ;# MGTHTXP2_117
set_property PACKAGE_PIN H1   [get_ports {txn[14]}]  ;# MGTHTXN2_117
set_property PACKAGE_PIN K6   [get_ports {rxp[14]}]  ;# MGTHRXP2_117
set_property PACKAGE_PIN K5   [get_ports {rxn[14]}]  ;# MGTHRXN2_117
set_property PACKAGE_PIN F2   [get_ports {txp[15]}]  ;# MGTHTXP3_117
set_property PACKAGE_PIN F1   [get_ports {txn[15]}]  ;# MGTHTXN3_117
set_property PACKAGE_PIN J4   [get_ports {rxp[15]}]  ;# MGTHRXP3_117
set_property PACKAGE_PIN J3   [get_ports {rxn[15]}]  ;# MGTHRXN3_117
set_property PACKAGE_PIN D2   [get_ports {txp[16]}]  ;# MGTHTXP0_118
set_property PACKAGE_PIN D1   [get_ports {txn[16]}]  ;# MGTHTXN0_118
set_property PACKAGE_PIN G4   [get_ports {rxp[16]}]  ;# MGTHRXP0_118
set_property PACKAGE_PIN G3   [get_ports {rxn[16]}]  ;# MGTHRXN0_118
set_property PACKAGE_PIN C4   [get_ports {txp[17]}]  ;# MGTHTXP1_118
set_property PACKAGE_PIN C3   [get_ports {txn[17]}]  ;# MGTHTXN1_118
set_property PACKAGE_PIN E4   [get_ports {rxp[17]}]  ;# MGTHRXP1_118
set_property PACKAGE_PIN E3   [get_ports {rxn[17]}]  ;# MGTHRXN1_118
set_property PACKAGE_PIN B2   [get_ports {txp[18]}]  ;# MGTHTXP2_118
set_property PACKAGE_PIN B1   [get_ports {txn[18]}]  ;# MGTHTXN2_118
set_property PACKAGE_PIN D6   [get_ports {rxp[18]}]  ;# MGTHRXP2_118
set_property PACKAGE_PIN D5   [get_ports {rxn[18]}]  ;# MGTHRXN2_118
set_property PACKAGE_PIN A4   [get_ports {txp[19]}]  ;# MGTHTXP3_118
set_property PACKAGE_PIN A3   [get_ports {txn[19]}]  ;# MGTHTXN3_118
set_property PACKAGE_PIN B6   [get_ports {rxp[19]}]  ;# MGTHRXP3_118
set_property PACKAGE_PIN B5   [get_ports {rxn[19]}]  ;# MGTHRXN3_118
