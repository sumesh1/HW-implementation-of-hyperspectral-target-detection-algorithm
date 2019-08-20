----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01.06.2019 12:11:36
-- Design Name: 
-- Module Name: ShiftRegisterPixel - Behavioral
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

entity ShiftRegisterPixel is
	generic (
		DELAY        : positive := 16;
		NUM_BANDS    :positive := 16;
		PIXEL_DATA_WIDTH  : positive := 16
	);
	port (

		CLK              : in std_logic;
		RESETN           : in std_logic;
		WRITE_ENABLE 	 : in std_logic;
		COMPONENT_NUMBER : in std_logic_vector (7-1 downto 0);
		COMPONENT_IN     : in std_logic_vector(PIXEL_DATA_WIDTH-1 downto 0);
		COMPONENT_OUT	 : out std_logic_vector(PIXEL_DATA_WIDTH-1 downto 0)
		
	);
end ShiftRegisterPixel;



---------------------------------------------------------------------------------	 
	-- ARCHITECTURE
---------------------------------------------------------------------------------

architecture arh of ShiftRegisterPixel is


	type PixVectType is array (0 to DELAY-1) of std_logic_vector(PIXEL_DATA_WIDTH-1 downto 0);
	signal PIXEL_VECTOR : PixVectType;

begin



				COMPONENT_OUT <= PIXEL_VECTOR (DELAY - 1 - to_integer(unsigned(COMPONENT_NUMBER)));
	process (CLK)
	begin
		
		if rising_edge(CLK) then
			
		
				--COMPONENT_OUT <= PIXEL_VECTOR (DELAY - 1 - to_integer(unsigned(COMPONENT_NUMBER)));
			
				if (WRITE_ENABLE = '1') then
				
					PIXEL_VECTOR <= COMPONENT_IN & PIXEL_VECTOR (0 to DELAY-2);
				
				end if;
				
		end if;
		
	end process;


end arh;

