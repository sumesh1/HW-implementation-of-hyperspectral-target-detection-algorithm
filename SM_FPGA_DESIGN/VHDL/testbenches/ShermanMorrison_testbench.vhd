----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01.02.2019 16:51:40
-- Design Name: 
-- Module Name: ShermanMorrison_testbench - Behavioral
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
use IEEE.NUMERIC_STD.ALL;



entity ShermanMorrison_testbench is

end ShermanMorrison_testbench;

architecture Behavioral of ShermanMorrison_testbench is

	constant PIXEL_DATA_WIDTH : positive := 16;
	constant CORRELATION_DATA_WIDTH : positive := 32;
	constant NUM_BANDS        : positive := 16;
	constant OUT_DATA_WIDTH   : positive := 32;

	signal CLK                : std_logic;
	signal RESETN             : std_logic;
	signal S_AXIS_TREADY      : std_logic;
	signal S_AXIS_TDATA       : std_logic_vector(PIXEL_DATA_WIDTH - 1 downto 0);
	signal S_AXIS_TLAST       : std_logic;
	signal S_AXIS_TVALID      : std_logic;

	signal M_AXIS_TVALID     : std_logic;
	signal M_AXIS_TDATA      : std_logic_vector(OUT_DATA_WIDTH - 1 downto 0);
	signal M_AXIS_TLAST      : std_logic;
	signal M_AXIS_TREADY     : std_logic;

begin


SMInstance : entity WORK.ShermanMorrison(Behavioral)
		generic map(
			PIXEL_DATA_WIDTH => PIXEL_DATA_WIDTH,
			OUT_DATA_WIDTH   => OUT_DATA_WIDTH,
			CORRELATION_DATA_WIDTH  => CORRELATION_DATA_WIDTH,
			NUM_BANDS        => NUM_BANDS
		)
		port map
		(

			CLK              => CLK,
			RESETN           => RESETN,
			S_AXIS_TREADY    => S_AXIS_TREADY,
			S_AXIS_TDATA     => S_AXIS_TDATA,
			S_AXIS_TLAST     => S_AXIS_TLAST,
			S_AXIS_TVALID    => S_AXIS_TVALID,
			M_AXIS_TVALID   => M_AXIS_TVALID,
			M_AXIS_TDATA    => M_AXIS_TDATA,
			M_AXIS_TLAST    => M_AXIS_TLAST,
			M_AXIS_TREADY   => M_AXIS_TREADY
		);


	process is
	begin
		RESETN <= '1';
		wait for 1 NS;
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
	
	process is
	begin
	
	S_AXIS_TVALID <= '1';
	M_AXIS_TREADY <= '1';
	S_AXIS_TLAST  <= '0';
	
	wait;
	end process;
	
	process is
	begin
		wait until CLK'event and CLK = '1';
		if (RESETN = '0') then
			S_AXIS_TDATA <= std_logic_vector(to_unsigned(25000, PIXEL_DATA_WIDTH));
		elsif (S_AXIS_TVALID = '1') then
			S_AXIS_TDATA <= std_logic_vector(unsigned(S_AXIS_TDATA) + 10);
		end if;

	end process;
	
	
	
	


end Behavioral;
