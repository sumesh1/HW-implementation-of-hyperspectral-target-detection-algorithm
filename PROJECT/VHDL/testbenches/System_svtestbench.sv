/*
-- Company: 
-- Engineer: 
-- 
-- Create Date: 30.09.2018 16:04:26
-- Design Name: 
-- Module Name: _svtb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
*/

import axi_vip_pkg::*;
import sys_axi_vip_0_0_pkg::*;

module System_svtb;

parameter PIXEL_DATA_WIDTH       = 16;
parameter BRAM_DATA_WIDTH       = 32;
parameter NUM_BANDS              = 16;
parameter OUT_DATA_WIDTH         = 32;

//AXI VIP LITE interface signals
xil_axi_ulong  addr1 = 32'hC0000000, addr2 = 32'hC0000004,addr3 = 32'hC0000008, addr4 = 32'hC0000000C;
xil_axi_prot_t prot = 0;
logic [31:0] data_wr1 = 32'd500000000, data_wr2 = 32'd500000000,data_wr3 = 32'h00000001;
logic [31:0] data_rd1, data_rd2;
xil_axi_resp_t resp;


logic	[31:0]  M_AXIS_tdata;
logic			M_AXIS_tlast;
logic			M_AXIS_tready; 
logic			M_AXIS_tvalid;
logic	[15:0] 	S_AXIS_tdata;
logic			S_AXIS_tready;
logic			S_AXIS_tvalid;
logic 			S_AXIS_tlast;
logic			clk;
logic			resetn;
logic			START;
integer 		i = 0;



//Design under test
sys_wrapper DUT
(

   .M_AXIS_DOUT_tdata (M_AXIS_tdata), 
   .M_AXIS_DOUT_tlast (M_AXIS_tlast ),
   .M_AXIS_DOUT_tready (M_AXIS_tready ),
   .M_AXIS_DOUT_tvalid (M_AXIS_tvalid ),
   .S_AXIS_tdata (S_AXIS_tdata ),
   .S_AXIS_tready (S_AXIS_tready ),
   .S_AXIS_tvalid (S_AXIS_tvalid ),
   .S_AXIS_tlast (S_AXIS_tlast),
   .clk(clk),
   .resetn (resetn )
);

//VHDL testbench for generating signals and handling files
VHDL_testbench  #(PIXEL_DATA_WIDTH,BRAM_DATA_WIDTH, NUM_BANDS,OUT_DATA_WIDTH) VHDL_testbench_inst
(
	.CLK            (clk),             
	.RESETN         (resetn),            
	.S_AXIS_TREADY  (S_AXIS_tready),        
	.S_AXIS_TDATA   (S_AXIS_tdata),        
	.S_AXIS_TVALID  (S_AXIS_tvalid),       
	.S_AXIS_TLAST	(S_AXIS_tlast),
	.M_AXIS_TVALID 	(M_AXIS_tvalid),
	.M_AXIS_TDATA   (M_AXIS_tdata),
	.M_AXIS_TLAST   (M_AXIS_tlast),
	.M_AXIS_TREADY  (M_AXIS_tready),
	.START (START)
	
);

sys_axi_vip_0_0_mst_t 	master_agent;

// matrix file
logic [32-1:0] matrix[16*16-1:0 ];

// get memory contents from file
initial
  $readmemh("D:/SmallSAT/HW-implementation-of-hyperspectral-target-detection-algorithm/PROJECT/SIMULATION_FILES/matrix.txt", matrix);

// sR file
logic [32-1:0] sR[16-1:0];

// get memory contents from file
initial
  $readmemh("D:/SmallSAT/HW-implementation-of-hyperspectral-target-detection-algorithm/PROJECT/SIMULATION_FILES/stat.txt", sR);
  
 logic [32-1:0] sRs = 32'd1566759688;


initial 
begin
	START = 0;
    //Create an agent
    master_agent = new("master vip agent", DUT.sys_i.axi_vip_0.inst.IF);
  
    // set tag for agents for easy debug
    master_agent.set_agent_tag("Master VIP");
  
    // set print out verbosity level.
    master_agent.set_verbosity(400);
  
    //Start the agent
    master_agent.start_master();
    #2000ns;
	
	//no debug
	master_agent.AXI4LITE_WRITE_BURST(addr4,prot,0,resp);
	
	//uploading initial matrix
	#1000ns;
	for (i = 0; i<NUM_BANDS*NUM_BANDS;i++)
	begin
		#20ns
		master_agent.AXI4LITE_WRITE_BURST(addr1,prot,matrix[i],resp);
	end	
 	
	//uploading sR
	for (i = 0; i< NUM_BANDS ;i++)
	begin
		#20ns
		master_agent.AXI4LITE_WRITE_BURST(addr2,prot,sR[i],resp);
	end	
	
	master_agent.AXI4LITE_WRITE_BURST(addr3,prot,sRs,resp);
	
	//enabling testbench
	#1000ns;
	START = 1;
	
end


	
	
endmodule