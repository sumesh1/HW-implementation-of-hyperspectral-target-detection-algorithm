start_gui
create_project ShermanMorrison D:/Vivado/ShermanMorrison -part xc7z020clg484-1
set_property board_part em.avnet.com:zed:part0:1.4 [current_project]
set_property target_language VHDL [current_project]
add_files -norecurse {D:/git_hw/HW-implementation-of-hyperspectral-target-detection-algorithm/THESIS/VHDL/SMnew/dp_controller_sm.vhd D:/git_hw/HW-implementation-of-hyperspectral-target-detection-algorithm/THESIS/VHDL/SMnew/ShermanMorrisonTopLevel.vhd D:/git_hw/HW-implementation-of-hyperspectral-target-detection-algorithm/THESIS/VHDL/SMnew/mult_datapath.vhd D:/git_hw/HW-implementation-of-hyperspectral-target-detection-algorithm/THESIS/VHDL/SMnew/dp_datapath_sm.vhd D:/git_hw/HW-implementation-of-hyperspectral-target-detection-algorithm/THESIS/VHDL/SMnew/MultiplierArray.vhd D:/git_hw/HW-implementation-of-hyperspectral-target-detection-algorithm/THESIS/VHDL/SMnew/CorrelationMatrix.vhd D:/git_hw/HW-implementation-of-hyperspectral-target-detection-algorithm/THESIS/VHDL/SMnew/ShermanMorrisonController.vhd D:/git_hw/HW-implementation-of-hyperspectral-target-detection-algorithm/THESIS/VHDL/SMnew/InputPixel.vhd D:/git_hw/HW-implementation-of-hyperspectral-target-detection-algorithm/THESIS/VHDL/SMnew/DotProductArray.vhd D:/git_hw/HW-implementation-of-hyperspectral-target-detection-algorithm/THESIS/VHDL/SMnew/mult_controller.vhd D:/git_hw/HW-implementation-of-hyperspectral-target-detection-algorithm/THESIS/VHDL/SMnew/td_package.vhd}
add_files -fileset sim_1 -norecurse D:/git_hw/HW-implementation-of-hyperspectral-target-detection-algorithm/THESIS/VHDL/SMnew/ShermanMorrison_testbench.vhd
file mkdir D:/Vivado/ShermanMorrison/ShermanMorrison.srcs/constrs_1/new
close [ open D:/Vivado/ShermanMorrison/ShermanMorrison.srcs/constrs_1/new/timing.xdc w ]
add_files -fileset constrs_1 D:/Vivado/ShermanMorrison/ShermanMorrison.srcs/constrs_1/new/timing.xdc
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
update_compile_order -fileset sources_1

set_property top ShermanMorrison_testbench [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
update_compile_order -fileset sim_1

create_bd_design "sys"
update_compile_order -fileset sources_1

create_bd_cell -type module -reference ShermanMorrisonTopLevel ShermanMorrisonTopLe_0

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:div_gen:5.1 div_gen_0
endgroup
set_property -dict [list CONFIG.dividend_and_quotient_width.VALUE_SRC USER CONFIG.divisor_width.VALUE_SRC USER CONFIG.operand_sign.VALUE_SRC USER] [get_bd_cells div_gen_0]
set_property -dict [list CONFIG.dividend_and_quotient_width {2} CONFIG.divisor_width {32} CONFIG.remainder_type {Fractional} CONFIG.ARESETN {true} CONFIG.fractional_width {32} CONFIG.latency {38}] [get_bd_cells div_gen_0]

connect_bd_intf_net [get_bd_intf_pins ShermanMorrisonTopLe_0/M_DIV_AXIS] [get_bd_intf_pins div_gen_0/S_AXIS_DIVISOR]
connect_bd_intf_net [get_bd_intf_pins div_gen_0/M_AXIS_DOUT] [get_bd_intf_pins ShermanMorrisonTopLe_0/S_DIV_AXIS]
startgroup
create_bd_port -dir I -type clk aclk
set_property -dict [list CONFIG.FREQ_HZ [get_property CONFIG.FREQ_HZ [get_bd_pins div_gen_0/aclk]]] [get_bd_ports aclk]
connect_bd_net [get_bd_pins /div_gen_0/aclk] [get_bd_ports aclk]
set_property CONFIG.FREQ_HZ 1000000 [get_bd_ports aclk]
endgroup
connect_bd_net [get_bd_ports aclk] [get_bd_pins ShermanMorrisonTopLe_0/CLK]
startgroup
create_bd_port -dir I -type rst aresetn
connect_bd_net [get_bd_pins /div_gen_0/aresetn] [get_bd_ports aresetn]
endgroup
connect_bd_net [get_bd_ports aresetn] [get_bd_pins ShermanMorrisonTopLe_0/RESETN]
startgroup
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS_DIVIDEND
set_property CONFIG.HAS_TREADY [get_property CONFIG.HAS_TREADY [get_bd_intf_pins div_gen_0/S_AXIS_DIVIDEND]] [get_bd_intf_ports S_AXIS_DIVIDEND]
connect_bd_intf_net [get_bd_intf_pins div_gen_0/S_AXIS_DIVIDEND] [get_bd_intf_ports S_AXIS_DIVIDEND]
endgroup
startgroup
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS
set_property CONFIG.TDATA_NUM_BYTES [get_property CONFIG.TDATA_NUM_BYTES [get_bd_intf_pins ShermanMorrisonTopLe_0/S_AXIS]] [get_bd_intf_ports S_AXIS]
connect_bd_intf_net [get_bd_intf_pins ShermanMorrisonTopLe_0/S_AXIS] [get_bd_intf_ports S_AXIS]
endgroup
startgroup
create_bd_port -dir I -from 511 -to 0 INPUT_COLUMN
connect_bd_net [get_bd_pins /ShermanMorrisonTopLe_0/INPUT_COLUMN] [get_bd_ports INPUT_COLUMN]
endgroup

regenerate_bd_layout
validate_bd_design
save_bd_design

make_wrapper -files [get_files D:/Vivado/ShermanMorrison/ShermanMorrison.srcs/sources_1/bd/sys/sys.bd] -top
add_files -norecurse D:/Vivado/ShermanMorrison/ShermanMorrison.srcs/sources_1/bd/sys/hdl/sys_wrapper.vhd
update_compile_order -fileset sources_1

set_property top sys_wrapper [current_fileset]
update_compile_order -fileset sources_1

