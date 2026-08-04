set_property SRC_FILE_INFO {cfile:c:/Users/lskje/Desktop/FPGA_Orderbook/xxv_ethernet_0_ex/imports/xxv_ethernet_0_example_top.xdc rfile:../../../imports/xxv_ethernet_0_example_top.xdc id:1} [current_design]
set_property src_info {type:XDC file:1 line:126 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay  10.000 -datapath_only -from [get_pins -of [get_cells -hier -filter { name =~ */pktgen_enable_int_reg*}] -filter { name =~ *C } ] -to [get_pins -of [get_cells -hier -filter { name =~ */*_sync_pkt_gen_enable/s_out_d2_cdc_to_reg*}] -filter { name =~ *D } ] -quiet
set_property src_info {type:XDC file:1 line:128 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay  10.000 -datapath_only -from [get_pins -of [get_cells -hier -filter { name =~ */i_RX_WD_ALIGN/align_status_reg[*]*}] -filter { name =~ *C } ] -to [get_pins -of [get_cells -hier -filter { name =~ */s_out_d2_cdc_to_reg*}] -filter { name =~ *D } ] -quiet
set_property src_info {type:XDC file:1 line:130 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay -from [get_pins -of [get_cells -hier -filter { name =~ */rx_errors_int_reg*}] -filter { name =~ *C } ] -to [get_pins -of [get_cells -hier -filter { name =~ */s_out_d2_cdc_to_reg[*]*}] -filter { name =~ *D } ] 10.000 -datapath_only -quiet
set_property src_info {type:XDC file:1 line:134 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay -from [get_pins -of [get_cells -hier -filter { name =~ */rx_packet_count_int_reg[*]*}] -filter { name =~ *C } ] -to [get_pins -of [get_cells -hier -filter { name =~ */s_out_d2_cdc_to_reg[*]*}] -filter { name =~ *D } ] 10.000 -datapath_only -quiet
set_property src_info {type:XDC file:1 line:136 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay -from [get_pins -of [get_cells -hier -filter { name =~ */tx_sent_count_int_reg[*]*}] -filter { name =~ *C } ] -to [get_pins -of [get_cells -hier -filter { name =~ */s_out_d2_cdc_to_reg[*]*}] -filter { name =~ *D } ] 10.000 -datapath_only -quiet
set_property src_info {type:XDC file:1 line:138 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay  10.000 -datapath_only -from [get_pins -of [get_cells -hier -filter { name =~ */rx_total_bytes_int_reg*}] -filter { name =~ *C } ] -to [get_pins -of [get_cells -hier -filter { name =~ */s_out_d2_cdc_to_reg*}] -filter { name =~ *D } ] -quiet
set_property src_info {type:XDC file:1 line:140 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay -from [get_pins -of [get_cells -hier -filter { name =~ */tx_total_bytes_int_reg[*]*}] -filter { name =~ *C } ] -to [get_pins -of [get_cells -hier -filter { name =~ */s_out_d2_cdc_to_reg[*]*}] -filter { name =~ *D } ] 10.000 -datapath_only -quiet
set_property src_info {type:XDC file:1 line:142 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay -from [get_pins -of [get_cells -hier -filter { name =~ */tx_time_out_int_reg*}] -filter { name =~ *C } ] -to [get_pins -of [get_cells -hier -filter { name =~ */s_out_d2_cdc_to_reg[*]*}] -filter { name =~ *D } ] 10.000 -datapath_only -quiet
set_property src_info {type:XDC file:1 line:144 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay -from [get_pins -of [get_cells -hier -filter { name =~ */tx_done_int_reg*}] -filter { name =~ *C } ] -to [get_pins -of [get_cells -hier -filter { name =~ */s_out_d2_cdc_to_reg[*]*}] -filter { name =~ *D } ] 10.000 -datapath_only -quiet
set_property src_info {type:XDC file:1 line:147 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay -from [get_pins -of [get_cells -hier -filter { name =~ */rx_data_err_reg_reg*}] -filter { name =~ *C } ] -to [get_pins -of [get_cells -hier -filter { name =~ */s_out_d2_cdc_to_reg[*]*}] -filter { name =~ *D } ] 10.000 -datapath_only -quiet
set_property src_info {type:XDC file:1 line:149 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay -from [get_pins -of [get_cells -hier -filter { name =~ */mode_switch_reg*}] -filter { name =~ *C } ] 10.000 -datapath_only -quiet
set_property src_info {type:XDC file:1 line:150 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay -from [get_pins -of [get_cells -hier -filter { name =~ */pipe_reg*}] -filter { name =~ *C } ] 2.5 -datapath_only -quiet
set_property src_info {type:XDC file:1 line:152 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay  10.000 -datapath_only -from [get_pins -of [get_cells -hier -filter { name =~ */i_pif_registers/ctl_rsfec_enable_r_reg*}] -filter { name =~ *C } ] -to [get_pins -of [get_cells -hier -filter { name =~ */gt*_channel_gen.gen_gt*_channel_inst[*].GT*_CHANNEL_PRIM_INST*}] -filter { name =~ *RXGEARBOXSLIP } ] -quiet
set_property src_info {type:XDC file:1 line:161 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -type CDC -id {CDC-11} -user "xxv_ethernet" -desc "The align status signal is synced with different syncers where fan-out is expected and so can be waived" -tags "11999" -from [get_pins -of [get_cells -hier -filter {name =~ */i_RX_WD_ALIGN/align_status_reg*}] -filter {name =~ *C}] -to [get_pins -of [get_cells -hier -filter {name =~ */s_out_d2_cdc_to_reg*}] -filter {name =~ *D}]
set_property src_info {type:XDC file:1 line:165 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -type CDC -id {CDC-11} -user "xxv_ethernet" -desc "The reset signal is synced with different syncers where fan-out is expected and so can be waived" -tags "11999" -from [get_pins -of [get_cells -hier -filter {name =~ */rx_reset_done_async_r*}] -filter {name =~ *C}] -to [get_pins -of [get_cells -hier -filter {name =~ */s_out_d2_cdc_to_reg*}] -filter {name =~ *D}]
set_property src_info {type:XDC file:1 line:169 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -type CDC -id {CDC-11} -user "xxv_ethernet" -desc "The align status signal is synced with different syncers where fan-out is expected and so can be waived" -tags "11999" -from [get_pins -of [get_cells -hier -filter {name =~ */i_RX_WD_ALIGN/align_status_reg*}] -filter {name =~ *C}] -to [get_pins -of [get_cells -hier -filter {name =~ */i_*_TRAFFIC_GENERATOR/i_*_PKT_CHK/rx_block_lock_led_*d_reg*}] -filter {name =~ *D}]
set_property src_info {type:XDC file:1 line:173 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -type CDC -id {CDC-2} -user "xxv_ethernet" -desc "The align status signal is synced with different syncers where fan-out is expected and so can be waived" -tags "11999" -from [get_pins -of [get_cells -hier -filter {name =~ */i_RX_WD_ALIGN/align_status_reg*}] -filter {name =~ *C}] -to [get_pins -of [get_cells -hier -filter {name =~ */i_*_TRAFFIC_GENERATOR/i_*_PKT_CHK/rx_block_lock_led_*d_reg*}] -filter {name =~ *D}]
set_property src_info {type:XDC file:1 line:177 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -type CDC -id {CDC-1} -user "xxv_ethernet" -desc "The align status signal is synced with different syncers where fan-out is expected and so can be waived" -tags "11999" -from [get_pins -of [get_cells -hier -filter {name =~ */i_RX_DELETE_FCS/*_d*_reg*}] -filter {name =~ *C}] -to [get_pins -of [get_cells -hier -filter {name =~ */i_*_TRAFFIC_GENERATOR/*_reg*}] -filter {name =~ *}]
set_property src_info {type:XDC file:1 line:181 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -type CDC -id {CDC-11} -user "xxv_ethernet" -desc "The align status signal is synced with different syncers where fan-out is expected and so can be waived" -tags "11999" -from [get_pins -of [get_cells -hier -filter {name =~ */i_RX_WD_ALIGN/align_status_reg*}] -filter {name =~ *C}] -to [get_pins -of [get_cells -hier -filter {name =~ */i_*_TRAF_CHK*/rx_block_lock_led_*d_reg*}] -filter {name =~ *D}]
set_property src_info {type:XDC file:1 line:185 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -type CDC -id {CDC-1} -user "xxv_ethernet" -desc "The align status signal is synced with different syncers where fan-out is expected and so can be waived" -tags "11999" -from [get_pins -of [get_cells -hier -filter {name =~ */i_RX_WD_ALIGN/align_status_reg*}] -filter {name =~ *C}] -to [get_pins -of [get_cells -hier -filter {name =~ */i_*_TRAF_CHK*/rx_block_lock_led_*d_reg*}] -filter {name =~ *D}]
set_property src_info {type:XDC file:1 line:189 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -type CDC -id {CDC-2} -user "xxv_ethernet" -desc "The align status signal is synced with different syncers where fan-out is expected and so can be waived" -tags "11999" -from [get_pins -of [get_cells -hier -filter {name =~ */i_RX_WD_ALIGN/align_status_reg*}] -filter {name =~ *C}] -to [get_pins -of [get_cells -hier -filter {name =~ */i_*_TRAF_CHK*/rx_block_lock_led_*d_reg*}] -filter {name =~ *D}]
set_property src_info {type:XDC file:1 line:193 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -type CDC -id {CDC-1} -user "xxv_ethernet" -desc "The align status signal is synced with different syncers where fan-out is expected and so can be waived" -tags "11999" -from [get_pins -of [get_cells -hier -filter {name =~ */i_RX_DECODER/data_*_reg*}] -filter {name =~ *C}] -to [get_pins -of [get_cells -hier -filter {name =~ */i_*_TRAF_CHK*/*_reg*}] -filter {name =~ *}]
set_property src_info {type:XDC file:1 line:202 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay -datapath_only -from [get_pins -of [get_cells -hier -filter { name =~ */*_axi_if_top/i_pif_registers/ctl_rsfec_enable_r_reg*}] -filter { name =~ *C }] 10.000 -quiet
set_property src_info {type:XDC file:1 line:204 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay -datapath_only -from [get_pins -of [get_cells -hier -filter { name =~ */*_axi_if_top/i_pif_registers/ctl_*x_max_packet_len_out_reg*}] -filter { name =~ *C }] 10.000 -quiet
set_property src_info {type:XDC file:1 line:206 export:INPUT save:INPUT read:READ} [current_design]
set_max_delay -from [get_pins -of [get_cells -hier -filter { name =~ */inst/*x_*bit_gt_pipeline_serdes*/data_out_*d*}] -filter { name =~ *C } ] 10.000 -datapath_only -quiet
