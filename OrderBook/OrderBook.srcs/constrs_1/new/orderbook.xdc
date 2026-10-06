#-------------------------------------------------------------------------------
# order_book_engine_top.xdc
#
# Clock only. No pin or I/O standard constraints: the top has a 512-bit slave
# data bus and will not fit a package, so synthesise out of context.
#
#   synth_design -top order_book_engine_top -part <part> -mode out_of_context
#-------------------------------------------------------------------------------

create_clock -name clk -period 6.210 -waveform {0.000 3.105} [get_ports clk]
