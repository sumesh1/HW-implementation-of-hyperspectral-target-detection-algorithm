# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "C_MM2S_COMP_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_MM2S_DATA_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_MM2S_NUM_COMP" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S2MM_COMP_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S2MM_DATA_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S2MM_INDET_LENGTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S2MM_NUM_COMP" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_TINYMOVER" -parent ${Page_0}


}

proc update_PARAM_VALUE.C_MM2S_COMP_WIDTH { PARAM_VALUE.C_MM2S_COMP_WIDTH } {
	# Procedure called to update C_MM2S_COMP_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_MM2S_COMP_WIDTH { PARAM_VALUE.C_MM2S_COMP_WIDTH } {
	# Procedure called to validate C_MM2S_COMP_WIDTH
	return true
}

proc update_PARAM_VALUE.C_MM2S_DATA_WIDTH { PARAM_VALUE.C_MM2S_DATA_WIDTH } {
	# Procedure called to update C_MM2S_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_MM2S_DATA_WIDTH { PARAM_VALUE.C_MM2S_DATA_WIDTH } {
	# Procedure called to validate C_MM2S_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_MM2S_NUM_COMP { PARAM_VALUE.C_MM2S_NUM_COMP } {
	# Procedure called to update C_MM2S_NUM_COMP when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_MM2S_NUM_COMP { PARAM_VALUE.C_MM2S_NUM_COMP } {
	# Procedure called to validate C_MM2S_NUM_COMP
	return true
}

proc update_PARAM_VALUE.C_S2MM_COMP_WIDTH { PARAM_VALUE.C_S2MM_COMP_WIDTH } {
	# Procedure called to update C_S2MM_COMP_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S2MM_COMP_WIDTH { PARAM_VALUE.C_S2MM_COMP_WIDTH } {
	# Procedure called to validate C_S2MM_COMP_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S2MM_DATA_WIDTH { PARAM_VALUE.C_S2MM_DATA_WIDTH } {
	# Procedure called to update C_S2MM_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S2MM_DATA_WIDTH { PARAM_VALUE.C_S2MM_DATA_WIDTH } {
	# Procedure called to validate C_S2MM_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S2MM_INDET_LENGTH { PARAM_VALUE.C_S2MM_INDET_LENGTH } {
	# Procedure called to update C_S2MM_INDET_LENGTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S2MM_INDET_LENGTH { PARAM_VALUE.C_S2MM_INDET_LENGTH } {
	# Procedure called to validate C_S2MM_INDET_LENGTH
	return true
}

proc update_PARAM_VALUE.C_S2MM_NUM_COMP { PARAM_VALUE.C_S2MM_NUM_COMP } {
	# Procedure called to update C_S2MM_NUM_COMP when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S2MM_NUM_COMP { PARAM_VALUE.C_S2MM_NUM_COMP } {
	# Procedure called to validate C_S2MM_NUM_COMP
	return true
}

proc update_PARAM_VALUE.C_S_AXI_CTRL_STATUS_ADDR_WIDTH { PARAM_VALUE.C_S_AXI_CTRL_STATUS_ADDR_WIDTH } {
	# Procedure called to update C_S_AXI_CTRL_STATUS_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_CTRL_STATUS_ADDR_WIDTH { PARAM_VALUE.C_S_AXI_CTRL_STATUS_ADDR_WIDTH } {
	# Procedure called to validate C_S_AXI_CTRL_STATUS_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_CTRL_STATUS_DATA_WIDTH { PARAM_VALUE.C_S_AXI_CTRL_STATUS_DATA_WIDTH } {
	# Procedure called to update C_S_AXI_CTRL_STATUS_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_CTRL_STATUS_DATA_WIDTH { PARAM_VALUE.C_S_AXI_CTRL_STATUS_DATA_WIDTH } {
	# Procedure called to validate C_S_AXI_CTRL_STATUS_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_TINYMOVER { PARAM_VALUE.C_TINYMOVER } {
	# Procedure called to update C_TINYMOVER when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_TINYMOVER { PARAM_VALUE.C_TINYMOVER } {
	# Procedure called to validate C_TINYMOVER
	return true
}


proc update_MODELPARAM_VALUE.C_MM2S_DATA_WIDTH { MODELPARAM_VALUE.C_MM2S_DATA_WIDTH PARAM_VALUE.C_MM2S_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_MM2S_DATA_WIDTH}] ${MODELPARAM_VALUE.C_MM2S_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_MM2S_COMP_WIDTH { MODELPARAM_VALUE.C_MM2S_COMP_WIDTH PARAM_VALUE.C_MM2S_COMP_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_MM2S_COMP_WIDTH}] ${MODELPARAM_VALUE.C_MM2S_COMP_WIDTH}
}

proc update_MODELPARAM_VALUE.C_MM2S_NUM_COMP { MODELPARAM_VALUE.C_MM2S_NUM_COMP PARAM_VALUE.C_MM2S_NUM_COMP } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_MM2S_NUM_COMP}] ${MODELPARAM_VALUE.C_MM2S_NUM_COMP}
}

proc update_MODELPARAM_VALUE.C_TINYMOVER { MODELPARAM_VALUE.C_TINYMOVER PARAM_VALUE.C_TINYMOVER } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_TINYMOVER}] ${MODELPARAM_VALUE.C_TINYMOVER}
}

proc update_MODELPARAM_VALUE.C_S2MM_DATA_WIDTH { MODELPARAM_VALUE.C_S2MM_DATA_WIDTH PARAM_VALUE.C_S2MM_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S2MM_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S2MM_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S2MM_COMP_WIDTH { MODELPARAM_VALUE.C_S2MM_COMP_WIDTH PARAM_VALUE.C_S2MM_COMP_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S2MM_COMP_WIDTH}] ${MODELPARAM_VALUE.C_S2MM_COMP_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S2MM_NUM_COMP { MODELPARAM_VALUE.C_S2MM_NUM_COMP PARAM_VALUE.C_S2MM_NUM_COMP } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S2MM_NUM_COMP}] ${MODELPARAM_VALUE.C_S2MM_NUM_COMP}
}

proc update_MODELPARAM_VALUE.C_S2MM_INDET_LENGTH { MODELPARAM_VALUE.C_S2MM_INDET_LENGTH PARAM_VALUE.C_S2MM_INDET_LENGTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S2MM_INDET_LENGTH}] ${MODELPARAM_VALUE.C_S2MM_INDET_LENGTH}
}

proc update_MODELPARAM_VALUE.C_S_AXI_CTRL_STATUS_ADDR_WIDTH { MODELPARAM_VALUE.C_S_AXI_CTRL_STATUS_ADDR_WIDTH PARAM_VALUE.C_S_AXI_CTRL_STATUS_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_CTRL_STATUS_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_CTRL_STATUS_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S_AXI_CTRL_STATUS_DATA_WIDTH { MODELPARAM_VALUE.C_S_AXI_CTRL_STATUS_DATA_WIDTH PARAM_VALUE.C_S_AXI_CTRL_STATUS_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_CTRL_STATUS_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_CTRL_STATUS_DATA_WIDTH}
}

