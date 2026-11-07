# qsfp_test_build.tcl - build the QSFP bring-up test.
#
# Run from the Vivado Tcl Console (no project needs to be open):
#   source C:/Users/lskje/Desktop/FPGA_Orderbook/pin_finder/qsfp_test_build.tcl
#
# Output next to this script: qsfp_test.bit / qsfp_test.ltx
# Project is (re)created in .\prj_qsfp

set here    [file dirname [file normalize [info script]]]
set prj_dir [file join $here prj_qsfp]

catch {close_project}
create_project qsfp_test $prj_dir -part xc7vx690tffg1157-2 -force
set_property target_language Verilog [current_project]

# 10G PCS/PMA - same as OrderBook's core, but reference clock 1 (clk1)
create_ip -name ten_gig_eth_pcs_pma -vendor xilinx.com -library ip -module_name tg_pcs_pma
set_property -dict [list \
  CONFIG.MDIO_Management {true}   \
  CONFIG.base_kr         {BASE-R} \
  CONFIG.SupportLevel    {1}      \
  CONFIG.RefClkRate      {156.25} \
  CONFIG.RefClk          {clk1}   \
  CONFIG.DClkRate        {100.00} \
] [get_ips tg_pcs_pma]

# VIO: 6 single-bit inputs, 3 single-bit outputs (all outputs start at 0)
create_ip -name vio -vendor xilinx.com -library ip -module_name vio_qsfp
set_property -dict [list \
  CONFIG.C_NUM_PROBE_IN  {6} \
  CONFIG.C_NUM_PROBE_OUT {3} \
] [get_ips vio_qsfp]

generate_target all [get_ips]

add_files -norecurse [file join $here qsfp_test_top.v]
add_files -fileset constrs_1 -norecurse [file join $here qsfp_test.xdc]
set_property top qsfp_test_top [get_filesets sources_1]
update_compile_order -fileset sources_1

launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

set rundir [get_property DIRECTORY [get_runs impl_1]]
set bit    [file join $rundir qsfp_test_top.bit]
if {![file exists $bit]} {
  error "Build failed - open [file join $rundir runme.log] (or the synth_1 log) and check the first ERROR."
}
file copy -force $bit [file join $here qsfp_test.bit]
set ltx [file join $rundir qsfp_test_top.ltx]
if {[file exists $ltx]} { file copy -force $ltx [file join $here qsfp_test.ltx] }

puts "=== Done ==="
puts "Bitstream: [file join $here qsfp_test.bit]"
puts "Probes:    [file join $here qsfp_test.ltx]"
