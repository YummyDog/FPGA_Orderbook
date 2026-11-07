set_property SRC_FILE_INFO {cfile:c:/Users/lskje/Desktop/FPGA_Orderbook/OrderBook/OrderBook.gen/sources_1/bd/top/ip/top_ten_gig_eth_pcs_pma_0_0/synth/top_ten_gig_eth_pcs_pma_0_0.xdc rfile:../../../OrderBook.gen/sources_1/bd/top/ip/top_ten_gig_eth_pcs_pma_0_0/synth/top_ten_gig_eth_pcs_pma_0_0.xdc id:1 order:EARLY scoped_inst:top_i/ten_gig_eth_pcs_pma_0/U0} [current_design]
set_property SRC_FILE_INFO {cfile:c:/Users/lskje/Desktop/FPGA_Orderbook/OrderBook/OrderBook.gen/sources_1/bd/top/ip/top_ten_gig_eth_pcs_pma_1_0/synth/top_ten_gig_eth_pcs_pma_1_0.xdc rfile:../../../OrderBook.gen/sources_1/bd/top/ip/top_ten_gig_eth_pcs_pma_1_0/synth/top_ten_gig_eth_pcs_pma_1_0.xdc id:2 order:EARLY scoped_inst:top_i/ten_gig_eth_pcs_pma_1/U0} [current_design]
set_property SRC_FILE_INFO {cfile:c:/Users/lskje/Desktop/FPGA_Orderbook/OrderBook/OrderBook.gen/sources_1/bd/top/ip/top_vio_link_0/top_vio_link_0.xdc rfile:../../../OrderBook.gen/sources_1/bd/top/ip/top_vio_link_0/top_vio_link_0.xdc id:3 order:EARLY scoped_inst:top_i/vio_link} [current_design]
set_property SRC_FILE_INFO {cfile:C:/Users/lskje/Desktop/FPGA_Orderbook/OrderBook/OrderBook.srcs/constrs_1/new/orderbook.xdc rfile:../../../OrderBook.srcs/constrs_1/new/orderbook.xdc id:4} [current_design]
set_property SRC_FILE_INFO {cfile:C:/Users/lskje/Desktop/FPGA_Orderbook/OrderBook/OrderBook.srcs/constrs_1/new/debug_valids.xdc rfile:../../../OrderBook.srcs/constrs_1/new/debug_valids.xdc id:5} [current_design]
set_property SRC_FILE_INFO {cfile:c:/Users/lskje/Desktop/FPGA_Orderbook/OrderBook/OrderBook.gen/sources_1/bd/top/ip/top_ten_gig_eth_pcs_pma_1_0/synth/top_ten_gig_eth_pcs_pma_1_0_clocks.xdc rfile:../../../OrderBook.gen/sources_1/bd/top/ip/top_ten_gig_eth_pcs_pma_1_0/synth/top_ten_gig_eth_pcs_pma_1_0_clocks.xdc id:6 order:LATE scoped_inst:top_i/ten_gig_eth_pcs_pma_1/U0} [current_design]
current_instance top_i/ten_gig_eth_pcs_pma_0/U0
set_property src_info {type:SCOPED_XDC file:1 line:70 export:INPUT save:INPUT read:READ} [current_design]
set_multicycle_path 2 -from [get_cells * -hierarchical -filter {NAME =~ *mcp1_* && (PRIMITIVE_SUBGROUP =~ flop || PRIMITIVE_SUBGROUP =~ SDR)}] -to [get_cells -of [filter [all_fanout -flat -endpoints_only -from [get_pins -filter {NAME=~*/Q} -of_objects [get_cells -hierarchical -filter {NAME =~ *rxratecounter_i*rxusrclk2_en156*}]]] {NAME =~ *WE}]]
set_property src_info {type:SCOPED_XDC file:1 line:71 export:INPUT save:INPUT read:READ} [current_design]
set_multicycle_path -hold 1 -from [get_cells * -hierarchical -filter {NAME =~ *mcp1_* && (PRIMITIVE_SUBGROUP =~ flop || PRIMITIVE_SUBGROUP =~ SDR)}] -to [get_cells -of [filter [all_fanout -flat -endpoints_only -from [get_pins -filter {NAME=~*/Q} -of_objects [get_cells -hierarchical -filter {NAME =~ *rxratecounter_i*rxusrclk2_en156*}]]] {NAME =~ *WE}]]
set_property src_info {type:SCOPED_XDC file:1 line:73 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay -from [get_cells -hierarchical -filter {NAME =~ *elastic*rd_truegray_reg* && (PRIMITIVE_SUBGROUP =~ flop || PRIMITIVE_SUBGROUP =~ SDR)}] -to [get_cells -hierarchical -filter {NAME =~ *elastic*rag_writesync0_reg* && (PRIMITIVE_SUBGROUP =~ flop || PRIMITIVE_SUBGROUP =~ SDR)}] -datapath_only 6.400
set_property src_info {type:SCOPED_XDC file:1 line:74 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay -from [get_cells -hierarchical -filter {NAME =~ *elastic*wr_gray_reg* && (PRIMITIVE_SUBGROUP =~ flop || PRIMITIVE_SUBGROUP =~ SDR)}] -to [get_cells -hierarchical -filter {NAME =~ *elastic*wr_gray_rdclk0_reg* && (PRIMITIVE_SUBGROUP =~ flop || PRIMITIVE_SUBGROUP =~ SDR)}] -datapath_only 3.100
set_property src_info {type:SCOPED_XDC file:1 line:75 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay -from [get_cells -hierarchical -filter {NAME =~ *elastic*rd_lastgray_reg* && (PRIMITIVE_SUBGROUP =~ flop || PRIMITIVE_SUBGROUP =~ SDR)}] -to [get_cells -hierarchical -filter {NAME =~ *elastic*rd_lastgray_wrclk0_reg* && (PRIMITIVE_SUBGROUP =~ flop || PRIMITIVE_SUBGROUP =~ SDR)}] -datapath_only 6.400
set_property src_info {type:SCOPED_XDC file:1 line:77 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay -from [get_cells -hierarchical -filter {NAME =~ *txrate*rd_truegray_reg* && (PRIMITIVE_SUBGROUP =~ flop || PRIMITIVE_SUBGROUP =~ SDR)}] -to [get_cells -hierarchical -filter {NAME =~ *txrate*rag_writesync0_reg* && (PRIMITIVE_SUBGROUP =~ flop || PRIMITIVE_SUBGROUP =~ SDR)}] -datapath_only 3.100
set_property src_info {type:SCOPED_XDC file:1 line:78 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay -from [get_cells -hierarchical -filter {NAME =~ *txrate*wr_gray_reg* && (PRIMITIVE_SUBGROUP =~ flop || PRIMITIVE_SUBGROUP =~ SDR)}] -to [get_cells -hierarchical -filter {NAME =~ *txrate*wr_gray_rdclk0_reg* && (PRIMITIVE_SUBGROUP =~ flop || PRIMITIVE_SUBGROUP =~ SDR)}] -datapath_only 6.400
set_property src_info {type:SCOPED_XDC file:1 line:79 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay -from [get_cells -hierarchical -filter {NAME =~ *txrate*rd_lastgray_reg* && (PRIMITIVE_SUBGROUP =~ flop || PRIMITIVE_SUBGROUP =~ SDR)}] -to [get_cells -hierarchical -filter {NAME =~ *txrate*rd_lastgray_wrclk0_reg* && (PRIMITIVE_SUBGROUP =~ flop || PRIMITIVE_SUBGROUP =~ SDR)}] -datapath_only 3.100
set_property src_info {type:SCOPED_XDC file:1 line:85 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay -from [get_cells -of [all_fanin -flat [get_pins -of_objects [get_cells -hierarchical -filter {NAME =~ *resyncs*d1_reg}] -filter {NAME =~ *D}]] -filter {IS_SEQUENTIAL=="1" && NAME !~ "*resyncs*d1_reg"}] -to [get_pins -of_objects [get_cells -hierarchical -filter {NAME =~ *resyncs*d1_reg}] -filter {NAME =~ *D}] 3.100 -datapath_only
set_property src_info {type:SCOPED_XDC file:1 line:98 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay -datapath_only -from [get_clocks -of_objects [get_ports refclk_p]] -to [get_pins -of_objects [get_cells -hier -filter {NAME =~ *coreclk_rxusrclk2_timer_125us_resync/*synchc_inst*d1_reg}] -filter {NAME =~ *D}] 6.400
set_property src_info {type:SCOPED_XDC file:1 line:102 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay -datapath_only -from [get_cells -hierarchical -filter {NAME =~ *drp_ipif_i*synch_*d_reg_reg* && (PRIMITIVE_SUBGROUP =~ flop || PRIMITIVE_SUBGROUP =~ SDR)}] -to [get_pins -of_objects [get_cells -hierarchical -filter {NAME =~ *drp_ipif_i*synch_*q_reg*}] -filter {NAME =~ *D || NAME =~ *R || NAME =~ *S}] 3.100
set_property src_info {type:SCOPED_XDC file:1 line:113 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -scope -type CDC -id {CDC-10} -user "ten_gig_eth_pcs_pma" -tags "11999" -desc "Combi logic will be not result in glitched and thus safe to ignore" -from [get_pins -of [get_cells -hier -filter {name =~ */*gt*xreset_i*}] -filter {name =~ *C}]
current_instance
current_instance top_i/ten_gig_eth_pcs_pma_1/U0
set_property src_info {type:SCOPED_XDC file:2 line:69 export:INPUT save:INPUT read:READ} [current_design]
set_multicycle_path 2 -from [get_cells * -hierarchical -filter {NAME =~ *mcp1_* && (PRIMITIVE_SUBGROUP =~ flop || PRIMITIVE_SUBGROUP =~ SDR)}] -to [get_cells -of [filter [all_fanout -flat -endpoints_only -from [get_pins -filter {NAME=~*/Q} -of_objects [get_cells -hierarchical -filter {NAME =~ *rxratecounter_i*rxusrclk2_en156*}]]] {NAME =~ *WE}]]
set_property src_info {type:SCOPED_XDC file:2 line:70 export:INPUT save:INPUT read:READ} [current_design]
set_multicycle_path -hold 1 -from [get_cells * -hierarchical -filter {NAME =~ *mcp1_* && (PRIMITIVE_SUBGROUP =~ flop || PRIMITIVE_SUBGROUP =~ SDR)}] -to [get_cells -of [filter [all_fanout -flat -endpoints_only -from [get_pins -filter {NAME=~*/Q} -of_objects [get_cells -hierarchical -filter {NAME =~ *rxratecounter_i*rxusrclk2_en156*}]]] {NAME =~ *WE}]]
set_property src_info {type:SCOPED_XDC file:2 line:72 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay -from [get_cells -hierarchical -filter {NAME =~ *elastic*rd_truegray_reg* && (PRIMITIVE_SUBGROUP =~ flop || PRIMITIVE_SUBGROUP =~ SDR)}] -to [get_cells -hierarchical -filter {NAME =~ *elastic*rag_writesync0_reg* && (PRIMITIVE_SUBGROUP =~ flop || PRIMITIVE_SUBGROUP =~ SDR)}] -datapath_only 6.400
set_property src_info {type:SCOPED_XDC file:2 line:73 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay -from [get_cells -hierarchical -filter {NAME =~ *elastic*wr_gray_reg* && (PRIMITIVE_SUBGROUP =~ flop || PRIMITIVE_SUBGROUP =~ SDR)}] -to [get_cells -hierarchical -filter {NAME =~ *elastic*wr_gray_rdclk0_reg* && (PRIMITIVE_SUBGROUP =~ flop || PRIMITIVE_SUBGROUP =~ SDR)}] -datapath_only 3.100
set_property src_info {type:SCOPED_XDC file:2 line:74 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay -from [get_cells -hierarchical -filter {NAME =~ *elastic*rd_lastgray_reg* && (PRIMITIVE_SUBGROUP =~ flop || PRIMITIVE_SUBGROUP =~ SDR)}] -to [get_cells -hierarchical -filter {NAME =~ *elastic*rd_lastgray_wrclk0_reg* && (PRIMITIVE_SUBGROUP =~ flop || PRIMITIVE_SUBGROUP =~ SDR)}] -datapath_only 6.400
set_property src_info {type:SCOPED_XDC file:2 line:76 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay -from [get_cells -hierarchical -filter {NAME =~ *txrate*rd_truegray_reg* && (PRIMITIVE_SUBGROUP =~ flop || PRIMITIVE_SUBGROUP =~ SDR)}] -to [get_cells -hierarchical -filter {NAME =~ *txrate*rag_writesync0_reg* && (PRIMITIVE_SUBGROUP =~ flop || PRIMITIVE_SUBGROUP =~ SDR)}] -datapath_only 3.100
set_property src_info {type:SCOPED_XDC file:2 line:77 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay -from [get_cells -hierarchical -filter {NAME =~ *txrate*wr_gray_reg* && (PRIMITIVE_SUBGROUP =~ flop || PRIMITIVE_SUBGROUP =~ SDR)}] -to [get_cells -hierarchical -filter {NAME =~ *txrate*wr_gray_rdclk0_reg* && (PRIMITIVE_SUBGROUP =~ flop || PRIMITIVE_SUBGROUP =~ SDR)}] -datapath_only 6.400
set_property src_info {type:SCOPED_XDC file:2 line:78 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay -from [get_cells -hierarchical -filter {NAME =~ *txrate*rd_lastgray_reg* && (PRIMITIVE_SUBGROUP =~ flop || PRIMITIVE_SUBGROUP =~ SDR)}] -to [get_cells -hierarchical -filter {NAME =~ *txrate*rd_lastgray_wrclk0_reg* && (PRIMITIVE_SUBGROUP =~ flop || PRIMITIVE_SUBGROUP =~ SDR)}] -datapath_only 3.100
set_property src_info {type:SCOPED_XDC file:2 line:84 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay -from [get_cells -of [all_fanin -flat [get_pins -of_objects [get_cells -hierarchical -filter {NAME =~ *resyncs*d1_reg}] -filter {NAME =~ *D}]] -filter {IS_SEQUENTIAL=="1" && NAME !~ "*resyncs*d1_reg"}] -to [get_pins -of_objects [get_cells -hierarchical -filter {NAME =~ *resyncs*d1_reg}] -filter {NAME =~ *D}] 3.100 -datapath_only
set_property src_info {type:SCOPED_XDC file:2 line:96 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay -datapath_only -from [get_cells -hierarchical -filter {NAME =~ *drp_ipif_i*synch_*d_reg_reg* && (PRIMITIVE_SUBGROUP =~ flop || PRIMITIVE_SUBGROUP =~ SDR)}] -to [get_pins -of_objects [get_cells -hierarchical -filter {NAME =~ *drp_ipif_i*synch_*q_reg*}] -filter {NAME =~ *D || NAME =~ *R || NAME =~ *S}] 3.100
set_property src_info {type:SCOPED_XDC file:2 line:107 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -scope -type CDC -id {CDC-10} -user "ten_gig_eth_pcs_pma" -tags "11999" -desc "Combi logic will be not result in glitched and thus safe to ignore" -from [get_pins -of [get_cells -hier -filter {name =~ */*gt*xreset_i*}] -filter {name =~ *C}]
current_instance
current_instance top_i/vio_link
set_property src_info {type:SCOPED_XDC file:3 line:55 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -type CDC -id CDC-4 -from [get_pins -filter {REF_PIN_NAME=~C} -of_objects [get_cells -hierarchical -filter {SCOPED_NAME =~ "*probe_in_reg_reg*"}]]  -to [get_pins -filter {REF_PIN_NAME=~D} -of_objects [get_cells -hierarchical -filter {SCOPED_NAME =~ "*data_int_sync1_reg*"}]]  -user "vio" -description {The path has combinational circuit. But from hardware prospective the design works perfectly and the signals crossing happen after a very long time from the source has the value.} -tags "1050886" -scope -internal
set_property src_info {type:SCOPED_XDC file:3 line:56 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -type CDC -id CDC-1 -from [get_pins -filter {REF_PIN_NAME=~C} -of_objects [get_cells -hierarchical -filter { SCOPED_NAME =~  "*Hold_probe_in*" &&  IS_SEQUENTIAL } ]]  -to [get_pins -filter {REF_PIN_NAME=~CE} -of_objects [get_cells -hierarchical -filter { SCOPED_NAME =~  "*PROBE_IN_INST/probe_in_reg*" && IS_SEQUENTIAL} ]]  -user "vio" -description {The path has combinational circuit. But from hardware prospective the design works perfectly and the signals crossing happen after a very long time from the source has the value.} -tags "1050886" -scope -internal
current_instance
set_property src_info {type:XDC file:4 line:19 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay -datapath_only -from [get_clocks -of_objects [get_ports gt_refclk_clk_p]] -to [get_clocks -of_objects [get_pins -hier -filter {NAME =~ *gthe2_i/RXOUTCLK}]] 3.100
set_property src_info {type:XDC file:4 line:22 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AH9 [get_ports clk25in]
set_property src_info {type:XDC file:4 line:26 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AL33 [get_ports fan]
set_property src_info {type:XDC file:4 line:33 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN V6  [get_ports gt_refclk_clk_p]   ;# MGTREFCLK1P_116
set_property src_info {type:XDC file:4 line:34 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN V5  [get_ports gt_refclk_clk_n]   ;# MGTREFCLK1N_116
set_property src_info {type:XDC file:4 line:38 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN Y2  [get_ports sfp_txp]           ;# MGTHTXP0_116
set_property src_info {type:XDC file:4 line:39 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN Y1  [get_ports sfp_txn]           ;# MGTHTXN0_116
set_property src_info {type:XDC file:4 line:40 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AA4 [get_ports sfp_rxp]           ;# MGTHRXP0_116
set_property src_info {type:XDC file:4 line:41 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AA3 [get_ports sfp_rxn]           ;# MGTHRXN0_116
set_property src_info {type:XDC file:4 line:45 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN T2  [get_ports sfp1_txp]          ;# MGTHTXP2_116
set_property src_info {type:XDC file:4 line:46 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN T1  [get_ports sfp1_txn]          ;# MGTHTXN2_116
set_property src_info {type:XDC file:4 line:47 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN U4  [get_ports sfp1_rxp]          ;# MGTHRXP2_116
set_property src_info {type:XDC file:4 line:48 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN U3  [get_ports sfp1_rxn]          ;# MGTHRXN2_116
set_property src_info {type:XDC file:4 line:52 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AH13 [get_ports QSFP_RESET]
set_property src_info {type:XDC file:4 line:54 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN AC12 [get_ports SFP_OR_OPT]
set_property src_info {type:XDC file:5 line:4 export:INPUT save:INPUT read:READ} [current_design]
set_property MARK_DEBUG true [get_nets -quiet {top_i/market_data_top_0/*/p_tvalid}]
set_property src_info {type:XDC file:5 line:6 export:INPUT save:INPUT read:READ} [current_design]
set_property MARK_DEBUG true [get_nets -quiet {top_i/market_data_top_0/*/u_input/u_axis/o_v}]
set_property src_info {type:XDC file:5 line:15 export:INPUT save:INPUT read:READ} [current_design]
set_property MARK_DEBUG true [get_nets -quiet {top_i/market_data_top_0/*/u_fullparser/e_fvalid}]
set_property src_info {type:XDC file:5 line:18 export:INPUT save:INPUT read:READ} [current_design]
set_property MARK_DEBUG true [get_nets -quiet {top_i/market_data_top_0/*/u_fullparser/i_fvalid}]
set_property src_info {type:XDC file:5 line:23 export:INPUT save:INPUT read:READ} [current_design]
set_property MARK_DEBUG true [get_nets -quiet {top_i/market_data_top_0/*/u_fullparser/u_fvalid}]
set_property src_info {type:XDC file:5 line:40 export:INPUT save:INPUT read:READ} [current_design]
set_property MARK_DEBUG true [get_nets -quiet {top_i/market_data_top_0/*/u_fullparser/u_itch/fv_keep[*]}]
set_property src_info {type:XDC file:5 line:46 export:INPUT save:INPUT read:READ} [current_design]
set_property MARK_DEBUG true [get_nets -quiet {top_i/market_data_top_0/*/u_fullparser/u_itch/fl_typ_r[*]}]
set_property src_info {type:XDC file:5 line:65 export:INPUT save:INPUT read:READ} [current_design]
set_property MARK_DEBUG true [get_nets -quiet {top_i/market_data_top_0/*/u_fullparser/u_itch/msg_type_r[*]}]
set_property src_info {type:XDC file:5 line:67 export:INPUT save:INPUT read:READ} [current_design]
set_property MARK_DEBUG true [get_nets -quiet {top_i/market_data_top_0/*/u_fullparser/u_itch/msg_fields_r[*]}]
set_property src_info {type:XDC file:5 line:69 export:INPUT save:INPUT read:READ} [current_design]
set_property MARK_DEBUG true [get_nets -quiet {top_i/market_data_top_0/*/u_fullparser/u_itch/msg_index_r[*]}]
set_property src_info {type:XDC file:5 line:71 export:INPUT save:INPUT read:READ} [current_design]
set_property MARK_DEBUG true [get_nets -quiet {top_i/market_data_top_0/*/u_fullparser/u_itch/msg_seq_r[*]}]
set_property src_info {type:XDC file:5 line:73 export:INPUT save:INPUT read:READ} [current_design]
set_property MARK_DEBUG true [get_nets -quiet {top_i/market_data_top_0/*/u_fullparser/u_itch/msg_len_r[*]}]
set_property src_info {type:XDC file:5 line:81 export:INPUT save:INPUT read:READ} [current_design]
set_property MARK_DEBUG true [get_nets -quiet {top_i/market_data_top_0/*/u_fullparser/u_itch/pkt_count_r[*]}]
set_property src_info {type:XDC file:5 line:89 export:INPUT save:INPUT read:READ} [current_design]
set_property MARK_DEBUG true [get_nets -quiet {top_i/market_data_top_0/*/u_engine/order_ev_valid}]
set_property src_info {type:XDC file:5 line:92 export:INPUT save:INPUT read:READ} [current_design]
set_property MARK_DEBUG true [get_nets -quiet {top_i/market_data_top_0/*/u_engine/fifo_ev_valid}]
current_instance top_i/ten_gig_eth_pcs_pma_1/U0
set_property src_info {type:SCOPED_XDC file:6 line:59 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay -datapath_only -from [get_clocks -of_objects [get_pins top_i/ten_gig_eth_pcs_pma_1/U0/coreclk]] -to [get_pins -of_objects [get_cells -hier -filter {NAME =~ *coreclk_rxusrclk2_timer_125us_resync/*synchc_inst*d1_reg}] -filter {NAME =~ *D}] 6.400
set_property src_info {type:SCOPED_XDC file:6 line:61 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay -datapath_only -from [get_clocks -of_objects [get_pins top_i/ten_gig_eth_pcs_pma_1/U0/coreclk]] -to [get_pins -of_objects [get_cells -hierarchical -filter {NAME =~ *drp_ipif_i*synch_*q_reg*}] -filter {NAME =~ *D || NAME =~ *R || NAME =~ *S}] 3.100
