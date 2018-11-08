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
	
	component dot_product is
generic (
	bit_depth_1 : positive := 12;
	bit_depth_2 : positive := 32;
	p_bit_width : positive := 48
 );
 Port (
 clk : in std_logic ;
 en : in std_logic ;
 reset_n : in std_logic ;
 in_1 : in std_logic_vector ( bit_depth_1 -1 downto 0);
 in_2 : in std_logic_vector ( bit_depth_2 -1 downto 0);
 v_len : in std_logic_vector (11 downto 0);
 p_rdy : out std_logic ;
 p : out std_logic_vector ( p_bit_width -1 downto 0)
 );
 end component; 
		
 signal Stage1_Ready: std_logic_vector(NUM_BANDS downto 0);
 constant all_ones: std_logic_vector(NUM_BANDS downto 0) := (others => '1'); 
begin
---------------------------------------------------------------------------------	 
-- Dot product datapaths
----------------------------------------------------------------------------------	
 GEN_DP: for I in 0 to NUM_BANDS-1 generate
   begin
	datapath_MAC_inst: dot_product
		generic map (
		bit_depth_1 => PIXEL_DATA_WIDTH,
		bit_depth_2 => BRAM_DATA_WIDTH,
		p_bit_width => ST1OUT_DATA_WIDTH
		 )
		 port map (
		clk          =>  CLK,
		en			 =>  Stage1_Enable,
		reset_n      =>	 RESETN,
		in_1         =>	 Stage1_DataIn,
		in_2 		 =>  CORR_MATRIX_COLUMN(I),
		v_len		 =>  std_logic_vector(to_unsigned(NUM_BANDS,12)),
		p_rdy		 =>  Stage1_Ready(I),
		p 			 =>  Stage1_DataOut(I)
		 );
 end generate GEN_DP;
 
 
 Stage1_DataValid <= '1' when (Stage1_Ready = all_ones) else '0';
 


------------------------------------------------------------------------------
--GENERATE STAGE 1 sTR^-1x DOT PRODUCT MODULE   
------------------------------------------------------------------------------


 datapath_MAC_inst_sR: dot_product
	generic map (
		bit_depth_1 => PIXEL_DATA_WIDTH,
		bit_depth_2 => BRAM_DATA_WIDTH,
		p_bit_width => ST1OUT_DATA_WIDTH
	 )
	 port map (
		clk          =>  CLK,
		en 			 =>  Stage1_Enable,
		reset_n      =>	 RESETN,
		in_1         =>	 Stage1_DataIn,
		in_2 		 =>  STATIC_VECTOR_SR,
		v_len 		 =>  std_logic_vector(to_unsigned(NUM_BANDS,12)),
		p_rdy		 =>  Stage1_Ready (NUM_BANDS),
		p 			 =>  Stage1_DataSROut
	 );

	

-- stage2_out_data_static <= std_logic_vector ( signed ( stage2_in_data_static )* signed ( stage2_in_data_static ));
 
 

end Behavioral;