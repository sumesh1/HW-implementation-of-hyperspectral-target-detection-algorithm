----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.02.2019 13:30:23
-- Design Name: 
-- Module Name: ShermanMorrisonTopLevel - Behavioral
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
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.math_real.all;
library work;
use work.td_package.all;


entity ShermanMorrisonTopLevel is
	generic (
		NUM_BANDS        : positive := 16;
		PIXEL_DATA_WIDTH : positive := 16;
		CORRELATION_DATA_WIDTH  : positive := 32;
		OUT_DATA_WIDTH   : positive := 32
	);
	port (

		CLK              : in std_logic;
		RESETN           : in std_logic;
		S_AXIS_TREADY    : out std_logic;
		S_AXIS_TDATA     : in std_logic_vector(PIXEL_DATA_WIDTH - 1 downto 0);
		S_AXIS_TLAST     : in std_logic;
		S_AXIS_TVALID    : in std_logic
		
	);
end ShermanMorrisonTopLevel;

architecture Behavioral of ShermanMorrisonTopLevel is



begin
---------------------------------------------------------------------------------	 
	-- INSTANCES
---------------------------------------------------------------------------------

	CorrMatrixInst: entity work.CorrelationMatrix(Registers)
		generic map (
			NUM_BANDS                 =>  NUM_BANDS,    
			CORRELATION_DATA_WIDTH    =>  CORRELATION_DATA_WIDTH
		)
		port map (
			CLK              =>   CLK,           
			RESETN           =>   RESETN,        
			WRITE_ENABLE 	 =>   WRITE_ENABLE, 
			COLUMN_NUMBER 	 =>   COLUMN_NUMBER, 
			COLUMN_IN		 =>   COLUMN_IN,	
			COLUMN_OUT	     =>   COLUMN_OUT	  
		);
		
	DotProductArrayInst: entity work.DotProductArray(Behavioral)
		generic map (
			NUM_BANDS       =>  NUM_BANDS,    
			IN1_DATA_WIDTH  =>  PIXEL_DATA_WIDTH,
			IN2_DATA_WIDTH  =>  CORRELATION_DATA_WIDTH,
			OUT_DATA_WIDTH  =>  CORRELATION_DATA_WIDTH
		)
		port map (
			CLK              =>   CLK,           
			RESETN           =>   RESETN,        
			ENABLE 		     =>   STEP1_ENABLE, 
			IN1_COMPONENT	 =>   PIXEL_COMPONENT, 
			IN2_COLUMN		 =>   COLUMN_OUT,	
			COLUMN_OUT	     =>   STEP1_DOTPROD,	  
			DATA_VALID	     =>	  STEP1_DATA_VALID
		);
		
		
	TempMatrixInst: entity work.CorrelationMatrix(Registers)
		generic map (
			NUM_BANDS                 =>  NUM_BANDS,    
			CORRELATION_DATA_WIDTH    =>  CORRELATION_DATA_WIDTH
		)
		port map (
			CLK              =>   CLK,           
			RESETN           =>   RESETN,        
			WRITE_ENABLE 	 =>   WRITE_ENABLE, 
			COLUMN_NUMBER 	 =>   COLUMN_NUMBER, 
			COLUMN_IN		 =>   COLUMN_IN,	
			COLUMN_OUT	     =>   COLUMN_OUT	  	
		);
		
	MultiplierArrayInst: entity work.MultiplierArray(Behavioral)
		generic map (
			NUM_BANDS       =>  NUM_BANDS,    
			IN1_DATA_WIDTH  =>  CORRELATION_DATA_WIDTH,
			IN2_DATA_WIDTH  =>  CORRELATION_DATA_WIDTH,
			OUT_DATA_WIDTH  =>  CORRELATION_DATA_WIDTH
		)
		port map (
			CLK              =>   CLK,           
			RESETN           =>   RESETN,        
			ENABLE 		     =>   ENABLE, 
			IN1_COMPONENT	 =>   PIXEL_COMPONENT, 
			IN2_COLUMN		 =>   COLUMN_OUT,	
			COLUMN_OUT	     =>   STEP2_DOTPROD,	  
			DATA_VALID	     =>	  STEP2_DATA_VALID
		);
		
		
		
		
	



end Behavioral;
