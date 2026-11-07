create_debug_core u_ila_valids ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_valids]
set_property ALL_PROBE_SAME_MU_CNT 2 [get_debug_cores u_ila_valids]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_valids]
set_property C_DATA_DEPTH 4096 [get_debug_cores u_ila_valids]
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_valids]
set_property C_INPUT_PIPE_STAGES 1 [get_debug_cores u_ila_valids]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_valids]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_valids]
set_property port_width 1 [get_debug_ports u_ila_valids/clk]
connect_debug_port u_ila_valids/clk [get_nets [list clk]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe0]
set_property port_width 1 [get_debug_ports u_ila_valids/probe0]
connect_debug_port u_ila_valids/probe0 [get_nets [list top_i/market_data_top_0/U0/u_input/u_axis/h_v]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe1]
set_property port_width 1 [get_debug_ports u_ila_valids/probe1]
connect_debug_port u_ila_valids/probe1 [get_nets [list top_i/market_data_top_0/U0/u_fullparser/s_axis_tvalid]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe2]
set_property port_width 1 [get_debug_ports u_ila_valids/probe2]
connect_debug_port u_ila_valids/probe2 [get_nets [list top_i/market_data_top_0/U0/u_input/crc_done]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe3]
set_property port_width 1 [get_debug_ports u_ila_valids/probe3]
connect_debug_port u_ila_valids/probe3 [get_nets [list top_i/market_data_top_0/U0/u_input/u_extend/res_v]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe4]
set_property port_width 1 [get_debug_ports u_ila_valids/probe4]
connect_debug_port u_ila_valids/probe4 [get_nets [list top_i/market_data_top_0/U0/u_input/u_extend/cnt_v]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe5]
set_property port_width 1 [get_debug_ports u_ila_valids/probe5]
connect_debug_port u_ila_valids/probe5 [get_nets [list top_i/market_data_top_0/U0/mold_cnt_v]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe6]
set_property port_width 1 [get_debug_ports u_ila_valids/probe6]
connect_debug_port u_ila_valids/probe6 [get_nets [list top_i/market_data_top_0/U0/fcs_complete_i]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe7]
set_property port_width 1 [get_debug_ports u_ila_valids/probe7]
connect_debug_port u_ila_valids/probe7 [get_nets [list top_i/market_data_top_0/U0/fcs_true_i]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe8]
set_property port_width 1 [get_debug_ports u_ila_valids/probe8]
connect_debug_port u_ila_valids/probe8 [get_nets [list top_i/market_data_top_0/U0/fcs_false_i]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe9]
set_property port_width 1 [get_debug_ports u_ila_valids/probe9]
connect_debug_port u_ila_valids/probe9 [get_nets [list top_i/market_data_top_0/U0/u_fullparser/e_tvalid]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe10]
set_property port_width 1 [get_debug_ports u_ila_valids/probe10]
connect_debug_port u_ila_valids/probe10 [get_nets [list top_i/market_data_top_0/U0/u_fullparser/u_eth/fields_valid_r]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe11]
set_property port_width 1 [get_debug_ports u_ila_valids/probe11]
connect_debug_port u_ila_valids/probe11 [get_nets [list top_i/market_data_top_0/U0/u_fullparser/i_tvalid]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe12]
set_property port_width 1 [get_debug_ports u_ila_valids/probe12]
connect_debug_port u_ila_valids/probe12 [get_nets [list top_i/market_data_top_0/U0/u_fullparser/u_ipv4/fields_valid_r]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe13]
set_property port_width 1 [get_debug_ports u_ila_valids/probe13]
connect_debug_port u_ila_valids/probe13 [get_nets [list top_i/market_data_top_0/U0/u_fullparser/u_ipv4/ihl_invalid_r]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe14]
set_property port_width 1 [get_debug_ports u_ila_valids/probe14]
connect_debug_port u_ila_valids/probe14 [get_nets [list top_i/market_data_top_0/U0/u_fullparser/u_ipv4/ver_invalid_r]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe15]
set_property port_width 1 [get_debug_ports u_ila_valids/probe15]
connect_debug_port u_ila_valids/probe15 [get_nets [list top_i/market_data_top_0/U0/u_fullparser/u_tvalid]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe16]
set_property port_width 1 [get_debug_ports u_ila_valids/probe16]
connect_debug_port u_ila_valids/probe16 [get_nets [list top_i/market_data_top_0/U0/u_fullparser/u_udp/fields_valid_r]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe17]
set_property port_width 1 [get_debug_ports u_ila_valids/probe17]
connect_debug_port u_ila_valids/probe17 [get_nets [list top_i/market_data_top_0/U0/u_fullparser/u_udp/len_invalid_r]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe18]
set_property port_width 1 [get_debug_ports u_ila_valids/probe18]
connect_debug_port u_ila_valids/probe18 [get_nets [list top_i/market_data_top_0/U0/u_fullparser/d_tvalid]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe19]
set_property port_width 1 [get_debug_ports u_ila_valids/probe19]
connect_debug_port u_ila_valids/probe19 [get_nets [list top_i/market_data_top_0/U0/eng_valid]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe20]
set_property port_width 1 [get_debug_ports u_ila_valids/probe20]
connect_debug_port u_ila_valids/probe20 [get_nets [list top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tlast]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe21]
set_property port_width 8 [get_debug_ports u_ila_valids/probe21]
connect_debug_port u_ila_valids/probe21 [get_nets [list {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tkeep[0]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tkeep[1]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tkeep[2]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tkeep[3]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tkeep[4]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tkeep[5]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tkeep[6]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tkeep[7]}]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe22]
set_property port_width 64 [get_debug_ports u_ila_valids/probe22]
connect_debug_port u_ila_valids/probe22 [get_nets [list {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[0]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[1]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[2]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[3]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[4]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[5]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[6]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[7]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[8]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[9]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[10]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[11]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[12]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[13]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[14]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[15]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[16]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[17]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[18]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[19]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[20]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[21]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[22]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[23]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[24]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[25]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[26]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[27]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[28]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[29]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[30]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[31]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[32]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[33]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[34]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[35]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[36]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[37]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[38]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[39]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[40]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[41]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[42]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[43]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[44]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[45]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[46]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[47]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[48]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[49]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[50]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[51]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[52]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[53]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[54]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[55]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[56]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[57]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[58]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[59]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[60]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[61]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[62]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/s_axis_tdata[63]}]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe23]
set_property port_width 1 [get_debug_ports u_ila_valids/probe23]
connect_debug_port u_ila_valids/probe23 [get_nets [list top_i/market_data_top_0/U0/u_fullparser/u_itch/adv_c]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe24]
set_property port_width 1 [get_debug_ports u_ila_valids/probe24]
connect_debug_port u_ila_valids/probe24 [get_nets [list top_i/market_data_top_0/U0/u_fullparser/u_itch/flush_r]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe25]
set_property port_width 1 [get_debug_ports u_ila_valids/probe25]
connect_debug_port u_ila_valids/probe25 [get_nets [list top_i/market_data_top_0/U0/u_fullparser/u_itch/fv_valid]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe26]
set_property port_width 1 [get_debug_ports u_ila_valids/probe26]
connect_debug_port u_ila_valids/probe26 [get_nets [list top_i/market_data_top_0/U0/u_fullparser/u_itch/k1_last]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe27]
set_property port_width 1 [get_debug_ports u_ila_valids/probe27]
connect_debug_port u_ila_valids/probe27 [get_nets [list top_i/market_data_top_0/U0/u_fullparser/u_itch/fv_last]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe28]
set_property port_width 8 [get_debug_ports u_ila_valids/probe28]
connect_debug_port u_ila_valids/probe28 [get_nets [list {top_i/market_data_top_0/U0/u_fullparser/u_itch/fv_keep_reg_n_0_[0]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/fv_keep_reg_n_0_[1]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/fv_keep_reg_n_0_[2]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/fv_keep_reg_n_0_[3]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/fv_keep_reg_n_0_[4]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/fv_keep_reg_n_0_[5]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/fv_keep_reg_n_0_[6]} top_i/market_data_top_0/U0/u_fullparser/u_itch/p_1_in23_in]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe29]
set_property port_width 1 [get_debug_ports u_ila_valids/probe29]
connect_debug_port u_ila_valids/probe29 [get_nets [list top_i/market_data_top_0/U0/u_fullparser/u_itch/active_r]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe30]
set_property port_width 1 [get_debug_ports u_ila_valids/probe30]
connect_debug_port u_ila_valids/probe30 [get_nets [list top_i/market_data_top_0/U0/u_fullparser/u_itch/armed_r]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe31]
set_property port_width 1 [get_debug_ports u_ila_valids/probe31]
connect_debug_port u_ila_valids/probe31 [get_nets [list top_i/market_data_top_0/U0/u_fullparser/u_itch/pay_arm_c]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe32]
set_property port_width 7 [get_debug_ports u_ila_valids/probe32]
connect_debug_port u_ila_valids/probe32 [get_nets [list {top_i/market_data_top_0/U0/u_fullparser/u_itch/rem_r[0]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/rem_r[1]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/rem_r[2]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/rem_r[3]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/rem_r[4]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/rem_r[5]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/rem_r[6]}]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe33]
set_property port_width 3 [get_debug_ports u_ila_valids/probe33]
connect_debug_port u_ila_valids/probe33 [get_nets [list {top_i/market_data_top_0/U0/u_fullparser/u_itch/lane_r[0]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/lane_r[1]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/lane_r[2]}]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe34]
set_property port_width 8 [get_debug_ports u_ila_valids/probe34]
connect_debug_port u_ila_valids/probe34 [get_nets [list {top_i/market_data_top_0/U0/u_fullparser/u_itch/fl_typ_r[0]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/fl_typ_r_reg_n_0_[1]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/fl_typ_r_reg_n_0_[2]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/fl_typ_r_reg_n_0_[3]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/fl_typ_r_reg_n_0_[4]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/fl_typ_r_reg_n_0_[5]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/fl_typ_r_reg_n_0_[6]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/fl_typ_r_reg_n_0_[7]}]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe35]
set_property port_width 1 [get_debug_ports u_ila_valids/probe35]
connect_debug_port u_ila_valids/probe35 [get_nets [list top_i/market_data_top_0/U0/u_fullparser/u_itch/fl_scope_r]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe36]
set_property port_width 1 [get_debug_ports u_ila_valids/probe36]
connect_debug_port u_ila_valids/probe36 [get_nets [list top_i/market_data_top_0/U0/u_fullparser/u_itch/fl_lenok_r]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe37]
set_property port_width 1 [get_debug_ports u_ila_valids/probe37]
connect_debug_port u_ila_valids/probe37 [get_nets [list top_i/market_data_top_0/U0/u_fullparser/u_itch/t0_hit_r]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe38]
set_property port_width 8 [get_debug_ports u_ila_valids/probe38]
connect_debug_port u_ila_valids/probe38 [get_nets [list {top_i/market_data_top_0/U0/u_fullparser/u_itch/tb_scope[0]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/tb_scope[1]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/tb_scope[2]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/tb_scope[3]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/tb_scope[4]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/tb_scope[5]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/tb_scope[6]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/tb_scope[7]}]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe39]
set_property port_width 8 [get_debug_ports u_ila_valids/probe39]
connect_debug_port u_ila_valids/probe39 [get_nets [list {top_i/market_data_top_0/U0/u_fullparser/u_itch/tb_ist[0]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/tb_ist[1]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/tb_ist[2]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/tb_ist[3]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/tb_ist[4]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/tb_ist[5]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/tb_ist[6]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/tb_ist[7]}]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe40]
set_property port_width 8 [get_debug_ports u_ila_valids/probe40]
connect_debug_port u_ila_valids/probe40 [get_nets [list {top_i/market_data_top_0/U0/u_fullparser/u_itch/tb_lenok[0]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/tb_lenok[1]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/tb_lenok[2]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/tb_lenok[3]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/tb_lenok[4]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/tb_lenok[5]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/tb_lenok[6]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/tb_lenok[7]}]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe41]
set_property port_width 8 [get_debug_ports u_ila_valids/probe41]
connect_debug_port u_ila_valids/probe41 [get_nets [list {top_i/market_data_top_0/U0/u_fullparser/u_itch/tb_two[0]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/tb_two[1]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/tb_two[2]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/tb_two[3]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/tb_two[4]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/tb_two[5]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/tb_two[6]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/tb_two[7]}]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe42]
set_property port_width 1 [get_debug_ports u_ila_valids/probe42]
connect_debug_port u_ila_valids/probe42 [get_nets [list top_i/market_data_top_0/U0/u_fullparser/u_itch/start_ok_c]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe43]
set_property port_width 1 [get_debug_ports u_ila_valids/probe43]
connect_debug_port u_ila_valids/probe43 [get_nets [list top_i/market_data_top_0/U0/u_fullparser/u_itch/end_ok_c]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe44]
set_property port_width 1 [get_debug_ports u_ila_valids/probe44]
connect_debug_port u_ila_valids/probe44 [get_nets [list top_i/market_data_top_0/U0/u_fullparser/u_itch/surv_ok_c]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe45]
set_property port_width 1 [get_debug_ports u_ila_valids/probe45]
connect_debug_port u_ila_valids/probe45 [get_nets [list top_i/market_data_top_0/U0/u_fullparser/u_itch/first_ok_c]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe46]
set_property port_width 1 [get_debug_ports u_ila_valids/probe46]
connect_debug_port u_ila_valids/probe46 [get_nets [list top_i/market_data_top_0/U0/u_fullparser/u_itch/load_c]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe47]
set_property port_width 1 [get_debug_ports u_ila_valids/probe47]
connect_debug_port u_ila_valids/probe47 [get_nets [list top_i/market_data_top_0/U0/u_fullparser/u_itch/ret_norm_c]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe48]
set_property port_width 1 [get_debug_ports u_ila_valids/probe48]
connect_debug_port u_ila_valids/probe48 [get_nets [list top_i/market_data_top_0/U0/u_fullparser/u_itch/ret_tail_c]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe49]
set_property port_width 1 [get_debug_ports u_ila_valids/probe49]
connect_debug_port u_ila_valids/probe49 [get_nets [list top_i/market_data_top_0/U0/u_fullparser/u_itch/retire_c]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe50]
set_property port_width 8 [get_debug_ports u_ila_valids/probe50]
connect_debug_port u_ila_valids/probe50 [get_nets [list {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_type[0]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_type[1]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_type[2]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_type[3]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_type[4]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_type[5]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_type[6]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_type[7]}]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe51]
set_property port_width 32 [get_debug_ports u_ila_valids/probe51]
connect_debug_port u_ila_valids/probe51 [get_nets [list {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[0]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[1]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[2]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[3]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[4]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[5]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[6]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[7]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[8]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[9]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[10]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[11]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[12]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[13]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[14]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[15]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[16]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[17]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[18]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[19]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[20]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[21]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[22]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[23]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[24]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[25]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[26]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[27]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[28]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[29]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[30]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[31]}]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe52]
set_property port_width 64 [get_debug_ports u_ila_valids/probe52]
connect_debug_port u_ila_valids/probe52 [get_nets [list {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[32]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[33]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[34]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[35]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[36]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[37]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[38]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[39]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[40]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[41]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[42]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[43]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[44]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[45]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[46]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[47]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[48]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[49]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[50]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[51]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[52]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[53]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[54]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[55]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[56]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[57]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[58]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[59]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[60]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[61]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[62]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[63]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[64]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[65]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[66]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[67]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[68]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[69]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[70]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[71]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[72]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[73]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[74]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[75]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[76]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[77]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[78]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[79]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[80]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[81]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[82]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[83]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[84]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[85]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[86]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[87]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[88]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[89]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[90]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[91]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[92]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[93]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[94]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[95]}]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe53]
set_property port_width 32 [get_debug_ports u_ila_valids/probe53]
connect_debug_port u_ila_valids/probe53 [get_nets [list {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[96]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[97]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[98]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[99]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[100]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[101]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[102]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[103]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[104]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[105]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[106]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[107]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[108]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[109]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[110]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[111]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[112]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[113]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[114]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[115]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[116]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[117]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[118]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[119]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[120]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[121]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[122]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[123]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[124]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[125]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[126]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[127]}]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe54]
set_property port_width 8 [get_debug_ports u_ila_valids/probe54]
connect_debug_port u_ila_valids/probe54 [get_nets [list {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[128]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[129]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[130]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[131]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[132]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[133]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[134]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[135]}]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe55]
set_property port_width 32 [get_debug_ports u_ila_valids/probe55]
connect_debug_port u_ila_valids/probe55 [get_nets [list {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[136]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[137]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[138]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[139]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[140]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[141]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[142]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[143]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[144]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[145]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[146]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[147]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[148]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[149]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[150]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[151]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[152]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[153]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[154]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[155]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[156]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[157]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[158]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[159]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[160]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[161]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[162]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[163]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[164]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[165]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[166]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[167]}]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe56]
set_property port_width 64 [get_debug_ports u_ila_valids/probe56]
connect_debug_port u_ila_valids/probe56 [get_nets [list {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[168]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[169]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[170]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[171]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[172]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[173]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[174]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[175]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[176]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[177]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[178]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[179]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[180]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[181]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[182]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[183]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[184]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[185]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[186]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[187]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[188]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[189]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[190]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[191]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[192]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[193]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[194]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[195]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[196]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[197]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[198]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[199]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[200]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[201]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[202]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[203]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[204]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[205]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[206]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[207]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[208]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[209]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[210]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[211]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[212]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[213]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[214]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[215]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[216]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[217]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[218]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[219]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[220]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[221]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[222]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[223]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[224]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[225]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[226]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[227]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[228]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[229]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[230]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[231]}]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe57]
set_property port_width 32 [get_debug_ports u_ila_valids/probe57]
connect_debug_port u_ila_valids/probe57 [get_nets [list {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[232]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[233]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[234]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[235]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[236]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[237]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[238]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[239]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[240]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[241]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[242]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[243]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[244]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[245]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[246]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[247]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[248]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[249]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[250]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[251]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[252]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[253]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[254]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[255]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[256]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[257]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[258]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[259]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[260]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[261]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[262]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[263]}]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe58]
set_property port_width 16 [get_debug_ports u_ila_valids/probe58]
connect_debug_port u_ila_valids/probe58 [get_nets [list {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[264]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[265]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[266]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[267]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[268]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[269]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[270]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[271]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[272]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[273]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[274]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[275]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[276]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields[277]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[278]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[279]}]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe59]
set_property port_width 8 [get_debug_ports u_ila_valids/probe59]
connect_debug_port u_ila_valids/probe59 [get_nets [list {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[280]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[281]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[282]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[283]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[284]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[285]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[286]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_fields_r_reg_n_0_[287]}]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe60]
set_property port_width 16 [get_debug_ports u_ila_valids/probe60]
connect_debug_port u_ila_valids/probe60 [get_nets [list {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_index_r_reg_n_0_[0]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_index_r_reg_n_0_[1]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_index_r_reg_n_0_[2]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_index_r_reg_n_0_[3]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_index_r_reg_n_0_[4]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_index_r_reg_n_0_[5]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_index_r_reg_n_0_[6]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_index_r_reg_n_0_[7]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_index_r_reg_n_0_[8]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_index_r_reg_n_0_[9]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_index_r_reg_n_0_[10]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_index_r_reg_n_0_[11]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_index_r_reg_n_0_[12]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_index_r_reg_n_0_[13]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_index_r_reg_n_0_[14]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_index_r_reg_n_0_[15]}]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe61]
set_property port_width 64 [get_debug_ports u_ila_valids/probe61]
connect_debug_port u_ila_valids/probe61 [get_nets [list {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[0]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[1]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[2]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[3]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[4]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[5]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[6]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[7]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[8]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[9]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[10]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[11]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[12]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[13]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[14]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[15]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[16]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[17]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[18]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[19]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[20]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[21]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[22]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[23]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[24]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[25]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[26]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[27]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[28]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[29]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[30]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[31]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[32]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[33]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[34]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[35]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[36]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[37]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[38]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[39]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[40]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[41]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[42]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[43]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[44]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[45]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[46]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[47]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[48]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[49]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[50]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[51]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[52]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[53]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[54]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[55]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[56]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[57]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[58]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[59]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[60]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[61]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[62]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_seq_r[63]}]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe62]
set_property port_width 16 [get_debug_ports u_ila_valids/probe62]
connect_debug_port u_ila_valids/probe62 [get_nets [list {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_len_r[0]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_len_r[1]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_len_r[2]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_len_r[3]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_len_r[4]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_len_r[5]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_len_r[6]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_len_r[7]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_len_r[8]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_len_r[9]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_len_r[10]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_len_r[11]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_len_r[12]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_len_r[13]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_len_r[14]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_len_r[15]}]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe63]
set_property port_width 6 [get_debug_ports u_ila_valids/probe63]
connect_debug_port u_ila_valids/probe63 [get_nets [list {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_stat_r[0]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_stat_r[1]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_stat_r[2]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_stat_r[3]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_stat_r[4]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/msg_stat_r[5]}]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe64]
set_property port_width 32 [get_debug_ports u_ila_valids/probe64]
connect_debug_port u_ila_valids/probe64 [get_nets [list {top_i/market_data_top_0/U0/u_fullparser/u_itch/seconds_r[0]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/seconds_r[1]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/seconds_r[2]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/seconds_r[3]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/seconds_r[4]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/seconds_r[5]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/seconds_r[6]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/seconds_r[7]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/seconds_r[8]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/seconds_r[9]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/seconds_r[10]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/seconds_r[11]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/seconds_r[12]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/seconds_r[13]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/seconds_r[14]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/seconds_r[15]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/seconds_r[16]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/seconds_r[17]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/seconds_r[18]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/seconds_r[19]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/seconds_r[20]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/seconds_r[21]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/seconds_r[22]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/seconds_r[23]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/seconds_r[24]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/seconds_r[25]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/seconds_r[26]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/seconds_r[27]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/seconds_r[28]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/seconds_r[29]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/seconds_r[30]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/seconds_r[31]}]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe65]
set_property port_width 1 [get_debug_ports u_ila_valids/probe65]
connect_debug_port u_ila_valids/probe65 [get_nets [list top_i/market_data_top_0/U0/u_fullparser/u_itch/pkt_done_r]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe66]
set_property port_width 16 [get_debug_ports u_ila_valids/probe66]
connect_debug_port u_ila_valids/probe66 [get_nets [list {top_i/market_data_top_0/U0/u_fullparser/u_itch/pkt_count_r[0]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/pkt_count_r_reg_n_0_[1]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/pkt_count_r_reg_n_0_[2]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/pkt_count_r_reg_n_0_[3]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/pkt_count_r_reg_n_0_[4]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/pkt_count_r_reg_n_0_[5]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/pkt_count_r_reg_n_0_[6]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/pkt_count_r_reg_n_0_[7]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/pkt_count_r_reg_n_0_[8]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/pkt_count_r_reg_n_0_[9]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/pkt_count_r_reg_n_0_[10]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/pkt_count_r_reg_n_0_[11]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/pkt_count_r_reg_n_0_[12]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/pkt_count_r_reg_n_0_[13]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/pkt_count_r_reg_n_0_[14]} {top_i/market_data_top_0/U0/u_fullparser/u_itch/pkt_count_r_reg_n_0_[15]}]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe67]
set_property port_width 1 [get_debug_ports u_ila_valids/probe67]
connect_debug_port u_ila_valids/probe67 [get_nets [list top_i/market_data_top_0/U0/u_engine/in_tvalid]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe68]
set_property port_width 1 [get_debug_ports u_ila_valids/probe68]
connect_debug_port u_ila_valids/probe68 [get_nets [list top_i/market_data_top_0/U0/u_engine/in_px_valid]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe69]
set_property port_width 1 [get_debug_ports u_ila_valids/probe69]
connect_debug_port u_ila_valids/probe69 [get_nets [list top_i/market_data_top_0/U0/u_engine/u_book_input_stage/r_tvalid]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe70]
set_property port_width 1 [get_debug_ports u_ila_valids/probe70]
connect_debug_port u_ila_valids/probe70 [get_nets [list top_i/market_data_top_0/U0/u_engine/cmd_tvalid]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe71]
set_property port_width 1 [get_debug_ports u_ila_valids/probe71]
connect_debug_port u_ila_valids/probe71 [get_nets [list top_i/market_data_top_0/U0/u_engine/cmd_px_valid]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe72]
set_property port_width 1 [get_debug_ports u_ila_valids/probe72]
connect_debug_port u_ila_valids/probe72 [get_nets [list top_i/market_data_top_0/U0/u_engine/mut_tvalid]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe73]
set_property port_width 1 [get_debug_ports u_ila_valids/probe73]
connect_debug_port u_ila_valids/probe73 [get_nets [list top_i/market_data_top_0/U0/u_engine/price_ev_valid]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe74]
set_property port_width 1 [get_debug_ports u_ila_valids/probe74]
connect_debug_port u_ila_valids/probe74 [get_nets [list top_i/market_data_top_0/U0/u_engine/ob_ts_en]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe75]
set_property port_width 1 [get_debug_ports u_ila_valids/probe75]
connect_debug_port u_ila_valids/probe75 [get_nets [list top_i/market_data_top_0/U0/u_engine/fifo_ts_en]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe76]
set_property port_width 1 [get_debug_ports u_ila_valids/probe76]
connect_debug_port u_ila_valids/probe76 [get_nets [list top_i/market_data_top_0/U0/u_engine/u_time_event_fifo/any_v]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe77]
set_property port_width 1 [get_debug_ports u_ila_valids/probe77]
connect_debug_port u_ila_valids/probe77 [get_nets [list top_i/market_data_top_0/U0/u_engine/u_time_event_fifo/out_v]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe78]
set_property port_width 1 [get_debug_ports u_ila_valids/probe78]
connect_debug_port u_ila_valids/probe78 [get_nets [list top_i/market_data_top_0/U0/u_engine/m_tvalid]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe79]
set_property port_width 2 [get_debug_ports u_ila_valids/probe79]
connect_debug_port u_ila_valids/probe79 [get_nets [list {top_i/market_data_top_0/U0/u_engine/m_valid[0]} {top_i/market_data_top_0/U0/u_engine/m_valid[1]}]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe80]
set_property port_width 1 [get_debug_ports u_ila_valids/probe80]
connect_debug_port u_ila_valids/probe80 [get_nets [list top_i/market_data_top_0/U0/ev_valid_i]]
create_debug_port u_ila_valids probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_valids/probe81]
set_property port_width 1 [get_debug_ports u_ila_valids/probe81]
connect_debug_port u_ila_valids/probe81 [get_nets [list top_i/market_data_top_0/U0/ev_ready_i]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets top_i/market_data_top_0/U0/u_input/u_axis/clk]
