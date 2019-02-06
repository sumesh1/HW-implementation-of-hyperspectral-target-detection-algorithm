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
library work;
use work.td_package.all;

entity CorrelationMatrix is
	generic (
		NUM_BANDS        : positive := 16;
		CORRELATION_DATA_WIDTH  : positive := 32
	);
	port (

		CLK              : in std_logic;
		RESETN           : in std_logic;
		WRITE_ENABLE 	 : in std_logic;
		COLUMN_NUMBER 	 : in std_logic_vector (integer(ceil(log2(real(NUM_BANDS))))-1 downto 0);
		COLUMN_IN		 : in CorrMatrixColumn;
		COLUMN_OUT	     : out CorrMatrixColumn
		
	);
end CorrelationMatrix;


---------------------------------------------------------------------------------	 
	-- ARCHITECTURE WITH REGISTERS
---------------------------------------------------------------------------------
architecture Registers of CorrelationMatrix is
	
	constant vectornumb: std_logic_vector (CORRELATION_DATA_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(500000000, CORRELATION_DATA_WIDTH));
	signal CORR_MATRIX : CorrMatrixType;

begin

	COLUMN_OUT <= CORR_MATRIX(COLUMN_NUMBER);
	

	process (CLK, RESETN)
	variable pixel_count: integer range 0 to NUM_BANDS := 0;
	begin
		if (rising_edge (CLK)) then
			if (RESETN = '0') then
				
				CORR_MATRIX <= (others => vectornumb);
				
			else
			
				if (WRITE_ENABLE = '1') then
		
					CORR_MATRIX(to_integer(unsigned(COLUMN_NUMBER))) <= COLUMN_IN;
				
				end if;
				
			
			end if;
		end if;

	end process;


end Registers;


---------------------------------------------------------------------------------	 
	-- ARCHITECTURE WITH BRAM
---------------------------------------------------------------------------------

-- architecture BRAM of CorrelationMatrix is

	-- signal CORR_MATRIX : CorrMatrixType := (others => (others => vectornumb));

-- begin


-- end BRAM;
