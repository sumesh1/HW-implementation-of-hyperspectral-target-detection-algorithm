----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.02.2019 19:31:11
-- Design Name: 
-- Module Name: ShermanMorrisonController_testbench - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ShermanMorrisonController_testbench is
--  Port ( );
end ShermanMorrisonController_testbench;

architecture Behavioral of ShermanMorrisonController_testbench is

constant NUM_BANDS : integer := 16;


signal	CLK             : std_logic;
signal	RESETN          : std_logic;
signal	S_AXIS_TLAST    : std_logic;
signal	S_AXIS_TVALID   : std_logic;
signal	S_AXIS_TREADY   : std_logic;
signal	STEP1_DONE      : std_logic;
signal	STEP2_DONE      : std_logic;
signal	STEP3_DONE      : std_logic;
signal	STEP1_ENABLE    : std_logic;
signal	STEP2_ENABLE    : std_logic;
signal	STEP3_ENABLE    : std_logic;

begin


instant: entity work.ShermanMorrisonController(Behavioral)
	generic map(
		NUM_BANDS => NUM_BANDS
		)
	port map(

	CLK          	=>	   	CLK             ,
	RESETN       	=>	   	RESETN          ,
	S_AXIS_TLAST 	=>	   	S_AXIS_TLAST    ,
	S_AXIS_TVALID	=>	   	S_AXIS_TVALID   ,
	S_AXIS_TREADY	=>	   	S_AXIS_TREADY   ,
	STEP1_DONE   	=>	   	STEP1_DONE      ,
	STEP2_DONE   	=>	   	STEP2_DONE      ,
	STEP3_DONE   	=>	   	STEP3_DONE      ,
	STEP1_ENABLE 	=>	   	STEP1_ENABLE    ,
	STEP2_ENABLE 	=>	   	STEP2_ENABLE    ,
	STEP3_ENABLE 	=>	   	STEP3_ENABLE 
	
	
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
	S_AXIS_TLAST  <= '0';
	
	wait;
	end process;
	
	process is
	begin
	
		STEP1_DONE  <= '0'; 
		STEP2_DONE  <= '0'; 	
		STEP3_DONE  <= '0';
		
		wait for 410 NS;
		
		STEP1_DONE <= '1';
		wait for 20 NS;
		STEP1_DONE <= '0';
		
		wait for 300 NS;
		STEP2_DONE <= '1';
		wait for 20 NS;
		STEP2_DONE <= '0';
	wait; 
	end process;
	


end Behavioral;
