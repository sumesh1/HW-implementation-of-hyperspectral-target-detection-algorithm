----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 30.09.2018 16:04:26
-- Design Name: 
-- Module Name: MasterOutput_tb - Behavioral
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

entity MasterOutput_tb is
	--  Port ( );
end MasterOutput_tb;

architecture Behavioral of MasterOutput_tb is

constant DATA_WIDTH    : positive := 32;
constant PACKET_SIZE   : positive := 4;
signal   CLK           : std_logic;
signal   RESETN        : std_logic;
signal   DATA_IN       : std_logic_vector(DATA_WIDTH - 1 downto 0);
signal   DATA_IN_VALID : std_logic;
signal   M_AXIS_TVALID : std_logic;
signal   M_AXIS_TDATA  : std_logic_vector(DATA_WIDTH - 1 downto 0);
signal   M_AXIS_TLAST  : std_logic;
signal   M_AXIS_TREADY : std_logic;
signal   STOP_PIPELINE : std_logic;

signal cnt : integer;
	
begin

MasterOutput_INST: entity work.MasterOutput
   generic map (
      DATA_WIDTH  => DATA_WIDTH,
      PACKET_SIZE => PACKET_SIZE)
   port map (
      CLK           => CLK,
      RESETN        => RESETN,
      DATA_IN       => DATA_IN,
      DATA_IN_VALID => DATA_IN_VALID,
      M_AXIS_TVALID => M_AXIS_TVALID,
      M_AXIS_TDATA  => M_AXIS_TDATA,
      M_AXIS_TLAST  => M_AXIS_TLAST,
      M_AXIS_TREADY => M_AXIS_TREADY,
      STOP_PIPELINE => STOP_PIPELINE);


	process is
	begin
		RESETN <= '0';
		wait for 50 NS;
		RESETN <= '1';
		wait;
	end process;

	process is
	begin
		 CLK <= '0';
		wait for 10 NS;
		 CLK <= '1';
		wait for 10 NS;
	end process;
		
	
	process (CLK) is

	begin
	
		if (rising_edge(CLK)) then
		
			if (resetn = '0') then
			
				DATA_IN_VALID  <= '0';
				cnt <= 0;
				
			elsif (cnt < 5) then
			
				cnt <= cnt + 1;
				DATA_IN_VALID  <= '0';
				
				
			elsif (cnt > 12 and cnt < 40) then
				cnt <= cnt + 1;
				DATA_IN_VALID  <= '1';
				
			elsif (cnt >= 40 and cnt < 45) then
			
				cnt <= cnt + 1;
				DATA_IN_VALID  <= '0';

			else
			
				cnt <= cnt + 1;
				DATA_IN_VALID  <= '1';
				
			end if;
			
		end if;
		
	end process;

	process is
	begin
	
		wait until CLK'event and CLK = '1';
		
		if (RESETN = '0') then
		
			DATA_IN <= std_logic_vector(to_unsigned(0, 32));
			
		elsif (DATA_IN_VALID = '1' and STOP_PIPELINE = '0') then
		
			DATA_IN <= std_logic_vector(unsigned(DATA_IN) + 1);
			
		end if;

	end process;
	


	process is
	begin
	
	M_AXIS_TREADY <= '0';
	
	wait for 300 NS;
	
	M_AXIS_TREADY <= '1';
	
	wait for 300 NS;
	
	M_AXIS_TREADY <= '0';
	
	wait for 100 NS;
	
	M_AXIS_TREADY <= '1';
	
	wait;
	end process;

	
	
end architecture;