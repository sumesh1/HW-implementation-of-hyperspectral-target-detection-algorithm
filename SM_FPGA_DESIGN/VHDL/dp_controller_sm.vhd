----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Dordije Boskovic
-- 
-- Create Date: 
-- Design Name: 
-- Module Name: Dot product controller - Behavioral
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
use IEEE . STD_LOGIC_1164 . all;
use ieee . numeric_std . all;

entity dp_controller_sm is
	generic (
		V_LEN : integer := 16
	);
	port (
		clk     : in std_logic;
		en      : in std_logic;
		reset_n : in std_logic;
		p_rdy   : out std_logic;
		clear  : out std_logic
	);
end dp_controller_sm;

architecture Behavioral of dp_controller_sm is

	signal counter : integer range 0 to V_LEN + 2;
	signal out_rdy : std_logic;
	signal start_counter: std_logic;

begin

	out_rdy <= '1' when (counter = (V_LEN + 2)) else '0';
	clear   <= out_rdy;
	p_rdy   <= out_rdy;

	
	
	process (clk)
	begin
		if (rising_edge (clk)) then
			if (reset_n = '0') then
			
				counter <= 0;
			
			elsif (en = '1') then

				if (counter = (V_LEN + 2)) then
					counter <= 0;
				else
					counter <= counter + 1;
				end if;
			
			end if;
		end if;

	end process;

	
end Behavioral;