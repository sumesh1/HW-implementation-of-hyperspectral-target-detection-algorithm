----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Dordije Boskovic
-- 
-- Create Date: 14.10.2018 10:15:03
-- Design Name: 
-- Module Name: Stage1 - Behavioral
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

library IEEE ;
use IEEE.STD_LOGIC_1164.ALL ;
use ieee.numeric_std.all ;
use work.my_types_pkg.all;
-------------------------------------------------------------------------------------
-- Definition of Ports
-- CLK            : Synchronous clock
-- RESET_N        : System reset, active low
-- EN  			  : Data in is valid
-- IN_1  		  : Data in 1
-- IN_2   		  : Data in 2
-- V_LEN		  : Length of input array
-- P_RDY		  : Data out is valid
-- P		      : Data Out
-------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Entity Section
------------------------------------------------------------------------------

entity Accelerator_Stage1 is
	generic
	(
		PIXEL_DATA_WIDTH : positive := 16;
		BRAM_DATA_WIDTH : positive := 32;
		ST1OUT_DATA_WIDTH : positive :=50;
		NUM_BANDS : positive := 16
	);
	port 
	(	
		CLK	: in	std_logic;
		RESETN	: in	std_logic;
		Stage1_Enable	: in	std_logic;
		Stage1_DataIn	: in	std_logic_vector(PIXEL_DATA_WIDTH-1 downto 0);
		Stage1_DataValid	: out	std_logic;
		Stage1_DataOut    	: out	data_array (0 to NUM_BANDS-1)(ST1OUT_DATA_WIDTH-1 downto 0);
		Stage1_DataSROut : out std_logic_vector (ST1OUT_DATA_WIDTH-1 downto 0);
		CORR_MATRIX_COLUMN   : in 	data_array (0 to NUM_BANDS-1)(BRAM_DATA_WIDTH-1 downto 0);
		STATIC_VECTOR_SR	: in std_logic_vector (BRAM_DATA_WIDTH-1 downto 0)
		
	);

end Accelerator_Stage1;

------------------------------------------------------------------------------
-- Architecture Section
------------------------------------------------------------------------------

architecture Behavioral of Accelerator_Stage1 is
	
	
 component dp_controller is
	 Generic(
		V_LEN: integer := 16
	 );
	 Port (
		 clk    	: in std_logic ;
		 en     	: in std_logic ;
		 reset_n	: in std_logic ;
		 p_rdy  	: out std_logic ;
		 ripple 	: out std_logic
	 );
 end component ;
 
 component  dp_datapath is
	generic (
		bit_depth_1 : positive := 12;
		bit_depth_2 : positive := 32;
		P_BIT_WIDTH : positive := 48
	 );
	 Port (
		 clk 		: in std_logic ;
		 en 		: in std_logic ;
		 ripple 	: in std_logic;
		 reset_n 	: in std_logic ;
		 in_1 		: in std_logic_vector ( bit_depth_1 -1 downto 0);
		 in_2 		: in std_logic_vector ( bit_depth_2 -1 downto 0);
		 p 			: out std_logic_vector ( P_bit_width -1 downto 0)
	 );
 end component ;
	
 signal ripple: std_logic;
 
begin
---------------------------------------------------------------------------------	 
-- Dot product datapaths
----------------------------------------------------------------------------------	
 GEN_DP: for I in 0 to NUM_BANDS-1 generate
   begin
	dp_datapath_inst: dp_datapath
		generic map (
		bit_depth_1 => PIXEL_DATA_WIDTH,
		bit_depth_2 => BRAM_DATA_WIDTH,
		p_bit_width => ST1OUT_DATA_WIDTH
		 )
		 port map (
		clk          =>  CLK,
		en			 =>  Stage1_Enable,
		ripple		 =>  ripple,
		reset_n      =>	 RESETN,
		in_1         =>	 Stage1_DataIn,
		in_2 		 =>  CORR_MATRIX_COLUMN(I),
		p 			 =>  Stage1_DataOut(I)
		 );
 end generate GEN_DP;
 
 
---------------------------------------------------------------------------------	 
-- Dot product controller
----------------------------------------------------------------------------------	 

	dp_controller_inst: dp_controller
		generic map(
			V_LEN => NUM_BANDS
		)
		port map(
			clk      =>   CLK,    
			en       =>   Stage1_Enable,     
			reset_n  =>   RESETN,
			p_rdy    =>   Stage1_DataValid,  
			ripple   =>   ripple 
		);


------------------------------------------------------------------------------
--GENERATE STAGE 1 sTR^-1x DOT PRODUCT MODULE   
------------------------------------------------------------------------------
	 
	 dp_datapath_inst_SR: dp_datapath
		generic map (
		bit_depth_1 => PIXEL_DATA_WIDTH,
		bit_depth_2 => BRAM_DATA_WIDTH,
		p_bit_width => ST1OUT_DATA_WIDTH
		 )
		 port map (
		clk          =>  CLK,
		en			 =>  Stage1_Enable,
		ripple		 =>  ripple,
		reset_n      =>	 RESETN,
		in_1         =>	 Stage1_DataIn,
		in_2 		 =>  STATIC_VECTOR_SR,
		p 			 =>  Stage1_DataSROut
		 );
 

end Behavioral;