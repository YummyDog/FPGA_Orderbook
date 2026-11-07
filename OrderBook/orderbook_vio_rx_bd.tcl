# orderbook_vio_rx_bd.tcl - let the VIO show what core B actually decodes
#
# Run ONCE in the Vivado Tcl Console with the OrderBook project open
# (after orderbook_qsfp_bd.tcl, orderbook_vio_bd.tcl, orderbook_por_bd.tcl):
#   source C:/Users/lskje/Desktop/FPGA_Orderbook/OrderBook/orderbook_vio_rx_bd.tcl
#
# Adds two VIO inputs on vio_link:
#   probe_in5 [7:0]  core B xgmii_rxc
#   probe_in6 [63:0] core B xgmii_rxd
# With the ConnectX-5 sending idles and the RX polarity right, these read
#   xgmii_rxc = FF, xgmii_rxd = 0707070707070707
# With the wrong polarity they show error characters (FE...) instead.
# (Both are in core A's coreclk domain = the VIO clock; the existing
#  "-through vio_link/probe_in*" false path in orderbook.xdc covers them.)

set B ten_gig_eth_pcs_pma_1

open_bd_design [get_files top.bd]

set vio [get_bd_cells vio_link]
if {[get_property CONFIG.C_NUM_PROBE_IN $vio] >= 7} {
  error "vio_link already has 7+ inputs - this script has already been applied"
}

set_property -dict [list \
  CONFIG.C_NUM_PROBE_IN    {7}  \
  CONFIG.C_PROBE_IN5_WIDTH {8}  \
  CONFIG.C_PROBE_IN6_WIDTH {64} \
] $vio

connect_bd_net [get_bd_pins $B/xgmii_rxc] [get_bd_pins vio_link/probe_in5]
connect_bd_net [get_bd_pins $B/xgmii_rxd] [get_bd_pins vio_link/probe_in6]

validate_bd_design
save_bd_design
generate_target all [get_files top.bd]

puts "=== VIO RX probes added. Next: reset_run synth_1; launch_runs impl_1 -to_step write_bitstream -jobs 4 ==="
