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
use IEEE.STD_LOGIC_1164.all;
use IEEE.math_real.all;
use ieee.numeric_std.all;
library work;
use work.td_package.all;
entity ShermanMorrisonController is
	generic (
		NUM_BANDS : positive := 16
	);
	port (

		CLK                 : in std_logic;
		RESETN              : in std_logic;
		VALID_SIGS          : in Valid_signals;

		S_AXIS_TVALID       : in std_logic;
		S_AXIS_TREADY       : out std_logic;
		S_AXIS_FIFO_TVALID  : in std_logic;
		S_AXIS_FIFO_TREADY  : out std_logic;
		CONTROLLER_SIGS     : out Controller_Signals;

		INPUT_COLUMN_VALID  : in std_logic;
		S_DIV_AXIS_TVALID   : in std_logic;
		M_DIV_AXIS_TVALID   : out std_logic;
		OUTPUT_STREAM_VALID : out std_logic;
		ENABLE_CORE         : in std_logic

	);
end ShermanMorrisonController;

architecture Behavioral of ShermanMorrisonController is
	type state_type is (Idle, InitializeMatrix, WaitForStart, WriteVector, Step1Fetch, Step1, Step1Wait, Step2Fetch, Step2, Step2Wait, Step3Fetch, Step3);
	signal State                  : state_type;

	signal S_AXIS_TREADY_temp     : std_logic;
	signal S_AXIS_FIFO_TREADY_temp: std_logic;
	--will be packaged
	signal STEP1_ENABLE           : std_logic;
	signal STEP2_ENABLE           : std_logic;
	signal STEP3_ENABLE           : std_logic;
	signal ENABLE_INPUT           : std_logic;
	signal TD_ENABLE_INPUT        : std_logic;
	signal ENABLE_STEP3           : std_logic;
	signal ENABLE_STEP3_RXTD      : std_logic;

	signal COMPONENT_WRITE_ENABLE : std_logic;
	signal COMPONENT_TD_WRITE_ENABLE : std_logic;
	signal COLUMN_WRITE_ENABLE    : std_logic;
	signal TEMP_WRITE_ENABLE      : std_logic;

	signal MULT_ARRAY_ENABLE      : std_logic;
	signal DP_ARRAY_ENABLE 		  : std_logic;
	signal TD_DP_ST1_ENABLE		  : std_logic;

	signal STEP2_ENABLE_dly       : std_logic;
	signal STEP2_ENABLE_DIV       : std_logic;
	signal STEP2_DIV_IN_VALID     : std_logic;
	
	signal STEP3_ENABLE_dly       : std_logic;
	signal STEP3_ENABLE_dly2      : std_logic;
	signal STEP3_ENABLE_TD        : std_logic;
	signal STEP3_TEMP_COUNT       : std_logic;

	signal STEP1_DATA_VALID       : std_logic;
	signal STEP2_DATA_VALID       : std_logic;
	signal STEP3_DATA_VALID       : std_logic;
	signal MULT_ARRAY_VALID       : std_logic;

	--CORRELATION MATRIX selector
	signal COLUMN_IN_SEL          : std_logic;
	signal MULT_ARRAY_SEL         : std_logic;
	signal DIV_SEL				  : std_logic;
	signal COUNT_ST1              : std_logic;
	signal COUNT_ST2              : std_logic;
	signal COUNT_RS				  : std_logic;
	signal DP_ARRAY_SAVE          : std_logic;
	
	--DP array selector
	signal DP_ARRAY_SEL			  : std_logic_vector (1 downto 0);
	
	signal TDS_VALID			  : std_logic;

	--ADDRESSES FOR BRAM MODULES
	signal COMPONENT_TD_NUMBER    : std_logic_vector (integer(ceil(log2(real(NUM_BANDS)))) - 1 downto 0);
	signal COMPONENT_NUMBER       : std_logic_vector (integer(ceil(log2(real(NUM_BANDS)))) - 1 downto 0);
	signal COLUMN_NUMBER          : std_logic_vector (integer(ceil(log2(real(NUM_BANDS)))) - 1 downto 0);
	signal COLUMN_NUMBER_W        : std_logic_vector (integer(ceil(log2(real(NUM_BANDS)))) - 1 downto 0);
	signal TEMP_COLUMN_NUMBER     : std_logic_vector (integer(ceil(log2(real(NUM_BANDS)))) - 1 downto 0);

	
	signal START_TARGET_DETECTION : std_logic;

begin

---------------------------------------------------------------------------------	 
-- PACKING
---------------------------------------------------------------------------------	

	CONTROLLER_SIGS <=
		(
		STEP1_ENABLE           => STEP1_ENABLE,
		STEP2_ENABLE           => STEP2_ENABLE,
		STEP2_ENABLE_DIV       => STEP2_ENABLE_DIV,
		STEP3_ENABLE           => STEP3_ENABLE,
		STEP3_ENABLE_TD		   => STEP3_ENABLE_TD,
		COMPONENT_WRITE_ENABLE => COMPONENT_WRITE_ENABLE,
		COMPONENT_TD_WRITE_ENABLE => COMPONENT_TD_WRITE_ENABLE,
		COLUMN_WRITE_ENABLE    => COLUMN_WRITE_ENABLE,
		TEMP_WRITE_ENABLE      => TEMP_WRITE_ENABLE,
		MULT_ARRAY_ENABLE      => MULT_ARRAY_ENABLE,
		DP_ARRAY_ENABLE        => DP_ARRAY_ENABLE,
		TD_DP_ST1_ENABLE       => TD_DP_ST1_ENABLE,
		COLUMN_IN_SEL          => COLUMN_IN_SEL,
		MULT_ARRAY_SEL         => MULT_ARRAY_SEL,
		DIV_SEL				   => DIV_SEL,
		COUNT_ST1              => COUNT_ST1,
		COUNT_ST2              => COUNT_ST2,
		COUNT_RS		       => COUNT_RS,
		DP_ARRAY_SAVE		   => DP_ARRAY_SAVE,
		DP_ARRAY_SEL		   => DP_ARRAY_SEL,
		COMPONENT_NUMBER       => COMPONENT_NUMBER,
		COMPONENT_TD_NUMBER    => COMPONENT_TD_NUMBER,
		COLUMN_NUMBER          => COLUMN_NUMBER,
		COLUMN_NUMBER_W        => COLUMN_NUMBER_W,
		TEMP_COLUMN_NUMBER     => TEMP_COLUMN_NUMBER
		);
		
	--STEP1_DATA_VALID       <= VALID_SIGS.STEP1_DATA_VALID;
	--STEP2_DATA_VALID          <=	VALID_SIGS.STEP2_DATA_VALID;
	--STEP3_DATA_VALID          <= 	VALID_SIGS.STEP3_DATA_VALID;
	MULT_ARRAY_VALID       <= VALID_SIGS.MULT_ARRAY_VALID;
	STEP2_DIV_IN_VALID     <= VALID_SIGS.STEP2_DIV_IN_VALID;
	TDS_VALID			   <= VALID_SIGS.TDS_VALID;
	
---------------------------------------------------------------------------------	 
-- CONTROL LOGIC
---------------------------------------------------------------------------------		

	S_AXIS_TREADY          <= S_AXIS_TREADY_temp;
	S_AXIS_FIFO_TREADY     <= S_AXIS_FIFO_TREADY_temp;
	COMPONENT_WRITE_ENABLE <= S_AXIS_TREADY_temp and S_AXIS_TVALID;
	COMPONENT_TD_WRITE_ENABLE <= S_AXIS_FIFO_TREADY_temp and S_AXIS_FIFO_TVALID;
	TEMP_WRITE_ENABLE      <= STEP2_DATA_VALID;
	COLUMN_WRITE_ENABLE    <= '1' when ((STEP3_DATA_VALID = '1') or (INPUT_COLUMN_VALID = '1' and ((state = Idle) or (state = InitializeMatrix)))) else '0';

	STEP2_ENABLE_DIV       <= STEP2_ENABLE or STEP2_ENABLE_dly;
	STEP3_ENABLE_TD		   <= STEP3_ENABLE or STEP3_ENABLE_dly; --or STEP3_ENABLE_dly2;

	--SHARED DP ARRAY
	DP_ARRAY_ENABLE		   <= STEP1_ENABLE or (STEP2_ENABLE or STEP2_ENABLE_dly) or (ENABLE_STEP3_RXTD); 
	TD_DP_ST1_ENABLE       <= STEP1_ENABLE;
	--DP_ARRAY_SEL  		   <= '1' when (state = step1) else '0';

	--SHARED MULT ARRAY
	MULT_ARRAY_ENABLE      <= STEP2_ENABLE or STEP3_ENABLE;

	STEP2_DATA_VALID       <= MULT_ARRAY_VALID when (state = Step2) else '0';
	STEP3_DATA_VALID       <= MULT_ARRAY_VALID when (state = Step3) else '0';

	M_DIV_AXIS_TVALID      <= '1' when (STEP2_DIV_IN_VALID = '1' or state = Step2Fetch) else '0';--TDS_VALID;
	DIV_SEL				   <= '0' when (STEP2_DIV_IN_VALID = '1') else '1';

	COLUMN_IN_SEL          <= '0' when (state = Idle or state = InitializeMatrix) else '1';
	MULT_ARRAY_SEL         <= '1' when (state = Step2) else '0';

	COUNT_ST1			   <= '1' when (STEP1_ENABLE = '1' or state = Step1Fetch) else '0';
	COUNT_ST2              <= '1' when (state = Step2Fetch or state = Step2) else '0';
	DP_ARRAY_SAVE	       <= '1' when (state = Step2Fetch) else '0';
	COUNT_RS			   <= '1' when (STEP3_ENABLE = '1' or state = Step3Fetch) else '0';
	

	--OUTPUT STREAM VALID
	OUTPUT_STREAM_VALID    <= '0' when (state = Step2Wait) else (S_DIV_AXIS_TVALID and START_TARGET_DETECTION);

	
	--DELAY FOR STEP 2 DP For division
	process (CLK)
	begin
		if (rising_edge (CLK)) then
			if (RESETN = '0') then

				STEP2_ENABLE_dly <= '0';
				STEP3_ENABLE_dly <= '0';
				STEP3_ENABLE_dly2 <= '0';

			else

				STEP2_ENABLE_dly <= STEP2_ENABLE;
				STEP3_ENABLE_dly <= STEP3_ENABLE;
				STEP3_ENABLE_dly2 <= STEP3_ENABLE_dly;

			end if;
		end if;

	end process;


--TEMPORARY RESULTS MATRIX COLUMN COUNTER (NEEDED SEPARATELY).
	process (CLK)
	begin
		if (rising_edge (CLK)) then
			if (RESETN = '0') then

				TEMP_COLUMN_NUMBER <= (others => '0');
	
			else

				if ((TEMP_WRITE_ENABLE = '1' or STEP3_TEMP_COUNT = '1') and unsigned(TEMP_COLUMN_NUMBER) = NUM_BANDS - 1 ) then

					TEMP_COLUMN_NUMBER <= (others => '0');

				elsif ((TEMP_WRITE_ENABLE = '1' or STEP3_TEMP_COUNT = '1')) then

					TEMP_COLUMN_NUMBER <= std_logic_vector(unsigned(TEMP_COLUMN_NUMBER) + 1);

				else

					TEMP_COLUMN_NUMBER <= (others => '0');

				end if;

			end if;
		end if;

	end process;





	--STATE MACHINE TO CONTROL UPDATING OF CORRELATION MATRIX	
	states : process (CLK)
		variable counter     : integer range 0 to NUM_BANDS + 4;
		variable pix_counter : integer range 0 to NUM_BANDS;
		variable td_pix_counter : integer range 0 to NUM_BANDS;
		variable delay_counter   : integer range 0 to 2*NUM_BANDS;
	begin
		if (rising_edge (CLK)) then
			if (RESETN = '0') then

				counter     		 	:= 0;
				pix_counter 		 	:= 0;
				td_pix_counter  	 	:= 0;
				delay_counter 		 	:= 0;
				state           	 	<= Idle;
				COMPONENT_NUMBER 	 	<= (others => '0');
				COMPONENT_TD_NUMBER  	<= (others => '0');
				COLUMN_NUMBER   	 	<= (others => '0');
				COLUMN_NUMBER_W  	 	<= (others => '0');
				ENABLE_INPUT     	 	<= '0';
				TD_ENABLE_INPUT  	 	<= '0';
				ENABLE_STEP3    	 	<= '0';
				ENABLE_STEP3_RXTD    	<= '0';
				START_TARGET_DETECTION 	<= '0';

			else

				case state is

					when Idle =>

						if (INPUT_COLUMN_VALID = '1') then

							counter := counter + 1;
							COLUMN_NUMBER   <= std_logic_vector(to_unsigned(counter, COMPONENT_NUMBER'length));
							COLUMN_NUMBER_W <= std_logic_vector(to_unsigned(counter, COMPONENT_NUMBER'length));
							state <= InitializeMatrix;

						end if;
						
					when InitializeMatrix =>



						if (counter = NUM_BANDS and INPUT_COLUMN_VALID = '1') then

							counter := 0;
							COLUMN_NUMBER   <= std_logic_vector(to_unsigned(counter, COMPONENT_NUMBER'length));
							COLUMN_NUMBER_W <= std_logic_vector(to_unsigned(counter, COMPONENT_NUMBER'length));
							state <= WaitForStart;

						elsif (counter = NUM_BANDS-1) then

							COLUMN_NUMBER   <= std_logic_vector(to_unsigned(counter, COMPONENT_NUMBER'length));
							COLUMN_NUMBER_W <= std_logic_vector(to_unsigned(counter, COMPONENT_NUMBER'length));
							counter := counter + 1;

						elsif (counter < NUM_BANDS and INPUT_COLUMN_VALID = '1') then
							
							counter := counter + 1;
							COLUMN_NUMBER   <= std_logic_vector(to_unsigned(counter, COMPONENT_NUMBER'length));
							COLUMN_NUMBER_W <= std_logic_vector(to_unsigned(counter, COMPONENT_NUMBER'length));
							
						
						end if;

						
					when WaitForStart =>

						if ((S_AXIS_TREADY_temp and S_AXIS_TVALID) = '1') then

							state <= WriteVector;
							counter := counter + 1;

						end if;

						COMPONENT_NUMBER <= std_logic_vector(to_unsigned(counter, COMPONENT_NUMBER'length));

					when WriteVector =>

						if (counter = NUM_BANDS - 1) then

							counter := 0;
							state <= Step1Fetch;

						elsif ((S_AXIS_TREADY_temp and S_AXIS_TVALID) = '1') then

							counter := counter + 1;

						end if;

						COMPONENT_NUMBER <= std_logic_vector(to_unsigned(counter, COMPONENT_NUMBER'length));

					when Step1Fetch =>

						state <= Step1;
						counter := counter + 1;

						COMPONENT_NUMBER <= std_logic_vector(to_unsigned(counter, COMPONENT_NUMBER'length));
						COLUMN_NUMBER    <= std_logic_vector(to_unsigned(counter, COMPONENT_NUMBER'length));

					when Step1 =>

						if (counter = NUM_BANDS + 3) then

							counter := 0;
							state            	<= Step1Wait;
							COMPONENT_NUMBER 	<= std_logic_vector(to_unsigned(counter, COMPONENT_NUMBER'length));
							COLUMN_NUMBER    	<= std_logic_vector(to_unsigned(counter, COMPONENT_NUMBER'length));
							COMPONENT_TD_NUMBER <= std_logic_vector(to_unsigned(counter, COMPONENT_NUMBER'length));

						elsif (counter >= NUM_BANDS - 1) then

							counter := counter + 1;
							COMPONENT_NUMBER 	<= (others => '0');
							COMPONENT_TD_NUMBER <= (others => '0');
							COLUMN_NUMBER    	<= (others => '0');

						else

							counter := counter + 1;
							COMPONENT_NUMBER 	<= std_logic_vector(to_unsigned(counter, COMPONENT_NUMBER'length));
							COMPONENT_TD_NUMBER <= std_logic_vector(to_unsigned(counter, COMPONENT_NUMBER'length));
							COLUMN_NUMBER   	<= std_logic_vector(to_unsigned(counter, COMPONENT_NUMBER'length));

						end if;

					when Step1Wait =>

						state            <= Step2Fetch;
						COMPONENT_NUMBER <= std_logic_vector(to_unsigned(counter, COMPONENT_NUMBER'length));
						COLUMN_NUMBER    <= std_logic_vector(to_unsigned(counter, COMPONENT_NUMBER'length));
					
					when Step2Fetch =>

						state <= Step2;
						counter := 1;
						--STEP2_INPUT <= STEP1_DOTPROD (counter);
						COMPONENT_NUMBER <= std_logic_vector(to_unsigned(counter, COMPONENT_NUMBER'length));
						COLUMN_NUMBER    <= std_logic_vector(to_unsigned(counter, COMPONENT_NUMBER'length));
						
						if (delay_counter < NUM_BANDS) then 
							delay_counter := delay_counter + 1;
							TD_ENABLE_INPUT <= '0';
							START_TARGET_DETECTION <= '0';
						else
							TD_ENABLE_INPUT <= '1';
							START_TARGET_DETECTION <= '1';
						end if;	

					when Step2 =>

						if (counter = NUM_BANDS + 2) then

							counter := 0;
							state <= Step2Wait;
							COLUMN_NUMBER    <= std_logic_vector(to_unsigned(counter, COMPONENT_NUMBER'length));

						elsif (counter >= NUM_BANDS - 1) then

							counter := counter + 1;
							COLUMN_NUMBER    <= (others => '0');
						else

							counter := counter + 1;
							--STEP2_INPUT <= STEP1_DOTPROD (counter);
							COMPONENT_NUMBER <= std_logic_vector(to_unsigned(counter, COMPONENT_NUMBER'length));
							COLUMN_NUMBER    <= std_logic_vector(to_unsigned(counter, COMPONENT_NUMBER'length));

						end if;

						if (td_pix_counter = NUM_BANDS - 1) then

							td_pix_counter := 0;
							TD_ENABLE_INPUT <= '0';

						elsif ((S_AXIS_FIFO_TREADY_temp and S_AXIS_FIFO_TVALID) = '1') then

							td_pix_counter := td_pix_counter + 1;

						end if;

						COMPONENT_TD_NUMBER <= std_logic_vector(to_unsigned(td_pix_counter, COMPONENT_TD_NUMBER'length));



					when Step2Wait =>

						--waiting for division to finish
						if (S_DIV_AXIS_TVALID = '1') then
							state <= Step3Fetch;
							--STEP3_INPUT <= S_DIV_AXIS_TDATA (CORRELATION_DATA_WIDTH - 1 downto 0);
						end if;

					when Step3Fetch =>

						state <= Step3;
						counter := 0;
						COLUMN_NUMBER    <= std_logic_vector(to_unsigned(counter, COMPONENT_NUMBER'length));
						COLUMN_NUMBER_W  <= std_logic_vector(to_unsigned(counter, COMPONENT_NUMBER'length));
						COMPONENT_NUMBER <= std_logic_vector(to_unsigned(counter, COMPONENT_NUMBER'length));
						COMPONENT_TD_NUMBER <= std_logic_vector(to_unsigned(counter, COMPONENT_TD_NUMBER'length));
						ENABLE_INPUT     <= '1';
						ENABLE_STEP3     <= '1';

					when Step3 =>


						if(counter = NUM_BANDS + 2 ) then
					
							ENABLE_STEP3  <= '0';
							ENABLE_STEP3_RXTD   <= '0';
							COLUMN_NUMBER   <= (others => '0');
							COLUMN_NUMBER_W <= COLUMN_NUMBER;

						elsif (counter <= NUM_BANDS +1  and ENABLE_STEP3 = '0') then

							counter :=  counter + 1; 
							ENABLE_STEP3  <= '0';
							ENABLE_STEP3_RXTD   <= '1';
							COLUMN_NUMBER   <= (others => '0');
							COLUMN_NUMBER_W <= COLUMN_NUMBER;
							COMPONENT_TD_NUMBER <= (others => '0');
							--	COMPONENT_NUMBER <= std_logic_vector(to_unsigned(counter,COMPONENT_NUMBER'length));

						elsif((counter = NUM_BANDS) and ENABLE_STEP3 = '1')	then

							ENABLE_STEP3  <= '0';
							COLUMN_NUMBER 	<= (others => '0');
							COLUMN_NUMBER_W <= COLUMN_NUMBER;
							COMPONENT_TD_NUMBER <= (others => '0');
							ENABLE_STEP3_RXTD   <= '1';

						elsif((counter = NUM_BANDS-1)  and (STEP3_ENABLE_dly='1' or STEP3_DATA_VALID = '1') and ENABLE_STEP3 = '1') then

							counter := counter + 1; 
							COLUMN_NUMBER 	<= (others => '0');
							COLUMN_NUMBER_W <= COLUMN_NUMBER;
							COMPONENT_TD_NUMBER <= (others => '0');
							ENABLE_STEP3_RXTD   <= '1';


						--elsif (STEP3_DATA_VALID = '1') then
						elsif ((STEP3_ENABLE_dly='1' or STEP3_DATA_VALID = '1') and ENABLE_STEP3 = '1') then  -- maybe STEP3_ENABLE_dly
							counter := counter + 1; 
							COLUMN_NUMBER 		<= std_logic_vector(to_unsigned(counter, COMPONENT_NUMBER'length));
							COLUMN_NUMBER_W 	<= COLUMN_NUMBER;
							COMPONENT_TD_NUMBER <= std_logic_vector(to_unsigned(counter, COMPONENT_TD_NUMBER'length));
							ENABLE_STEP3_RXTD   <= '1';
							--	COMPONENT_NUMBER <= std_logic_vector(to_unsigned(counter,COMPONENT_NUMBER'length));

						else

							counter := 0;
							COLUMN_NUMBER 	<= std_logic_vector(to_unsigned(counter, COMPONENT_NUMBER'length));
							COLUMN_NUMBER_W <= COLUMN_NUMBER;
							COMPONENT_TD_NUMBER <= std_logic_vector(to_unsigned(counter, COMPONENT_TD_NUMBER'length));
							--	COMPONENT_NUMBER <= std_logic_vector(to_unsigned(counter,COMPONENT_NUMBER'length));
 
						end if;

						if (pix_counter = NUM_BANDS - 1) then

							pix_counter := 0;
							ENABLE_INPUT <= '0';

						elsif ((S_AXIS_TREADY_temp and S_AXIS_TVALID) = '1') then

							pix_counter := pix_counter + 1;

						end if;

						COMPONENT_NUMBER <= std_logic_vector(to_unsigned(pix_counter, COMPONENT_NUMBER'length));

						--all has finished, we can proceed
						if (ENABLE_STEP3 = '0' and ENABLE_INPUT = '0' and ENABLE_STEP3_RXTD = '0') then
							pix_counter := 0;
							counter := 0;
							state <= Step1Fetch;

						end if;

					when others =>

						state <= Idle;

				end case;

			end if;
		end if;

	end process states;
	--COMBINATORIAL PROCESS OF THE STATE MACHINE	
	comb_proc : process (state, STEP3_DATA_VALID, ENABLE_INPUT, ENABLE_STEP3, ENABLE_CORE,TD_ENABLE_INPUT)
	begin

			S_AXIS_TREADY_temp <= '0';
			S_AXIS_FIFO_TREADY_temp <= '0';
			STEP1_ENABLE       <= '0';
			STEP2_ENABLE       <= '0';
			STEP3_ENABLE       <= '0';
			STEP3_TEMP_COUNT   <= '0';
			DP_ARRAY_SEL       <= "01";

		case state is

			when Idle =>

				S_AXIS_TREADY_temp <= '0';
				STEP1_ENABLE       <= '0';
				STEP2_ENABLE       <= '0';
				STEP3_ENABLE       <= '0';

			when InitializeMatrix =>

				S_AXIS_TREADY_temp <= '0';
				STEP1_ENABLE       <= '0';
				STEP2_ENABLE       <= '0';
				STEP3_ENABLE       <= '0';

			when WaitForStart =>

				if (ENABLE_CORE = '1') then
					S_AXIS_TREADY_temp <= '1';
				else
					S_AXIS_TREADY_temp <= '0';
				end if;

				STEP1_ENABLE <= '0';
				STEP2_ENABLE <= '0';
				STEP3_ENABLE <= '0';

			when WriteVector =>

				S_AXIS_TREADY_temp <= '1';
				STEP1_ENABLE       <= '0';
				STEP2_ENABLE       <= '0';
				STEP3_ENABLE       <= '0';

			when Step1Fetch =>

				S_AXIS_TREADY_temp <= '0';
				STEP1_ENABLE       <= '0';
				STEP2_ENABLE       <= '0';
				STEP3_ENABLE       <= '0';

			when Step1 =>

				S_AXIS_TREADY_temp <= '0';
				STEP1_ENABLE       <= '1';
				STEP2_ENABLE       <= '0';
				STEP3_ENABLE       <= '0';
				DP_ARRAY_SEL       <= "01";

			when Step1Wait =>

				S_AXIS_TREADY_temp <= '0';
				STEP1_ENABLE       <= '0';
				STEP2_ENABLE       <= '0';
				STEP3_ENABLE       <= '0';

			when Step2Fetch =>

				S_AXIS_TREADY_temp <= '0';
				STEP1_ENABLE       <= '0';
				STEP2_ENABLE       <= '0';
				STEP3_ENABLE       <= '0';

			when Step2 =>

				if (TD_ENABLE_INPUT = '1') then
					S_AXIS_FIFO_TREADY_temp <= '1'; --simultaneous write
				else
					S_AXIS_FIFO_TREADY_temp <= '0';
				end if;

				S_AXIS_TREADY_temp <= '0';
				STEP1_ENABLE       <= '0';
				STEP2_ENABLE       <= '1';
				STEP3_ENABLE       <= '0';
				DP_ARRAY_SEL       <= "00";

			when Step2Wait =>

				S_AXIS_TREADY_temp <= '0';
				STEP1_ENABLE       <= '0';
				STEP2_ENABLE       <= '0';
				STEP3_ENABLE       <= '0';

			when Step3Fetch =>

				S_AXIS_TREADY_temp <= '0';
				STEP1_ENABLE       <= '0';
				STEP2_ENABLE       <= '0';
				STEP3_ENABLE       <= '0';
				STEP3_TEMP_COUNT   <= '1';

			when Step3 =>

				DP_ARRAY_SEL       <= "10";

				if (ENABLE_INPUT = '1') then
					S_AXIS_TREADY_temp <= '1'; --simultaneous write
				else
					S_AXIS_TREADY_temp <= '0';
				end if;

				STEP1_ENABLE <= '0';
				STEP2_ENABLE <= '0';

				if (ENABLE_STEP3 = '1') then
					STEP3_ENABLE 	 <= '1';
					STEP3_TEMP_COUNT <= '1';
				else
					STEP3_ENABLE 	 <= '0';
					STEP3_TEMP_COUNT <= '0';
				end if;
			when others =>

				S_AXIS_TREADY_temp <= '0';
				STEP1_ENABLE       <= '0';
				STEP2_ENABLE       <= '0';
				STEP3_ENABLE       <= '0';

		end case;

	end process comb_proc;
end Behavioral;