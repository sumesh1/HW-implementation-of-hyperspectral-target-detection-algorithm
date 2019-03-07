/*
-- Company: 
-- Engineer: 
-- 
-- Create Date: 30.09.2018 16:04:26
-- Design Name: 
-- Module Name: MasterOutput_svtb - Behavioral
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

//import axi_vip_v1_1_3_pkg::*;
//import design_1_axi_vip_0_0_pkg::*;

module ShermanMorrison_svtb;


//bit aclk = 0;
//bit aresetn = 0;
/* xil_axi_ulong  addr1 = 32'hC0000000, addr2 = 32'hC0000004;
xil_axi_prot_t prot = 0;
logic [31:0] data_wr1 = 32'h01234567, data_wr2 = 32'h89ABCDEF;
logic [31:0] data_rd1, data_rd2;
xil_axi_resp_t resp;
 */

logic	[31:0] M_AXIS_tdata ;
logic	M_AXIS_tlast ;
logic	M_AXIS_tready; 
logic	M_AXIS_tvalid ;
logic	[7:0] S_AXIS_DIVIDEND_tdata ;
logic	S_AXIS_DIVIDEND_tvalid ;
logic	[15:0] S_AXIS_tdata ;
logic	S_AXIS_tready ;
logic	S_AXIS_tvalid ;
logic	clk;
logic	resetn ;


sys_wrapper DUT
(

   .M_AXIS_tdata (M_AXIS_tdata), 
   .M_AXIS_tlast (M_AXIS_tlast ),
   .M_AXIS_tready (M_AXIS_tready ),
   .M_AXIS_tvalid (M_AXIS_tvalid ),
   .S_AXIS_DIVIDEND_tdata (S_AXIS_DIVIDEND_tdata ),
   .S_AXIS_DIVIDEND_tvalid (S_AXIS_DIVIDEND_tvalid ),
   .S_AXIS_tdata (S_AXIS_tdata ),
   .S_AXIS_tready (S_AXIS_tready ),
   .S_AXIS_tvalid (S_AXIS_tvalid ),
   .aclk(clk),
   .aresetn (resetn )
);

/* 
design_1_axi_vip_0_0_mst_t      master_agent;

initial begin
    //Create an agent
    master_agent = new("master vip agent",DUT.design_1_i.axi_vip_0.inst.IF);
  
    // set tag for agents for easy debug
    master_agent.set_agent_tag("Master VIP");
  
    // set print out verbosity level.
    master_agent.set_verbosity(400);
  
    //Start the agent
    master_agent.start_master();
  
    #50ns
    resetn = 1;
end

 */
   
   
	initial begin
	
		clk = 0;
		forever #5ns clk =~ clk ;
		
	end

	initial begin
	
		resetn = 0;
		#50ns resetn = 1;
		
	end
/* 	
	initial begin
	
		M_AXIS_TREADY = 0;
		
		#600ns M_AXIS_TREADY = 1;
		
		#700ns M_AXIS_TREADY = 0;
		
		#100ns M_AXIS_TREADY = 1;
	
	end
	
	always_ff @ (posedge CLK)
		begin
			if ( RESETN == 0 )
			 begin
			 
				DATA_IN_VALID  <= 0;
				cnt <= 0;
				
			 end
			
			else if  (cnt < 5) 
				begin
				cnt <= cnt + 1;
				DATA_IN_VALID  <= 0;
				end
			else if (cnt > 12 && cnt < 120) 
				begin
				cnt <= cnt + 1;
				DATA_IN_VALID  <= 1;
				end
			else if (cnt >= 120 && cnt < 200) 
				begin
				cnt <= cnt + 1;
				DATA_IN_VALID  <= 0;
				end
			else
				begin
				cnt <= cnt + 1;
				DATA_IN_VALID  <= 1;
				end
		
		end 
		
	always_ff @ (posedge CLK)
	begin
		if ( RESETN == 0 )
		 begin
		 
			DATA_IN <= '0;
			
		 end
		
		else if  (DATA_IN_VALID == 1 && STOP_PIPELINE == 0) 
			begin
			
			DATA_IN <= DATA_IN + 1;
			
			end
		
	end  */
	
// ASSERTIONS ----------------------------------------------------------------------

/*   property stopping_pipeline;
    @(posedge CLK)  ( M_AXIS_TREADY == 0 |=> STOP_PIPELINE == 1);
  endproperty 
  
  assert property (stopping_pipeline);	
  
   property outputs;
    @(posedge CLK)  ( M_AXIS_TREADY == 1 && M_AXIS_TVALID == 1 |-> M_AXIS_TDATA == $past(M_AXIS_TDATA,1) + 1);
  endproperty 
  
  assert property (outputs);	
  
    property transaction_happens;
    @(posedge CLK)  ( M_AXIS_TREADY == 1 && M_AXIS_TVALID == 1 |=> MasterOutput_inst.written_vectors != $past(MasterOutput_inst.written_vectors,1) );
  endproperty 
  
  assert property (transaction_happens);	
  
   property reading_happens;
    @(posedge CLK)  ( DATA_IN_VALID == 1 && STOP_PIPELINE == 0 |=> MasterOutput_inst.read_vectors != $past(MasterOutput_inst.read_vectors,1) );
  endproperty 
  
  assert property (reading_happens);	
  
   property reading_correct;
    @(posedge CLK)  ( DATA_IN_VALID == 1 && STOP_PIPELINE == 0 |=> MasterOutput_inst.Output_Array (MasterOutput_inst.read_vectors) == $past(DATA_IN,1) );
  endproperty 
  
  assert property (reading_correct);	
	
	 */
endmodule
