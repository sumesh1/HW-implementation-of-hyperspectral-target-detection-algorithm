library IEEE;
use IEEE . STD_LOGIC_1164 . all;
use ieee . numeric_std . all;

package my_types_pkg is
	
	type data_array_st1 is array (0 to 16 - 1) of std_logic_vector(52 - 1 downto 0);
	type data_array_st1r is array (0 to 16 - 1) of std_logic_vector(32 - 1 downto 0);
	type data_array_bram is array (0 to 16 - 1) of std_logic_vector(32 - 1 downto 0);
	
end package;