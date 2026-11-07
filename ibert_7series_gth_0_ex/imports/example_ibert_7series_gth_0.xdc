# file: ibert_7series_gth_0.xdc
####################################################################################
##**************************************************************************

##
## System clock Divider paramter values
##
set_property CLKFBOUT_MULT_F 10.000 [get_cells u_ibert_core/inst/SYSCLK_DIVIDER.U_GT_MMCM]
set_property DIVCLK_DIVIDE 1 [get_cells u_ibert_core/inst/SYSCLK_DIVIDER.U_GT_MMCM]
set_property CLKIN1_PERIOD 10.0 [get_cells u_ibert_core/inst/SYSCLK_DIVIDER.U_GT_MMCM]
set_property CLKOUT0_DIVIDE_F 10.000 [get_cells u_ibert_core/inst/SYSCLK_DIVIDER.U_GT_MMCM]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_pins u_ibert_core/inst/SYSCLK_DIVIDER.U_GT_MMCM/CLKIN1]

##
## Icon Constraints
##
create_clock -name J_CLK -period 30 [get_pins -of_objects [get_cells u_ibert_core/inst/bscan_inst/SERIES7_BSCAN.bscan_inst] -filter {name =~ *DRCK}]
create_clock -name U_CLK -period 30 [get_pins -of_objects [get_cells u_ibert_core/inst/bscan_inst/SERIES7_BSCAN.bscan_inst] -filter {name =~ *UPDATE}]
create_clock -name D_CLK -period 10.0 [get_ports SYSCLKP_I]
set_clock_groups -group [get_clocks D_CLK] -asynchronous 
set_clock_groups -group [get_clocks J_CLK] -asynchronous
set_clock_groups -group [get_clocks U_CLK] -asynchronous

##
## Clock Constraints for MGT refclk
##
create_clock -name REFCLK0_0 -period 6.4 [get_ports GTREFCLK0P_I[0]]
set_clock_groups -group [get_clocks -include_generated_clocks REFCLK0_0] -asynchronous
create_clock -name REFCLK0_1 -period 6.4 [get_ports GTREFCLK1P_I[0]]
set_clock_groups -group [get_clocks -include_generated_clocks REFCLK0_1] -asynchronous
create_clock -name REFCLK1_0 -period 6.4 [get_ports GTREFCLK0P_I[1]]
set_clock_groups -group [get_clocks -include_generated_clocks REFCLK1_0] -asynchronous
create_clock -name REFCLK1_1 -period 6.4 [get_ports GTREFCLK1P_I[1]]
set_clock_groups -group [get_clocks -include_generated_clocks REFCLK1_1] -asynchronous
create_clock -name REFCLK2_0 -period 6.4 [get_ports GTREFCLK0P_I[2]]
set_clock_groups -group [get_clocks -include_generated_clocks REFCLK2_0] -asynchronous
create_clock -name REFCLK2_1 -period 6.4 [get_ports GTREFCLK1P_I[2]]
set_clock_groups -group [get_clocks -include_generated_clocks REFCLK2_1] -asynchronous
create_clock -name REFCLK3_0 -period 6.4 [get_ports GTREFCLK0P_I[3]]
set_clock_groups -group [get_clocks -include_generated_clocks REFCLK3_0] -asynchronous
create_clock -name REFCLK3_1 -period 6.4 [get_ports GTREFCLK1P_I[3]]
set_clock_groups -group [get_clocks -include_generated_clocks REFCLK3_1] -asynchronous
create_clock -name REFCLK4_0 -period 6.4 [get_ports GTREFCLK0P_I[4]]
set_clock_groups -group [get_clocks -include_generated_clocks REFCLK4_0] -asynchronous
create_clock -name REFCLK4_1 -period 6.4 [get_ports GTREFCLK1P_I[4]]
set_clock_groups -group [get_clocks -include_generated_clocks REFCLK4_1] -asynchronous

##
## TX/RX out clock constraints
##
# GT X1Y16
create_clock -name Q16_RXCLK0 -period 3.103 [get_pins {u_ibert_core/inst/QUAD[0].u_q/CH[0].u_ch/u_gthe2_channel/RXOUTCLK}]
set_clock_groups -group [get_clocks Q16_RXCLK0] -asynchronous
create_clock -name  Q16_TX0 -period 3.103 [get_pins {u_ibert_core/inst/QUAD[0].u_q/CH[0].u_ch/u_gthe2_channel/TXOUTCLK}]
set_clock_groups -group [get_clocks Q16_TX0] -asynchronous
# GT X1Y17
create_clock -name Q16_RXCLK1 -period 3.103 [get_pins {u_ibert_core/inst/QUAD[0].u_q/CH[1].u_ch/u_gthe2_channel/RXOUTCLK}]
set_clock_groups -group [get_clocks Q16_RXCLK1] -asynchronous
# GT X1Y18
create_clock -name Q16_RXCLK2 -period 3.103 [get_pins {u_ibert_core/inst/QUAD[0].u_q/CH[2].u_ch/u_gthe2_channel/RXOUTCLK}]
set_clock_groups -group [get_clocks Q16_RXCLK2] -asynchronous
# GT X1Y19
create_clock -name Q16_RXCLK3 -period 3.103 [get_pins {u_ibert_core/inst/QUAD[0].u_q/CH[3].u_ch/u_gthe2_channel/RXOUTCLK}]
set_clock_groups -group [get_clocks Q16_RXCLK3] -asynchronous
# GT X1Y20
create_clock -name Q17_RXCLK0 -period 3.103 [get_pins {u_ibert_core/inst/QUAD[1].u_q/CH[0].u_ch/u_gthe2_channel/RXOUTCLK}]
set_clock_groups -group [get_clocks Q17_RXCLK0] -asynchronous
create_clock -name  Q17_TX0 -period 3.103 [get_pins {u_ibert_core/inst/QUAD[1].u_q/CH[0].u_ch/u_gthe2_channel/TXOUTCLK}]
set_clock_groups -group [get_clocks Q17_TX0] -asynchronous
# GT X1Y21
create_clock -name Q17_RXCLK1 -period 3.103 [get_pins {u_ibert_core/inst/QUAD[1].u_q/CH[1].u_ch/u_gthe2_channel/RXOUTCLK}]
set_clock_groups -group [get_clocks Q17_RXCLK1] -asynchronous
# GT X1Y22
create_clock -name Q17_RXCLK2 -period 3.103 [get_pins {u_ibert_core/inst/QUAD[1].u_q/CH[2].u_ch/u_gthe2_channel/RXOUTCLK}]
set_clock_groups -group [get_clocks Q17_RXCLK2] -asynchronous
# GT X1Y23
create_clock -name Q17_RXCLK3 -period 3.103 [get_pins {u_ibert_core/inst/QUAD[1].u_q/CH[3].u_ch/u_gthe2_channel/RXOUTCLK}]
set_clock_groups -group [get_clocks Q17_RXCLK3] -asynchronous
# GT X1Y24
create_clock -name Q18_RXCLK0 -period 3.103 [get_pins {u_ibert_core/inst/QUAD[2].u_q/CH[0].u_ch/u_gthe2_channel/RXOUTCLK}]
set_clock_groups -group [get_clocks Q18_RXCLK0] -asynchronous
create_clock -name  Q18_TX0 -period 3.103 [get_pins {u_ibert_core/inst/QUAD[2].u_q/CH[0].u_ch/u_gthe2_channel/TXOUTCLK}]
set_clock_groups -group [get_clocks Q18_TX0] -asynchronous
# GT X1Y25
create_clock -name Q18_RXCLK1 -period 3.103 [get_pins {u_ibert_core/inst/QUAD[2].u_q/CH[1].u_ch/u_gthe2_channel/RXOUTCLK}]
set_clock_groups -group [get_clocks Q18_RXCLK1] -asynchronous
# GT X1Y26
create_clock -name Q18_RXCLK2 -period 3.103 [get_pins {u_ibert_core/inst/QUAD[2].u_q/CH[2].u_ch/u_gthe2_channel/RXOUTCLK}]
set_clock_groups -group [get_clocks Q18_RXCLK2] -asynchronous
# GT X1Y27
create_clock -name Q18_RXCLK3 -period 3.103 [get_pins {u_ibert_core/inst/QUAD[2].u_q/CH[3].u_ch/u_gthe2_channel/RXOUTCLK}]
set_clock_groups -group [get_clocks Q18_RXCLK3] -asynchronous
# GT X1Y28
create_clock -name Q19_RXCLK0 -period 3.103 [get_pins {u_ibert_core/inst/QUAD[3].u_q/CH[0].u_ch/u_gthe2_channel/RXOUTCLK}]
set_clock_groups -group [get_clocks Q19_RXCLK0] -asynchronous
create_clock -name  Q19_TX0 -period 3.103 [get_pins {u_ibert_core/inst/QUAD[3].u_q/CH[0].u_ch/u_gthe2_channel/TXOUTCLK}]
set_clock_groups -group [get_clocks Q19_TX0] -asynchronous
# GT X1Y29
create_clock -name Q19_RXCLK1 -period 3.103 [get_pins {u_ibert_core/inst/QUAD[3].u_q/CH[1].u_ch/u_gthe2_channel/RXOUTCLK}]
set_clock_groups -group [get_clocks Q19_RXCLK1] -asynchronous
# GT X1Y30
create_clock -name Q19_RXCLK2 -period 3.103 [get_pins {u_ibert_core/inst/QUAD[3].u_q/CH[2].u_ch/u_gthe2_channel/RXOUTCLK}]
set_clock_groups -group [get_clocks Q19_RXCLK2] -asynchronous
# GT X1Y31
create_clock -name Q19_RXCLK3 -period 3.103 [get_pins {u_ibert_core/inst/QUAD[3].u_q/CH[3].u_ch/u_gthe2_channel/RXOUTCLK}]
set_clock_groups -group [get_clocks Q19_RXCLK3] -asynchronous
# GT X1Y32
create_clock -name Q20_RXCLK0 -period 3.103 [get_pins {u_ibert_core/inst/QUAD[4].u_q/CH[0].u_ch/u_gthe2_channel/RXOUTCLK}]
set_clock_groups -group [get_clocks Q20_RXCLK0] -asynchronous
create_clock -name  Q20_TX0 -period 3.103 [get_pins {u_ibert_core/inst/QUAD[4].u_q/CH[0].u_ch/u_gthe2_channel/TXOUTCLK}]
set_clock_groups -group [get_clocks Q20_TX0] -asynchronous
# GT X1Y33
create_clock -name Q20_RXCLK1 -period 3.103 [get_pins {u_ibert_core/inst/QUAD[4].u_q/CH[1].u_ch/u_gthe2_channel/RXOUTCLK}]
set_clock_groups -group [get_clocks Q20_RXCLK1] -asynchronous
# GT X1Y34
create_clock -name Q20_RXCLK2 -period 3.103 [get_pins {u_ibert_core/inst/QUAD[4].u_q/CH[2].u_ch/u_gthe2_channel/RXOUTCLK}]
set_clock_groups -group [get_clocks Q20_RXCLK2] -asynchronous
# GT X1Y35
create_clock -name Q20_RXCLK3 -period 3.103 [get_pins {u_ibert_core/inst/QUAD[4].u_q/CH[3].u_ch/u_gthe2_channel/RXOUTCLK}]
set_clock_groups -group [get_clocks Q20_RXCLK3] -asynchronous

##
## System clock pin locs and timing constraints
##
set_property PACKAGE_PIN AH9 [get_ports SYSCLKP_I]
set_property IOSTANDARD LVCMOS18 [get_ports SYSCLKP_I]

##
## GTHE2 Channel and Common Loc constraints
##
set_property LOC GTHE2_CHANNEL_X1Y16 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[0].u_ch/u_gthe2_channel]
set_property LOC GTHE2_CHANNEL_X1Y17 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[1].u_ch/u_gthe2_channel]
set_property LOC GTHE2_CHANNEL_X1Y18 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[2].u_ch/u_gthe2_channel]
set_property LOC GTHE2_CHANNEL_X1Y19 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[3].u_ch/u_gthe2_channel]
set_property LOC GTHE2_COMMON_X1Y4 [get_cells u_ibert_core/inst/QUAD[0].u_q/u_common/u_gthe2_common]
set_property LOC GTHE2_CHANNEL_X1Y20 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[0].u_ch/u_gthe2_channel]
set_property LOC GTHE2_CHANNEL_X1Y21 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[1].u_ch/u_gthe2_channel]
set_property LOC GTHE2_CHANNEL_X1Y22 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[2].u_ch/u_gthe2_channel]
set_property LOC GTHE2_CHANNEL_X1Y23 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[3].u_ch/u_gthe2_channel]
set_property LOC GTHE2_COMMON_X1Y5 [get_cells u_ibert_core/inst/QUAD[1].u_q/u_common/u_gthe2_common]
set_property LOC GTHE2_CHANNEL_X1Y24 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[0].u_ch/u_gthe2_channel]
set_property LOC GTHE2_CHANNEL_X1Y25 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[1].u_ch/u_gthe2_channel]
set_property LOC GTHE2_CHANNEL_X1Y26 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[2].u_ch/u_gthe2_channel]
set_property LOC GTHE2_CHANNEL_X1Y27 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[3].u_ch/u_gthe2_channel]
set_property LOC GTHE2_COMMON_X1Y6 [get_cells u_ibert_core/inst/QUAD[2].u_q/u_common/u_gthe2_common]
set_property LOC GTHE2_CHANNEL_X1Y28 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[0].u_ch/u_gthe2_channel]
set_property LOC GTHE2_CHANNEL_X1Y29 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[1].u_ch/u_gthe2_channel]
set_property LOC GTHE2_CHANNEL_X1Y30 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[2].u_ch/u_gthe2_channel]
set_property LOC GTHE2_CHANNEL_X1Y31 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[3].u_ch/u_gthe2_channel]
set_property LOC GTHE2_COMMON_X1Y7 [get_cells u_ibert_core/inst/QUAD[3].u_q/u_common/u_gthe2_common]
set_property LOC GTHE2_CHANNEL_X1Y32 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[0].u_ch/u_gthe2_channel]
set_property LOC GTHE2_CHANNEL_X1Y33 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[1].u_ch/u_gthe2_channel]
set_property LOC GTHE2_CHANNEL_X1Y34 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[2].u_ch/u_gthe2_channel]
set_property LOC GTHE2_CHANNEL_X1Y35 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[3].u_ch/u_gthe2_channel]
set_property LOC GTHE2_COMMON_X1Y8 [get_cells u_ibert_core/inst/QUAD[4].u_q/u_common/u_gthe2_common]

##
## BUFH Loc constraints for TX/RX userclks
##

set_property LOC BUFHCE_X1Y48 [get_cells u_ibert_core/inst/QUAD[0].u_q/u_common/u_clocking/local_txusr.u_txusr]
set_property LOC BUFHCE_X1Y49 [get_cells u_ibert_core/inst/QUAD[0].u_q/u_common/u_clocking/rx_ind.u_rxusr0]
set_property LOC BUFHCE_X1Y50 [get_cells u_ibert_core/inst/QUAD[0].u_q/u_common/u_clocking/rx_ind.u_rxusr1]
set_property LOC BUFHCE_X1Y51 [get_cells u_ibert_core/inst/QUAD[0].u_q/u_common/u_clocking/rx_ind.u_rxusr2]
set_property LOC BUFHCE_X1Y52 [get_cells u_ibert_core/inst/QUAD[0].u_q/u_common/u_clocking/rx_ind.u_rxusr3]
set_property LOC BUFHCE_X1Y60 [get_cells u_ibert_core/inst/QUAD[1].u_q/u_common/u_clocking/local_txusr.u_txusr]
set_property LOC BUFHCE_X1Y61 [get_cells u_ibert_core/inst/QUAD[1].u_q/u_common/u_clocking/rx_ind.u_rxusr0]
set_property LOC BUFHCE_X1Y62 [get_cells u_ibert_core/inst/QUAD[1].u_q/u_common/u_clocking/rx_ind.u_rxusr1]
set_property LOC BUFHCE_X1Y63 [get_cells u_ibert_core/inst/QUAD[1].u_q/u_common/u_clocking/rx_ind.u_rxusr2]
set_property LOC BUFHCE_X1Y64 [get_cells u_ibert_core/inst/QUAD[1].u_q/u_common/u_clocking/rx_ind.u_rxusr3]
set_property LOC BUFHCE_X1Y72 [get_cells u_ibert_core/inst/QUAD[2].u_q/u_common/u_clocking/local_txusr.u_txusr]
set_property LOC BUFHCE_X1Y73 [get_cells u_ibert_core/inst/QUAD[2].u_q/u_common/u_clocking/rx_ind.u_rxusr0]
set_property LOC BUFHCE_X1Y74 [get_cells u_ibert_core/inst/QUAD[2].u_q/u_common/u_clocking/rx_ind.u_rxusr1]
set_property LOC BUFHCE_X1Y75 [get_cells u_ibert_core/inst/QUAD[2].u_q/u_common/u_clocking/rx_ind.u_rxusr2]
set_property LOC BUFHCE_X1Y76 [get_cells u_ibert_core/inst/QUAD[2].u_q/u_common/u_clocking/rx_ind.u_rxusr3]
set_property LOC BUFHCE_X1Y84 [get_cells u_ibert_core/inst/QUAD[3].u_q/u_common/u_clocking/local_txusr.u_txusr]
set_property LOC BUFHCE_X1Y85 [get_cells u_ibert_core/inst/QUAD[3].u_q/u_common/u_clocking/rx_ind.u_rxusr0]
set_property LOC BUFHCE_X1Y86 [get_cells u_ibert_core/inst/QUAD[3].u_q/u_common/u_clocking/rx_ind.u_rxusr1]
set_property LOC BUFHCE_X1Y87 [get_cells u_ibert_core/inst/QUAD[3].u_q/u_common/u_clocking/rx_ind.u_rxusr2]
set_property LOC BUFHCE_X1Y88 [get_cells u_ibert_core/inst/QUAD[3].u_q/u_common/u_clocking/rx_ind.u_rxusr3]
set_property LOC BUFHCE_X1Y96 [get_cells u_ibert_core/inst/QUAD[4].u_q/u_common/u_clocking/local_txusr.u_txusr]
set_property LOC BUFHCE_X1Y97 [get_cells u_ibert_core/inst/QUAD[4].u_q/u_common/u_clocking/rx_ind.u_rxusr0]
set_property LOC BUFHCE_X1Y98 [get_cells u_ibert_core/inst/QUAD[4].u_q/u_common/u_clocking/rx_ind.u_rxusr1]
set_property LOC BUFHCE_X1Y99 [get_cells u_ibert_core/inst/QUAD[4].u_q/u_common/u_clocking/rx_ind.u_rxusr2]
set_property LOC BUFHCE_X1Y100 [get_cells u_ibert_core/inst/QUAD[4].u_q/u_common/u_clocking/rx_ind.u_rxusr3]


##
## MGT reference clock BUFFERS location constraints
##

set_property LOC IBUFDS_GTE2_X1Y8 [get_cells u_buf_q16_clk0]
set_property LOC IBUFDS_GTE2_X1Y9 [get_cells u_buf_q16_clk1]
set_property LOC IBUFDS_GTE2_X1Y10 [get_cells u_buf_q17_clk0]
set_property LOC IBUFDS_GTE2_X1Y11 [get_cells u_buf_q17_clk1]
set_property LOC IBUFDS_GTE2_X1Y12 [get_cells u_buf_q18_clk0]
set_property LOC IBUFDS_GTE2_X1Y13 [get_cells u_buf_q18_clk1]
set_property LOC IBUFDS_GTE2_X1Y14 [get_cells u_buf_q19_clk0]
set_property LOC IBUFDS_GTE2_X1Y15 [get_cells u_buf_q19_clk1]
set_property LOC IBUFDS_GTE2_X1Y16 [get_cells u_buf_q20_clk0]
set_property LOC IBUFDS_GTE2_X1Y17 [get_cells u_buf_q20_clk1]

##
## Attribute values for GTHE2 Channel and Common instances
##
##
## Attribute Values for QUAD[16] - Channel
##

 ##------Comma Detection and Alignment---------
set_property ALIGN_COMMA_DOUBLE "FALSE" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ALIGN_COMMA_ENABLE 10'b0001111111 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ALIGN_COMMA_WORD 1 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ALIGN_MCOMMA_DET "TRUE" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ALIGN_MCOMMA_VALUE 10'b1010000011 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ALIGN_PCOMMA_DET "TRUE" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ALIGN_PCOMMA_VALUE 10'b0101111100 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property DEC_MCOMMA_DETECT "FALSE" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property DEC_PCOMMA_DETECT "FALSE" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property DEC_VALID_COMMA_ONLY "FALSE" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property DMONITOR_CFG 24'h000A00 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]

 ##--------------Channel Bonding--------------
set_property CBCC_DATA_SOURCE_SEL "DECODED" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_KEEP_ALIGN "FALSE" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_MAX_SKEW 7 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_LEN 1 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_1_1 10'b0101111100 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_1_2 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_1_3 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_1_4 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_1_ENABLE 4'b1111 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_2_1 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_2_2 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_2_3 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_2_4 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_2_ENABLE 4'b1111 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_2_USE "FALSE" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------Clock Correction------------
set_property CLK_COR_KEEP_IDLE "FALSE" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_MAX_LAT 19.0 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_MIN_LAT 15.0 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_PRECEDENCE "TRUE" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_CORRECT_USE "FALSE" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_REPEAT_WAIT 0 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_LEN 1 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_1_1 10'b0100011100 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_1_2 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_1_3 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_1_4 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_1_ENABLE 4'b1111 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_2_1 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_2_2 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_2_3 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_2_4 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_2_ENABLE 4'b1111 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_2_USE "FALSE" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------Channel PLL----------------------
set_property CPLL_CFG 24'hBC07DC [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CPLL_FBDIV 1 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CPLL_FBDIV_45 4 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CPLL_INIT_CFG 24'h00001E [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CPLL_LOCK_CFG 16'h01E8 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CPLL_REFCLK_DIV 1 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXOUT_DIV 1 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXOUT_DIV 1 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------------Eyescan--------------
set_property ES_CONTROL 6'b000000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_ERRDET_EN "TRUE" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_EYE_SCAN_EN "TRUE" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_HORZ_OFFSET 12'h000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_PMA_CFG 10'b0000000000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_PRESCALE 5'b00000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_QUALIFIER 80'h00000000000000000000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_QUAL_MASK 80'h11111111111111111111 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_SDATA_MASK 80'h00000000000000000000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_VERT_OFFSET 9'b010000000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property FTS_DESKEW_SEQ_ENABLE 4'b1111 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property FTS_LANE_DESKEW_CFG 4'b1111 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property FTS_LANE_DESKEW_EN "FALSE" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property GEARBOX_MODE 3'b000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property OUTREFCLK_SEL_INV 2'b11 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PCS_PCIE_EN "FALSE" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PCS_RSVD_ATTR 48'h000000000000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PMA_RSV 32'h00000080 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PMA_RSV2 32'h1C00000A [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PMA_RSV3 2'b00 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PMA_RSV4 15'h0008 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_BIAS_CFG 24'h0C0010 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------Rx Elastic Buffer and Phase alignment-------------
set_property RXBUF_ADDR_MODE "FAST" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_EIDLE_HI_CNT 4'b1000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_EIDLE_LO_CNT 4'b0000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_EN "TRUE" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_BUFFER_CFG 6'b000000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_RESET_ON_CB_CHANGE "TRUE" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_RESET_ON_COMMAALIGN "FALSE" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_RESET_ON_EIDLE "FALSE" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_RESET_ON_RATE_CHANGE "TRUE" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUFRESET_TIME 5'b00001 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_THRESH_OVFLW 61 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_THRESH_OVRD "FALSE" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_THRESH_UNDFLW 4 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXDLY_CFG 16'h001F [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXDLY_LCFG 9'h030 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXDLY_TAP_CFG 16'h0000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------RX driver, OOB signalling, Coupling and Eq., CDR------------
set_property RXCDR_CFG 83'h0002007FE2000C208001A [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXCDRFREQRESET_TIME 5'b00001 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXCDR_FR_RESET_ON_EIDLE 1'b0 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXCDR_HOLD_DURING_EIDLE 1'b0 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXCDR_LOCK_CFG 6'b010101 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXCDR_PH_RESET_ON_EIDLE 1'b0 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXCDRPHRESET_TIME 5'b00001 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXDFELPMRESET_TIME 7'b0001111 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXOOB_CFG 7'b0000110 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------------------RX Interface-------------------------
set_property RX_INT_DATAWIDTH 1 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DATA_WIDTH 32 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_CLKMUX_PD 1'b1 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_CLK25_DIV 7 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_CM_SEL 2'b11 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_CM_TRIM 4'b1010 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DDI_SEL 6'b000000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DEBUG_CFG 12'b000000000000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
 
 ##------------RX Decision Feedback Equalizer(DFE)-------------
set_property RX_DEFER_RESET_BUF_EN "TRUE" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_GAIN_CFG 23'h0020C0 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_H2_CFG 12'b000000000000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_H3_CFG 12'b000001000000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_H4_CFG 11'b00011100000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_H5_CFG 11'b00011100000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_LPM_HOLD_DURING_EIDLE 1'b0 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_CFG 33'h041000310 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_LPM_CFG 16'h0080 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_OS_CFG 13'b0000010000000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_UT_CFG 17'b00011100000000000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_VP_CFG 17'b00011101010100011 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DISPERR_SEQ_MATCH "TRUE" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------------------RX Gearbox---------------------------
set_property RXGEARBOX_EN "FALSE" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXISCANRESET_TIME 5'b00001 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXLPM_HF_CFG 14'b00001000000000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXLPM_LF_CFG 18'b001001000000000000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPCSRESET_TIME 5'b00001 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPH_CFG 24'h000000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPHDLY_CFG 24'h084020 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPH_MONITOR_SEL 5'b00000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPMARESET_TIME 5'b00011 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------------------PRBS Detection-----------------------
set_property RXPRBS_ERR_LOOPBACK 1'b0 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_SIG_VALID_DLY 10 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXSLIDE_AUTO_WAIT 7 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXSLIDE_MODE "off" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_XCLK_SEL "RXREC" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------RX Attributes for PCI Express/SATA/SAS----------
set_property PD_TRANS_TIME_FROM_P2 12'h03c [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PD_TRANS_TIME_NONE_P2 8'h3c [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PD_TRANS_TIME_TO_P2 8'h64 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SAS_MAX_COM 64 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SAS_MIN_COM 36 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_BURST_SEQ_LEN 4'b1111 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_BURST_VAL 3'b100 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_CPLL_CFG "VCO_3000MHZ" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_EIDLE_VAL 3'b100 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_MAX_BURST 8 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_MAX_INIT 21 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_MAX_WAKE 7 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_MIN_BURST 4 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_MIN_INIT 12 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_MIN_WAKE 4 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SHOW_REALIGN_COMMA "TRUE" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TERM_RCAL_CFG 15'b100001000010000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TERM_RCAL_OVRD 3'b000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TRANS_TIME_RATE 8'h0E [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TST_RSV 32'h00000000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]

 ##------------TX Buffering and Phase Alignment----------------
set_property TXBUF_EN "TRUE" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXBUF_RESET_ON_RATE_CHANGE "FALSE" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------------------TX Interface-------------------------
set_property TX_DATA_WIDTH 32 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_DEEMPH0 6'b000000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_DEEMPH1 6'b000000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXDLY_CFG 16'h001F [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXDLY_LCFG 9'h030 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXDLY_TAP_CFG 16'h0000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_INT_DATAWIDTH 1 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_CLKMUX_PD 1'b1 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_CLK25_DIV 7 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]

 ##--------------TX Driver and OOB Signalling------------------
set_property TX_EIDLE_ASSERT_DELAY 3'b110 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_EIDLE_DEASSERT_DELAY 3'b100 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_LOOPBACK_DRIVE_HIZ "FALSE" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MAINCURSOR_SEL 1'b0 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_DRIVE_MODE "DIRECT" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------------------TX Gearbox---------------------------
set_property TXGEARBOX_EN "FALSE" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]

 ##----------------TX Attributes for PCI Express---------------
set_property TX_MARGIN_FULL_0 7'b1001110 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_FULL_1 7'b1001001 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_FULL_2 7'b1000101 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_FULL_3 7'b1000010 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_FULL_4 7'b1000000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_LOW_0 7'b1000110 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_LOW_1 7'b1000100 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_LOW_2 7'b1000010 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_LOW_3 7'b1000000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_LOW_4 7'b1000000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPCSRESET_TIME 5'b00001 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPH_CFG 16'h0780 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPHDLY_CFG 24'h084020 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPH_MONITOR_SEL 5'b00000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPMARESET_TIME 5'b00001 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_QPI_STATUS_EN 1'b0 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_RXDETECT_CFG 14'h1832 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_RXDETECT_REF 3'b100 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_XCLK_SEL "TXOUT" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property UCODEER_CLR 1'b0 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- JTAG Attributes ---------------
set_property ACJTAG_DEBUG_MODE 1'b0 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ACJTAG_MODE 1'b0 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ACJTAG_RESET 1'b0 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ADAPT_CFG0 20'h00C10 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CFOK_CFG 42'h24800040E80 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CFOK_CFG2 6'h20 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CFOK_CFG3 6'h20 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- EYESCAN ---------------
set_property ES_CLK_PHASE_SEL 1'b0 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PMA_RSV5 4'h0 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RESET_POWERSAVE_DISABLE 1'b0 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- RX Phase Interpolator ---------------
set_property RXPI_CFG0 2'b0 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPI_CFG1 2'b11 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPI_CFG2 2'b11 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPI_CFG3 2'b11 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPI_CFG4 1'b0 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPI_CFG5 1'b0 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPI_CFG6 3'b100 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]

 ##------------RX Decision Feedback Equalizer(DFE)-------------
set_property RX_DFELPM_CFG0 4'b0110 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFELPM_CFG1 1'b0 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFELPM_KLKH_AGC_STUP_EN 1'b1 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_AGC_CFG0 2'b0 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_AGC_CFG1 3'b010 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_AGC_CFG2 4'b0000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_AGC_OVRDEN 1'b1 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_H6_CFG 11'h020 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_H7_CFG 11'h020 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KH_CFG0 2'b10 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KH_CFG1 1'h2 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KH_CFG2 4'b0010 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KH_OVRDEN 1'b1 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KL_CFG0 2'b01 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KL_CFG1 3'b010 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KL_CFG2 4'b0010 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KL_OVRDEN 1'b1 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_ST_CFG 54'h00E100000C003F [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- TX Phase Interpolator ---------------
set_property TXPI_CFG0 2'b00 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_CFG1 2'b00 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_CFG2 2'b00 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_CFG3 1'b0 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_CFG4 1'b0 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_CFG5 3'b100 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_GREY_SEL 1'b0 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_INVSTROBE_SEL 1'b0 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_PPMCLK_SEL "TXUSRCLK2" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_PPM_CFG 8'h00 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_SYNFREQ_PPM 3'b000 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_RXDETECT_PRECHARGE_TIME 17'h155CC [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property USE_PCS_CLK_PHASE_SEL 1'b0 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- LOOPBACK ---------------
set_property LOOPBACK_CFG 1'b0 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- OOB Signalling ---------------
set_property RXOOB_CLK_CFG "PMA" [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXOSCALRESET_TIME 5'b00011 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXOSCALRESET_TIMEOUT 6'b0 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property A_RXOSCALRESET 1'b0 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXOOB_CFG 1'b0 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- RX SYNC ---------------
set_property RXSYNC_MULTILANE 1'b0 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXSYNC_OVRD 1'b0 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXSYNC_SKIP_DA 1'b0 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- TX SYNC ---------------
set_property TXSYNC_MULTILANE 1'b0 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXSYNC_OVRD 1'b0 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXSYNC_SKIP_DA 1'b0 [get_cells u_ibert_core/inst/QUAD[0].u_q/CH[*].u_ch/u_gthe2_channel]

##
## Attribute Values for QUAD[16] - Common
##
set_property BIAS_CFG 64'h0000040000001050 [get_cells u_ibert_core/inst/QUAD[0].u_q/u_common/u_gthe2_common]
set_property COMMON_CFG 32'h0000001C [get_cells u_ibert_core/inst/QUAD[0].u_q/u_common/u_gthe2_common]
set_property QPLL_CFG 27'h0480187 [get_cells u_ibert_core/inst/QUAD[0].u_q/u_common/u_gthe2_common]
set_property QPLL_CLKOUT_CFG 4'b1111 [get_cells u_ibert_core/inst/QUAD[0].u_q/u_common/u_gthe2_common]
set_property QPLL_COARSE_FREQ_OVRD_EN 1'b0 [get_cells u_ibert_core/inst/QUAD[0].u_q/u_common/u_gthe2_common]
set_property QPLL_CP_MONITOR_EN 1'b0 [get_cells u_ibert_core/inst/QUAD[0].u_q/u_common/u_gthe2_common]
set_property QPLL_FBDIV_MONITOR_EN 1'b0 [get_cells u_ibert_core/inst/QUAD[0].u_q/u_common/u_gthe2_common]
set_property QPLL_INIT_CFG 24'h000006 [get_cells u_ibert_core/inst/QUAD[0].u_q/u_common/u_gthe2_common]
set_property QPLL_LOCK_CFG 16'h05E8 [get_cells u_ibert_core/inst/QUAD[0].u_q/u_common/u_gthe2_common]
set_property QPLL_LPF 4'b1111 [get_cells u_ibert_core/inst/QUAD[0].u_q/u_common/u_gthe2_common]
set_property QPLL_REFCLK_DIV 1 [get_cells u_ibert_core/inst/QUAD[0].u_q/u_common/u_gthe2_common]
set_property QPLL_RP_COMP 1'b0 [get_cells u_ibert_core/inst/QUAD[0].u_q/u_common/u_gthe2_common]
set_property QPLL_VTRL_RESET 2'b00 [get_cells u_ibert_core/inst/QUAD[0].u_q/u_common/u_gthe2_common]
set_property RCAL_CFG 2'b00 [get_cells u_ibert_core/inst/QUAD[0].u_q/u_common/u_gthe2_common]
set_property RSVD_ATTR0 16'h0000 [get_cells u_ibert_core/inst/QUAD[0].u_q/u_common/u_gthe2_common]
set_property RSVD_ATTR1 16'h0000 [get_cells u_ibert_core/inst/QUAD[0].u_q/u_common/u_gthe2_common]
##
## Attribute Values for QUAD[17] - Channel
##

 ##------Comma Detection and Alignment---------
set_property ALIGN_COMMA_DOUBLE "FALSE" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ALIGN_COMMA_ENABLE 10'b0001111111 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ALIGN_COMMA_WORD 1 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ALIGN_MCOMMA_DET "TRUE" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ALIGN_MCOMMA_VALUE 10'b1010000011 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ALIGN_PCOMMA_DET "TRUE" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ALIGN_PCOMMA_VALUE 10'b0101111100 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property DEC_MCOMMA_DETECT "FALSE" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property DEC_PCOMMA_DETECT "FALSE" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property DEC_VALID_COMMA_ONLY "FALSE" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property DMONITOR_CFG 24'h000A00 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]

 ##--------------Channel Bonding--------------
set_property CBCC_DATA_SOURCE_SEL "DECODED" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_KEEP_ALIGN "FALSE" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_MAX_SKEW 7 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_LEN 1 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_1_1 10'b0101111100 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_1_2 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_1_3 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_1_4 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_1_ENABLE 4'b1111 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_2_1 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_2_2 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_2_3 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_2_4 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_2_ENABLE 4'b1111 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_2_USE "FALSE" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------Clock Correction------------
set_property CLK_COR_KEEP_IDLE "FALSE" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_MAX_LAT 19.0 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_MIN_LAT 15.0 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_PRECEDENCE "TRUE" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_CORRECT_USE "FALSE" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_REPEAT_WAIT 0 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_LEN 1 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_1_1 10'b0100011100 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_1_2 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_1_3 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_1_4 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_1_ENABLE 4'b1111 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_2_1 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_2_2 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_2_3 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_2_4 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_2_ENABLE 4'b1111 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_2_USE "FALSE" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------Channel PLL----------------------
set_property CPLL_CFG 24'hBC07DC [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CPLL_FBDIV 1 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CPLL_FBDIV_45 4 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CPLL_INIT_CFG 24'h00001E [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CPLL_LOCK_CFG 16'h01E8 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CPLL_REFCLK_DIV 1 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXOUT_DIV 1 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXOUT_DIV 1 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------------Eyescan--------------
set_property ES_CONTROL 6'b000000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_ERRDET_EN "TRUE" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_EYE_SCAN_EN "TRUE" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_HORZ_OFFSET 12'h000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_PMA_CFG 10'b0000000000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_PRESCALE 5'b00000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_QUALIFIER 80'h00000000000000000000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_QUAL_MASK 80'h11111111111111111111 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_SDATA_MASK 80'h00000000000000000000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_VERT_OFFSET 9'b010000000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property FTS_DESKEW_SEQ_ENABLE 4'b1111 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property FTS_LANE_DESKEW_CFG 4'b1111 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property FTS_LANE_DESKEW_EN "FALSE" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property GEARBOX_MODE 3'b000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property OUTREFCLK_SEL_INV 2'b11 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PCS_PCIE_EN "FALSE" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PCS_RSVD_ATTR 48'h000000000000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PMA_RSV 32'h00000080 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PMA_RSV2 32'h1C00000A [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PMA_RSV3 2'b00 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PMA_RSV4 15'h0008 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_BIAS_CFG 24'h0C0010 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------Rx Elastic Buffer and Phase alignment-------------
set_property RXBUF_ADDR_MODE "FAST" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_EIDLE_HI_CNT 4'b1000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_EIDLE_LO_CNT 4'b0000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_EN "TRUE" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_BUFFER_CFG 6'b000000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_RESET_ON_CB_CHANGE "TRUE" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_RESET_ON_COMMAALIGN "FALSE" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_RESET_ON_EIDLE "FALSE" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_RESET_ON_RATE_CHANGE "TRUE" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUFRESET_TIME 5'b00001 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_THRESH_OVFLW 61 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_THRESH_OVRD "FALSE" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_THRESH_UNDFLW 4 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXDLY_CFG 16'h001F [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXDLY_LCFG 9'h030 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXDLY_TAP_CFG 16'h0000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------RX driver, OOB signalling, Coupling and Eq., CDR------------
set_property RXCDR_CFG 83'h0002007FE2000C208001A [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXCDRFREQRESET_TIME 5'b00001 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXCDR_FR_RESET_ON_EIDLE 1'b0 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXCDR_HOLD_DURING_EIDLE 1'b0 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXCDR_LOCK_CFG 6'b010101 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXCDR_PH_RESET_ON_EIDLE 1'b0 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXCDRPHRESET_TIME 5'b00001 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXDFELPMRESET_TIME 7'b0001111 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXOOB_CFG 7'b0000110 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------------------RX Interface-------------------------
set_property RX_INT_DATAWIDTH 1 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DATA_WIDTH 32 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_CLKMUX_PD 1'b1 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_CLK25_DIV 7 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_CM_SEL 2'b11 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_CM_TRIM 4'b1010 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DDI_SEL 6'b000000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DEBUG_CFG 12'b000000000000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
 
 ##------------RX Decision Feedback Equalizer(DFE)-------------
set_property RX_DEFER_RESET_BUF_EN "TRUE" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_GAIN_CFG 23'h0020C0 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_H2_CFG 12'b000000000000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_H3_CFG 12'b000001000000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_H4_CFG 11'b00011100000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_H5_CFG 11'b00011100000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_LPM_HOLD_DURING_EIDLE 1'b0 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_CFG 33'h041000310 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_LPM_CFG 16'h0080 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_OS_CFG 13'b0000010000000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_UT_CFG 17'b00011100000000000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_VP_CFG 17'b00011101010100011 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DISPERR_SEQ_MATCH "TRUE" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------------------RX Gearbox---------------------------
set_property RXGEARBOX_EN "FALSE" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXISCANRESET_TIME 5'b00001 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXLPM_HF_CFG 14'b00001000000000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXLPM_LF_CFG 18'b001001000000000000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPCSRESET_TIME 5'b00001 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPH_CFG 24'h000000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPHDLY_CFG 24'h084020 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPH_MONITOR_SEL 5'b00000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPMARESET_TIME 5'b00011 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------------------PRBS Detection-----------------------
set_property RXPRBS_ERR_LOOPBACK 1'b0 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_SIG_VALID_DLY 10 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXSLIDE_AUTO_WAIT 7 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXSLIDE_MODE "off" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_XCLK_SEL "RXREC" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------RX Attributes for PCI Express/SATA/SAS----------
set_property PD_TRANS_TIME_FROM_P2 12'h03c [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PD_TRANS_TIME_NONE_P2 8'h3c [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PD_TRANS_TIME_TO_P2 8'h64 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SAS_MAX_COM 64 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SAS_MIN_COM 36 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_BURST_SEQ_LEN 4'b1111 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_BURST_VAL 3'b100 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_CPLL_CFG "VCO_3000MHZ" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_EIDLE_VAL 3'b100 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_MAX_BURST 8 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_MAX_INIT 21 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_MAX_WAKE 7 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_MIN_BURST 4 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_MIN_INIT 12 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_MIN_WAKE 4 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SHOW_REALIGN_COMMA "TRUE" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TERM_RCAL_CFG 15'b100001000010000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TERM_RCAL_OVRD 3'b000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TRANS_TIME_RATE 8'h0E [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TST_RSV 32'h00000000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]

 ##------------TX Buffering and Phase Alignment----------------
set_property TXBUF_EN "TRUE" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXBUF_RESET_ON_RATE_CHANGE "FALSE" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------------------TX Interface-------------------------
set_property TX_DATA_WIDTH 32 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_DEEMPH0 6'b000000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_DEEMPH1 6'b000000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXDLY_CFG 16'h001F [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXDLY_LCFG 9'h030 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXDLY_TAP_CFG 16'h0000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_INT_DATAWIDTH 1 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_CLKMUX_PD 1'b1 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_CLK25_DIV 7 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]

 ##--------------TX Driver and OOB Signalling------------------
set_property TX_EIDLE_ASSERT_DELAY 3'b110 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_EIDLE_DEASSERT_DELAY 3'b100 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_LOOPBACK_DRIVE_HIZ "FALSE" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MAINCURSOR_SEL 1'b0 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_DRIVE_MODE "DIRECT" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------------------TX Gearbox---------------------------
set_property TXGEARBOX_EN "FALSE" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]

 ##----------------TX Attributes for PCI Express---------------
set_property TX_MARGIN_FULL_0 7'b1001110 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_FULL_1 7'b1001001 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_FULL_2 7'b1000101 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_FULL_3 7'b1000010 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_FULL_4 7'b1000000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_LOW_0 7'b1000110 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_LOW_1 7'b1000100 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_LOW_2 7'b1000010 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_LOW_3 7'b1000000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_LOW_4 7'b1000000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPCSRESET_TIME 5'b00001 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPH_CFG 16'h0780 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPHDLY_CFG 24'h084020 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPH_MONITOR_SEL 5'b00000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPMARESET_TIME 5'b00001 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_QPI_STATUS_EN 1'b0 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_RXDETECT_CFG 14'h1832 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_RXDETECT_REF 3'b100 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_XCLK_SEL "TXOUT" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property UCODEER_CLR 1'b0 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- JTAG Attributes ---------------
set_property ACJTAG_DEBUG_MODE 1'b0 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ACJTAG_MODE 1'b0 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ACJTAG_RESET 1'b0 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ADAPT_CFG0 20'h00C10 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CFOK_CFG 42'h24800040E80 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CFOK_CFG2 6'h20 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CFOK_CFG3 6'h20 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- EYESCAN ---------------
set_property ES_CLK_PHASE_SEL 1'b0 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PMA_RSV5 4'h0 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RESET_POWERSAVE_DISABLE 1'b0 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- RX Phase Interpolator ---------------
set_property RXPI_CFG0 2'b0 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPI_CFG1 2'b11 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPI_CFG2 2'b11 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPI_CFG3 2'b11 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPI_CFG4 1'b0 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPI_CFG5 1'b0 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPI_CFG6 3'b100 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]

 ##------------RX Decision Feedback Equalizer(DFE)-------------
set_property RX_DFELPM_CFG0 4'b0110 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFELPM_CFG1 1'b0 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFELPM_KLKH_AGC_STUP_EN 1'b1 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_AGC_CFG0 2'b0 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_AGC_CFG1 3'b010 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_AGC_CFG2 4'b0000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_AGC_OVRDEN 1'b1 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_H6_CFG 11'h020 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_H7_CFG 11'h020 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KH_CFG0 2'b10 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KH_CFG1 1'h2 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KH_CFG2 4'b0010 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KH_OVRDEN 1'b1 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KL_CFG0 2'b01 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KL_CFG1 3'b010 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KL_CFG2 4'b0010 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KL_OVRDEN 1'b1 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_ST_CFG 54'h00E100000C003F [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- TX Phase Interpolator ---------------
set_property TXPI_CFG0 2'b00 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_CFG1 2'b00 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_CFG2 2'b00 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_CFG3 1'b0 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_CFG4 1'b0 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_CFG5 3'b100 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_GREY_SEL 1'b0 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_INVSTROBE_SEL 1'b0 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_PPMCLK_SEL "TXUSRCLK2" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_PPM_CFG 8'h00 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_SYNFREQ_PPM 3'b000 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_RXDETECT_PRECHARGE_TIME 17'h155CC [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property USE_PCS_CLK_PHASE_SEL 1'b0 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- LOOPBACK ---------------
set_property LOOPBACK_CFG 1'b0 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- OOB Signalling ---------------
set_property RXOOB_CLK_CFG "PMA" [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXOSCALRESET_TIME 5'b00011 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXOSCALRESET_TIMEOUT 6'b0 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property A_RXOSCALRESET 1'b0 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXOOB_CFG 1'b0 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- RX SYNC ---------------
set_property RXSYNC_MULTILANE 1'b0 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXSYNC_OVRD 1'b0 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXSYNC_SKIP_DA 1'b0 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- TX SYNC ---------------
set_property TXSYNC_MULTILANE 1'b0 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXSYNC_OVRD 1'b0 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXSYNC_SKIP_DA 1'b0 [get_cells u_ibert_core/inst/QUAD[1].u_q/CH[*].u_ch/u_gthe2_channel]

##
## Attribute Values for QUAD[17] - Common
##
set_property BIAS_CFG 64'h0000040000001050 [get_cells u_ibert_core/inst/QUAD[1].u_q/u_common/u_gthe2_common]
set_property COMMON_CFG 32'h0000001C [get_cells u_ibert_core/inst/QUAD[1].u_q/u_common/u_gthe2_common]
set_property QPLL_CFG 27'h0480187 [get_cells u_ibert_core/inst/QUAD[1].u_q/u_common/u_gthe2_common]
set_property QPLL_CLKOUT_CFG 4'b1111 [get_cells u_ibert_core/inst/QUAD[1].u_q/u_common/u_gthe2_common]
set_property QPLL_COARSE_FREQ_OVRD_EN 1'b0 [get_cells u_ibert_core/inst/QUAD[1].u_q/u_common/u_gthe2_common]
set_property QPLL_CP_MONITOR_EN 1'b0 [get_cells u_ibert_core/inst/QUAD[1].u_q/u_common/u_gthe2_common]
set_property QPLL_FBDIV_MONITOR_EN 1'b0 [get_cells u_ibert_core/inst/QUAD[1].u_q/u_common/u_gthe2_common]
set_property QPLL_INIT_CFG 24'h000006 [get_cells u_ibert_core/inst/QUAD[1].u_q/u_common/u_gthe2_common]
set_property QPLL_LOCK_CFG 16'h05E8 [get_cells u_ibert_core/inst/QUAD[1].u_q/u_common/u_gthe2_common]
set_property QPLL_LPF 4'b1111 [get_cells u_ibert_core/inst/QUAD[1].u_q/u_common/u_gthe2_common]
set_property QPLL_REFCLK_DIV 1 [get_cells u_ibert_core/inst/QUAD[1].u_q/u_common/u_gthe2_common]
set_property QPLL_RP_COMP 1'b0 [get_cells u_ibert_core/inst/QUAD[1].u_q/u_common/u_gthe2_common]
set_property QPLL_VTRL_RESET 2'b00 [get_cells u_ibert_core/inst/QUAD[1].u_q/u_common/u_gthe2_common]
set_property RCAL_CFG 2'b00 [get_cells u_ibert_core/inst/QUAD[1].u_q/u_common/u_gthe2_common]
set_property RSVD_ATTR0 16'h0000 [get_cells u_ibert_core/inst/QUAD[1].u_q/u_common/u_gthe2_common]
set_property RSVD_ATTR1 16'h0000 [get_cells u_ibert_core/inst/QUAD[1].u_q/u_common/u_gthe2_common]
##
## Attribute Values for QUAD[18] - Channel
##

 ##------Comma Detection and Alignment---------
set_property ALIGN_COMMA_DOUBLE "FALSE" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ALIGN_COMMA_ENABLE 10'b0001111111 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ALIGN_COMMA_WORD 1 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ALIGN_MCOMMA_DET "TRUE" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ALIGN_MCOMMA_VALUE 10'b1010000011 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ALIGN_PCOMMA_DET "TRUE" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ALIGN_PCOMMA_VALUE 10'b0101111100 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property DEC_MCOMMA_DETECT "FALSE" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property DEC_PCOMMA_DETECT "FALSE" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property DEC_VALID_COMMA_ONLY "FALSE" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property DMONITOR_CFG 24'h000A00 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]

 ##--------------Channel Bonding--------------
set_property CBCC_DATA_SOURCE_SEL "DECODED" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_KEEP_ALIGN "FALSE" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_MAX_SKEW 7 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_LEN 1 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_1_1 10'b0101111100 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_1_2 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_1_3 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_1_4 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_1_ENABLE 4'b1111 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_2_1 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_2_2 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_2_3 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_2_4 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_2_ENABLE 4'b1111 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_2_USE "FALSE" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------Clock Correction------------
set_property CLK_COR_KEEP_IDLE "FALSE" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_MAX_LAT 19.0 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_MIN_LAT 15.0 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_PRECEDENCE "TRUE" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_CORRECT_USE "FALSE" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_REPEAT_WAIT 0 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_LEN 1 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_1_1 10'b0100011100 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_1_2 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_1_3 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_1_4 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_1_ENABLE 4'b1111 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_2_1 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_2_2 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_2_3 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_2_4 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_2_ENABLE 4'b1111 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_2_USE "FALSE" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------Channel PLL----------------------
set_property CPLL_CFG 24'hBC07DC [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CPLL_FBDIV 1 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CPLL_FBDIV_45 4 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CPLL_INIT_CFG 24'h00001E [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CPLL_LOCK_CFG 16'h01E8 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CPLL_REFCLK_DIV 1 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXOUT_DIV 1 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXOUT_DIV 1 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------------Eyescan--------------
set_property ES_CONTROL 6'b000000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_ERRDET_EN "TRUE" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_EYE_SCAN_EN "TRUE" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_HORZ_OFFSET 12'h000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_PMA_CFG 10'b0000000000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_PRESCALE 5'b00000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_QUALIFIER 80'h00000000000000000000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_QUAL_MASK 80'h11111111111111111111 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_SDATA_MASK 80'h00000000000000000000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_VERT_OFFSET 9'b010000000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property FTS_DESKEW_SEQ_ENABLE 4'b1111 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property FTS_LANE_DESKEW_CFG 4'b1111 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property FTS_LANE_DESKEW_EN "FALSE" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property GEARBOX_MODE 3'b000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property OUTREFCLK_SEL_INV 2'b11 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PCS_PCIE_EN "FALSE" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PCS_RSVD_ATTR 48'h000000000000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PMA_RSV 32'h00000080 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PMA_RSV2 32'h1C00000A [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PMA_RSV3 2'b00 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PMA_RSV4 15'h0008 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_BIAS_CFG 24'h0C0010 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------Rx Elastic Buffer and Phase alignment-------------
set_property RXBUF_ADDR_MODE "FAST" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_EIDLE_HI_CNT 4'b1000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_EIDLE_LO_CNT 4'b0000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_EN "TRUE" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_BUFFER_CFG 6'b000000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_RESET_ON_CB_CHANGE "TRUE" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_RESET_ON_COMMAALIGN "FALSE" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_RESET_ON_EIDLE "FALSE" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_RESET_ON_RATE_CHANGE "TRUE" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUFRESET_TIME 5'b00001 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_THRESH_OVFLW 61 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_THRESH_OVRD "FALSE" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_THRESH_UNDFLW 4 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXDLY_CFG 16'h001F [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXDLY_LCFG 9'h030 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXDLY_TAP_CFG 16'h0000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------RX driver, OOB signalling, Coupling and Eq., CDR------------
set_property RXCDR_CFG 83'h0002007FE2000C208001A [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXCDRFREQRESET_TIME 5'b00001 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXCDR_FR_RESET_ON_EIDLE 1'b0 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXCDR_HOLD_DURING_EIDLE 1'b0 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXCDR_LOCK_CFG 6'b010101 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXCDR_PH_RESET_ON_EIDLE 1'b0 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXCDRPHRESET_TIME 5'b00001 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXDFELPMRESET_TIME 7'b0001111 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXOOB_CFG 7'b0000110 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------------------RX Interface-------------------------
set_property RX_INT_DATAWIDTH 1 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DATA_WIDTH 32 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_CLKMUX_PD 1'b1 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_CLK25_DIV 7 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_CM_SEL 2'b11 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_CM_TRIM 4'b1010 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DDI_SEL 6'b000000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DEBUG_CFG 12'b000000000000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
 
 ##------------RX Decision Feedback Equalizer(DFE)-------------
set_property RX_DEFER_RESET_BUF_EN "TRUE" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_GAIN_CFG 23'h0020C0 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_H2_CFG 12'b000000000000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_H3_CFG 12'b000001000000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_H4_CFG 11'b00011100000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_H5_CFG 11'b00011100000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_LPM_HOLD_DURING_EIDLE 1'b0 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_CFG 33'h041000310 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_LPM_CFG 16'h0080 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_OS_CFG 13'b0000010000000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_UT_CFG 17'b00011100000000000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_VP_CFG 17'b00011101010100011 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DISPERR_SEQ_MATCH "TRUE" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------------------RX Gearbox---------------------------
set_property RXGEARBOX_EN "FALSE" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXISCANRESET_TIME 5'b00001 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXLPM_HF_CFG 14'b00001000000000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXLPM_LF_CFG 18'b001001000000000000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPCSRESET_TIME 5'b00001 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPH_CFG 24'h000000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPHDLY_CFG 24'h084020 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPH_MONITOR_SEL 5'b00000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPMARESET_TIME 5'b00011 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------------------PRBS Detection-----------------------
set_property RXPRBS_ERR_LOOPBACK 1'b0 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_SIG_VALID_DLY 10 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXSLIDE_AUTO_WAIT 7 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXSLIDE_MODE "off" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_XCLK_SEL "RXREC" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------RX Attributes for PCI Express/SATA/SAS----------
set_property PD_TRANS_TIME_FROM_P2 12'h03c [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PD_TRANS_TIME_NONE_P2 8'h3c [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PD_TRANS_TIME_TO_P2 8'h64 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SAS_MAX_COM 64 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SAS_MIN_COM 36 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_BURST_SEQ_LEN 4'b1111 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_BURST_VAL 3'b100 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_CPLL_CFG "VCO_3000MHZ" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_EIDLE_VAL 3'b100 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_MAX_BURST 8 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_MAX_INIT 21 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_MAX_WAKE 7 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_MIN_BURST 4 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_MIN_INIT 12 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_MIN_WAKE 4 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SHOW_REALIGN_COMMA "TRUE" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TERM_RCAL_CFG 15'b100001000010000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TERM_RCAL_OVRD 3'b000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TRANS_TIME_RATE 8'h0E [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TST_RSV 32'h00000000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]

 ##------------TX Buffering and Phase Alignment----------------
set_property TXBUF_EN "TRUE" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXBUF_RESET_ON_RATE_CHANGE "FALSE" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------------------TX Interface-------------------------
set_property TX_DATA_WIDTH 32 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_DEEMPH0 6'b000000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_DEEMPH1 6'b000000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXDLY_CFG 16'h001F [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXDLY_LCFG 9'h030 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXDLY_TAP_CFG 16'h0000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_INT_DATAWIDTH 1 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_CLKMUX_PD 1'b1 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_CLK25_DIV 7 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]

 ##--------------TX Driver and OOB Signalling------------------
set_property TX_EIDLE_ASSERT_DELAY 3'b110 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_EIDLE_DEASSERT_DELAY 3'b100 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_LOOPBACK_DRIVE_HIZ "FALSE" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MAINCURSOR_SEL 1'b0 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_DRIVE_MODE "DIRECT" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------------------TX Gearbox---------------------------
set_property TXGEARBOX_EN "FALSE" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]

 ##----------------TX Attributes for PCI Express---------------
set_property TX_MARGIN_FULL_0 7'b1001110 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_FULL_1 7'b1001001 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_FULL_2 7'b1000101 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_FULL_3 7'b1000010 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_FULL_4 7'b1000000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_LOW_0 7'b1000110 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_LOW_1 7'b1000100 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_LOW_2 7'b1000010 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_LOW_3 7'b1000000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_LOW_4 7'b1000000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPCSRESET_TIME 5'b00001 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPH_CFG 16'h0780 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPHDLY_CFG 24'h084020 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPH_MONITOR_SEL 5'b00000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPMARESET_TIME 5'b00001 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_QPI_STATUS_EN 1'b0 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_RXDETECT_CFG 14'h1832 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_RXDETECT_REF 3'b100 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_XCLK_SEL "TXOUT" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property UCODEER_CLR 1'b0 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- JTAG Attributes ---------------
set_property ACJTAG_DEBUG_MODE 1'b0 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ACJTAG_MODE 1'b0 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ACJTAG_RESET 1'b0 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ADAPT_CFG0 20'h00C10 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CFOK_CFG 42'h24800040E80 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CFOK_CFG2 6'h20 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CFOK_CFG3 6'h20 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- EYESCAN ---------------
set_property ES_CLK_PHASE_SEL 1'b0 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PMA_RSV5 4'h0 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RESET_POWERSAVE_DISABLE 1'b0 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- RX Phase Interpolator ---------------
set_property RXPI_CFG0 2'b0 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPI_CFG1 2'b11 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPI_CFG2 2'b11 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPI_CFG3 2'b11 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPI_CFG4 1'b0 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPI_CFG5 1'b0 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPI_CFG6 3'b100 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]

 ##------------RX Decision Feedback Equalizer(DFE)-------------
set_property RX_DFELPM_CFG0 4'b0110 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFELPM_CFG1 1'b0 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFELPM_KLKH_AGC_STUP_EN 1'b1 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_AGC_CFG0 2'b0 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_AGC_CFG1 3'b010 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_AGC_CFG2 4'b0000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_AGC_OVRDEN 1'b1 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_H6_CFG 11'h020 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_H7_CFG 11'h020 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KH_CFG0 2'b10 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KH_CFG1 1'h2 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KH_CFG2 4'b0010 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KH_OVRDEN 1'b1 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KL_CFG0 2'b01 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KL_CFG1 3'b010 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KL_CFG2 4'b0010 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KL_OVRDEN 1'b1 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_ST_CFG 54'h00E100000C003F [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- TX Phase Interpolator ---------------
set_property TXPI_CFG0 2'b00 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_CFG1 2'b00 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_CFG2 2'b00 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_CFG3 1'b0 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_CFG4 1'b0 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_CFG5 3'b100 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_GREY_SEL 1'b0 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_INVSTROBE_SEL 1'b0 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_PPMCLK_SEL "TXUSRCLK2" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_PPM_CFG 8'h00 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_SYNFREQ_PPM 3'b000 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_RXDETECT_PRECHARGE_TIME 17'h155CC [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property USE_PCS_CLK_PHASE_SEL 1'b0 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- LOOPBACK ---------------
set_property LOOPBACK_CFG 1'b0 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- OOB Signalling ---------------
set_property RXOOB_CLK_CFG "PMA" [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXOSCALRESET_TIME 5'b00011 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXOSCALRESET_TIMEOUT 6'b0 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property A_RXOSCALRESET 1'b0 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXOOB_CFG 1'b0 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- RX SYNC ---------------
set_property RXSYNC_MULTILANE 1'b0 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXSYNC_OVRD 1'b0 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXSYNC_SKIP_DA 1'b0 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- TX SYNC ---------------
set_property TXSYNC_MULTILANE 1'b0 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXSYNC_OVRD 1'b0 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXSYNC_SKIP_DA 1'b0 [get_cells u_ibert_core/inst/QUAD[2].u_q/CH[*].u_ch/u_gthe2_channel]

##
## Attribute Values for QUAD[18] - Common
##
set_property BIAS_CFG 64'h0000040000001050 [get_cells u_ibert_core/inst/QUAD[2].u_q/u_common/u_gthe2_common]
set_property COMMON_CFG 32'h0000001C [get_cells u_ibert_core/inst/QUAD[2].u_q/u_common/u_gthe2_common]
set_property QPLL_CFG 27'h0480187 [get_cells u_ibert_core/inst/QUAD[2].u_q/u_common/u_gthe2_common]
set_property QPLL_CLKOUT_CFG 4'b1111 [get_cells u_ibert_core/inst/QUAD[2].u_q/u_common/u_gthe2_common]
set_property QPLL_COARSE_FREQ_OVRD_EN 1'b0 [get_cells u_ibert_core/inst/QUAD[2].u_q/u_common/u_gthe2_common]
set_property QPLL_CP_MONITOR_EN 1'b0 [get_cells u_ibert_core/inst/QUAD[2].u_q/u_common/u_gthe2_common]
set_property QPLL_FBDIV_MONITOR_EN 1'b0 [get_cells u_ibert_core/inst/QUAD[2].u_q/u_common/u_gthe2_common]
set_property QPLL_INIT_CFG 24'h000006 [get_cells u_ibert_core/inst/QUAD[2].u_q/u_common/u_gthe2_common]
set_property QPLL_LOCK_CFG 16'h05E8 [get_cells u_ibert_core/inst/QUAD[2].u_q/u_common/u_gthe2_common]
set_property QPLL_LPF 4'b1111 [get_cells u_ibert_core/inst/QUAD[2].u_q/u_common/u_gthe2_common]
set_property QPLL_REFCLK_DIV 1 [get_cells u_ibert_core/inst/QUAD[2].u_q/u_common/u_gthe2_common]
set_property QPLL_RP_COMP 1'b0 [get_cells u_ibert_core/inst/QUAD[2].u_q/u_common/u_gthe2_common]
set_property QPLL_VTRL_RESET 2'b00 [get_cells u_ibert_core/inst/QUAD[2].u_q/u_common/u_gthe2_common]
set_property RCAL_CFG 2'b00 [get_cells u_ibert_core/inst/QUAD[2].u_q/u_common/u_gthe2_common]
set_property RSVD_ATTR0 16'h0000 [get_cells u_ibert_core/inst/QUAD[2].u_q/u_common/u_gthe2_common]
set_property RSVD_ATTR1 16'h0000 [get_cells u_ibert_core/inst/QUAD[2].u_q/u_common/u_gthe2_common]
##
## Attribute Values for QUAD[19] - Channel
##

 ##------Comma Detection and Alignment---------
set_property ALIGN_COMMA_DOUBLE "FALSE" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ALIGN_COMMA_ENABLE 10'b0001111111 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ALIGN_COMMA_WORD 1 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ALIGN_MCOMMA_DET "TRUE" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ALIGN_MCOMMA_VALUE 10'b1010000011 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ALIGN_PCOMMA_DET "TRUE" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ALIGN_PCOMMA_VALUE 10'b0101111100 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property DEC_MCOMMA_DETECT "FALSE" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property DEC_PCOMMA_DETECT "FALSE" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property DEC_VALID_COMMA_ONLY "FALSE" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property DMONITOR_CFG 24'h000A00 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]

 ##--------------Channel Bonding--------------
set_property CBCC_DATA_SOURCE_SEL "DECODED" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_KEEP_ALIGN "FALSE" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_MAX_SKEW 7 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_LEN 1 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_1_1 10'b0101111100 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_1_2 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_1_3 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_1_4 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_1_ENABLE 4'b1111 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_2_1 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_2_2 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_2_3 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_2_4 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_2_ENABLE 4'b1111 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_2_USE "FALSE" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------Clock Correction------------
set_property CLK_COR_KEEP_IDLE "FALSE" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_MAX_LAT 19.0 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_MIN_LAT 15.0 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_PRECEDENCE "TRUE" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_CORRECT_USE "FALSE" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_REPEAT_WAIT 0 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_LEN 1 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_1_1 10'b0100011100 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_1_2 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_1_3 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_1_4 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_1_ENABLE 4'b1111 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_2_1 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_2_2 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_2_3 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_2_4 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_2_ENABLE 4'b1111 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_2_USE "FALSE" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------Channel PLL----------------------
set_property CPLL_CFG 24'hBC07DC [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CPLL_FBDIV 1 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CPLL_FBDIV_45 4 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CPLL_INIT_CFG 24'h00001E [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CPLL_LOCK_CFG 16'h01E8 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CPLL_REFCLK_DIV 1 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXOUT_DIV 1 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXOUT_DIV 1 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------------Eyescan--------------
set_property ES_CONTROL 6'b000000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_ERRDET_EN "TRUE" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_EYE_SCAN_EN "TRUE" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_HORZ_OFFSET 12'h000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_PMA_CFG 10'b0000000000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_PRESCALE 5'b00000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_QUALIFIER 80'h00000000000000000000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_QUAL_MASK 80'h11111111111111111111 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_SDATA_MASK 80'h00000000000000000000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_VERT_OFFSET 9'b010000000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property FTS_DESKEW_SEQ_ENABLE 4'b1111 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property FTS_LANE_DESKEW_CFG 4'b1111 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property FTS_LANE_DESKEW_EN "FALSE" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property GEARBOX_MODE 3'b000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property OUTREFCLK_SEL_INV 2'b11 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PCS_PCIE_EN "FALSE" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PCS_RSVD_ATTR 48'h000000000000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PMA_RSV 32'h00000080 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PMA_RSV2 32'h1C00000A [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PMA_RSV3 2'b00 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PMA_RSV4 15'h0008 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_BIAS_CFG 24'h0C0010 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------Rx Elastic Buffer and Phase alignment-------------
set_property RXBUF_ADDR_MODE "FAST" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_EIDLE_HI_CNT 4'b1000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_EIDLE_LO_CNT 4'b0000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_EN "TRUE" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_BUFFER_CFG 6'b000000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_RESET_ON_CB_CHANGE "TRUE" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_RESET_ON_COMMAALIGN "FALSE" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_RESET_ON_EIDLE "FALSE" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_RESET_ON_RATE_CHANGE "TRUE" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUFRESET_TIME 5'b00001 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_THRESH_OVFLW 61 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_THRESH_OVRD "FALSE" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_THRESH_UNDFLW 4 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXDLY_CFG 16'h001F [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXDLY_LCFG 9'h030 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXDLY_TAP_CFG 16'h0000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------RX driver, OOB signalling, Coupling and Eq., CDR------------
set_property RXCDR_CFG 83'h0002007FE2000C208001A [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXCDRFREQRESET_TIME 5'b00001 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXCDR_FR_RESET_ON_EIDLE 1'b0 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXCDR_HOLD_DURING_EIDLE 1'b0 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXCDR_LOCK_CFG 6'b010101 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXCDR_PH_RESET_ON_EIDLE 1'b0 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXCDRPHRESET_TIME 5'b00001 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXDFELPMRESET_TIME 7'b0001111 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXOOB_CFG 7'b0000110 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------------------RX Interface-------------------------
set_property RX_INT_DATAWIDTH 1 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DATA_WIDTH 32 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_CLKMUX_PD 1'b1 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_CLK25_DIV 7 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_CM_SEL 2'b11 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_CM_TRIM 4'b1010 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DDI_SEL 6'b000000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DEBUG_CFG 12'b000000000000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
 
 ##------------RX Decision Feedback Equalizer(DFE)-------------
set_property RX_DEFER_RESET_BUF_EN "TRUE" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_GAIN_CFG 23'h0020C0 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_H2_CFG 12'b000000000000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_H3_CFG 12'b000001000000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_H4_CFG 11'b00011100000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_H5_CFG 11'b00011100000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_LPM_HOLD_DURING_EIDLE 1'b0 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_CFG 33'h041000310 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_LPM_CFG 16'h0080 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_OS_CFG 13'b0000010000000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_UT_CFG 17'b00011100000000000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_VP_CFG 17'b00011101010100011 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DISPERR_SEQ_MATCH "TRUE" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------------------RX Gearbox---------------------------
set_property RXGEARBOX_EN "FALSE" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXISCANRESET_TIME 5'b00001 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXLPM_HF_CFG 14'b00001000000000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXLPM_LF_CFG 18'b001001000000000000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPCSRESET_TIME 5'b00001 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPH_CFG 24'h000000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPHDLY_CFG 24'h084020 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPH_MONITOR_SEL 5'b00000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPMARESET_TIME 5'b00011 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------------------PRBS Detection-----------------------
set_property RXPRBS_ERR_LOOPBACK 1'b0 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_SIG_VALID_DLY 10 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXSLIDE_AUTO_WAIT 7 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXSLIDE_MODE "off" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_XCLK_SEL "RXREC" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------RX Attributes for PCI Express/SATA/SAS----------
set_property PD_TRANS_TIME_FROM_P2 12'h03c [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PD_TRANS_TIME_NONE_P2 8'h3c [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PD_TRANS_TIME_TO_P2 8'h64 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SAS_MAX_COM 64 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SAS_MIN_COM 36 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_BURST_SEQ_LEN 4'b1111 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_BURST_VAL 3'b100 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_CPLL_CFG "VCO_3000MHZ" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_EIDLE_VAL 3'b100 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_MAX_BURST 8 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_MAX_INIT 21 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_MAX_WAKE 7 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_MIN_BURST 4 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_MIN_INIT 12 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_MIN_WAKE 4 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SHOW_REALIGN_COMMA "TRUE" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TERM_RCAL_CFG 15'b100001000010000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TERM_RCAL_OVRD 3'b000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TRANS_TIME_RATE 8'h0E [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TST_RSV 32'h00000000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]

 ##------------TX Buffering and Phase Alignment----------------
set_property TXBUF_EN "TRUE" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXBUF_RESET_ON_RATE_CHANGE "FALSE" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------------------TX Interface-------------------------
set_property TX_DATA_WIDTH 32 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_DEEMPH0 6'b000000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_DEEMPH1 6'b000000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXDLY_CFG 16'h001F [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXDLY_LCFG 9'h030 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXDLY_TAP_CFG 16'h0000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_INT_DATAWIDTH 1 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_CLKMUX_PD 1'b1 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_CLK25_DIV 7 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]

 ##--------------TX Driver and OOB Signalling------------------
set_property TX_EIDLE_ASSERT_DELAY 3'b110 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_EIDLE_DEASSERT_DELAY 3'b100 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_LOOPBACK_DRIVE_HIZ "FALSE" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MAINCURSOR_SEL 1'b0 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_DRIVE_MODE "DIRECT" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------------------TX Gearbox---------------------------
set_property TXGEARBOX_EN "FALSE" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]

 ##----------------TX Attributes for PCI Express---------------
set_property TX_MARGIN_FULL_0 7'b1001110 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_FULL_1 7'b1001001 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_FULL_2 7'b1000101 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_FULL_3 7'b1000010 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_FULL_4 7'b1000000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_LOW_0 7'b1000110 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_LOW_1 7'b1000100 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_LOW_2 7'b1000010 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_LOW_3 7'b1000000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_LOW_4 7'b1000000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPCSRESET_TIME 5'b00001 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPH_CFG 16'h0780 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPHDLY_CFG 24'h084020 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPH_MONITOR_SEL 5'b00000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPMARESET_TIME 5'b00001 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_QPI_STATUS_EN 1'b0 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_RXDETECT_CFG 14'h1832 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_RXDETECT_REF 3'b100 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_XCLK_SEL "TXOUT" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property UCODEER_CLR 1'b0 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- JTAG Attributes ---------------
set_property ACJTAG_DEBUG_MODE 1'b0 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ACJTAG_MODE 1'b0 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ACJTAG_RESET 1'b0 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ADAPT_CFG0 20'h00C10 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CFOK_CFG 42'h24800040E80 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CFOK_CFG2 6'h20 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CFOK_CFG3 6'h20 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- EYESCAN ---------------
set_property ES_CLK_PHASE_SEL 1'b0 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PMA_RSV5 4'h0 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RESET_POWERSAVE_DISABLE 1'b0 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- RX Phase Interpolator ---------------
set_property RXPI_CFG0 2'b0 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPI_CFG1 2'b11 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPI_CFG2 2'b11 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPI_CFG3 2'b11 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPI_CFG4 1'b0 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPI_CFG5 1'b0 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPI_CFG6 3'b100 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]

 ##------------RX Decision Feedback Equalizer(DFE)-------------
set_property RX_DFELPM_CFG0 4'b0110 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFELPM_CFG1 1'b0 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFELPM_KLKH_AGC_STUP_EN 1'b1 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_AGC_CFG0 2'b0 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_AGC_CFG1 3'b010 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_AGC_CFG2 4'b0000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_AGC_OVRDEN 1'b1 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_H6_CFG 11'h020 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_H7_CFG 11'h020 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KH_CFG0 2'b10 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KH_CFG1 1'h2 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KH_CFG2 4'b0010 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KH_OVRDEN 1'b1 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KL_CFG0 2'b01 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KL_CFG1 3'b010 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KL_CFG2 4'b0010 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KL_OVRDEN 1'b1 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_ST_CFG 54'h00E100000C003F [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- TX Phase Interpolator ---------------
set_property TXPI_CFG0 2'b00 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_CFG1 2'b00 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_CFG2 2'b00 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_CFG3 1'b0 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_CFG4 1'b0 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_CFG5 3'b100 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_GREY_SEL 1'b0 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_INVSTROBE_SEL 1'b0 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_PPMCLK_SEL "TXUSRCLK2" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_PPM_CFG 8'h00 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_SYNFREQ_PPM 3'b000 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_RXDETECT_PRECHARGE_TIME 17'h155CC [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property USE_PCS_CLK_PHASE_SEL 1'b0 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- LOOPBACK ---------------
set_property LOOPBACK_CFG 1'b0 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- OOB Signalling ---------------
set_property RXOOB_CLK_CFG "PMA" [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXOSCALRESET_TIME 5'b00011 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXOSCALRESET_TIMEOUT 6'b0 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property A_RXOSCALRESET 1'b0 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXOOB_CFG 1'b0 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- RX SYNC ---------------
set_property RXSYNC_MULTILANE 1'b0 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXSYNC_OVRD 1'b0 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXSYNC_SKIP_DA 1'b0 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- TX SYNC ---------------
set_property TXSYNC_MULTILANE 1'b0 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXSYNC_OVRD 1'b0 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXSYNC_SKIP_DA 1'b0 [get_cells u_ibert_core/inst/QUAD[3].u_q/CH[*].u_ch/u_gthe2_channel]

##
## Attribute Values for QUAD[19] - Common
##
set_property BIAS_CFG 64'h0000040000001050 [get_cells u_ibert_core/inst/QUAD[3].u_q/u_common/u_gthe2_common]
set_property COMMON_CFG 32'h0000001C [get_cells u_ibert_core/inst/QUAD[3].u_q/u_common/u_gthe2_common]
set_property QPLL_CFG 27'h0480187 [get_cells u_ibert_core/inst/QUAD[3].u_q/u_common/u_gthe2_common]
set_property QPLL_CLKOUT_CFG 4'b1111 [get_cells u_ibert_core/inst/QUAD[3].u_q/u_common/u_gthe2_common]
set_property QPLL_COARSE_FREQ_OVRD_EN 1'b0 [get_cells u_ibert_core/inst/QUAD[3].u_q/u_common/u_gthe2_common]
set_property QPLL_CP_MONITOR_EN 1'b0 [get_cells u_ibert_core/inst/QUAD[3].u_q/u_common/u_gthe2_common]
set_property QPLL_FBDIV_MONITOR_EN 1'b0 [get_cells u_ibert_core/inst/QUAD[3].u_q/u_common/u_gthe2_common]
set_property QPLL_INIT_CFG 24'h000006 [get_cells u_ibert_core/inst/QUAD[3].u_q/u_common/u_gthe2_common]
set_property QPLL_LOCK_CFG 16'h05E8 [get_cells u_ibert_core/inst/QUAD[3].u_q/u_common/u_gthe2_common]
set_property QPLL_LPF 4'b1111 [get_cells u_ibert_core/inst/QUAD[3].u_q/u_common/u_gthe2_common]
set_property QPLL_REFCLK_DIV 1 [get_cells u_ibert_core/inst/QUAD[3].u_q/u_common/u_gthe2_common]
set_property QPLL_RP_COMP 1'b0 [get_cells u_ibert_core/inst/QUAD[3].u_q/u_common/u_gthe2_common]
set_property QPLL_VTRL_RESET 2'b00 [get_cells u_ibert_core/inst/QUAD[3].u_q/u_common/u_gthe2_common]
set_property RCAL_CFG 2'b00 [get_cells u_ibert_core/inst/QUAD[3].u_q/u_common/u_gthe2_common]
set_property RSVD_ATTR0 16'h0000 [get_cells u_ibert_core/inst/QUAD[3].u_q/u_common/u_gthe2_common]
set_property RSVD_ATTR1 16'h0000 [get_cells u_ibert_core/inst/QUAD[3].u_q/u_common/u_gthe2_common]
##
## Attribute Values for QUAD[20] - Channel
##

 ##------Comma Detection and Alignment---------
set_property ALIGN_COMMA_DOUBLE "FALSE" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ALIGN_COMMA_ENABLE 10'b0001111111 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ALIGN_COMMA_WORD 1 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ALIGN_MCOMMA_DET "TRUE" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ALIGN_MCOMMA_VALUE 10'b1010000011 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ALIGN_PCOMMA_DET "TRUE" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ALIGN_PCOMMA_VALUE 10'b0101111100 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property DEC_MCOMMA_DETECT "FALSE" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property DEC_PCOMMA_DETECT "FALSE" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property DEC_VALID_COMMA_ONLY "FALSE" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property DMONITOR_CFG 24'h000A00 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]

 ##--------------Channel Bonding--------------
set_property CBCC_DATA_SOURCE_SEL "DECODED" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_KEEP_ALIGN "FALSE" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_MAX_SKEW 7 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_LEN 1 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_1_1 10'b0101111100 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_1_2 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_1_3 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_1_4 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_1_ENABLE 4'b1111 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_2_1 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_2_2 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_2_3 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_2_4 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_2_ENABLE 4'b1111 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CHAN_BOND_SEQ_2_USE "FALSE" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------Clock Correction------------
set_property CLK_COR_KEEP_IDLE "FALSE" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_MAX_LAT 19.0 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_MIN_LAT 15.0 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_PRECEDENCE "TRUE" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_CORRECT_USE "FALSE" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_REPEAT_WAIT 0 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_LEN 1 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_1_1 10'b0100011100 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_1_2 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_1_3 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_1_4 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_1_ENABLE 4'b1111 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_2_1 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_2_2 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_2_3 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_2_4 10'b0100000000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_2_ENABLE 4'b1111 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CLK_COR_SEQ_2_USE "FALSE" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------Channel PLL----------------------
set_property CPLL_CFG 24'hBC07DC [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CPLL_FBDIV 1 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CPLL_FBDIV_45 4 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CPLL_INIT_CFG 24'h00001E [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CPLL_LOCK_CFG 16'h01E8 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CPLL_REFCLK_DIV 1 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXOUT_DIV 1 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXOUT_DIV 1 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------------Eyescan--------------
set_property ES_CONTROL 6'b000000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_ERRDET_EN "TRUE" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_EYE_SCAN_EN "TRUE" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_HORZ_OFFSET 12'h000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_PMA_CFG 10'b0000000000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_PRESCALE 5'b00000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_QUALIFIER 80'h00000000000000000000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_QUAL_MASK 80'h11111111111111111111 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_SDATA_MASK 80'h00000000000000000000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ES_VERT_OFFSET 9'b010000000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property FTS_DESKEW_SEQ_ENABLE 4'b1111 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property FTS_LANE_DESKEW_CFG 4'b1111 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property FTS_LANE_DESKEW_EN "FALSE" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property GEARBOX_MODE 3'b000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property OUTREFCLK_SEL_INV 2'b11 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PCS_PCIE_EN "FALSE" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PCS_RSVD_ATTR 48'h000000000000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PMA_RSV 32'h00000080 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PMA_RSV2 32'h1C00000A [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PMA_RSV3 2'b00 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PMA_RSV4 15'h0008 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_BIAS_CFG 24'h0C0010 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------Rx Elastic Buffer and Phase alignment-------------
set_property RXBUF_ADDR_MODE "FAST" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_EIDLE_HI_CNT 4'b1000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_EIDLE_LO_CNT 4'b0000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_EN "TRUE" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_BUFFER_CFG 6'b000000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_RESET_ON_CB_CHANGE "TRUE" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_RESET_ON_COMMAALIGN "FALSE" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_RESET_ON_EIDLE "FALSE" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_RESET_ON_RATE_CHANGE "TRUE" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUFRESET_TIME 5'b00001 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_THRESH_OVFLW 61 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_THRESH_OVRD "FALSE" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXBUF_THRESH_UNDFLW 4 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXDLY_CFG 16'h001F [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXDLY_LCFG 9'h030 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXDLY_TAP_CFG 16'h0000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------RX driver, OOB signalling, Coupling and Eq., CDR------------
set_property RXCDR_CFG 83'h0002007FE2000C208001A [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXCDRFREQRESET_TIME 5'b00001 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXCDR_FR_RESET_ON_EIDLE 1'b0 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXCDR_HOLD_DURING_EIDLE 1'b0 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXCDR_LOCK_CFG 6'b010101 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXCDR_PH_RESET_ON_EIDLE 1'b0 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXCDRPHRESET_TIME 5'b00001 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXDFELPMRESET_TIME 7'b0001111 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXOOB_CFG 7'b0000110 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------------------RX Interface-------------------------
set_property RX_INT_DATAWIDTH 1 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DATA_WIDTH 32 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_CLKMUX_PD 1'b1 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_CLK25_DIV 7 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_CM_SEL 2'b11 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_CM_TRIM 4'b1010 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DDI_SEL 6'b000000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DEBUG_CFG 12'b000000000000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
 
 ##------------RX Decision Feedback Equalizer(DFE)-------------
set_property RX_DEFER_RESET_BUF_EN "TRUE" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_GAIN_CFG 23'h0020C0 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_H2_CFG 12'b000000000000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_H3_CFG 12'b000001000000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_H4_CFG 11'b00011100000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_H5_CFG 11'b00011100000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_LPM_HOLD_DURING_EIDLE 1'b0 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_CFG 33'h041000310 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_LPM_CFG 16'h0080 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_OS_CFG 13'b0000010000000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_UT_CFG 17'b00011100000000000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_VP_CFG 17'b00011101010100011 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DISPERR_SEQ_MATCH "TRUE" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------------------RX Gearbox---------------------------
set_property RXGEARBOX_EN "FALSE" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXISCANRESET_TIME 5'b00001 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXLPM_HF_CFG 14'b00001000000000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXLPM_LF_CFG 18'b001001000000000000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPCSRESET_TIME 5'b00001 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPH_CFG 24'h000000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPHDLY_CFG 24'h084020 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPH_MONITOR_SEL 5'b00000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPMARESET_TIME 5'b00011 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------------------PRBS Detection-----------------------
set_property RXPRBS_ERR_LOOPBACK 1'b0 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_SIG_VALID_DLY 10 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXSLIDE_AUTO_WAIT 7 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXSLIDE_MODE "off" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_XCLK_SEL "RXREC" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------RX Attributes for PCI Express/SATA/SAS----------
set_property PD_TRANS_TIME_FROM_P2 12'h03c [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PD_TRANS_TIME_NONE_P2 8'h3c [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PD_TRANS_TIME_TO_P2 8'h64 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SAS_MAX_COM 64 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SAS_MIN_COM 36 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_BURST_SEQ_LEN 4'b1111 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_BURST_VAL 3'b100 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_CPLL_CFG "VCO_3000MHZ" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_EIDLE_VAL 3'b100 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_MAX_BURST 8 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_MAX_INIT 21 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_MAX_WAKE 7 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_MIN_BURST 4 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_MIN_INIT 12 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SATA_MIN_WAKE 4 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property SHOW_REALIGN_COMMA "TRUE" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TERM_RCAL_CFG 15'b100001000010000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TERM_RCAL_OVRD 3'b000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TRANS_TIME_RATE 8'h0E [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TST_RSV 32'h00000000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]

 ##------------TX Buffering and Phase Alignment----------------
set_property TXBUF_EN "TRUE" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXBUF_RESET_ON_RATE_CHANGE "FALSE" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------------------TX Interface-------------------------
set_property TX_DATA_WIDTH 32 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_DEEMPH0 6'b000000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_DEEMPH1 6'b000000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXDLY_CFG 16'h001F [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXDLY_LCFG 9'h030 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXDLY_TAP_CFG 16'h0000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_INT_DATAWIDTH 1 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_CLKMUX_PD 1'b1 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_CLK25_DIV 7 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]

 ##--------------TX Driver and OOB Signalling------------------
set_property TX_EIDLE_ASSERT_DELAY 3'b110 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_EIDLE_DEASSERT_DELAY 3'b100 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_LOOPBACK_DRIVE_HIZ "FALSE" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MAINCURSOR_SEL 1'b0 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_DRIVE_MODE "DIRECT" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]

 ##-----------------------TX Gearbox---------------------------
set_property TXGEARBOX_EN "FALSE" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]

 ##----------------TX Attributes for PCI Express---------------
set_property TX_MARGIN_FULL_0 7'b1001110 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_FULL_1 7'b1001001 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_FULL_2 7'b1000101 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_FULL_3 7'b1000010 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_FULL_4 7'b1000000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_LOW_0 7'b1000110 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_LOW_1 7'b1000100 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_LOW_2 7'b1000010 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_LOW_3 7'b1000000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_MARGIN_LOW_4 7'b1000000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPCSRESET_TIME 5'b00001 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPH_CFG 16'h0780 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPHDLY_CFG 24'h084020 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPH_MONITOR_SEL 5'b00000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPMARESET_TIME 5'b00001 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_QPI_STATUS_EN 1'b0 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_RXDETECT_CFG 14'h1832 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_RXDETECT_REF 3'b100 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_XCLK_SEL "TXOUT" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property UCODEER_CLR 1'b0 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- JTAG Attributes ---------------
set_property ACJTAG_DEBUG_MODE 1'b0 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ACJTAG_MODE 1'b0 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ACJTAG_RESET 1'b0 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property ADAPT_CFG0 20'h00C10 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CFOK_CFG 42'h24800040E80 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CFOK_CFG2 6'h20 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property CFOK_CFG3 6'h20 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- EYESCAN ---------------
set_property ES_CLK_PHASE_SEL 1'b0 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property PMA_RSV5 4'h0 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RESET_POWERSAVE_DISABLE 1'b0 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- RX Phase Interpolator ---------------
set_property RXPI_CFG0 2'b0 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPI_CFG1 2'b11 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPI_CFG2 2'b11 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPI_CFG3 2'b11 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPI_CFG4 1'b0 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPI_CFG5 1'b0 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXPI_CFG6 3'b100 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]

 ##------------RX Decision Feedback Equalizer(DFE)-------------
set_property RX_DFELPM_CFG0 4'b0110 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFELPM_CFG1 1'b0 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFELPM_KLKH_AGC_STUP_EN 1'b1 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_AGC_CFG0 2'b0 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_AGC_CFG1 3'b010 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_AGC_CFG2 4'b0000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_AGC_OVRDEN 1'b1 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_H6_CFG 11'h020 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_H7_CFG 11'h020 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KH_CFG0 2'b10 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KH_CFG1 1'h2 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KH_CFG2 4'b0010 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KH_OVRDEN 1'b1 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KL_CFG0 2'b01 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KL_CFG1 3'b010 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KL_CFG2 4'b0010 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_KL_LPM_KL_OVRDEN 1'b1 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RX_DFE_ST_CFG 54'h00E100000C003F [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- TX Phase Interpolator ---------------
set_property TXPI_CFG0 2'b00 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_CFG1 2'b00 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_CFG2 2'b00 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_CFG3 1'b0 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_CFG4 1'b0 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_CFG5 3'b100 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_GREY_SEL 1'b0 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_INVSTROBE_SEL 1'b0 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_PPMCLK_SEL "TXUSRCLK2" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_PPM_CFG 8'h00 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXPI_SYNFREQ_PPM 3'b000 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TX_RXDETECT_PRECHARGE_TIME 17'h155CC [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property USE_PCS_CLK_PHASE_SEL 1'b0 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- LOOPBACK ---------------
set_property LOOPBACK_CFG 1'b0 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- OOB Signalling ---------------
set_property RXOOB_CLK_CFG "PMA" [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXOSCALRESET_TIME 5'b00011 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXOSCALRESET_TIMEOUT 6'b0 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property A_RXOSCALRESET 1'b0 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXOOB_CFG 1'b0 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- RX SYNC ---------------
set_property RXSYNC_MULTILANE 1'b0 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXSYNC_OVRD 1'b0 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property RXSYNC_SKIP_DA 1'b0 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]

 ##---------------- TX SYNC ---------------
set_property TXSYNC_MULTILANE 1'b0 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXSYNC_OVRD 1'b0 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]
set_property TXSYNC_SKIP_DA 1'b0 [get_cells u_ibert_core/inst/QUAD[4].u_q/CH[*].u_ch/u_gthe2_channel]

##
## Attribute Values for QUAD[20] - Common
##
set_property BIAS_CFG 64'h0000040000001050 [get_cells u_ibert_core/inst/QUAD[4].u_q/u_common/u_gthe2_common]
set_property COMMON_CFG 32'h0000001C [get_cells u_ibert_core/inst/QUAD[4].u_q/u_common/u_gthe2_common]
set_property QPLL_CFG 27'h0480187 [get_cells u_ibert_core/inst/QUAD[4].u_q/u_common/u_gthe2_common]
set_property QPLL_CLKOUT_CFG 4'b1111 [get_cells u_ibert_core/inst/QUAD[4].u_q/u_common/u_gthe2_common]
set_property QPLL_COARSE_FREQ_OVRD_EN 1'b0 [get_cells u_ibert_core/inst/QUAD[4].u_q/u_common/u_gthe2_common]
set_property QPLL_CP_MONITOR_EN 1'b0 [get_cells u_ibert_core/inst/QUAD[4].u_q/u_common/u_gthe2_common]
set_property QPLL_FBDIV_MONITOR_EN 1'b0 [get_cells u_ibert_core/inst/QUAD[4].u_q/u_common/u_gthe2_common]
set_property QPLL_INIT_CFG 24'h000006 [get_cells u_ibert_core/inst/QUAD[4].u_q/u_common/u_gthe2_common]
set_property QPLL_LOCK_CFG 16'h05E8 [get_cells u_ibert_core/inst/QUAD[4].u_q/u_common/u_gthe2_common]
set_property QPLL_LPF 4'b1111 [get_cells u_ibert_core/inst/QUAD[4].u_q/u_common/u_gthe2_common]
set_property QPLL_REFCLK_DIV 1 [get_cells u_ibert_core/inst/QUAD[4].u_q/u_common/u_gthe2_common]
set_property QPLL_RP_COMP 1'b0 [get_cells u_ibert_core/inst/QUAD[4].u_q/u_common/u_gthe2_common]
set_property QPLL_VTRL_RESET 2'b00 [get_cells u_ibert_core/inst/QUAD[4].u_q/u_common/u_gthe2_common]
set_property RCAL_CFG 2'b00 [get_cells u_ibert_core/inst/QUAD[4].u_q/u_common/u_gthe2_common]
set_property RSVD_ATTR0 16'h0000 [get_cells u_ibert_core/inst/QUAD[4].u_q/u_common/u_gthe2_common]
set_property RSVD_ATTR1 16'h0000 [get_cells u_ibert_core/inst/QUAD[4].u_q/u_common/u_gthe2_common]

