# orderbook_polarity_final_bd.tcl - fix the QSFP lane-1 polarities as constants
#
# Run ONCE in the Vivado Tcl Console with the OrderBook project open:
#   source C:/Users/lskje/Desktop/FPGA_Orderbook/OrderBook/orderbook_polarity_final_bd.tcl
#
# Found with the VIO on this board:
#   core A (X1Y24, TX -> QSFP lane 1): gt0_txpolarity = 1  (inverted)
#   core B (X1Y26, RX <- QSFP lane 1): gt0_rxpolarity = 0  (normal)
#
# xlconstant_0 = 1, xlconstant_1 = 0 (already in the design).
# The VIO stays for monitoring (status inputs) and its probe_out2 still drives
# the power-on-reset button; probe_out0/1 are simply left unconnected.

set A ten_gig_eth_pcs_pma_0
set B ten_gig_eth_pcs_pma_1

open_bd_design [get_files top.bd]

# move A txpolarity and B rxpolarity off the VIO onto the constants
foreach {pin const} [list \
  $A/gt0_txpolarity xlconstant_0 \
  $B/gt0_rxpolarity xlconstant_1 \
] {
  set p [get_bd_pins $pin]
  set n [get_bd_nets -quiet -of_objects $p]
  if {[llength $n]} { disconnect_bd_net $n $p }
  connect_bd_net [get_bd_pins $const/dout] $p
}

validate_bd_design
save_bd_design
generate_target all [get_files top.bd]

puts "=== Polarity fixed: A txpol = 1, B rxpol = 0. Next: reset_run synth_1; launch_runs impl_1 -to_step write_bitstream -jobs 4 ==="
