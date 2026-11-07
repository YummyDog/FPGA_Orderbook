# orderbook_vio_bd.tcl - add a VIO to OrderBook's block design for link debug
#
# Run ONCE in the Vivado Tcl Console with the OrderBook project open
# (after orderbook_qsfp_bd.tcl has been applied):
#   source C:/Users/lskje/Desktop/FPGA_Orderbook/OrderBook/orderbook_vio_bd.tcl
#
# VIO "vio_link", clocked by core A's coreclk_out (156.25 MHz):
#   probe_in0 [7:0] core A core_status   (bit 0 = PCS block lock; A's RX = lane 3, unused)
#   probe_in1 [7:0] core B core_status   (bit 0 = PCS block lock on QSFP lane 1  <-- the one that matters)
#   probe_in2       core A resetdone_out
#   probe_in3       core A qplllock_out
#   probe_in4       core B gt0_rxresetdone
#   probe_out0      core A gt0_txpolarity   (starts at 1)
#   probe_out1      core B gt0_rxpolarity   (starts at 1)
#
# The two polarity pins are moved off xlconstant_0 onto the VIO; everything
# else (QSFP_RESET = 1, SFP_OR_OPT = 0, A rxpol = 0, B txpol = 0) is unchanged.

set A ten_gig_eth_pcs_pma_0
set B ten_gig_eth_pcs_pma_1

open_bd_design [get_files top.bd]

if {[llength [get_bd_cells -quiet vio_link]]} {
  error "vio_link already exists - this script has already been applied"
}

# ---- VIO ----
set vio_vlnv [lindex [lsort [get_ipdefs -all xilinx.com:ip:vio:*]] end]
create_bd_cell -type ip -vlnv $vio_vlnv vio_link
set_property -dict [list \
  CONFIG.C_NUM_PROBE_IN        {5}   \
  CONFIG.C_NUM_PROBE_OUT       {2}   \
  CONFIG.C_PROBE_IN0_WIDTH     {8}   \
  CONFIG.C_PROBE_IN1_WIDTH     {8}   \
  CONFIG.C_PROBE_OUT0_INIT_VAL {0x1} \
  CONFIG.C_PROBE_OUT1_INIT_VAL {0x1} \
] [get_bd_cells vio_link]

connect_bd_net [get_bd_pins $A/coreclk_out] [get_bd_pins vio_link/clk]

# ---- status inputs ----
connect_bd_net [get_bd_pins $A/core_status]      [get_bd_pins vio_link/probe_in0]
connect_bd_net [get_bd_pins $B/core_status]      [get_bd_pins vio_link/probe_in1]
connect_bd_net [get_bd_pins $A/resetdone_out]    [get_bd_pins vio_link/probe_in2]
connect_bd_net [get_bd_pins $A/qplllock_out]     [get_bd_pins vio_link/probe_in3]
connect_bd_net [get_bd_pins $B/gt0_rxresetdone]  [get_bd_pins vio_link/probe_in4]

# ---- polarity: move A txpol and B rxpol from xlconstant_0 to the VIO ----
disconnect_bd_net [get_bd_nets -of_objects [get_bd_pins $A/gt0_txpolarity]] [get_bd_pins $A/gt0_txpolarity]
disconnect_bd_net [get_bd_nets -of_objects [get_bd_pins $B/gt0_rxpolarity]] [get_bd_pins $B/gt0_rxpolarity]
connect_bd_net [get_bd_pins vio_link/probe_out0] [get_bd_pins $A/gt0_txpolarity]
connect_bd_net [get_bd_pins vio_link/probe_out1] [get_bd_pins $B/gt0_rxpolarity]

validate_bd_design
save_bd_design
generate_target all [get_files top.bd]

puts "=== VIO added. Next: reset_run synth_1; launch_runs impl_1 -to_step write_bitstream -jobs 4 ==="
