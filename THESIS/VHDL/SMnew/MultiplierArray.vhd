----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.02.2019 12:11:36
-- Design Name: 
-- Module Name: Multipliers - Behavioral
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
library work;
use work.td_package.all;

entity MultiplierArray is
	generic (
		NUM_BANDS        : positive := 16;
		IN1_DATA_WIDTH   : positive := 32;
		IN2_DATA_WIDTH   : positive := 32;
		OUT_DATA_WIDTH   : positive := 32
	);
	port (

		CLK              : in std_logic;
		RESETN           : in std_logic;
		ENABLE 			 : in std_logic;
		IN1_COMPONENT	 : in std_logic_vector(IN1_DATA_WIDTH-1 downto 0);
		IN2_COLUMN		 : in CorrMatrixColumn;
		COLUMN_OUT	     : out CorrMatrixColumn;
		DATA_VALID	     : out std_logic
	
	);
end MultiplierArray;

architecture Behavioral of MultiplierArray is

	signal CLEAR : std_logic;

begin

---------------------------------------------------------------------------------	 
	-- product datapath
---------------------------------------------------------------------------------	

	GEN_MULT : for I in 0 to NUM_BANDS - 1 generate
	begin
		mult_datapath_inst : entity work.mult_datapath(Behavioral)
		generic map(
			bit_depth_1 => IN1_DATA_WIDTH,
			bit_depth_2 => IN2_DATA_WIDTH,
			p_bit_width => OUT_DATA_WIDTH
		)
		port map(
			clk     => CLK,
			en      => ENABLE,
			clear   => CLEAR,
			reset_n => RESETN,
			in_1    => IN1_COMPONENT,
			in_2    => IN2_COLUMN(I),
			p       => COLUMN_OUT(I)
		);
	end generate GEN_MULT;
	
	
	
---------------------------------------------------------------------------------	 
	-- product controller
---------------------------------------------------------------------------------	
	
	mult_controller_inst :  entity work.mult_controller(Behavioral)
	generic map(
		PIPELINE_DEPTH => 2
	)
	port map(
		clk     => CLK,
		en      => ENABLE,
		reset_n => RESETN,
		clear   => CLEAR,
		p_rdy   => DATA_VALID
	);	



end Behavioral;
