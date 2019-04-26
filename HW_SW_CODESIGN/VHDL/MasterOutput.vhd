----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09.10.2018 22:02:54
-- Design Name: 
-- Module Name: MasterOutput - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: Packet FIFO, does not use BRAM
-- 
-- Revision: 10.04.2019.
-- Revision 
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;


entity MasterOutput is
	generic (
		DATA_WIDTH  : positive := 32;
		PACKET_SIZE : positive := 8
	);
	port (
		CLK           : in std_logic;
		RESETN        : in std_logic;
		DATA_IN       : in std_logic_vector(DATA_WIDTH - 1 downto 0);
		DATA_IN_VALID : in std_logic;
		M_AXIS_TVALID : out std_logic;
		M_AXIS_TDATA  : out std_logic_vector(DATA_WIDTH - 1 downto 0);
		M_AXIS_TLAST  : out std_logic;
		M_AXIS_TREADY : in std_logic;
		STOP_PIPELINE : out std_logic;
		LAST_PIXEL	  : in std_logic
	);
end MasterOutput;

architecture Behavioral of MasterOutput is

	type STATE_TYPE is (Idle, Write_Outputs);
	signal state : STATE_TYPE;

	type Output_Array_Type is array (0 to PACKET_SIZE - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);
	signal Output_Array          : Output_Array_Type;

	signal read_vectors          : natural range 0 to PACKET_SIZE - 1;
	signal written_vectors       : natural range 0 to PACKET_SIZE - 1;
	signal tlast                 : std_logic;
	signal Full                  : std_logic;
	signal stop_pipeline_temp    : std_logic;
	signal end_signal			 : std_logic;

begin

	--TLAST is only asserted if it is the last element of the packet 
	--and last incoming packet of data stream from DMA was computed in DMA
	M_AXIS_TLAST       <= tlast and end_signal;
	
	--pipeline stalled if DMA cannot accept incoming packet
	stop_pipeline_temp <= '1' when (state = Write_Outputs and M_AXIS_TREADY = '0') else '0';
	STOP_PIPELINE      <= stop_pipeline_temp;
	
	
	process(CLK) is
	begin
		if( rising_edge(CLK)) then
			if(RESETN = '0') then
			
				end_signal <= '0';
				
			else
			
				if( end_signal = '0') then
					end_signal <= LAST_PIXEL;
				end if;
			
			end if;
			
		end if;
	end process;
	
	--Collect data from accelerator and assemble into packets
	Input_Module : process (CLK) is
	begin
		if (rising_edge(CLK)) then
			if (RESETN = '0') then
				read_vectors <= 0;
				Full         <= '0';
				Output_Array <= (others => (others => '0'));

			else
			
				if (DATA_IN_VALID = '1' and stop_pipeline_temp = '0') then
					
					Output_Array (read_vectors) <= DATA_IN;
					
					if (read_vectors = PACKET_SIZE - 1) then
						
						read_vectors <= 0;
						Full         <= '1';
						
					else
					
						read_vectors <= read_vectors + 1;
						Full <= '0';
						
					end if;
				
				else 
					
					Full <= '0';
				
				end if;	
				
			end if;
		end if;
	end process Input_Module;
	
	--send data over AXI stream bus
	Output_Module : process (CLK) is
	begin
		if (rising_edge(CLK)) then
			if (RESETN = '0') then
				tlast           <= '0';
				written_vectors <= 0;
				state <= Idle;
				M_AXIS_TVALID 	<= '0';
				
			else
			
				case state is
				
					when Idle =>
						
						tlast           <= '0';
						
						if (Full = '1') then
							
							state 			<= Write_Outputs;
							M_AXIS_TVALID 	<= '1';
							M_AXIS_TDATA    <= Output_Array (written_vectors);
							written_vectors <= written_vectors + 1;
						
						else 
						
							M_AXIS_TVALID 	<= '0';
							
						end if;
					
					when Write_Outputs =>
						
						if( M_AXIS_TREADY = '1') then 
							
							M_AXIS_TDATA    <= Output_Array (written_vectors);
							
							if (written_vectors = PACKET_SIZE - 1) then
								
								state 			<= Idle;
								tlast           <= '1';
								written_vectors <= 0;
							
							else
								
								tlast 			<= '0';
								written_vectors <= written_vectors + 1;
								
							end if;	
							
						end if;
					
				end case;
		
			end if;
		end if;


	end process Output_Module;
	
	

end architecture Behavioral;