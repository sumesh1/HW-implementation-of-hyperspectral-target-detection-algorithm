----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.02.2019 13:30:23
-- Design Name: 
-- Module Name: ShermanMorrisonTopLevel - Behavioral
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
use ieee.numeric_std.all;
library work;
use work.td_package.all;


entity ShermanMorrisonTopLevel is
	generic (
		NUM_BANDS        : positive := 16;
		PIXEL_DATA_WIDTH : positive := 16;
		CORRELATION_DATA_WIDTH  : positive := 32;
		OUT_DATA_WIDTH   : positive := 32
	);
	port (

		CLK              : in std_logic;
		RESETN           : in std_logic;
		S_AXIS_TREADY    : out std_logic;
		S_AXIS_TDATA     : in std_logic_vector(PIXEL_DATA_WIDTH - 1 downto 0);
		S_AXIS_TLAST     : in std_logic;
		S_AXIS_TVALID    : in std_logic;
		OUTPUT_COLUMN	 : out CorrMatrixColumn;
		OUTPUT_VALID     : out std_logic
		
	);
end ShermanMorrisonTopLevel;

architecture Behavioral of ShermanMorrisonTopLevel is

	signal COMPONENT_IN : std_logic_vector (PIXEL_DATA_WIDTH-1 downto 0);
	signal COMPONENT_OUT: std_logic_vector (PIXEL_DATA_WIDTH-1 downto 0);
	signal COMPONENT_NUMBER: std_logic_vector (integer(ceil(log2(real(NUM_BANDS))))-1 downto 0);
	signal COMPONENT_WRITE_ENABLE: std_logic;
	
	signal COLUMN_IN  : CorrMatrixColumn;
	signal COLUMN_OUT : CorrMatrixColumn;
	signal COLUMN_NUMBER: std_logic_vector (integer(ceil(log2(real(NUM_BANDS))))-1 downto 0);
	signal COLUMN_WRITE_ENABLE: std_logic;
	
	signal STEP1_ENABLE : std_logic;
	signal STEP1_DOTPROD :CorrMatrixColumn;
	signal STEP1_DATA_VALID: std_logic;
	signal S_AXIS_TREADY_temp: std_logic;
	
	
	signal STEP2_ENABLE : std_logic;
	signal STEP2_PROD :CorrMatrixColumn;
	signal STEP2_INPUT : std_logic_vector(OUT_DATA_WIDTH-1 downto 0);
	signal STEP2_DATA_VALID: std_logic;
	
	signal TEMP_COLUMN_IN  : CorrMatrixColumn;
	signal TEMP_COLUMN_OUT : CorrMatrixColumn;
	signal TEMP_COLUMN_NUMBER: std_logic_vector (integer(ceil(log2(real(NUM_BANDS))))-1 downto 0);
	signal TEMP_WRITE_ENABLE: std_logic;
	
	signal STEP3_ENABLE : std_logic;
	signal STEP3_PROD :CorrMatrixColumn;
	signal STEP3_INPUT : std_logic_vector(OUT_DATA_WIDTH-1 downto 0);
	signal STEP3_DATA_VALID: std_logic;
	
	constant vectornumb: std_logic_vector (CORRELATION_DATA_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(500000000, CORRELATION_DATA_WIDTH));
	
	type state_type is (Idle,WriteVector, Step1,Step1Wait,Step2,Step2Wait,Step3);
	signal State: state_type;
	
begin
---------------------------------------------------------------------------------	 
	-- INSTANCES
---------------------------------------------------------------------------------
	
	
	OUTPUT_COLUMN <= STEP1_DOTPROD;
	COMPONENT_IN  <= S_AXIS_TDATA;
	OUTPUT_VALID  <= STEP1_DATA_VALID;
	
	
	
	InputPixelInst: entity work.InputPixel(Registers)
		generic map (
			NUM_BANDS           =>  NUM_BANDS,    
			PIXEL_DATA_WIDTH    =>  PIXEL_DATA_WIDTH
		)
		port map (
			CLK              =>   CLK,           
			RESETN           =>   RESETN,        
			WRITE_ENABLE 	 =>   COMPONENT_WRITE_ENABLE, 
			COMPONENT_NUMBER =>   COMPONENT_NUMBER, 
			COMPONENT_IN	 =>   COMPONENT_IN,	
			COMPONENT_OUT	 =>   COMPONENT_OUT	  
		);

	CorrMatrixInst: entity work.CorrelationMatrix(Registers)  --CHANGE Registers architecture to BRAM if BRAM is preferred
		generic map (
			NUM_BANDS                 =>  NUM_BANDS,    
			CORRELATION_DATA_WIDTH    =>  CORRELATION_DATA_WIDTH
		)
		port map (
			CLK              =>   CLK,           
			RESETN           =>   RESETN,        
			WRITE_ENABLE 	 =>   COLUMN_WRITE_ENABLE, 
			COLUMN_NUMBER 	 =>   COLUMN_NUMBER, 
			COLUMN_IN		 =>   COLUMN_IN,	
			COLUMN_OUT	     =>   COLUMN_OUT	  
		);
		
	DotProductArrayInst: entity work.DotProductArray(Behavioral)
		generic map (
			NUM_BANDS       =>  NUM_BANDS,    
			IN1_DATA_WIDTH  =>  PIXEL_DATA_WIDTH,
			IN2_DATA_WIDTH  =>  CORRELATION_DATA_WIDTH,
			OUT_DATA_WIDTH  =>  CORRELATION_DATA_WIDTH
		)
		port map (
			CLK              =>   CLK,           
			RESETN           =>   RESETN,        
			ENABLE 		     =>   STEP1_ENABLE, 
			IN1_COMPONENT	 =>   COMPONENT_OUT, 
			IN2_COLUMN		 =>   COLUMN_OUT,	
			COLUMN_OUT	     =>   STEP1_DOTPROD,	  
			DATA_VALID	     =>	  STEP1_DATA_VALID
		);
		
	MultiplierArrayInst: entity work.MultiplierArray(Behavioral)
		generic map (
			NUM_BANDS       =>  NUM_BANDS,    
			IN1_DATA_WIDTH  =>  CORRELATION_DATA_WIDTH,
			IN2_DATA_WIDTH  =>  CORRELATION_DATA_WIDTH,
			OUT_DATA_WIDTH  =>  CORRELATION_DATA_WIDTH
		)
		port map (
			CLK              =>   CLK,           
			RESETN           =>   RESETN,        
			ENABLE 		     =>   STEP2_ENABLE, 
			IN1_COMPONENT	 =>   STEP2_INPUT, 
			IN2_COLUMN		 =>   STEP1_DOTPROD,	
			COLUMN_OUT	     =>   STEP2_PROD,	  
			DATA_VALID	     =>	  STEP2_DATA_VALID
		);
		
	TempMatrixInst: entity work.CorrelationMatrix(Registers)   --CHANGE Registers architecture to BRAM if BRAM is preferred
		generic map (
			NUM_BANDS                 =>  NUM_BANDS,    
			CORRELATION_DATA_WIDTH    =>  CORRELATION_DATA_WIDTH
		)
		port map (
			CLK              =>   CLK,           
			RESETN           =>   RESETN,        
			WRITE_ENABLE 	 =>   TEMP_WRITE_ENABLE, 
			COLUMN_NUMBER 	 =>   TEMP_COLUMN_NUMBER, 
			COLUMN_IN		 =>   TEMP_COLUMN_IN,	
			COLUMN_OUT	     =>   TEMP_COLUMN_OUT	  	
		);
		
		
	MultiplierArrayInst2: entity work.MultiplierArray(Behavioral)
		generic map (
			NUM_BANDS       =>  NUM_BANDS,    
			IN1_DATA_WIDTH  =>  CORRELATION_DATA_WIDTH,
			IN2_DATA_WIDTH  =>  CORRELATION_DATA_WIDTH,
			OUT_DATA_WIDTH  =>  CORRELATION_DATA_WIDTH
		)
		port map (
			CLK              =>   CLK,           
			RESETN           =>   RESETN,        
			ENABLE 		     =>   STEP3_ENABLE, 
			IN1_COMPONENT	 =>   STEP3_INPUT, 
			IN2_COLUMN		 =>   TEMP_COLUMN_OUT,	
			COLUMN_OUT	     =>   STEP3_PROD,	  
			DATA_VALID	     =>	  STEP3_DATA_VALID
		);
		

		
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
							state <= Step1;
							COLUMN_NUMBER    <= std_logic_vector(to_unsigned(counter,COMPONENT_NUMBER'length));
							COMPONENT_NUMBER <= std_logic_vector(to_unsigned(counter,COMPONENT_NUMBER'length));
						
						elsif ( STEP3_DATA_VALID = '1') then 
							
							counter := counter + 1;
							COLUMN_NUMBER    <= std_logic_vector(to_unsigned(counter,COMPONENT_NUMBER'length));
							COMPONENT_NUMBER <= std_logic_vector(to_unsigned(counter,COMPONENT_NUMBER'length));
						
						else 
						
							counter := 0;
							COLUMN_NUMBER    <= std_logic_vector(to_unsigned(counter,COMPONENT_NUMBER'length));
							COMPONENT_NUMBER <= std_logic_vector(to_unsigned(counter,COMPONENT_NUMBER'length));
						
						end if;

						
					when others =>
					
						state <= Idle;
					
					
				end case;	
		
		
		
			end if;
		end if;

	end process states; 
	
	
	comb_proc: process(state,STEP3_DATA_VALID)
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
		
				if(STEP3_DATA_VALID = '1') then
					S_AXIS_TREADY_temp <= '1'; --simultaneous write
				else 
					S_AXIS_TREADY_temp <= '0';
				end if;	
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
