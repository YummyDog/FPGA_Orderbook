# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "G_CHECK_PREAMBLE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "G_FIFO_DEPTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "G_MAX_ORDERS" -parent ${Page_0}
  ipgui::add_param $IPINST -name "G_ORDER_BOOK_ID" -parent ${Page_0}
  ipgui::add_param $IPINST -name "G_TPID" -parent ${Page_0}
  ipgui::add_param $IPINST -name "G_TX_IPG_WORDS" -parent ${Page_0}


}

proc update_PARAM_VALUE.G_CHECK_PREAMBLE { PARAM_VALUE.G_CHECK_PREAMBLE } {
	# Procedure called to update G_CHECK_PREAMBLE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.G_CHECK_PREAMBLE { PARAM_VALUE.G_CHECK_PREAMBLE } {
	# Procedure called to validate G_CHECK_PREAMBLE
	return true
}

proc update_PARAM_VALUE.G_FIFO_DEPTH { PARAM_VALUE.G_FIFO_DEPTH } {
	# Procedure called to update G_FIFO_DEPTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.G_FIFO_DEPTH { PARAM_VALUE.G_FIFO_DEPTH } {
	# Procedure called to validate G_FIFO_DEPTH
	return true
}

proc update_PARAM_VALUE.G_MAX_ORDERS { PARAM_VALUE.G_MAX_ORDERS } {
	# Procedure called to update G_MAX_ORDERS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.G_MAX_ORDERS { PARAM_VALUE.G_MAX_ORDERS } {
	# Procedure called to validate G_MAX_ORDERS
	return true
}

proc update_PARAM_VALUE.G_ORDER_BOOK_ID { PARAM_VALUE.G_ORDER_BOOK_ID } {
	# Procedure called to update G_ORDER_BOOK_ID when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.G_ORDER_BOOK_ID { PARAM_VALUE.G_ORDER_BOOK_ID } {
	# Procedure called to validate G_ORDER_BOOK_ID
	return true
}

proc update_PARAM_VALUE.G_TPID { PARAM_VALUE.G_TPID } {
	# Procedure called to update G_TPID when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.G_TPID { PARAM_VALUE.G_TPID } {
	# Procedure called to validate G_TPID
	return true
}

proc update_PARAM_VALUE.G_TX_IPG_WORDS { PARAM_VALUE.G_TX_IPG_WORDS } {
	# Procedure called to update G_TX_IPG_WORDS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.G_TX_IPG_WORDS { PARAM_VALUE.G_TX_IPG_WORDS } {
	# Procedure called to validate G_TX_IPG_WORDS
	return true
}


proc update_MODELPARAM_VALUE.G_TPID { MODELPARAM_VALUE.G_TPID PARAM_VALUE.G_TPID } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.G_TPID}] ${MODELPARAM_VALUE.G_TPID}
}

proc update_MODELPARAM_VALUE.G_ORDER_BOOK_ID { MODELPARAM_VALUE.G_ORDER_BOOK_ID PARAM_VALUE.G_ORDER_BOOK_ID } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.G_ORDER_BOOK_ID}] ${MODELPARAM_VALUE.G_ORDER_BOOK_ID}
}

proc update_MODELPARAM_VALUE.G_FIFO_DEPTH { MODELPARAM_VALUE.G_FIFO_DEPTH PARAM_VALUE.G_FIFO_DEPTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.G_FIFO_DEPTH}] ${MODELPARAM_VALUE.G_FIFO_DEPTH}
}

proc update_MODELPARAM_VALUE.G_MAX_ORDERS { MODELPARAM_VALUE.G_MAX_ORDERS PARAM_VALUE.G_MAX_ORDERS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.G_MAX_ORDERS}] ${MODELPARAM_VALUE.G_MAX_ORDERS}
}

proc update_MODELPARAM_VALUE.G_CHECK_PREAMBLE { MODELPARAM_VALUE.G_CHECK_PREAMBLE PARAM_VALUE.G_CHECK_PREAMBLE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.G_CHECK_PREAMBLE}] ${MODELPARAM_VALUE.G_CHECK_PREAMBLE}
}

proc update_MODELPARAM_VALUE.G_TX_IPG_WORDS { MODELPARAM_VALUE.G_TX_IPG_WORDS PARAM_VALUE.G_TX_IPG_WORDS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.G_TX_IPG_WORDS}] ${MODELPARAM_VALUE.G_TX_IPG_WORDS}
}

