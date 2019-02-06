----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.02.2019 14:14:45
-- Design Name: 
-- Module Name: ShermanMorrisonController - Behavioral
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


entity ShermanMorrisonController is
	generic (
		NUM_BANDS        : positive := 16
	);
	port (

		CLK              : in std_logic;
		RESETN           : in std_logic;
		S_AXIS_TLAST     : in std_logic;
		S_AXIS_TVALID    : in std_logic;
		S_AXIS_TREADY    : out std_logic
		
	);
end ShermanMorrisonController;

architecture Behavioral of ShermanMorrisonController is

	signal STEP1_ENABLE : std_logic;
	signal STEP2_ENABLE : std_logic;
	signal STEP3_ENABLE : std_logic;
	signal STEP1_DONE   : std_logic;
	signal STEP2_DONE   : std_logic;
	signal STEP3_DONE   : std_logic;

	type state_type is (Idle, Working);
	signal Step1_State: state_type;
	signal Step2_State: state_type;
	signal Step3_State: state_type;
	
	signal STOP_PIPELINE: std_logic;

begin


---------------------------------------------------------------------------------	 
	-- INPUT SLAVE CONTROL
---------------------------------------------------------------------------------

	S_AXIS_TREADY_temp <= '1';
	S_AXIS_TREADY <= S_AXIS_TREADY_temp;
	
	STOP_PIPELINE <= '0';
	
	
	STEP1_ENABLE  <= (S_AXIS_TREADY_temp and S_AXIS_TVALID) and not STOP_PIPELINE;
	
	STEP2_ENABLE  <= STEP1_DONE and not STOP_PIPELINE;
	
	STEP3_ENABLE  <= STEP2_DONE and not STOP_PIPELINE;
	
	
	
	
	
	
	
	-- step1: process (CLK, RESETN)
	-- begin
		-- if (rising_edge (CLK)) then
			-- if (RESETN = '0') then
				
				-- Step1_State <= Idle;
				
			-- else
	
				-- case Step1_State is
				
					-- when Idle =>
						
						-- if (
					
					-- when Working =>
					
					
				-- end case;

	
			
			-- end if;
		-- end if;

	-- end process step1;


	-- step2: process (CLK, RESETN)
	-- begin
		-- if (rising_edge (CLK)) then
			-- if (RESETN = '0') then
				
				-- Step2_State <= Idle;
				
			-- else
			
				-- case Step2_State is
				
					-- when Idle =>
					
					
					-- when Working =>
					
					
				-- end case;

	
			
			-- end if;
		-- end if;

	-- end process step2;
	
	-- step3: process (CLK, RESETN)
	-- begin
		-- if (rising_edge (CLK)) then
			-- if (RESETN = '0') then
				
				-- Step3_State <= Idle;
				
			-- else

				-- case Step3_State is
				
					-- when Idle =>
					
					
					-- when Working =>
					
					
				-- end case;
	
			
			-- end if;
		-- end if;

	-- end process step3;


end Behavioral;
