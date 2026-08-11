#-------------------------------------------------------------------------------
# fullparser.xdc
#
# Timing constraints for the market-data header parser pipeline.
#
# Intended for an OUT-OF-CONTEXT synthesis run on `fullparser` alone, before
# it is wired to a transceiver and MAC. That run answers the one question the
# whole design rests on: does the ITCH framing loop close at 156.25 MHz?
#
#   Vivado:  set the fullparser module to "Out-of-Context per IP/Block",
#            or run:
#              synth_design -top fullparser -part <your-part> -mode out_of_context
#
# 10 Gbps at 64 bits/beat => 156.25 MHz => 6.400 ns
#
# NOTE none of this is part-specific. No pin assignments, no IO standards -
# those belong in the board-level XDC once a part is chosen.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# 1. Clock
#
# For the out-of-context run, clk is a primary input and we define it here.
#
# WHEN YOU INTEGRATE WITH THE MAC: delete this create_clock. The clock will
# come from the transceiver (tx_clk_out / rx_clk_out on the Xilinx 10G/25G
# Ethernet Subsystem) and its own XDC defines it. Defining it twice gives you
# two unrelated clocks and a pile of false failures.
#
# ALSO CONFIRM THE FREQUENCY. 64-bit at 156.25 MHz is the common 10G
# configuration, but some IP configurations present 64-bit data at
# 322.265625 MHz instead. Check what your IP actually produces before
# trusting 6.400 ns.
#-------------------------------------------------------------------------------
create_clock -period 6.400 -name clk [get_ports clk]

# A little uncertainty so the OOC result is not optimistic relative to the
# real design, where the clock arrives through a BUFG from a GT.
set_clock_uncertainty 0.100 [get_clocks clk]

#-------------------------------------------------------------------------------
# 2. IO budget (out-of-context only)
#
# Everything here is register-to-register internally, so the IO constraint
# only decides how much of the period is reserved for whatever sits outside.
# 20% in, 20% out leaves 60% for the parser itself - deliberately pessimistic,
# so if it passes this it will pass in context.
#
# WHEN YOU INTEGRATE: delete this whole section. Real paths to the MAC are
# register-to-register and need no IO delay.
#-------------------------------------------------------------------------------
set clk_period 6.400
set in_budget  [expr {$clk_period * 0.20}]
set out_budget [expr {$clk_period * 0.20}]

set in_ports [get_ports {s_axis_tdata[*] s_axis_tkeep[*] s_axis_tvalid \
                         s_axis_tlast m_axis_tready}]
set out_ports [get_ports {m_axis_tdata[*] m_axis_tkeep[*] m_axis_tvalid \
                          m_axis_tlast s_axis_tready \
                          msg_valid msg_index[*] msg_seqnum[*] msg_type[*] \
                          msg_length[*] msg_fields[*] msg_status[*] \
                          pkt_fields[*] exchange_seconds[*] \
                          pkt_done pkt_msg_count[*] pkt_count_mismatch \
                          eth_fields_valid ipv4_fields_valid \
                          udp_fields_valid mold_fields_valid}]

set_input_delay  -clock clk $in_budget  $in_ports
set_output_delay -clock clk $out_budget $out_ports

#-------------------------------------------------------------------------------
# 3. Reset
#
# resetn is SYNCHRONOUS and active low, so it is a normal timed path and needs
# no exception here.
#
# WHEN YOU INTEGRATE: whatever drives resetn from outside this clock domain
# needs a two-flop synchroniser. Do NOT false_path it - a synchronous reset
# that misses timing releases at different cycles in different parts of the
# pipeline, which is exactly the failure the beat counters cannot survive.
#-------------------------------------------------------------------------------
set_input_delay -clock clk $in_budget [get_ports resetn]

#-------------------------------------------------------------------------------
# 4. Deliberately absent
#
# There are no timing exceptions in this design and there should not be:
#
#   * no clock domain crossings - single clock throughout
#   * no multicycle paths - every path is genuinely single-cycle
#   * no false paths - nothing is asynchronous
#
# If you find yourself wanting to add one, something is wrong. The one place
# it might be tempting is the ITCH framing loop, and a multicycle there would
# silently halve the message rate rather than fix anything.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# 5. What to look at in the timing report
#
# Run after synthesis:
#
#   report_timing_summary -delay_type min_max -max_paths 20
#   report_timing -from [get_cells -hier -filter {NAME =~ *u_itch*rem_r*}] \
#                 -max_paths 10 -sort_by slack
#
# EXPECTED SHAPE OF THE RESULT
#
#   eth / ipv4 / udp / mold   huge slack. These are 3-4 logic levels of
#                             fixed-offset extraction into registers.
#
#   itch framing loop         the real constraint. The worst path should run
#                             from rem_r / phase_r / byte_idx_r through the
#                             unrolled eight-byte chain and back. This loop
#                             CANNOT be pipelined - adding a register stage
#                             inside it halves the message rate. If it fails,
#                             the fix is restructuring (compute all eight
#                             shifted views in parallel, leaving only an adder
#                             and a mux inside the loop), not another stage.
#
#   itch buffer decoder       eight variable-index byte writes into a 64-byte
#                             register file. Large but FEED-FORWARD, so it can
#                             take a pipeline stage if it needs one.
#
#   routing, not logic        523-bit and 512-bit buses crossing module
#                             boundaries. If failures look like high net delay
#                             with few logic levels, that is congestion rather
#                             than depth, and the answer is floorplanning.
#
# WATCH FOR MISLEADING SUCCESS
#
#   Once itch_parser is the last stage, m_axis has no consumer and synthesis
#   will trim the entire passthrough chain, making utilisation and timing look
#   far better than reality. Either keep m_axis driven to a debug port, or
#   check the utilisation report for missing registers before believing it.
#-------------------------------------------------------------------------------
