# orderbook_ila.tcl - ILA on the main pipeline valids (input, parser, engine)
#                     and the transmit path into 10G core A     (NO RTL changes)
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
#        register output (<name>_reg Q) -> net name -> hierarchical port pin
#   4. creates ILA "u_ila_tx" (depth 4096) and saves it to
#      constrs_1/new/debug_ila.xdc (implementation only)
#   5. writes OrderBook/ila_probe_map.txt (probe number -> signal)
#   6. launches impl_1 to write_bitstream
#
# Safe to re-run: debug_ila.xdc is emptied first, so you always get one fresh ILA.
#
# Signal entry formats (paths relative to market_data_top):
#   {path}                      1 bit
#   {path lo hi}                bits lo..hi
#   {path lo hi label}          bits lo..hi, shown with <label> in the probe map
#   {path lo hi label idx}      element idx of an array of vectors: path(idx)(lo..hi)
# Entries starting with "--" are section headings.

set M top_i/market_data_top_0/*

set T u_tx/u_order_tx_xgmii

set sigs [list \
  {-- Pipeline valids: input -> parser -> engine} \
  "p_tvalid|u_fullparser/s_axis_tvalid" \
  "fcs_true_i" \
  "fcs_false_i" \
  "u_fullparser/e_tvalid" \
  "u_fullparser/i_tvalid" \
  "u_fullparser/u_tvalid" \
  "u_fullparser/d_tvalid" \
  "eng_valid|u_engine/s_valid" \
  "u_engine/in_tvalid|u_engine/input_ev_valid" \
  "u_engine/cmd_tvalid" \
  "u_engine/cmd_tready" \
  "u_engine/mut_tvalid" \
  "u_engine/lvl_we|u_engine/price_ev_valid" \
  "u_engine/fifo_full|fifo_full" \
  \
  {-- TX slave (from the engine's event FIFO)} \
  "u_tx/s_valid|ev_valid_i|$T/s_axis_tvalid" \
  "u_tx/s_ready|ev_ready_i|$T/ready_r|$T/s_axis_tready" \
  "u_tx/s_payload|ev_payload_i|$T/s_axis_tdata 0 86 s_payload" \
  \
  {-- TX framer state (order_tx_xgmii)} \
  "$T/FSM_onehot_state|$T/FSM_sequential_state|$T/state 0 3 tx_state" \
  "$T/idx 0 2 tx_idx" \
  "$T/gap_cnt 0 1 tx_gap_cnt" \
  "$T/payload_r 0 86 tx_payload_r" \
  "$T/crc 0 31 tx_crc" \
  \
  {-- XGMII master (into 10G core A)} \
  "$T/txc_r|u_tx/xgmii_txc|xgmii_txc 0 7 xgmii_txc" \
  "$T/txd_r|u_tx/xgmii_txd|xgmii_txd 0 63 xgmii_txd" \
]

# no DONT_TOUCH needed: everything above drives the 10G core
set keep_cells {}

set ila      u_ila_tx
set depth    4096
set pdir     [get_property DIRECTORY [current_project]]
set cdir     $pdir/OrderBook.srcs/constrs_1/new
set mark_xdc $cdir/debug_valids.xdc
set ila_xdc  $cdir/debug_ila.xdc
set map_txt  $pdir/ila_probe_map.txt

# ---------------------------------------------------------------- helpers
proc _parse {e} {
  # -> {alts lo hi label idx}; lo = "" for a 1-bit signal, idx = "" unless an array element
  set alts [split [lindex $e 0] |]
  set idx ""
  if {[llength $e] >= 3} {
    set lo [lindex $e 1]; set hi [lindex $e 2]
    set label [expr {[llength $e] >= 4 ? [lindex $e 3] : "[lindex $alts 0]\[$hi:$lo\]"}]
    if {[llength $e] >= 5} { set idx [lindex $e 4] }
  } else {
    set lo ""; set hi ""; set label [lindex $alts 0]
  }
  return [list $alts $lo $hi $label $idx]
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

  # 1. register output by the flop's Q pin. Synthesis often puts the HDL
  #    name on the next-state or enable net and renames the real Q net
  #    <name>_reg_n_0_, so a net-name match can probe the wrong wire.
  set c [get_cells -quiet "$U/${path}_reg$s"]
  if {[llength $c]} {
    set q [get_pins -quiet -of_objects [lindex $c 0] -filter {REF_PIN_NAME == Q}]
    if {[llength $q]} {
      set n [get_nets -quiet -of_objects $q]
      if {[llength $n] && ![_is_const [lindex $n 0]]} { return [lindex $n 0] }
    }
    return ""
  }

  # 2. other bits of this register exist but this flop was optimised away:
  #    the bit is constant. Don't substitute a same-named net.
  if {[llength [get_cells -quiet "$U/${path}_reg*"]]} { return "" }

  # 3. wire or port, by net name
  set n [get_nets -quiet "$U/$path$s"]
  if {[llength $n]} { set n [lindex $n 0]; if {![_is_const $n]} { return $n }; return "" }

  # 4. hierarchical port pin
  set p [get_pins -quiet "$U/$path$s"]
  if {[llength $p]} { set n [get_nets -quiet -of_objects $p]
    if {[llength $n] && ![_is_const [lindex $n 0]]} { return [lindex $n 0] } }
  return ""
}

# Re-use the existing synthesis (skip steps 1-3) with:
#   set skip_synth 1; source .../orderbook_ila.tcl
# Only valid if the signal list has not changed since synth_1 ran.
set _skip [expr {[info exists ::skip_synth] && $::skip_synth}]
catch {unset ::skip_synth}

# ---------------------------------------------------------------- 1. constraints
file mkdir $cdir
if {!$_skip} {
  set fh [open $mark_xdc w]
  puts $fh "## generated by orderbook_ila.tcl - keep debug signals through synthesis"
  puts $fh "## (edit the lists in orderbook_ila.tcl, not this file)"
  set seen [dict create]
  foreach e $sigs {
    if {[string match --* $e]} continue
    lassign [_parse $e] alts lo hi label idx
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
}
close [open $ila_xdc w]      ;# start with no ILA (implementation-only file)

foreach f [list $mark_xdc $ila_xdc] {
  if {![llength [get_files -quiet $f]]} { add_files -fileset constrs_1 -norecurse $f }
}
if {!$_skip} {
  set_property used_in_synthesis      true  [get_files $mark_xdc]
  set_property used_in_implementation true  [get_files $mark_xdc]
}
set_property used_in_synthesis      false [get_files $ila_xdc]
set_property used_in_implementation true  [get_files $ila_xdc]

if {!$_skip} {
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
  # wait_on_run can return an error for unrelated reasons (e.g. Hardware
  # Manager losing its target while waiting); judge synthesis by its own result.
  if {[catch {wait_on_run synth_1} werr]} {
    puts "=== wait_on_run reported: $werr  - checking synth_1 itself"
    while {[get_property STATUS [get_runs synth_1]] ni {"synth_design Complete!" "synth_design ERROR"}
           && ![string match "*ERROR*" [get_property STATUS [get_runs synth_1]]]
           && [get_property PROGRESS [get_runs synth_1]] ne "100%"} {
      after 10000
    }
  }
} else {
  puts "=== skip_synth: re-using the existing synth_1 result"
}
if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} {
  error "synth_1 is not complete ([get_property STATUS [get_runs synth_1]]) - see the Messages tab"
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
  lassign [_parse $e] alts lo hi label idx
  set bits {}
  if {$lo eq ""} {
    set bits [list ""]
  } elseif {$idx eq ""} {
    for {set b $lo} {$b <= $hi} {incr b} { lappend bits $b }
  } else {
    # array element: name[idx][bit]
    for {set b $lo} {$b <= $hi} {incr b} { lappend bits "$idx\]\[$b" }
  }

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
  set_property C_CLK_INPUT_FREQ_HZ   156250000 [get_debug_cores dbg_hub]
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
  if {$w > 1 && [regexp {^(.*)\[([0-9]+)\]$} $nm -> base lo_i]
             && [regexp {\[([0-9]+)\]$} [lindex $nets end] -> hi_i]} {
    set nm "$base\[$hi_i:$lo_i\]"
  }
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
reset_run impl_1
launch_runs impl_1 -to_step write_bitstream -jobs 4
puts "=== impl_1 launched. Program with impl_1/top_wrapper.bit + top_wrapper.ltx ==="
