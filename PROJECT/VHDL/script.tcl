start_gui
create_project ACE_FPGA C:/Users/Dordije/VivadoProjects/ACE_FPGA -part xc7z020clg484-1
set_property board_part em.avnet.com:zed:part0:1.4 [current_project]
set_property target_language VHDL [current_project]
add_files -norecurse {D:/SmallSAT/HW-implementation-of-hyperspectral-target-detection-algorithm/PROJECT/VHDL/Stage1.vhd D:/SmallSAT/HW-implementation-of-hyperspectral-target-detection-algorithm/PROJECT/VHDL/dp_datapath.vhd D:/SmallSAT/HW-implementation-of-hyperspectral-target-detection-algorithm/PROJECT/VHDL/Stage3.vhd D:/SmallSAT/HW-implementation-of-hyperspectral-target-detection-algorithm/PROJECT/VHDL/TopLevel_wrapper.vhd D:/SmallSAT/HW-implementation-of-hyperspectral-target-detection-algorithm/PROJECT/VHDL/dp_controller.vhd D:/SmallSAT/HW-implementation-of-hyperspectral-target-detection-algorithm/PROJECT/VHDL/bram_wrapper.vhd D:/SmallSAT/HW-implementation-of-hyperspectral-target-detection-algorithm/PROJECT/VHDL/Stage2.vhd D:/SmallSAT/HW-implementation-of-hyperspectral-target-detection-algorithm/PROJECT/VHDL/MasterOutput.vhd D:/SmallSAT/HW-implementation-of-hyperspectral-target-detection-algorithm/PROJECT/VHDL/TopLevel.vhd D:/SmallSAT/HW-implementation-of-hyperspectral-target-detection-algorithm/PROJECT/VHDL/bram_topmodule.vhd D:/SmallSAT/HW-implementation-of-hyperspectral-target-detection-algorithm/PROJECT/VHDL/my_types_pkg.vhd D:/SmallSAT/HW-implementation-of-hyperspectral-target-detection-algorithm/PROJECT/VHDL/bram.vhd D:/SmallSAT/HW-implementation-of-hyperspectral-target-detection-algorithm/PROJECT/VHDL/Accelerator.vhd}
add_files -fileset sim_1 -norecurse {D:/SmallSAT/HW-implementation-of-hyperspectral-target-detection-algorithm/PROJECT/VHDL/testbenches/System_testpatterns.vhd D:/SmallSAT/HW-implementation-of-hyperspectral-target-detection-algorithm/PROJECT/VHDL/testbenches/System_svtestbench.sv}
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1


# CREATING SIMULATION BLOCK DESIGN
create_bd_design "sys"
update_compile_order -fileset sources_1
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vip:1.1 axi_vip_0
endgroup
set_property -dict [list CONFIG.PROTOCOL.VALUE_SRC USER] [get_bd_cells axi_vip_0]
set_property -dict [list CONFIG.PROTOCOL {AXI4LITE} CONFIG.INTERFACE_MODE {MASTER}] [get_bd_cells axi_vip_0]
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:div_gen:5.1 div_gen_0
endgroup
set_property -dict [list CONFIG.divisor_width.VALUE_SRC USER CONFIG.dividend_and_quotient_width.VALUE_SRC USER CONFIG.operand_sign.VALUE_SRC USER] [get_bd_cells div_gen_0]
set_property -dict [list CONFIG.dividend_and_quotient_width {32} CONFIG.dividend_has_tlast {true} CONFIG.divisor_width {32} CONFIG.divisor_has_tlast {true} CONFIG.remainder_type {Fractional} CONFIG.FlowControl {Blocking} CONFIG.OutTready {true} CONFIG.OutTLASTBehv {OR_all_TLASTs} CONFIG.ARESETN {true} CONFIG.fractional_width {32} CONFIG.latency {71}] [get_bd_cells div_gen_0]
create_bd_cell -type module -reference BRAM_WRAPPER BRAM_WRAPPER_0
create_bd_cell -type module -reference TopLevel_wrapper TopLevel_wrapper_0
set_property -dict [list CONFIG.C_S00_AXI_DATA_WIDTH {32} CONFIG.BRAM_DATA_WIDTH {32}] [get_bd_cells BRAM_WRAPPER_0]
startgroup
create_bd_port -dir I -type clk clk
connect_bd_net [get_bd_pins /TopLevel_wrapper_0/CLK] [get_bd_ports clk]
set_property CONFIG.FREQ_HZ 100000000 [get_bd_ports clk]
endgroup
startgroup
create_bd_port -dir I -type rst resetn
connect_bd_net [get_bd_pins /TopLevel_wrapper_0/RESETN] [get_bd_ports resetn]
endgroup
connect_bd_net [get_bd_ports clk] [get_bd_pins BRAM_WRAPPER_0/s00_axi_aclk]
connect_bd_net [get_bd_ports resetn] [get_bd_pins BRAM_WRAPPER_0/s00_axi_aresetn]
connect_bd_net [get_bd_ports clk] [get_bd_pins div_gen_0/aclk]
connect_bd_net [get_bd_ports resetn] [get_bd_pins div_gen_0/aresetn]
connect_bd_net [get_bd_ports clk] [get_bd_pins axi_vip_0/aclk]
connect_bd_net [get_bd_ports resetn] [get_bd_pins axi_vip_0/aresetn]
connect_bd_net [get_bd_pins BRAM_WRAPPER_0/MATRIX_ROW] [get_bd_pins TopLevel_wrapper_0/MATRIX_ROW]
connect_bd_net [get_bd_pins BRAM_WRAPPER_0/STATIC_VECTOR_SR] [get_bd_pins TopLevel_wrapper_0/STATIC_VECTOR_SR]
connect_bd_net [get_bd_pins BRAM_WRAPPER_0/STATIC_SRS] [get_bd_pins TopLevel_wrapper_0/STATIC_SRS]
connect_bd_net [get_bd_pins BRAM_WRAPPER_0/ROW_SELECT] [get_bd_pins TopLevel_wrapper_0/ROW_SELECT]
connect_bd_intf_net [get_bd_intf_pins axi_vip_0/M_AXI] [get_bd_intf_pins BRAM_WRAPPER_0/s00_axi]
startgroup
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS
set_property -dict [list CONFIG.TDATA_NUM_BYTES [get_property CONFIG.TDATA_NUM_BYTES [get_bd_intf_pins TopLevel_wrapper_0/S_AXIS]] CONFIG.HAS_TLAST [get_property CONFIG.HAS_TLAST [get_bd_intf_pins TopLevel_wrapper_0/S_AXIS]]] [get_bd_intf_ports S_AXIS]
connect_bd_intf_net [get_bd_intf_pins TopLevel_wrapper_0/S_AXIS] [get_bd_intf_ports S_AXIS]
endgroup
connect_bd_intf_net [get_bd_intf_pins TopLevel_wrapper_0/M1_AXIS] [get_bd_intf_pins div_gen_0/S_AXIS_DIVISOR]
connect_bd_intf_net [get_bd_intf_pins TopLevel_wrapper_0/M2_AXIS] [get_bd_intf_pins div_gen_0/S_AXIS_DIVIDEND]
startgroup
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS_DOUT
connect_bd_intf_net [get_bd_intf_pins div_gen_0/M_AXIS_DOUT] [get_bd_intf_ports M_AXIS_DOUT]
endgroup
assign_bd_address [get_bd_addr_segs {BRAM_WRAPPER_0/s00_axi/reg0 }]
set_property offset 0xC0000000 [get_bd_addr_segs {axi_vip_0/Master_AXI/SEG_BRAM_WRAPPER_0_reg0}]
validate_bd_design
save_bd_design
make_wrapper -files [get_files C:/Users/Dordije/VivadoProjects/ACE_FPGA/ACE_FPGA.srcs/sources_1/bd/sys/sys.bd] -top
add_files -norecurse C:/Users/Dordije/VivadoProjects/ACE_FPGA/ACE_FPGA.srcs/sources_1/bd/sys/hdl/sys_wrapper.vhd
update_compile_order -fileset sources_1
set_property top sys_wrapper [current_fileset]
update_compile_order -fileset sources_1
set_property file_type {VHDL 2008} [get_files  D:/SmallSAT/HW-implementation-of-hyperspectral-target-detection-algorithm/PROJECT/VHDL/bram_topmodule.vhd]
set_property file_type {VHDL 2008} [get_files  {D:/SmallSAT/HW-implementation-of-hyperspectral-target-detection-algorithm/PROJECT/VHDL/Accelerator.vhd D:/SmallSAT/HW-implementation-of-hyperspectral-target-detection-algorithm/PROJECT/VHDL/TopLevel.vhd}]
set_property file_type {VHDL 2008} [get_files  D:/SmallSAT/HW-implementation-of-hyperspectral-target-detection-algorithm/PROJECT/VHDL/testbenches/System_testpatterns.vhd]
update_compile_order -fileset sources_1
update_module_reference sys_TopLevel_wrapper_0_0



# LAUNCHING SIMULATION
generate_target Simulation [get_files C:/Users/Dordije/VivadoProjects/ACE_FPGA/ACE_FPGA.srcs/sources_1/bd/sys/sys.bd]
export_ip_user_files -of_objects [get_files C:/Users/Dordije/VivadoProjects/ACE_FPGA/ACE_FPGA.srcs/sources_1/bd/sys/sys.bd] -no_script -sync -force -quiet
export_simulation -of_objects [get_files C:/Users/Dordije/VivadoProjects/ACE_FPGA/ACE_FPGA.srcs/sources_1/bd/sys/sys.bd] -directory C:/Users/Dordije/VivadoProjects/ACE_FPGA/ACE_FPGA.ip_user_files/sim_scripts -ip_user_files_dir C:/Users/Dordije/VivadoProjects/ACE_FPGA/ACE_FPGA.ip_user_files -ipstatic_source_dir C:/Users/Dordije/VivadoProjects/ACE_FPGA/ACE_FPGA.ip_user_files/ipstatic -lib_map_path [list {modelsim=C:/Users/Dordije/VivadoProjects/ACE_FPGA/ACE_FPGA.cache/compile_simlib/modelsim} {questa=C:/Users/Dordije/VivadoProjects/ACE_FPGA/ACE_FPGA.cache/compile_simlib/questa} {riviera=C:/Users/Dordije/VivadoProjects/ACE_FPGA/ACE_FPGA.cache/compile_simlib/riviera} {activehdl=C:/Users/Dordije/VivadoProjects/ACE_FPGA/ACE_FPGA.cache/compile_simlib/activehdl}] -use_ip_compiled_libs -force -quiet
launch_simulation
source System_svtb.tcl


# CREATE SYNTHESIS BLOCK DESIGN

create_bd_design "synthesis"
update_compile_order -fileset sources_1
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
endgroup
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]
startgroup
set_property -dict [list CONFIG.PCW_USE_S_AXI_HP0 {1} CONFIG.PCW_USE_FABRIC_INTERRUPT {1} CONFIG.PCW_IRQ_F2P_INTR {1}] [get_bd_cells processing_system7_0]
endgroup
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma_0
endgroup
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0
endgroup
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:div_gen:5.1 div_gen_0
endgroup
create_bd_cell -type module -reference TopLevel_wrapper TopLevel_wrapper_0
create_bd_cell -type module -reference BRAM_WRAPPER BRAM_WRAPPER_0
set_property -dict [list CONFIG.dividend_and_quotient_width.VALUE_SRC USER CONFIG.divisor_width.VALUE_SRC USER CONFIG.operand_sign.VALUE_SRC USER] [get_bd_cells div_gen_0]
set_property -dict [list CONFIG.dividend_and_quotient_width {32} CONFIG.dividend_has_tlast {true} CONFIG.divisor_width {32} CONFIG.divisor_has_tlast {true} CONFIG.remainder_type {Fractional} CONFIG.FlowControl {Blocking} CONFIG.OutTready {true} CONFIG.OutTLASTBehv {OR_all_TLASTs} CONFIG.ARESETN {true} CONFIG.fractional_width {32} CONFIG.latency {71}] [get_bd_cells div_gen_0]
set_property -dict [list CONFIG.c_include_sg {0} CONFIG.c_sg_include_stscntrl_strm {0}] [get_bd_cells axi_dma_0]
connect_bd_net [get_bd_pins axi_dma_0/mm2s_introut] [get_bd_pins xlconcat_0/In0]
connect_bd_net [get_bd_pins axi_dma_0/s2mm_introut] [get_bd_pins xlconcat_0/In1]
connect_bd_net [get_bd_pins xlconcat_0/dout] [get_bd_pins processing_system7_0/IRQ_F2P]
connect_bd_intf_net [get_bd_intf_pins TopLevel_wrapper_0/M1_AXIS] [get_bd_intf_pins div_gen_0/S_AXIS_DIVISOR]
connect_bd_intf_net [get_bd_intf_pins TopLevel_wrapper_0/M2_AXIS] [get_bd_intf_pins div_gen_0/S_AXIS_DIVIDEND]
set_property -dict [list CONFIG.C_S00_AXI_DATA_WIDTH {32} CONFIG.BRAM_DATA_WIDTH {32}] [get_bd_cells BRAM_WRAPPER_0]
connect_bd_net [get_bd_pins BRAM_WRAPPER_0/MATRIX_ROW] [get_bd_pins TopLevel_wrapper_0/MATRIX_ROW]
connect_bd_net [get_bd_pins BRAM_WRAPPER_0/STATIC_VECTOR_SR] [get_bd_pins TopLevel_wrapper_0/STATIC_VECTOR_SR]
connect_bd_net [get_bd_pins BRAM_WRAPPER_0/STATIC_SRS] [get_bd_pins TopLevel_wrapper_0/STATIC_SRS]
connect_bd_net [get_bd_pins TopLevel_wrapper_0/ROW_SELECT] [get_bd_pins BRAM_WRAPPER_0/ROW_SELECT]
connect_bd_intf_net [get_bd_intf_pins div_gen_0/M_AXIS_DOUT] [get_bd_intf_pins axi_dma_0/S_AXIS_S2MM]
connect_bd_intf_net [get_bd_intf_pins axi_dma_0/M_AXIS_MM2S] [get_bd_intf_pins TopLevel_wrapper_0/S_AXIS]
startgroup
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/axi_dma_0/M_AXI_MM2S} Slave {/processing_system7_0/S_AXI_HP0} intc_ip {Auto} master_apm {0}}  [get_bd_intf_pins processing_system7_0/S_AXI_HP0]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/processing_system7_0/M_AXI_GP0} Slave {/axi_dma_0/S_AXI_LITE} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins axi_dma_0/S_AXI_LITE]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/processing_system7_0/FCLK_CLK0 (100 MHz)" }  [get_bd_pins div_gen_0/aclk]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/processing_system7_0/M_AXI_GP0} Slave {/BRAM_WRAPPER_0/s00_axi} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins BRAM_WRAPPER_0/s00_axi]
endgroup
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/processing_system7_0/FCLK_CLK0 (100 MHz)} Clk_slave {/processing_system7_0/FCLK_CLK0 (100 MHz)} Clk_xbar {/processing_system7_0/FCLK_CLK0 (100 MHz)} Master {/axi_dma_0/M_AXI_S2MM} Slave {/processing_system7_0/S_AXI_HP0} intc_ip {/axi_smc} master_apm {0}}  [get_bd_intf_pins axi_dma_0/M_AXI_S2MM]
validate_bd_design
save_bd_design
add_files -norecurse C:/Users/Dordije/VivadoProjects/ACE_FPGA/ACE_FPGA.srcs/sources_1/bd/synthesis/hdl/synthesis_wrapper.vhd
update_compile_order -fileset sources_1
set_property top synthesis_wrapper [current_fileset]

