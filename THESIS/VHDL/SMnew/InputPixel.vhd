----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.02.2019 12:11:36
-- Design Name: 
-- Module Name: InputPixel - Behavioral
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

entity InputPixel is
	generic (
		NUM_BANDS        : positive := 16;
		PIXEL_DATA_WIDTH  : positive := 16
	);
	port (

		CLK              : in std_logic;
		RESETN           : in std_logic;
		WRITE_ENABLE 	 : in std_logic;
		COMPONENT_NUMBER 	 : in std_logic_vector (integer(ceil(log2(real(NUM_BANDS))))-1 downto 0);
		COMPONENT_IN		 : in std_logic_vector(PIXEL_DATA_WIDTH-1 downto 0);
		COMPONENT_OUT	     : out std_logic_vector(PIXEL_DATA_WIDTH-1 downto 0)
		
	);
end InputPixel;


---------------------------------------------------------------------------------	 
	-- ARCHITECTURE WITH REGISTERS
---------------------------------------------------------------------------------
architecture Registers of InputPixel is
	
	type PixVectType is array (0 to NUM_BANDS-1) of std_logic_vector(PIXEL_DATA_WIDTH-1 downto 0);
	signal PIXEL_VECTOR : PixVectType;

begin

	COMPONENT_OUT <= PIXEL_VECTOR(to_integer(unsigned(COMPONENT_NUMBER)));
	

	process (CLK, RESETN)
	begin
		if (rising_edge (CLK)) then
			if (RESETN = '0') then
				
				PIXEL_VECTOR <= (others => (others => '0'));
				
			else
			
				if (WRITE_ENABLE = '1') then
		
					PIXEL_VECTOR(to_integer(unsigned(COMPONENT_NUMBER))) <= COMPONENT_IN;
				
				end if;
				
			
			end if;
		end if;

	end process;


end Registers;


---------------------------------------------------------------------------------	 
	-- ARCHITECTURE WITH BRAM
---------------------------------------------------------------------------------

architecture BRAM of InputPixel is


	type PixVectType is array (0 to NUM_BANDS-1) of std_logic_vector(PIXEL_DATA_WIDTH-1 downto 0);
	signal PIXEL_VECTOR : PixVectType;

begin

	process (CLK)
	begin
		
		if rising_edge(CLK) then
			
				
				COMPONENT_OUT (i) <= PIXEL_VECTOR (to_integer(unsigned(COMPONENT_NUMBER)));
				
				
			for i in 0 to NUM_BANDS - 1 loop
			
				if (WRITE_ENABLE = '1') then
				
					PIXEL_VECTOR (to_integer(unsigned(COLUMN_NUMBER))) <= COMPONENT_IN(i);
				
				end if;
			
			end loop;
				
		end if;
		
	end process;


end BRAM;

