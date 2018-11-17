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

entity tbdot is
	--  Port ( );
end tbdot;

architecture Behavioral of tbdot is

	constant bit_depth_1 : integer := 32;
	constant bit_depth_2 : integer := 32;
	constant P_BIT_WIDTH : integer := 64;
	constant V_LEN		 : integer := 4;

	signal clk           : std_logic;
	signal en            : std_logic;
	signal reset_n        : std_logic;

	signal in_1          : std_logic_vector (bit_depth_1 - 1 downto 0);
	signal in_2          : std_logic_vector (bit_depth_2 - 1 downto 0);
	signal p_rdy         : std_logic;
	signal ripple        : std_logic;
	signal p             : std_logic_vector (P_bit_width - 1 downto 0);
	signal cnt           : integer;

begin

	dp_controller_INST: entity work.dp_controller
   generic map (
      V_LEN => V_LEN)
   port map (
      clk     => clk,
      en      => en,
      reset_n => reset_n,
      p_rdy   => p_rdy,
      ripple  => ripple);

	
	dp_datapath_INST: entity work.dp_datapath
   generic map (
      bit_depth_1 => bit_depth_1,
      bit_depth_2 => bit_depth_2,
      P_BIT_WIDTH => P_BIT_WIDTH)
   port map (
      clk     => clk,
      en      => en,
      ripple  => ripple,
      reset_n => reset_n,
      in_1    => in_1,
      in_2    => in_2,
      p       => p);



	
	
	
	process is
	begin
		reset_n <= '0';
		wait for 50 NS;
		reset_n <= '1';
		wait;
	end process;

	process is
	begin
		clk <= '0';
		wait for 10 NS;
		clk <= '1';
		wait for 10 NS;
	end process;

	process (CLK) is

	begin
		if (rising_edge(CLK)) then
			if (reset_n = '0') then
				en  <= '0';
				cnt <= 0;
			elsif (cnt < 5) then
				cnt <= cnt + 1;
				en  <= '0';
			elsif (cnt > 12 and cnt < 14) then
				cnt <= cnt + 1;
				en  <= '0';
			elsif (cnt > 16 and cnt < 20) then
				cnt <= cnt + 1;
				en  <= '0';

			else
				cnt <= cnt + 1;
				en  <= '1';
			end if;
		end if;
	end process;

	process is
	begin
		wait until CLK'event and CLK = '1';
		if (reset_n = '0') then
			in_1 <= std_logic_vector(to_unsigned(0, 32));
		elsif (en = '1') then
			in_1 <= std_logic_vector(unsigned(in_1) + 1);
		end if;

	end process;

	process is
	begin
		in_2 <= std_logic_vector(to_unsigned(1, bit_depth_2));
		-- wait for 5000 NS;
		-- in_G <=(others=>'1');
		-- wait for 1000 NS;
		-- in_G <=(others=>'0');
		wait;
	end process;


	
end architecture;