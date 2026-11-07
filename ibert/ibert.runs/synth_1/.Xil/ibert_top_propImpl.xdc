set_property SRC_FILE_INFO {cfile:c:/Users/lskje/Desktop/FPGA_Orderbook/ibert/ibert.gen/sources_1/ip/ibert_7series_gth_0/synth/ibert_waivers.xdc rfile:../../../ibert.gen/sources_1/ip/ibert_7series_gth_0/synth/ibert_waivers.xdc id:1 order:EARLY scoped_inst:u_ibert_core/inst} [current_design]
set_property SRC_FILE_INFO {cfile:C:/Users/lskje/Desktop/FPGA_Orderbook/ibert/ibert.srcs/constrs_1/new/ibert_top.xdc rfile:../../../ibert.srcs/constrs_1/new/ibert_top.xdc id:2} [current_design]
current_instance u_ibert_core/inst
set_property src_info {type:SCOPED_XDC file:1 line:7 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-1} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-1 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*UUT_MASTER/U_ICON_INTERFACE/U_CMD*_STAT/stat_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*UUT_MASTER/U_ICON_INTERFACE/U_CMD*_STAT/shift_reg_in_reg[*]}]]
set_property src_info {type:SCOPED_XDC file:1 line:11 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-1} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-1 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_CHANNEL_REGS/reg_*/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_PATTERN_HANDLER/gen32.patchk20/patgen_rx/pat_id_r1_reg[*]}]]
set_property src_info {type:SCOPED_XDC file:1 line:15 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-1} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-1 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_CHANNEL_REGS/reg_*/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_PATTERN_HANDLER/gen32.patgen32/pat_id_r1_reg[*]}]]
set_property src_info {type:SCOPED_XDC file:1 line:19 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-1} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-1 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_RXUSRCLK*_FREQ_COUNTER/state_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*CE} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_RXUSRCLK*_FREQ_COUNTER/testclk_cnt_reg[*]}]]
set_property src_info {type:SCOPED_XDC file:1 line:23 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-1} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-1 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_TXUSRCLK*_FREQ_COUNTER/state_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*CE} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_TXUSRCLK*_FREQ_COUNTER/testclk_cnt_reg[*]}]]
set_property src_info {type:SCOPED_XDC file:1 line:27 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-1} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-1 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_RESET_CONTROLLER/GTTXRESET_O_reg}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_PATTERN_HANDLER/gen32.patgen32/init_r1_reg}]]
set_property src_info {type:SCOPED_XDC file:1 line:31 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-1} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-1 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_CHANNEL_REGS/reg_300/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_PATTERN_HANDLER/tei_dly1_reg}]]
set_property src_info {type:SCOPED_XDC file:1 line:35 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-1} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-1 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*U_ICON/U_CMD/iTARGET_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*UUT_MASTER/U_ICON_INTERFACE/U_CMD*/ctl_reg_en_reg[*]}]]
set_property src_info {type:SCOPED_XDC file:1 line:39 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-1} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-1 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*U_ICON/U_SYNC/SYNC_reg}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*UUT_MASTER/U_ICON_INTERFACE/U_CMD*/ctl_reg_en_reg[*]}]]
set_property src_info {type:SCOPED_XDC file:1 line:43 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-1} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-1 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*RXUSRCLK2*} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/u_gthe2_channel}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_RESET_CONTROLLER/rxresetdone_dly1_reg}]]
set_property src_info {type:SCOPED_XDC file:1 line:47 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-1} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-1 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_PATTERN_HANDLER/gen32.patchk20/link_reg}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_RXCDR_RESET/link_r_reg}]]
set_property src_info {type:SCOPED_XDC file:1 line:51 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-1} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-1 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*RXUSRCLK*} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/u_gthe2_channel}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_RXCDR_RESET/rxresetdone_r_reg}]]
set_property src_info {type:SCOPED_XDC file:1 line:55 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-1} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-1 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*TXUSRCLK*} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/u_gthe2_channel}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_RESET_CONTROLLER/txresetdone_dly1_reg}]]
set_property src_info {type:SCOPED_XDC file:1 line:59 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-1} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-1 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*UUT_MASTER/U_ICON_INTERFACE/U_CMD*_STAT/stat_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*UUT_MASTER/U_ICON_INTERFACE/icn_cmd_dout_reg}]]
set_property src_info {type:SCOPED_XDC file:1 line:63 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-1} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-1 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*UUT_MASTER/U_ICON_INTERFACE/U_CMD*/stat_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*UUT_MASTER/U_ICON_INTERFACE/icn_cmd_dout_reg}]]
set_property src_info {type:SCOPED_XDC file:1 line:67 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-1} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-1 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*U_ICON/iDATA_CMD_reg}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*CE} -of_objects [get_cells -hierarchical -filter {NAME =~*U_ICON/U_CMD/iTARGET_reg[*]}]]
set_property src_info {type:SCOPED_XDC file:1 line:71 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-1} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-1 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*U_ICON/iDATA_CMD_reg}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*R} -of_objects [get_cells -hierarchical -filter {NAME =~*U_ICON/U_SYNC/SYNC_reg}]]
set_property src_info {type:SCOPED_XDC file:1 line:75 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-1} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-1 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*U_ICON/iDATA_CMD_reg}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*R} -of_objects [get_cells -hierarchical -filter {NAME =~*U_ICON/U_SYNC/iSYNC_WORD_reg[*]}]]
set_property src_info {type:SCOPED_XDC file:1 line:88 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-10} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-10 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*UUT_MASTER/U_ICON_INTERFACE/U_CMD*/ctl_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~*UUT_MASTER/U_ICON_INTERFACE/U_CMD*_RD/U_RD_FIFO/SUBCORE_FIFO.xsdb_rdfifo_inst/inst_fifo_gen/gconvfifo.rf/grf.rf/rstblk/ngwrdrst.grst.g7serrst.rst_rd_reg1_reg}]]
set_property src_info {type:SCOPED_XDC file:1 line:92 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-10} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-10 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*UUT_MASTER/U_ICON_INTERFACE/U_CMD*/ctl_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~*UUT_MASTER/U_ICON_INTERFACE/U_CMD*_WR/U_WR_FIFO/SUBCORE_FIFO.xsdb_wrfifo_inst/inst_fifo_gen/gconvfifo.rf/grf.rf/rstblk/ngwrdrst.grst.g7serrst.rst_wr_reg1_reg}]]
set_property src_info {type:SCOPED_XDC file:1 line:96 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-10} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-10 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_PATTERN_HANDLER/gen32.patchk20/i_ones_counter/ANY_ONE_O_reg}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_PATTERN_HANDLER/u_lev/out_i_reg[*]}]]
set_property src_info {type:SCOPED_XDC file:1 line:100 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-10} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-10 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_RESET_CONTROLLER/mgt_reset_dly*_reg}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_TXUSRCLK*_FREQ_COUNTER/rst_i_dly1_reg}]]
set_property src_info {type:SCOPED_XDC file:1 line:104 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-10} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-10 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_RESET_CONTROLLER/mgt_reset_dly*_reg}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_RXUSRCLK*_FREQ_COUNTER/rst_i_dly1_reg}]]
set_property src_info {type:SCOPED_XDC file:1 line:108 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-10} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-10 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*U_ICON/U_CMD/iTARGET_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*UUT_MASTER/U_ICON_INTERFACE/U_CMD*/stat_reg_ld_reg[*]}]]
set_property src_info {type:SCOPED_XDC file:1 line:112 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-10} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-10 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*U_ICON/U_SYNC/SYNC_reg}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*UUT_MASTER/U_ICON_INTERFACE/U_CMD*/stat_reg_ld_reg[*]}]]
set_property src_info {type:SCOPED_XDC file:1 line:116 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-10} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-10 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*U_ICON/U_CMD/iTARGET_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*UUT_MASTER/U_ICON_INTERFACE/U_CMD*/ctl_reg_en_reg[*]}]]
set_property src_info {type:SCOPED_XDC file:1 line:120 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-10} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-10 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_CHANNEL_REGS/reg_*/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_PATTERN_HANDLER/u_lev/out_i_reg[*]}]]
set_property src_info {type:SCOPED_XDC file:1 line:124 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-10} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-10 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*U_ICON/U_CMD/iTARGET_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~*UUT_MASTER/U_ICON_INTERFACE/U_CMD*_WR/U_WR_FIFO/SUBCORE_FIFO.xsdb_wrfifo_inst/inst_fifo_gen/gconvfifo.rf/grf.rf/rstblk/ngwrdrst.grst.g7serrst.rst_rd_reg1_reg}]]
set_property src_info {type:SCOPED_XDC file:1 line:128 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-10} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-10 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*U_ICON/U_CMD/iTARGET_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~*UUT_MASTER/U_ICON_INTERFACE/U_CMD*_RD/U_RD_FIFO/SUBCORE_FIFO.xsdb_rdfifo_inst/inst_fifo_gen/gconvfifo.rf/grf.rf/rstblk/ngwrdrst.grst.g7serrst.rst_wr_reg1_reg}]]
set_property src_info {type:SCOPED_XDC file:1 line:132 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-10} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-10 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*U_ICON/U_SYNC/SYNC_reg}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~*UUT_MASTER/U_ICON_INTERFACE/U_CMD*_RD/U_RD_FIFO/SUBCORE_FIFO.xsdb_rdfifo_inst/inst_fifo_gen/gconvfifo.rf/grf.rf/rstblk/ngwrdrst.grst.g7serrst.rst_wr_reg1_reg}]]
set_property src_info {type:SCOPED_XDC file:1 line:136 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-10} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-10 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*U_ICON/U_SYNC/SYNC_reg}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~*UUT_MASTER/U_ICON_INTERFACE/U_CMD*_WR/U_WR_FIFO/SUBCORE_FIFO.xsdb_wrfifo_inst/inst_fifo_gen/gconvfifo.rf/grf.rf/rstblk/ngwrdrst.grst.g7serrst.rst_rd_reg1_reg}]]
set_property src_info {type:SCOPED_XDC file:1 line:146 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-11} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-11 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*UUT_MASTER/U_ICON_INTERFACE/U_CMD*/ctl_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~*UUT_MASTER/U_ICON_INTERFACE/U_CMD*_RD/U_RD_FIFO/SUBCORE_FIFO.xsdb_rdfifo_inst/inst_fifo_gen/gconvfifo.rf/grf.rf/rstblk/ngwrdrst.grst.g7serrst.rst_rd_reg1_reg}]]
set_property src_info {type:SCOPED_XDC file:1 line:150 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-11} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-11 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*UUT_MASTER/U_ICON_INTERFACE/U_CMD*/ctl_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~*UUT_MASTER/U_ICON_INTERFACE/U_CMD*_WR/U_WR_FIFO/SUBCORE_FIFO.xsdb_wrfifo_inst/inst_fifo_gen/gconvfifo.rf/grf.rf/rstblk/ngwrdrst.grst.g7serrst.rst_wr_reg1_reg}]]
set_property src_info {type:SCOPED_XDC file:1 line:154 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-11} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-11 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_RESET_CONTROLLER/mgt_reset_dly*_reg}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_RXUSRCLK*_FREQ_COUNTER/rst_i_dly1_reg}]]
set_property src_info {type:SCOPED_XDC file:1 line:158 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-11} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-11 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_RESET_CONTROLLER/mgt_reset_dly*_reg}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_TXUSRCLK*_FREQ_COUNTER/rst_i_dly1_reg}]]
set_property src_info {type:SCOPED_XDC file:1 line:162 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-11} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-11 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*U_ICON/U_CMD/iTARGET_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~*UUT_MASTER/U_ICON_INTERFACE/U_CMD*_RD/U_RD_FIFO/SUBCORE_FIFO.xsdb_rdfifo_inst/inst_fifo_gen/gconvfifo.rf/grf.rf/rstblk/ngwrdrst.grst.g7serrst.rst_wr_reg1_reg}]]
set_property src_info {type:SCOPED_XDC file:1 line:166 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-11} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-11 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*U_ICON/U_CMD/iTARGET_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~*UUT_MASTER/U_ICON_INTERFACE/U_CMD*_WR/U_WR_FIFO/SUBCORE_FIFO.xsdb_wrfifo_inst/inst_fifo_gen/gconvfifo.rf/grf.rf/rstblk/ngwrdrst.grst.g7serrst.rst_rd_reg1_reg}]]
set_property src_info {type:SCOPED_XDC file:1 line:170 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-11} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-11 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*U_ICON/U_SYNC/SYNC_reg}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~*UUT_MASTER/U_ICON_INTERFACE/U_CMD*_RD/U_RD_FIFO/SUBCORE_FIFO.xsdb_rdfifo_inst/inst_fifo_gen/gconvfifo.rf/grf.rf/rstblk/ngwrdrst.grst.g7serrst.rst_wr_reg1_reg}]]
set_property src_info {type:SCOPED_XDC file:1 line:174 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-11} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-11 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*U_ICON/U_SYNC/SYNC_reg}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~*UUT_MASTER/U_ICON_INTERFACE/U_CMD*_WR/U_WR_FIFO/SUBCORE_FIFO.xsdb_wrfifo_inst/inst_fifo_gen/gconvfifo.rf/grf.rf/rstblk/ngwrdrst.grst.g7serrst.rst_rd_reg1_reg}]]
set_property src_info {type:SCOPED_XDC file:1 line:186 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-13} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-13 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_CHANNEL_REGS/reg_*/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*RX8B10BEN} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/u_gthe*_channel}]]
set_property src_info {type:SCOPED_XDC file:1 line:190 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-13} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-13 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_CHANNEL_REGS/reg_*/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*RXCHBONDEN} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/u_gthe*_channel}]]
set_property src_info {type:SCOPED_XDC file:1 line:194 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-13} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-13 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_CHANNEL_REGS/reg_*/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*RXCHBONDMASTER} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/u_gthe*_channel}]]
set_property src_info {type:SCOPED_XDC file:1 line:198 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-13} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-13 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_CHANNEL_REGS/reg_*/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*RXCHBONDSLAVE} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/u_gthe*_channel}]]
set_property src_info {type:SCOPED_XDC file:1 line:202 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-13} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-13 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_CHANNEL_REGS/reg_*/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*RXCOMMADETEN} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/u_gthe*_channel}]]
set_property src_info {type:SCOPED_XDC file:1 line:206 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-13} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-13 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_CHANNEL_REGS/reg_*/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*RXGEARBOXSLIP} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/u_gthe*_channel}]]
set_property src_info {type:SCOPED_XDC file:1 line:210 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-13} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-13 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_CHANNEL_REGS/reg_*/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*RXMCOMMAALIGNEN} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/u_gthe*_channel}]]
set_property src_info {type:SCOPED_XDC file:1 line:214 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-13} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-13 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_CHANNEL_REGS/reg_*/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*RXPCOMMAALIGNEN} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/u_gthe*_channel}]]
set_property src_info {type:SCOPED_XDC file:1 line:218 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-13} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-13 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_CHANNEL_REGS/reg_*/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*RXPOLARITY} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/u_gthe*_channel}]]
set_property src_info {type:SCOPED_XDC file:1 line:222 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-13} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-13 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_CHANNEL_REGS/reg_*/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*RXPRBSCNTRESET} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/u_gthe*_channel}]]
set_property src_info {type:SCOPED_XDC file:1 line:226 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-13} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-13 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_CHANNEL_REGS/reg_*/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*RXSLIDE} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/u_gthe*_channel}]]
set_property src_info {type:SCOPED_XDC file:1 line:230 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-13} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-13 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_CHANNEL_REGS/reg_*/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*SETERRSTATUS} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/u_gthe*_channel}]]
set_property src_info {type:SCOPED_XDC file:1 line:234 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-13} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-13 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_CHANNEL_REGS/reg_*/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*RXCHBONDI[*]} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/u_gthe*_channel}]]
set_property src_info {type:SCOPED_XDC file:1 line:238 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-13} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-13 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_CHANNEL_REGS/reg_*/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*RXCHBONDLEVEL[*]} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/u_gthe*_channel}]]
set_property src_info {type:SCOPED_XDC file:1 line:242 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-13} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-13 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_CHANNEL_REGS/reg_*/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*RXPRBSSEL[*]} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/u_gthe*_channel}]]
set_property src_info {type:SCOPED_XDC file:1 line:246 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-13} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-13 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_CHANNEL_REGS/reg_*/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*RXRATE[*]} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/u_gthe*_channel}]]
set_property src_info {type:SCOPED_XDC file:1 line:250 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-13} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-13 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_CHANNEL_REGS/reg_*/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*TX8B10BEN} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/u_gthe*_channel}]]
set_property src_info {type:SCOPED_XDC file:1 line:254 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-13} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-13 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_CHANNEL_REGS/reg_*/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*TXCOMINIT} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/u_gthe*_channel}]]
set_property src_info {type:SCOPED_XDC file:1 line:258 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-13} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-13 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_CHANNEL_REGS/reg_*/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*TXCOMSAS} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/u_gthe*_channel}]]
set_property src_info {type:SCOPED_XDC file:1 line:262 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-13} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-13 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_CHANNEL_REGS/reg_*/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*TXCOMWAKE} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/u_gthe*_channel}]]
set_property src_info {type:SCOPED_XDC file:1 line:266 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-13} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-13 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_CHANNEL_REGS/reg_*/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*TXDETECTRX} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/u_gthe*_channel}]]
set_property src_info {type:SCOPED_XDC file:1 line:270 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-13} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-13 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_CHANNEL_REGS/reg_*/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*TXELECIDLE} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/u_gthe*_channel}]]
set_property src_info {type:SCOPED_XDC file:1 line:274 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-13} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-13 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_CHANNEL_REGS/reg_*/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*TXINHIBIT} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/u_gthe*_channel}]]
set_property src_info {type:SCOPED_XDC file:1 line:278 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-13} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-13 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_CHANNEL_REGS/reg_*/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*TXPIPPMEN} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/u_gthe*_channel}]]
set_property src_info {type:SCOPED_XDC file:1 line:282 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-13} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-13 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_CHANNEL_REGS/reg_*/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*TXPOLARITY} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/u_gthe*_channel}]]
set_property src_info {type:SCOPED_XDC file:1 line:286 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-13} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-13 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_CHANNEL_REGS/reg_*/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*TXPRBSFORCEERR} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/u_gthe*_channel}]]
set_property src_info {type:SCOPED_XDC file:1 line:290 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-13} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-13 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_CHANNEL_REGS/reg_*/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*TXSTARTSEQ} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/u_gthe*_channel}]]
set_property src_info {type:SCOPED_XDC file:1 line:294 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-13} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-13 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_CHANNEL_REGS/reg_*/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*TX8B10BBYPASS[*]} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/u_gthe*_channel}]]
set_property src_info {type:SCOPED_XDC file:1 line:298 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-13} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-13 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_CHANNEL_REGS/reg_*/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*TXHEADER[*]} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/u_gthe*_channel}]]
set_property src_info {type:SCOPED_XDC file:1 line:302 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-13} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-13 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_CHANNEL_REGS/reg_*/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*TXPRBSSEL[*]} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/u_gthe*_channel}]]
set_property src_info {type:SCOPED_XDC file:1 line:306 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-13} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-13 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_CHANNEL_REGS/reg_*/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*TXRATE[*]} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/u_gthe*_channel}]]
set_property src_info {type:SCOPED_XDC file:1 line:310 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-13} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-13 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_CHANNEL_REGS/reg_*/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*TXSEQUENCE[*]} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/u_gthe*_channel}]]
set_property src_info {type:SCOPED_XDC file:1 line:331 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-14} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-14 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_CHANNEL_REGS/reg_*/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*TXPD[*]} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/u_gthe*_channel}]]
set_property src_info {type:SCOPED_XDC file:1 line:335 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -type CDC -id {CDC-14} -user ibert_ultrascale_gty -tags "1168648" -description "CDC-14 waiver for CPLL Calibration logic" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/U_CHANNEL_REGS/reg_*/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[*]}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*TXPIPPMSTEPSIZE[*]} -of_objects [get_cells -hierarchical -filter {NAME =~*QUAD[*].u_q/CH[*].u_ch/u_gthe*_channel}]]
current_instance
set_property src_info {type:XDC file:2 line:9 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AH9 [get_ports clk25in]
set_property src_info {type:XDC file:2 line:14 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AL33 [get_ports fan]
set_property src_info {type:XDC file:2 line:21 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AH6 [get_ports {refclk0_p[0]}]   ;# MGTREFCLK0P_114
set_property src_info {type:XDC file:2 line:22 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AH5 [get_ports {refclk0_n[0]}]   ;# MGTREFCLK0N_114
set_property src_info {type:XDC file:2 line:24 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AB6 [get_ports {refclk0_p[1]}]   ;# MGTREFCLK0P_115
set_property src_info {type:XDC file:2 line:25 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AB5 [get_ports {refclk0_n[1]}]   ;# MGTREFCLK0N_115
set_property src_info {type:XDC file:2 line:27 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN T6 [get_ports {refclk0_p[2]}]   ;# MGTREFCLK0P_116
set_property src_info {type:XDC file:2 line:28 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN T5 [get_ports {refclk0_n[2]}]   ;# MGTREFCLK0N_116
set_property src_info {type:XDC file:2 line:30 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN M6 [get_ports {refclk0_p[3]}]   ;# MGTREFCLK0P_117
set_property src_info {type:XDC file:2 line:31 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN M5 [get_ports {refclk0_n[3]}]   ;# MGTREFCLK0N_117
set_property src_info {type:XDC file:2 line:33 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN F6 [get_ports {refclk0_p[4]}]   ;# MGTREFCLK0P_118
set_property src_info {type:XDC file:2 line:34 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN F5 [get_ports {refclk0_n[4]}]   ;# MGTREFCLK0N_118
set_property src_info {type:XDC file:2 line:38 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AP2  [get_ports {txp[0]}]  ;# MGTHTXP0_114
set_property src_info {type:XDC file:2 line:39 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AP1  [get_ports {txn[0]}]  ;# MGTHTXN0_114
set_property src_info {type:XDC file:2 line:40 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AP6  [get_ports {rxp[0]}]  ;# MGTHRXP0_114
set_property src_info {type:XDC file:2 line:41 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AP5  [get_ports {rxn[0]}]  ;# MGTHRXN0_114
set_property src_info {type:XDC file:2 line:42 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AN4  [get_ports {txp[1]}]  ;# MGTHTXP1_114
set_property src_info {type:XDC file:2 line:43 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AN3  [get_ports {txn[1]}]  ;# MGTHTXN1_114
set_property src_info {type:XDC file:2 line:44 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AM6  [get_ports {rxp[1]}]  ;# MGTHRXP1_114
set_property src_info {type:XDC file:2 line:45 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AM5  [get_ports {rxn[1]}]  ;# MGTHRXN1_114
set_property src_info {type:XDC file:2 line:46 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AM2  [get_ports {txp[2]}]  ;# MGTHTXP2_114
set_property src_info {type:XDC file:2 line:47 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AM1  [get_ports {txn[2]}]  ;# MGTHTXN2_114
set_property src_info {type:XDC file:2 line:48 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AL4  [get_ports {rxp[2]}]  ;# MGTHRXP2_114
set_property src_info {type:XDC file:2 line:49 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AL3  [get_ports {rxn[2]}]  ;# MGTHRXN2_114
set_property src_info {type:XDC file:2 line:50 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AK2  [get_ports {txp[3]}]  ;# MGTHTXP3_114
set_property src_info {type:XDC file:2 line:51 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AK1  [get_ports {txn[3]}]  ;# MGTHTXN3_114
set_property src_info {type:XDC file:2 line:52 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AJ4  [get_ports {rxp[3]}]  ;# MGTHRXP3_114
set_property src_info {type:XDC file:2 line:53 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AJ3  [get_ports {rxn[3]}]  ;# MGTHRXN3_114
set_property src_info {type:XDC file:2 line:54 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AH2  [get_ports {txp[4]}]  ;# MGTHTXP0_115
set_property src_info {type:XDC file:2 line:55 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AH1  [get_ports {txn[4]}]  ;# MGTHTXN0_115
set_property src_info {type:XDC file:2 line:56 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AG4  [get_ports {rxp[4]}]  ;# MGTHRXP0_115
set_property src_info {type:XDC file:2 line:57 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AG3  [get_ports {rxn[4]}]  ;# MGTHRXN0_115
set_property src_info {type:XDC file:2 line:58 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AF2  [get_ports {txp[5]}]  ;# MGTHTXP1_115
set_property src_info {type:XDC file:2 line:59 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AF1  [get_ports {txn[5]}]  ;# MGTHTXN1_115
set_property src_info {type:XDC file:2 line:60 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AF6  [get_ports {rxp[5]}]  ;# MGTHRXP1_115
set_property src_info {type:XDC file:2 line:61 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AF5  [get_ports {rxn[5]}]  ;# MGTHRXN1_115
set_property src_info {type:XDC file:2 line:62 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AD2  [get_ports {txp[6]}]  ;# MGTHTXP2_115
set_property src_info {type:XDC file:2 line:63 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AD1  [get_ports {txn[6]}]  ;# MGTHTXN2_115
set_property src_info {type:XDC file:2 line:64 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AE4  [get_ports {rxp[6]}]  ;# MGTHRXP2_115
set_property src_info {type:XDC file:2 line:65 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AE3  [get_ports {rxn[6]}]  ;# MGTHRXN2_115
set_property src_info {type:XDC file:2 line:66 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AB2  [get_ports {txp[7]}]  ;# MGTHTXP3_115
set_property src_info {type:XDC file:2 line:67 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AB1  [get_ports {txn[7]}]  ;# MGTHTXN3_115
set_property src_info {type:XDC file:2 line:68 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AC4  [get_ports {rxp[7]}]  ;# MGTHRXP3_115
set_property src_info {type:XDC file:2 line:69 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AC3  [get_ports {rxn[7]}]  ;# MGTHRXN3_115
set_property src_info {type:XDC file:2 line:70 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN Y2   [get_ports {txp[8]}]  ;# MGTHTXP0_116
set_property src_info {type:XDC file:2 line:71 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN Y1   [get_ports {txn[8]}]  ;# MGTHTXN0_116
set_property src_info {type:XDC file:2 line:72 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AA4  [get_ports {rxp[8]}]  ;# MGTHRXP0_116
set_property src_info {type:XDC file:2 line:73 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AA3  [get_ports {rxn[8]}]  ;# MGTHRXN0_116
set_property src_info {type:XDC file:2 line:74 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN V2   [get_ports {txp[9]}]  ;# MGTHTXP1_116
set_property src_info {type:XDC file:2 line:75 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN V1   [get_ports {txn[9]}]  ;# MGTHTXN1_116
set_property src_info {type:XDC file:2 line:76 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN W4   [get_ports {rxp[9]}]  ;# MGTHRXP1_116
set_property src_info {type:XDC file:2 line:77 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN W3   [get_ports {rxn[9]}]  ;# MGTHRXN1_116
set_property src_info {type:XDC file:2 line:78 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN T2   [get_ports {txp[10]}]  ;# MGTHTXP2_116
set_property src_info {type:XDC file:2 line:79 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN T1   [get_ports {txn[10]}]  ;# MGTHTXN2_116
set_property src_info {type:XDC file:2 line:80 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN U4   [get_ports {rxp[10]}]  ;# MGTHRXP2_116
set_property src_info {type:XDC file:2 line:81 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN U3   [get_ports {rxn[10]}]  ;# MGTHRXN2_116
set_property src_info {type:XDC file:2 line:82 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN P2   [get_ports {txp[11]}]  ;# MGTHTXP3_116
set_property src_info {type:XDC file:2 line:83 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN P1   [get_ports {txn[11]}]  ;# MGTHTXN3_116
set_property src_info {type:XDC file:2 line:84 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN R4   [get_ports {rxp[11]}]  ;# MGTHRXP3_116
set_property src_info {type:XDC file:2 line:85 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN R3   [get_ports {rxn[11]}]  ;# MGTHRXN3_116
set_property src_info {type:XDC file:2 line:86 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN M2   [get_ports {txp[12]}]  ;# MGTHTXP0_117
set_property src_info {type:XDC file:2 line:87 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN M1   [get_ports {txn[12]}]  ;# MGTHTXN0_117
set_property src_info {type:XDC file:2 line:88 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN N4   [get_ports {rxp[12]}]  ;# MGTHRXP0_117
set_property src_info {type:XDC file:2 line:89 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN N3   [get_ports {rxn[12]}]  ;# MGTHRXN0_117
set_property src_info {type:XDC file:2 line:90 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN K2   [get_ports {txp[13]}]  ;# MGTHTXP1_117
set_property src_info {type:XDC file:2 line:91 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN K1   [get_ports {txn[13]}]  ;# MGTHTXN1_117
set_property src_info {type:XDC file:2 line:92 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN L4   [get_ports {rxp[13]}]  ;# MGTHRXP1_117
set_property src_info {type:XDC file:2 line:93 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN L3   [get_ports {rxn[13]}]  ;# MGTHRXN1_117
set_property src_info {type:XDC file:2 line:94 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN H2   [get_ports {txp[14]}]  ;# MGTHTXP2_117
set_property src_info {type:XDC file:2 line:95 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN H1   [get_ports {txn[14]}]  ;# MGTHTXN2_117
set_property src_info {type:XDC file:2 line:96 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN K6   [get_ports {rxp[14]}]  ;# MGTHRXP2_117
set_property src_info {type:XDC file:2 line:97 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN K5   [get_ports {rxn[14]}]  ;# MGTHRXN2_117
set_property src_info {type:XDC file:2 line:98 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN F2   [get_ports {txp[15]}]  ;# MGTHTXP3_117
set_property src_info {type:XDC file:2 line:99 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN F1   [get_ports {txn[15]}]  ;# MGTHTXN3_117
set_property src_info {type:XDC file:2 line:100 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN J4   [get_ports {rxp[15]}]  ;# MGTHRXP3_117
set_property src_info {type:XDC file:2 line:101 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN J3   [get_ports {rxn[15]}]  ;# MGTHRXN3_117
set_property src_info {type:XDC file:2 line:102 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN D2   [get_ports {txp[16]}]  ;# MGTHTXP0_118
set_property src_info {type:XDC file:2 line:103 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN D1   [get_ports {txn[16]}]  ;# MGTHTXN0_118
set_property src_info {type:XDC file:2 line:104 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN G4   [get_ports {rxp[16]}]  ;# MGTHRXP0_118
set_property src_info {type:XDC file:2 line:105 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN G3   [get_ports {rxn[16]}]  ;# MGTHRXN0_118
set_property src_info {type:XDC file:2 line:106 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN C4   [get_ports {txp[17]}]  ;# MGTHTXP1_118
set_property src_info {type:XDC file:2 line:107 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN C3   [get_ports {txn[17]}]  ;# MGTHTXN1_118
set_property src_info {type:XDC file:2 line:108 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN E4   [get_ports {rxp[17]}]  ;# MGTHRXP1_118
set_property src_info {type:XDC file:2 line:109 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN E3   [get_ports {rxn[17]}]  ;# MGTHRXN1_118
set_property src_info {type:XDC file:2 line:110 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN B2   [get_ports {txp[18]}]  ;# MGTHTXP2_118
set_property src_info {type:XDC file:2 line:111 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN B1   [get_ports {txn[18]}]  ;# MGTHTXN2_118
set_property src_info {type:XDC file:2 line:112 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN D6   [get_ports {rxp[18]}]  ;# MGTHRXP2_118
set_property src_info {type:XDC file:2 line:113 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN D5   [get_ports {rxn[18]}]  ;# MGTHRXN2_118
set_property src_info {type:XDC file:2 line:114 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN A4   [get_ports {txp[19]}]  ;# MGTHTXP3_118
set_property src_info {type:XDC file:2 line:115 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN A3   [get_ports {txn[19]}]  ;# MGTHTXN3_118
set_property src_info {type:XDC file:2 line:116 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN B6   [get_ports {rxp[19]}]  ;# MGTHRXP3_118
set_property src_info {type:XDC file:2 line:117 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN B5   [get_ports {rxn[19]}]  ;# MGTHRXN3_118
