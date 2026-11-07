# qsfp_ctrl.tcl - helpers for the IBERT + QSFP-control test.
#
# Load once (in the ibert_7series_gth_0_ex project, after it has been built):
#   source C:/Users/lskje/Desktop/FPGA_Orderbook/pin_finder/ibert_7series_gth_0_ex/qsfp_ctrl.tcl
#
# Commands:
#   qsfp <reset> <opt>  set QSFP_RESET (AH13) / SFP_OR_OPT (AC12) to 0/1 and
#                       write ibert_qsfp_r<reset>_o<opt>.bit (no hardware access)
#   prog <reset> <opt>  program that bitstream on the target YOU have open
#                       (never opens Hardware Manager / server / target)
#   prbs                PRBS31 TX+RX on quad 116 (X1Y24..27), then show
#   show                status of quad 116
#   rxpol <0|1>         RX polarity on quad 116, reset RX, show
#   txpol <0|1>         TX polarity on quad 116 (then check the PC)
#
# Reference-design lane map (rugmac.xdc):
#   X1Y24: TX->lane1 RX<-lane3   X1Y25: TX->lane2 RX<-lane4
#   X1Y26: TX->lane3 RX<-lane1   X1Y27: TX->lane4 RX<-lane2

# Never opens Hardware Manager, the hw_server or the target itself.
# Returns the current hw device if one is already open, otherwise "".
proc _hw_dev {} {
  if {[catch {current_hw_device} dev]} { return "" }
  return $dev
}

proc _q116 {} {
  set l {}
  foreach n {24 25 26 27} { lappend l [get_hw_sio_gts -quiet *MGT_X1Y$n] }
  return [join $l]
}

proc qsfp {r o} {
  # implemented design
  if {[llength [get_designs -quiet impl_1]] == 0} { open_run impl_1 } else { current_design impl_1 }
  set rc [get_cells -hier -filter {NAME =~ *qsfp_reset_ff_reg*}]
  set oc [get_cells -hier -filter {NAME =~ *sfp_or_opt_ff_reg*}]
  if {[llength $rc] != 1 || [llength $oc] != 1} { error "control flip-flops not found - was the project rebuilt after the edit?" }
  set_property INIT [expr {$r ? "1'b1" : "1'b0"}] $rc
  set_property INIT [expr {$o ? "1'b1" : "1'b0"}] $oc

  set f [file join [get_property DIRECTORY [current_project]] "ibert_qsfp_r${r}_o${o}.bit"]
  write_bitstream -force $f
  puts "=== written: $f  (QSFP_RESET=$r  SFP_OR_OPT=$o) ==="
  puts "    program it yourself, or with the target already open:  prog $r $o"
}

# Program a qsfp bitstream using the ALREADY-OPEN target (never opens one).
proc prog {r o} {
  set dev [_hw_dev]
  if {$dev eq ""} { error "no hardware target open - open it yourself in Hardware Manager first" }
  set f [file join [get_property DIRECTORY [current_project]] "ibert_qsfp_r${r}_o${o}.bit"]
  if {![file exists $f]} { error "$f not found - run: qsfp $r $o" }
  set_property PROGRAM.FILE $f $dev
  set_property PROBES.FILE {} $dev
  program_hw_devices $dev
  refresh_hw_device $dev
  puts "=== programmed: QSFP_RESET=$r  SFP_OR_OPT=$o ==="
  prbs
}

proc prbs {} {
  set q [_q116]
  if {[llength $q] != 4} { error "quad 116 GTs not found ([llength $q]) - refresh the device" }
  set_property TX_PATTERN {PRBS 31-bit} $q
  set_property RX_PATTERN {PRBS 31-bit} $q
  commit_hw_sio $q
  rxreset
  after 2000
  show
}

proc show {} {
  set q [_q116]
  refresh_hw_sio $q
  foreach gt $q {
    puts [format "%-10s rxpol=%s txpol=%s status=%-9s ber=%s" \
      [get_property DISPLAY_NAME $gt] [get_property PORT.RXPOLARITY $gt] \
      [get_property PORT.TXPOLARITY $gt] [get_property STATUS $gt] [get_property RX_BER $gt]]
  }
}

proc rxreset {} {
  set q [_q116]
  set_property PORT.GTRXRESET 1 $q; commit_hw_sio $q
  set_property PORT.GTRXRESET 0 $q; commit_hw_sio $q
  after 500
  set_property LOGIC.MGT_ERRCNT_RESET_CTRL 1 $q; commit_hw_sio $q
  set_property LOGIC.MGT_ERRCNT_RESET_CTRL 0 $q; commit_hw_sio $q
}

proc rxpol {p} {
  set q [_q116]
  set_property PORT.RXPOLARITY $p $q; commit_hw_sio $q
  rxreset; after 2000
  puts "=== RXPOLARITY $p ==="
  show
}

proc txpol {p} {
  set q [_q116]
  set_property PORT.TXPOLARITY $p $q; commit_hw_sio $q
  puts "=== TXPOLARITY $p - now run on the PC:  mlxlink -d mt4119_pciconf0 -p 1 -c ==="
}

puts "qsfp_ctrl loaded: qsfp <reset> <opt> | prog <reset> <opt> | prbs | show | rxpol <0|1> | txpol <0|1>"
