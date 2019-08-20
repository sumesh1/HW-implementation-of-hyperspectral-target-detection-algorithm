----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.02.2019 12:11:36
-- Design Name: 
-- Module Name: CorrelationMatrix - Behavioral
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

entity TempMatrix is
	generic (
		NUM_BANDS        : positive := 16;
		CORRELATION_DATA_WIDTH  : positive := 32
	);
	port (

		CLK              : in std_logic;
		RESETN           : in std_logic;
		WRITE_ENABLE 	 : in std_logic;
		COLUMN_NUMBER 	 : in std_logic_vector (integer(ceil(log2(real(NUM_BANDS))))-1 downto 0);
		COLUMN_NUMBER_W	 : in std_logic_vector (integer(ceil(log2(real(NUM_BANDS))))-1 downto 0);
		COLUMN_IN		 : in TempMatrixColumn;
		COLUMN_OUT	     : out TempMatrixColumn
		
	);
end TempMatrix;


---------------------------------------------------------------------------------	 
	-- ARCHITECTURE WITH REGISTERS
---------------------------------------------------------------------------------
architecture Registers of TempMatrix is
	
	constant vectornumb: std_logic_vector (CORRELATION_DATA_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(500000000, CORRELATION_DATA_WIDTH));
	signal CORR_MATRIX : TempMatrixType;

begin

	COLUMN_OUT <= CORR_MATRIX(to_integer(unsigned(COLUMN_NUMBER)));
	

	process (CLK)
	begin
		if (rising_edge (CLK)) then
			if (RESETN = '0') then
				
				CORR_MATRIX <= (others => (others => vectornumb));
				
			else
			
				if (WRITE_ENABLE = '1') then
		
					CORR_MATRIX(to_integer(unsigned(COLUMN_NUMBER_W))) <= COLUMN_IN;
				
				end if;
				
			
			end if;
		end if;

	end process;


end Registers;


---------------------------------------------------------------------------------	 
	-- ARCHITECTURE WITH BRAM
---------------------------------------------------------------------------------

architecture BRAM of TempMatrix is

	constant vectornumb: std_logic_vector (CORRELATION_DATA_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(500000000, CORRELATION_DATA_WIDTH));
	type ram_type is array (0 to NUM_BANDS - 1) of std_logic_vector (NUM_BANDS * CORRELATION_DATA_WIDTH - 1 downto 0);
	signal CORR_MATRIX : ram_type;

begin

	process (CLK)
	begin
		
		if rising_edge(CLK) then
			
				
				for i in 0 to NUM_BANDS - 1 loop
					
					COLUMN_OUT (i) <= CORR_MATRIX (to_integer(unsigned(COLUMN_NUMBER)))((i + 1) * CORRELATION_DATA_WIDTH - 1 downto i * CORRELATION_DATA_WIDTH);
				
				end loop;
					
				for i in 0 to NUM_BANDS - 1 loop
				
					if (WRITE_ENABLE = '1') then
					
						CORR_MATRIX (to_integer(unsigned(COLUMN_NUMBER_W)))((i + 1) * CORRELATION_DATA_WIDTH - 1 downto i * CORRELATION_DATA_WIDTH) <= COLUMN_IN (i);
					
					end if;
				
				end loop;
			
			
		end if;
		
	end process;


end BRAM;