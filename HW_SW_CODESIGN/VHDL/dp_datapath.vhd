----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Dordije Boskovic
-- 
-- Create Date: 
-- Design Name: 
-- Module Name: Dot product datapath - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: MAC unit
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

entity dp_datapath is
	generic (
		bit_depth_1 : positive := 16;
		bit_depth_2 : positive := 32;
		P_BIT_WIDTH : positive := 52
	);
	port (
		clk     : in std_logic;
		en      : in std_logic;
		ripple  : in std_logic;
		reset_n : in std_logic;
		in_1    : in std_logic_vector (bit_depth_1 - 1 downto 0);
		in_2    : in std_logic_vector (bit_depth_2 - 1 downto 0);
		p       : out std_logic_vector (P_bit_width - 1 downto 0)
	);
end dp_datapath;

architecture Behavioral of dp_datapath is

	signal mul_r 	: std_logic_vector ((bit_depth_1 + bit_depth_2 - 1) downto 0);
	signal add_r 	: std_logic_vector ((P_BIT_WIDTH - 1) downto 0);
	signal in_1_reg	: std_logic_vector (bit_depth_1 - 1 downto 0);
	signal in_2_reg	: std_logic_vector (bit_depth_2 - 1 downto 0);
	
begin

	p <= add_r;

	process (clk)
	begin
		if (rising_edge (clk)) then
			if (reset_n = '0') then
				
				mul_r 		<= (others => '0');
				add_r 		<= (others => '0');
				in_1_reg	<= (others => '0');
				in_2_reg	<= (others => '0');	
				
			elsif (en = '1') then
				
				--First pipeline stage regs
				in_1_reg <= in_1;
				in_2_reg <= in_2;
				
				-- Multiply in1 and in2
				mul_r <= std_logic_vector (signed (in_1_reg) * signed (in_2_reg));
				
				if (ripple = '1') then
					-- Ripple multiplication register data to accumulator 
					add_r <= std_logic_vector (resize(signed (mul_r), add_r'length));
				
				else
					-- Acculumate result
					add_r <= std_logic_vector (signed (mul_r) + signed (add_r));
				
				end if;
				
			end if;
		end if;

	end process;
end Behavioral;