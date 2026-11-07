# ibert_build.tcl - add ibert_top.v / ibert_top.xdc to this project and build.
# In Vivado, with the "ibert" project open, run in the Tcl Console:
#   source [get_property DIRECTORY [current_project]]/ibert_build.tcl

set d [get_property DIRECTORY [current_project]]

set v   [file join $d ibert.srcs sources_1 new ibert_top.v]
set xdc [file join $d ibert.srcs constrs_1 new ibert_top.xdc]

if {[llength [get_files -quiet $v]] == 0}   { add_files -norecurse $v }
if {[llength [get_files -quiet $xdc]] == 0} { add_files -fileset constrs_1 -norecurse $xdc }
set_property target_constrs_file $xdc [get_filesets constrs_1]

set_property top ibert_top [get_filesets sources_1]
update_compile_order -fileset sources_1

reset_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

puts "Bitstream: [file join $d ibert.runs impl_1 ibert_top.bit]"
puts "Probes (if any): [file join $d ibert.runs impl_1 ibert_top.ltx]"
