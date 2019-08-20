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
use IEEE.math_real.all;
use ieee.numeric_std.all;
library work;
use work.td_package.all;

entity DotProductArray is
	generic (
		NUM_BANDS        : positive := 16;
		IN1_DATA_WIDTH   : positive := 16;
		IN2_DATA_WIDTH   : positive := 32;
		OUT_DATA_WIDTH   : positive := 32;
		DP_DATA_SLIDER   : positive := 60
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
end DotProductArray;

architecture Behavioral of DotProductArray is

	constant ACCUMULATOR_WIDTH: positive :=  (integer(ceil(log2(real(NUM_BANDS)))) + IN1_DATA_WIDTH + IN2_DATA_WIDTH );
	
	type DataOutType is array (0 to NUM_BANDS-1) of std_logic_vector(ACCUMULATOR_WIDTH-1 downto 0);
	
	signal DATA_OUT: DataOutType;
	signal DATA_CALCULATED: std_logic;
	signal CLEAR: std_logic;

begin


---------------------------------------------------------------------------------	 
	-- Dot product datapaths
---------------------------------------------------------------------------------
	GEN_DP : for I in 0 to NUM_BANDS - 1 generate
	begin
		dp_datapath_sm_inst : entity work.dp_datapath_sm(Behavioral)
		generic map(
			bit_depth_1 => IN1_DATA_WIDTH,
			bit_depth_2 => IN2_DATA_WIDTH,
			p_bit_width => ACCUMULATOR_WIDTH
		)
		port map(
			clk     => CLK,
			en      => ENABLE,
			clear   => CLEAR,
			reset_n => RESETN,
			in_1    => IN1_COMPONENT,
			in_2    => IN2_COLUMN(I),
			p       => DATA_OUT(I)
		);
	end generate GEN_DP;
	
	
---------------------------------------------------------------------------------	 
	-- Dot product controller
---------------------------------------------------------------------------------	 

	dp_controller_sm_inst : entity work.dp_controller_sm(Behavioral)
	generic map(
		V_LEN => NUM_BANDS
	)
	port map(
		clk     => CLK,
		en      => ENABLE,
		reset_n => RESETN,
		p_rdy   => DATA_CALCULATED,
		clear   => CLEAR
	);
	
	
---------------------------------------------------------------------------------	 
	-- DATA OUT
---------------------------------------------------------------------------------		
	
	process (CLK)
	begin
		if (rising_edge (CLK)) then
			if (RESETN = '0') then
				
				COLUMN_OUT <= (others => (others => '0'));
				DATA_VALID <= '0';
				
			else
	
				DATA_VALID <= DATA_CALCULATED;
	
				if( DATA_CALCULATED = '1') then
				
				
					for i in 0 to NUM_BANDS-1 loop
						--COLUMN_OUT(i) <= DATA_OUT(i)(ACCUMULATOR_WIDTH-1  downto ACCUMULATOR_WIDTH-OUT_DATA_WIDTH);
						--COLUMN_OUT(i) <= DATA_OUT(i)(60  downto 13);
						COLUMN_OUT(i) <= DATA_OUT(i)(DP_DATA_SLIDER  downto DP_DATA_SLIDER - OUT_DATA_WIDTH + 1);
					end loop;
					
				end if;
	
			
			end if;
		end if;

	end process;


end Behavioral;
