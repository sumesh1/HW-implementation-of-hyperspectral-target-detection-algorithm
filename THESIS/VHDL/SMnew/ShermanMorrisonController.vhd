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
		S_AXIS_TREADY    : out std_logic;
		STEP1_DONE   	 : in std_logic;
		STEP2_DONE   	 : in std_logic;
		STEP3_DONE   	 : in std_logic;
		STEP1_ENABLE 	 : out std_logic;
		STEP2_ENABLE     : out std_logic;
		STEP3_ENABLE     : out std_logic
		
		
		
	);
end ShermanMorrisonController;

architecture Behavioral of ShermanMorrisonController is

	
	signal STEP1_ENABLE_temp : std_logic;
	signal STEP2_ENABLE_temp : std_logic;
	signal STEP3_ENABLE_temp : std_logic;

	type state_type is (Idle,Step1,Step2,Step3);
	signal State: state_type;
	
	signal STOP_PIPELINE: std_logic;
	signal S_AXIS_TREADY_temp: std_logic;
	
begin


---------------------------------------------------------------------------------	 
	-- CONTROL LOGIC
---------------------------------------------------------------------------------		
		
	S_AXIS_TREADY <= S_AXIS_TREADY_temp;
	COMPONENT_WRITE_ENABLE <= S_AXIS_TREADY_temp and S_AXIS_TVALID;	
	TEMP_COLUMN_IN <= STEP2_PROD;
	TEMP_WRITE_ENABLE <= STEP2_DATA_VALID;
	COLUMN_WRITE_ENABLE <= STEP3_DATA_VALID;
	
	
	process (COLUMN_OUT,STEP3_PROD) 
	begin
	
		for i in 0 to NUM_BANDS-1 loop
		
			COLUMN_IN(i) <= std_logic_vector(signed(COLUMN_OUT(i)) - signed(STEP3_PROD(i)));
		
		end loop;
	
	end process;
	
	states: process (CLK, RESETN)
	variable counter: integer range 0 to NUM_BANDS + 3;
	begin
		if (rising_edge (CLK)) then
			if (RESETN = '0') then
				
				state <= Idle;
				counter := 0;
				COMPONENT_NUMBER <= (others => '0');
				COLUMN_NUMBER    <= (others => '0');
				STEP2_INPUT      <= (others => '0');
				STEP3_INPUT      <= (others => '0');
				
			else
		
				case state is
				
					when Idle =>
					
						if((S_AXIS_TREADY_temp and S_AXIS_TVALID) = '1') then
							
							state <= WriteVector;
							counter := counter + 1;
							COMPONENT_NUMBER <= std_logic_vector(to_unsigned(counter,COMPONENT_NUMBER'length));
							
						end if;	
					
					
					when WriteVector =>
					
						if (counter = NUM_BANDS - 1) then
							counter  := 0;
							state <= Step1;
						else
							counter := counter + 1;
						end if;
						
						COMPONENT_NUMBER <= std_logic_vector(to_unsigned(counter,COMPONENT_NUMBER'length));
					
					when Step1 =>
					
						if (counter = NUM_BANDS + 2) then
							counter := 0;
							state <= Step1Wait;
							COMPONENT_NUMBER <= std_logic_vector(to_unsigned(counter,COMPONENT_NUMBER'length));
							COLUMN_NUMBER    <= std_logic_vector(to_unsigned(counter,COMPONENT_NUMBER'length));
						
						elsif( counter >= NUM_BANDS - 1) then 
							
							counter := counter + 1;
							COMPONENT_NUMBER <= (others => '0');
							COLUMN_NUMBER    <= (others => '0');
							
						else
							counter := counter + 1;
							COMPONENT_NUMBER <= std_logic_vector(to_unsigned(counter,COMPONENT_NUMBER'length));
							COLUMN_NUMBER    <= std_logic_vector(to_unsigned(counter,COMPONENT_NUMBER'length));
						end if;
						
					when Step1Wait => 	
					
						state <= Step2;
						STEP2_INPUT <= STEP1_DOTPROD (counter);
						
					when Step2 =>
					
						if(counter = NUM_BANDS + 1) then
					
							counter := 0; 
							state <= Step2Wait;

						elsif( counter >= NUM_BANDS - 1) then 
						
							counter := counter + 1;
						
						else
						
							counter := counter + 1;
							STEP2_INPUT <= STEP1_DOTPROD (counter);
							
						end if;	
						
					when Step2Wait => 

						state <= Step3;
						STEP3_INPUT <= vectornumb;
						
					when Step3 => 

						if (counter >= NUM_BANDS - 1) then
							counter := 0;
							state <= Idle;
							COLUMN_NUMBER    <= std_logic_vector(to_unsigned(counter,COMPONENT_NUMBER'length));
						
						elsif ( STEP3_DATA_VALID = '1') then 
							
							counter := counter + 1;
							COLUMN_NUMBER    <= std_logic_vector(to_unsigned(counter,COMPONENT_NUMBER'length));
						
						else 
						
							counter := 0;
							COLUMN_NUMBER    <= std_logic_vector(to_unsigned(counter,COMPONENT_NUMBER'length));
						
						end if;

						
					when others =>
					
						state <= Idle;
					
					
				end case;	
		
		
		
			end if;
		end if;

	end process states; 
	
	
	comb_proc: process(state)
    begin
        case state is
           

		    when Idle =>
			
				S_AXIS_TREADY_temp <= '1';
				STEP1_ENABLE <= '0';
				STEP2_ENABLE <= '0';
				STEP3_ENABLE <= '0';
			
			when WriteVector => 
			
				S_AXIS_TREADY_temp <= '1';
				STEP1_ENABLE <= '0';
				STEP2_ENABLE <= '0';
				STEP3_ENABLE <= '0';
			
			when Step1 =>
			
				S_AXIS_TREADY_temp <= '0';
				STEP1_ENABLE <= '1';
				STEP2_ENABLE <= '0';
				STEP3_ENABLE <= '0';
				
			when Step1Wait =>
			
				S_AXIS_TREADY_temp <= '0';
				STEP1_ENABLE <= '0';
				STEP2_ENABLE <= '0';
				STEP3_ENABLE <= '0';
			
			when Step2 =>
			
				S_AXIS_TREADY_temp <= '0';
				STEP1_ENABLE <= '0';
				STEP2_ENABLE <= '1';
				STEP3_ENABLE <= '0';				
				
			when Step2Wait =>
			
				S_AXIS_TREADY_temp <= '0';
				STEP1_ENABLE <= '0';
				STEP2_ENABLE <= '0';	
				STEP3_ENABLE <= '0';
				
			when Step3 =>
		
				S_AXIS_TREADY_temp <= '0';
				STEP1_ENABLE <= '0';
				STEP2_ENABLE <= '0';
				STEP3_ENABLE <= '1';				
				
			when others =>
			
				S_AXIS_TREADY_temp <= '0';
				STEP1_ENABLE <= '0';
				STEP2_ENABLE <= '0';
				STEP3_ENABLE <= '0';
				
        end case;
    end process comb_proc;
	
	
	process (CLK, RESETN)
	begin
		if (rising_edge (CLK)) then
			if (RESETN = '0') then
				
				TEMP_COLUMN_NUMBER <= (others => '0');
				
			else
		
				if(TEMP_WRITE_ENABLE = '1' or STEP3_ENABLE = '1') then
				
					TEMP_COLUMN_NUMBER <= std_logic_vector(unsigned(TEMP_COLUMN_NUMBER)+1);
				
				else
				
					TEMP_COLUMN_NUMBER <= (others => '0');
				
				end if;
		
		
			end if;
		end if;

	end process;
	
	

end Behavioral;
