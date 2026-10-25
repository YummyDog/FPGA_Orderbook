set_property SRC_FILE_INFO {cfile:C:/Users/lskje/Desktop/FPGA_Orderbook/OrderBook/OrderBook.srcs/constrs_1/new/orderbook.xdc rfile:../../../OrderBook.srcs/constrs_1/new/orderbook.xdc id:1} [current_design]
set_property src_info {type:XDC file:1 line:15 export:INPUT save:INPUT read:READ} [current_design]
set_property IOSTANDARD LVCMOS18 [get_ports sfp_tx_disable]
set_property src_info {type:XDC file:1 line:16 export:INPUT save:INPUT read:READ} [current_design]
set_false_path -to [get_ports sfp_tx_disable]
set_property src_info {type:XDC file:1 line:25 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay -datapath_only -from [get_clocks -of_objects [get_ports gt_refclk_clk_p]] -to [get_clocks -of_objects [get_pins -hier -filter {NAME =~ *gthe2_i/RXOUTCLK}]] 3.100
set_property src_info {type:XDC file:1 line:28 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AH9 [get_ports clk25in]
set_property src_info {type:XDC file:1 line:32 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AL33 [get_ports fan]
set_property src_info {type:XDC file:1 line:39 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN T6  [get_ports gt_refclk_clk_p]   ;# MGTREFCLK0P_116
set_property src_info {type:XDC file:1 line:40 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN T5  [get_ports gt_refclk_clk_n]   ;# MGTREFCLK0N_116
set_property src_info {type:XDC file:1 line:41 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AC4 [get_ports sfp_rxp]           ;# MGTHRXP3_115
set_property src_info {type:XDC file:1 line:42 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AC3 [get_ports sfp_rxn]           ;# MGTHRXN3_115
set_property src_info {type:XDC file:1 line:43 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AB2 [get_ports sfp_txp]           ;# MGTHTXP3_115
set_property src_info {type:XDC file:1 line:44 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AB1 [get_ports sfp_txn]           ;# MGTHTXN3_115
