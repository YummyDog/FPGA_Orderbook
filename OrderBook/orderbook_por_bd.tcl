# orderbook_por_bd.tcl - give both 10G cores a proper power-on reset
#
# Run ONCE in the Vivado Tcl Console with the OrderBook project open
# (after orderbook_qsfp_bd.tcl and orderbook_vio_bd.tcl):
#   source C:/Users/lskje/Desktop/FPGA_Orderbook/OrderBook/orderbook_por_bd.tcl
#
# Adds module "por_0" (por_reset.v, clocked by clk25in):
#   rst_out -> ten_gig_eth_pcs_pma_0/reset   (was tied to 0)
#           -> ten_gig_eth_pcs_pma_1/areset  (was tied to 0)
#   force_rst <- vio_link/probe_out2  (new VIO output, starts at 0)
# ~2.6 ms reset after configuration, then a VIO button to re-pulse it.

set A ten_gig_eth_pcs_pma_0
set B ten_gig_eth_pcs_pma_1

set v [file normalize C:/Users/lskje/Desktop/FPGA_Orderbook/OrderBook/OrderBook.srcs/sources_1/new/por_reset.v]
if {[llength [get_files -quiet $v]] == 0} { add_files -norecurse $v }
update_compile_order -fileset sources_1

open_bd_design [get_files top.bd]

if {[llength [get_bd_cells -quiet por_0]]} {
  error "por_0 already exists - this script has already been applied"
}

create_bd_cell -type module -reference por_reset por_0
connect_bd_net [get_bd_ports clk25in] [get_bd_pins por_0/clk]

# third VIO output -> force_rst (initial value 0)
set_property CONFIG.C_NUM_PROBE_OUT {3} [get_bd_cells vio_link]
connect_bd_net [get_bd_pins vio_link/probe_out2] [get_bd_pins por_0/force_rst]

# reset both cores from the POR
connect_bd_net [get_bd_pins por_0/rst_out] [get_bd_pins $A/reset]
connect_bd_net [get_bd_pins por_0/rst_out] [get_bd_pins $B/areset]

validate_bd_design
save_bd_design
generate_target all [get_files top.bd]

puts "=== POR added. Next: reset_run synth_1; launch_runs impl_1 -to_step write_bitstream -jobs 4 ==="
