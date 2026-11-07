# orderbook_ila.tcl - ILA on market_data_top: every valid signal + the whole
#                     itch_parser interface (NO RTL changes)
#
# Run in the Vivado Tcl Console with the OrderBook project open:
#   source C:/Users/lskje/Desktop/FPGA_Orderbook/OrderBook/orderbook_ila.tcl
#
# What it does (project settings and constraints only - never touches RTL or hardware):
#   1. writes constrs_1/new/debug_valids.xdc
#        MARK_DEBUG on every signal below, DONT_TOUCH on the registers whose
#        outputs the RTL leaves open (so synthesis keeps them)
#   2. sets top.bd to global synthesis (synth_checkpoint_mode None)
#   3. runs synth_1, opens it and finds each signal. A signal can be given as
#      several names (a|b|c): the first one synthesis kept is used, by
#        net name -> register output (<name>_reg Q) -> hierarchical port pin
#   4. creates ILA "u_ila_valids" (depth 4096) and saves it to
#      constrs_1/new/debug_ila.xdc (implementation only)
#   5. writes OrderBook/ila_probe_map.txt (probe number -> signal)
#   6. launches impl_1 to write_bitstream
#
# Safe to re-run: debug_ila.xdc is emptied first, so you always get one fresh ILA.
#
# Signal entry formats (paths relative to market_data_top):
#   {path}                  1 bit
#   {path lo hi}            bits lo..hi
#   {path lo hi label}      bits lo..hi, shown with <label> in the probe map
# Entries starting with "--" are section headings.

set M top_i/market_data_top_0/*

set I u_fullparser/u_itch

set sigs [list \
  {-- Input stage} \
  {u_input/u_axis/h_v} \
  {p_tvalid|u_fullparser/s_axis_tvalid|u_input/u_axis/o_v} \
  {u_input/crc_done} \
  {u_input/u_extend/res_v} \
  {u_input/u_extend/cnt_v} \
  {mold_cnt_v} \
  {fcs_complete_i} \
  {fcs_true_i} \
  {fcs_false_i} \
  \
  {-- Parser stages: master tvalid + m_fields_valid} \
  {u_fullparser/e_tvalid} \
  {u_fullparser/e_fvalid|u_fullparser/u_eth/fields_valid_r} \
  {u_fullparser/i_tvalid} \
  {u_fullparser/i_fvalid|u_fullparser/u_ipv4/fields_valid_r} \
  {u_fullparser/u_ipv4/ihl_invalid_r} \
  {u_fullparser/u_ipv4/ver_invalid_r} \
  {u_fullparser/u_tvalid} \
  {u_fullparser/u_fvalid|u_fullparser/u_udp/fields_valid_r} \
  {u_fullparser/u_udp/len_invalid_r} \
  {u_fullparser/d_tvalid} \
  {eng_valid} \
  \
  {-- ITCH slave AXI-Stream (s_axis_tready is tied '1' in the RTL - nothing to probe)} \
  "$I/s_axis_tvalid|u_fullparser/d_tvalid" \
  "$I/s_axis_tlast|u_fullparser/d_tlast" \
  "$I/s_axis_tkeep|u_fullparser/d_tkeep 0 7" \
  "$I/s_axis_tdata|u_fullparser/d_tdata 0 63" \
  \
  {-- ITCH internal: window / framing valids} \
  "$I/adv_c" \
  "$I/flush_r" \
  "$I/fv_valid" \
  "$I/k1_last" \
  "$I/fv_last" \
  "$I/fv_keep 0 7" \
  "$I/active_r" \
  "$I/armed_r" \
  "$I/pay_arm_c" \
  "$I/rem_r 0 6" \
  "$I/lane_r 0 2" \
  "$I/fl_typ_r 0 7" \
  "$I/fl_scope_r" \
  "$I/fl_lenok_r" \
  "$I/t0_hit_r" \
  "$I/tb_scope 0 7" \
  "$I/tb_ist 0 7" \
  "$I/tb_lenok 0 7" \
  "$I/tb_two 0 7" \
  \
  {-- ITCH internal: retire decisions (combinational - see note on timing)} \
  "$I/start_ok_c" \
  "$I/end_ok_c" \
  "$I/surv_ok_c" \
  "$I/first_ok_c" \
  "$I/load_c" \
  "$I/ret_norm_c" \
  "$I/ret_tail_c" \
  "$I/retire_c" \
  \
  {-- ITCH master: message bus (the itch parser has no AXI master)} \
  "$I/msg_valid|$I/msg_valid_r" \
  "$I/msg_type|$I/msg_type_r 0 7" \
  "$I/msg_fields|$I/msg_fields_r 0 31 msg_fields.ts_ns" \
  "$I/msg_fields|$I/msg_fields_r 32 95 msg_fields.order_id" \
  "$I/msg_fields|$I/msg_fields_r 96 127 msg_fields.book_id" \
  "$I/msg_fields|$I/msg_fields_r 128 135 msg_fields.side" \
  "$I/msg_fields|$I/msg_fields_r 136 167 msg_fields.position" \
  "$I/msg_fields|$I/msg_fields_r 168 231 msg_fields.qty" \
  "$I/msg_fields|$I/msg_fields_r 232 263 msg_fields.price" \
  "$I/msg_fields|$I/msg_fields_r 264 279 msg_fields.extype" \
  "$I/msg_fields|$I/msg_fields_r 280 287 msg_fields.lot" \
  "$I/msg_index|$I/msg_index_r 0 15" \
  "$I/msg_seqnum|$I/msg_seq_r 0 63" \
  "$I/msg_length|$I/msg_len_r 0 15" \
  "$I/msg_status|$I/msg_stat_r 0 5" \
  "$I/exchange_seconds|$I/seconds_r 0 31" \
  "$I/pkt_done|$I/pkt_done_r" \
  "$I/pkt_msg_count|$I/pkt_count_r 0 15" \
  \
  {-- Engine} \
  {u_engine/in_tvalid} \
  {u_engine/in_px_valid} \
  {u_engine/u_book_input_stage/r_tvalid} \
  {u_engine/cmd_tvalid} \
  {u_engine/cmd_px_valid} \
  {u_engine/mut_tvalid} \
  {u_engine/price_ev_valid} \
  {u_engine/order_ev_valid|u_engine/ob_ts_en|u_engine/u_order_book/ts_en} \
  {u_engine/fifo_ev_valid|u_engine/fifo_ts_en|u_engine/u_order_fifo/ts_en} \
  {u_engine/u_time_event_fifo/any_v} \
  {u_engine/u_time_event_fifo/out_v} \
  {m_tvalid|u_engine/m_tvalid} \
  {m_valid|u_engine/m_valid 0 1} \
  {ev_valid_i} \
  {ev_ready_i} \
]

# Registers whose outputs the RTL leaves unconnected ("=> open"): without
# DONT_TOUCH synthesis deletes them and there is nothing to probe.
set keep_cells {
  u_fullparser/u_eth/fields_valid_r_reg
  u_fullparser/u_ipv4/fields_valid_r_reg
  u_fullparser/u_udp/fields_valid_r_reg
  u_fullparser/u_itch/msg_index_r_reg*
  u_fullparser/u_itch/msg_seq_r_reg*
  u_fullparser/u_itch/msg_len_r_reg*
  u_fullparser/u_itch/seconds_r_reg*
}

set ila      u_ila_valids
set depth    4096
set pdir     [get_property DIRECTORY [current_project]]
set cdir     $pdir/OrderBook.srcs/constrs_1/new
set mark_xdc $cdir/debug_valids.xdc
set ila_xdc  $cdir/debug_ila.xdc
set map_txt  $pdir/ila_probe_map.txt

# ---------------------------------------------------------------- helpers
proc _parse {e} {
  # -> {alts lo hi label}; lo = "" for a 1-bit signal
  set alts [split [lindex $e 0] |]
  if {[llength $e] >= 3} {
    set lo [lindex $e 1]; set hi [lindex $e 2]
    set label [expr {[llength $e] >= 4 ? [lindex $e 3] : "[lindex $alts 0]\[$hi:$lo\]"}]
  } else {
    set lo ""; set hi ""; set label [lindex $alts 0]
  }
  return [list $alts $lo $hi $label]
}

proc _is_const {n} {
  if {[get_property TYPE $n] in {GROUND POWER}} { return 1 }
  foreach d [get_pins -quiet -leaf -of_objects $n -filter {DIRECTION == OUT}] {
    if {[get_property REF_NAME [get_cells -of_objects $d]] in {GND VCC}} { return 1 }
  }
  return 0
}

# one bit of one candidate name -> net (or "")
proc _bit {U path b} {
  set s [expr {$b eq "" ? "" : "\[$b\]"}]
  set n [get_nets -quiet "$U/$path$s"]
  if {[llength $n]} { set n [lindex $n 0]; if {![_is_const $n]} { return $n }; return "" }
  set c [get_cells -quiet "$U/${path}_reg$s"]
  if {[llength $c]} {
    set q [get_pins -quiet -of_objects [lindex $c 0] -filter {REF_PIN_NAME == Q}]
    if {[llength $q]} { set n [get_nets -quiet -of_objects $q]
      if {[llength $n] && ![_is_const $n]} { return [lindex $n 0] } }
  }
  set p [get_pins -quiet "$U/$path$s"]
  if {[llength $p]} { set n [get_nets -quiet -of_objects $p]
    if {[llength $n] && ![_is_const [lindex $n 0]]} { return [lindex $n 0] } }
  return ""
}

# ---------------------------------------------------------------- 1. constraints
file mkdir $cdir
set fh [open $mark_xdc w]
puts $fh "## generated by orderbook_ila.tcl - keep debug signals through synthesis"
puts $fh "## (edit the lists in orderbook_ila.tcl, not this file)"
set seen [dict create]
foreach e $sigs {
  if {[string match --* $e]} continue
  lassign [_parse $e] alts lo hi label
  foreach a $alts {
    set pat [expr {$lo eq "" ? "$M/$a" : "$M/$a\[*\]"}]
    if {[dict exists $seen $pat]} continue
    dict set seen $pat 1
    puts $fh "set_property MARK_DEBUG true \[get_nets -quiet {$pat}\]"
  }
}
foreach c $keep_cells {
  puts $fh "set_property DONT_TOUCH true \[get_cells -quiet {$M/$c}\]"
}
close $fh
close [open $ila_xdc w]      ;# start with no ILA

foreach f [list $mark_xdc $ila_xdc] {
  if {![llength [get_files -quiet $f]]} { add_files -fileset constrs_1 -norecurse $f }
}
set_property used_in_synthesis      true  [get_files $mark_xdc]
set_property used_in_implementation true  [get_files $mark_xdc]
set_property used_in_synthesis      false [get_files $ila_xdc]
set_property used_in_implementation true  [get_files $ila_xdc]

# ---------------------------------------------------------------- 2. block design
set bd [get_files top.bd]
if {[get_property synth_checkpoint_mode $bd] ne "None"} {
  puts "=== top.bd: synth_checkpoint_mode [get_property synth_checkpoint_mode $bd] -> None"
  set_property synth_checkpoint_mode None $bd
  generate_target all $bd
}

# ---------------------------------------------------------------- 3. synthesis
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} {
  error "synth_1 failed - see the Messages tab"
}
open_run synth_1 -name synth_1

# market_data_top instance (U0 for packaged IP, inst for a module reference)
set U ""
foreach w {U0 inst} {
  if {[llength [get_cells -quiet top_i/market_data_top_0/$w]]} { set U top_i/market_data_top_0/$w; break }
}
if {$U eq ""} {
  puts "cells under top_i/market_data_top_0:"
  foreach c [get_cells -quiet top_i/market_data_top_0/*] { puts "  $c" }
  error "market_data_top instance not found - send me the list above"
}

set probes  {}     ;# {label nets via section}
set missing {}
set partial {}
set dups    {}
set used    [dict create]     ;# flat net -> label, for 1-bit duplicates
set section ""
foreach e $sigs {
  if {[string match --* $e]} { set section [string trim [string range $e 2 end]]; continue }
  lassign [_parse $e] alts lo hi label
  set bits {}
  if {$lo eq ""} { set bits [list ""] } else { for {set b $lo} {$b <= $hi} {incr b} { lappend bits $b } }

  # take the candidate name that resolves the most bits
  set best {}; set best_alt ""
  foreach a $alts {
    set nets {}
    foreach b $bits { set n [_bit $U $a $b]; if {$n ne ""} { lappend nets $n } }
    if {[llength $nets] > [llength $best]} { set best $nets; set best_alt $a }
    if {[llength $best] == [llength $bits]} break
  }
  if {![llength $best]} { lappend missing $label; continue }
  if {[llength $best] < [llength $bits]} {
    lappend partial "$label: [llength $best] of [llength $bits] bits (rest constant or removed)"
  }
  if {[llength $bits] == 1} {
    set flat [get_property PARENT $best]
    if {[dict exists $used $flat]} { lappend dups "$label = [dict get $used $flat]"; continue }
    dict set used $flat $label
  }
  lappend probes [list $label $best $best_alt $section]
}
if {![llength $probes]} { error "none of the signals were found" }

# ILA clock = clock pin of the first flip-flop driving one of the probes
set clk_net ""
foreach pr $probes {
  foreach n [lindex $pr 1] {
    foreach d [get_pins -quiet -leaf -of_objects [get_nets $n] -filter {DIRECTION == OUT}] {
      set c [get_cells -of_objects $d]
      if {[string match FD* [get_property REF_NAME $c]]} {
        set clk_net [get_nets -of_objects [get_pins $c/C]]
        break
      }
    }
    if {$clk_net ne ""} break
  }
  if {$clk_net ne ""} break
}
if {$clk_net eq ""} {
  set clk_net [get_nets -of_objects [get_pins top_i/ten_gig_eth_pcs_pma_0/coreclk_out]]
}

# ---------------------------------------------------------------- 4. ILA
create_debug_core $ila ila
set core [get_debug_cores $ila]
set_property C_DATA_DEPTH          $depth $core
set_property C_TRIGIN_EN           false  $core
set_property C_TRIGOUT_EN          false  $core
set_property C_INPUT_PIPE_STAGES   1      $core
set_property C_ADV_TRIGGER         false  $core
set_property C_EN_STRG_QUAL        true   $core
set_property ALL_PROBE_SAME_MU     true   $core
set_property ALL_PROBE_SAME_MU_CNT 2      $core

set_property port_width 1 [get_debug_ports $ila/clk]
connect_debug_port $ila/clk $clk_net

set i 0
set total 0
foreach pr $probes {
  set nets [lindex $pr 1]
  if {$i > 0} { create_debug_port $ila probe }
  set p [get_debug_ports $ila/probe$i]
  set_property port_width [llength $nets] $p
  set_property PROBE_TYPE DATA_AND_TRIGGER $p
  connect_debug_port $p [get_nets $nets]
  incr i
  incr total [llength $nets]
}

if {[llength [get_debug_cores -quiet dbg_hub]]} {
  set_property C_CLK_INPUT_FREQ_HZ   300000000 [get_debug_cores dbg_hub]
  set_property C_ENABLE_CLK_DIVIDER  false     [get_debug_cores dbg_hub]
  set_property C_USER_SCAN_CHAIN     1         [get_debug_cores dbg_hub]
  connect_debug_port dbg_hub/clk $clk_net
}

# save the ILA into debug_ila.xdc (not orderbook.xdc)
set cs [get_filesets constrs_1]
set old_target [get_property target_constrs_file $cs]
set_property target_constrs_file $ila_xdc $cs
save_constraints
set_property target_constrs_file $old_target $cs

# ---------------------------------------------------------------- 5. report
set clk_name [get_clocks -quiet -of_objects $clk_net]
set out {}
lappend out "ILA $ila   clock: $clk_net ($clk_name)   depth: $depth   $total bits in [llength $probes] probes"
lappend out "Probe names in Hardware Manager are the net names in the right-hand column."
set i 0
set last ""
foreach pr $probes {
  lassign $pr label nets alt section
  if {$section ne $last} { lappend out ""; lappend out "== $section"; set last $section }
  set w [llength $nets]
  set nm [lindex $nets 0]
  if {$w > 1} { regsub {\[[0-9]+\]$} $nm "" nm; set nm "$nm\[[expr {$w-1}]:0\]" }
  lappend out [format "  probe%-3d %-34s %3d  %s" $i $label $w $nm]
  incr i
}
if {[llength $dups]} {
  lappend out ""; lappend out "== Same wire as a probe above (not added twice)"
  foreach d $dups { lappend out "  $d" }
}
if {[llength $partial]} {
  lappend out ""; lappend out "== Partly found"
  foreach d $partial { lappend out "  $d" }
}
if {[llength $missing]} {
  lappend out ""; lappend out "== NOT FOUND (not in the ILA - send me these names)"
  foreach d $missing { lappend out "  $d" }
}
set fh [open $map_txt w]; puts $fh [join $out \n]; close $fh
puts ""; puts [join $out \n]; puts ""
puts "=== probe map saved to $map_txt"

close_design

# ---------------------------------------------------------------- 6. implementation
launch_runs impl_1 -to_step write_bitstream -jobs 4
puts "=== impl_1 launched. Program with impl_1/top_wrapper.bit + top_wrapper.ltx ==="
