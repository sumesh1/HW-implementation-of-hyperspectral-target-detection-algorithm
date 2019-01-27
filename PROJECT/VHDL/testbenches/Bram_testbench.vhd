----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 30.09.2018 16:04:26
-- Design Name: 
-- Module Name: tbdot - Behavioral
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
use IEEE.STD_LOGIC_1164.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Bram_testbench is
	--  Port ( );
end Bram_testbench;

architecture Behavioral of Bram_testbench is

constant SIZE       : integer := 4;
constant ADDR_WIDTH : integer := 2;
constant COL_WIDTH  : integer := 32;
constant NB_COL     : integer := 4;

signal   clk        : std_logic;
signal   we         : std_logic_vector(NB_COL - 1 downto 0) := (others => '0');
signal   r_addr     : std_logic_vector(ADDR_WIDTH - 1 downto 0) := (others => '0');
signal   w_addr     : std_logic_vector(ADDR_WIDTH - 1 downto 0) := (others => '0');
signal   din        : std_logic_vector(COL_WIDTH - 1 downto 0) := (others => '0');
signal   dout       : std_logic_vector (NB_COL * COL_WIDTH - 1 downto 0);

type 	 unpacked is array  (NB_COL - 1 downto 0) of std_logic_vector ( COL_WIDTH - 1 downto 0);
signal	 dout_unpacked : unpacked;


signal   we_last         : std_logic_vector(NB_COL - 1 downto 0) := (others => '0');
	
begin

	
BRAM_INST: entity work.BRAM
   generic map (
      SIZE       => SIZE,
      ADDR_WIDTH => ADDR_WIDTH,
      COL_WIDTH  => COL_WIDTH,
      NB_COL     => NB_COL)
   port map (
      clk    => clk,
      we     => we,
      r_addr => r_addr,
      w_addr => w_addr,
      din    => din,
      dout   => dout);
	

	process is
	begin
		clk <= '0';
		wait for 10 NS;
		clk <= '1';
		wait for 10 NS;
	end process;

--writing
	process (CLK) is
	variable i: integer := 0;
	begin
		
		if(rising_edge(CLK)) then
		
		
			--writing
			if ( i < SIZE * NB_COL) then
				
				din 	<= std_logic_vector (unsigned(din) + 1);
				
				if (i = 0) then
					we      <= std_logic_vector(to_unsigned(1, we'length));
					we_last <= std_logic_vector(to_unsigned(1, we'length));
				elsif (i mod NB_COL = 0) then
					w_addr  <= std_logic_vector(unsigned(w_addr) + 1);
					we      <= std_logic_vector(to_unsigned(1, we'length));
					we_last <= std_logic_vector(to_unsigned(1, we'length));
				else
					we      <= std_logic_vector(unsigned(we_last) sll 1);
					we_last <= std_logic_vector(unsigned(we_last) sll 1);
				end if;
				
				i := i + 1;
				
			end if;
			
			--reading
			if(i = 16) then
			
				r_addr  <= std_logic_vector(unsigned(r_addr) + 1);
		
			end if;
			
			

		end if;
	end process;

repack : for i in 0 to NB_COL - 1 generate
	dout_unpacked (i) <= dout((i+1)* (COL_WIDTH)  -1 downto i* COL_WIDTH );
end generate;


	
end architecture;