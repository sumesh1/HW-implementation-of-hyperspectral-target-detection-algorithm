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


module MasterOutput_svtb;


logic   		CLK;
logic   		RESETN;
logic  [31:0]	DATA_IN;
logic    	 	DATA_IN_VALID;
logic    		M_AXIS_TVALID;
logic  [31:0]	M_AXIS_TDATA;
logic   		M_AXIS_TLAST;
logic   		M_AXIS_TREADY;
logic   		STOP_PIPELINE;
logic  [31:0]   cnt;


MasterOutput MasterOutput_inst (
   .CLK                (CLK            ),
   .RESETN             (RESETN         ),
   .DATA_IN            (DATA_IN        ),
   .DATA_IN_VALID      (DATA_IN_VALID  ),
   .M_AXIS_TVALID      (M_AXIS_TVALID  ),
   .M_AXIS_TDATA       (M_AXIS_TDATA   ),
   .M_AXIS_TLAST       (M_AXIS_TLAST   ),
   .M_AXIS_TREADY      (M_AXIS_TREADY  ),
   .STOP_PIPELINE      (STOP_PIPELINE  )
   );
   
   
	initial begin
	
		CLK = 0;
		forever #5ns CLK =~ CLK ;
		
	end

	initial begin
	
		RESETN = 0;
		#50ns RESETN = 1;
		
	end
	
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
		
	end 
	
// ASSERTIONS ----------------------------------------------------------------------

  property stopping_pipeline;
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
	
	
endmodule
