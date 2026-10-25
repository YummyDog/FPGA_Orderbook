# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "G_ACTIVE_HIGH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "G_CLK_HZ" -parent ${Page_0}
  ipgui::add_param $IPINST -name "G_DUTY_PCT" -parent ${Page_0}
  ipgui::add_param $IPINST -name "G_MIN_DUTY_PCT" -parent ${Page_0}
  ipgui::add_param $IPINST -name "G_PWM_HZ" -parent ${Page_0}


}

proc update_PARAM_VALUE.G_ACTIVE_HIGH { PARAM_VALUE.G_ACTIVE_HIGH } {
	# Procedure called to update G_ACTIVE_HIGH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.G_ACTIVE_HIGH { PARAM_VALUE.G_ACTIVE_HIGH } {
	# Procedure called to validate G_ACTIVE_HIGH
	return true
}

proc update_PARAM_VALUE.G_CLK_HZ { PARAM_VALUE.G_CLK_HZ } {
	# Procedure called to update G_CLK_HZ when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.G_CLK_HZ { PARAM_VALUE.G_CLK_HZ } {
	# Procedure called to validate G_CLK_HZ
	return true
}

proc update_PARAM_VALUE.G_DUTY_PCT { PARAM_VALUE.G_DUTY_PCT } {
	# Procedure called to update G_DUTY_PCT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.G_DUTY_PCT { PARAM_VALUE.G_DUTY_PCT } {
	# Procedure called to validate G_DUTY_PCT
	return true
}

proc update_PARAM_VALUE.G_MIN_DUTY_PCT { PARAM_VALUE.G_MIN_DUTY_PCT } {
	# Procedure called to update G_MIN_DUTY_PCT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.G_MIN_DUTY_PCT { PARAM_VALUE.G_MIN_DUTY_PCT } {
	# Procedure called to validate G_MIN_DUTY_PCT
	return true
}

proc update_PARAM_VALUE.G_PWM_HZ { PARAM_VALUE.G_PWM_HZ } {
	# Procedure called to update G_PWM_HZ when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.G_PWM_HZ { PARAM_VALUE.G_PWM_HZ } {
	# Procedure called to validate G_PWM_HZ
	return true
}


proc update_MODELPARAM_VALUE.G_CLK_HZ { MODELPARAM_VALUE.G_CLK_HZ PARAM_VALUE.G_CLK_HZ } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.G_CLK_HZ}] ${MODELPARAM_VALUE.G_CLK_HZ}
}

proc update_MODELPARAM_VALUE.G_PWM_HZ { MODELPARAM_VALUE.G_PWM_HZ PARAM_VALUE.G_PWM_HZ } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.G_PWM_HZ}] ${MODELPARAM_VALUE.G_PWM_HZ}
}

proc update_MODELPARAM_VALUE.G_DUTY_PCT { MODELPARAM_VALUE.G_DUTY_PCT PARAM_VALUE.G_DUTY_PCT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.G_DUTY_PCT}] ${MODELPARAM_VALUE.G_DUTY_PCT}
}

proc update_MODELPARAM_VALUE.G_MIN_DUTY_PCT { MODELPARAM_VALUE.G_MIN_DUTY_PCT PARAM_VALUE.G_MIN_DUTY_PCT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.G_MIN_DUTY_PCT}] ${MODELPARAM_VALUE.G_MIN_DUTY_PCT}
}

proc update_MODELPARAM_VALUE.G_ACTIVE_HIGH { MODELPARAM_VALUE.G_ACTIVE_HIGH PARAM_VALUE.G_ACTIVE_HIGH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.G_ACTIVE_HIGH}] ${MODELPARAM_VALUE.G_ACTIVE_HIGH}
}

