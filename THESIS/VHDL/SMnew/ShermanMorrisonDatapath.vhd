----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.02.2019 13:30:23
-- Design Name: 
-- Module Name: ShermanMorrisonDatapath - Behavioral
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
entity ShermanMorrisonDatapath is
	generic (
		NUM_BANDS              : positive := 16;
		PIXEL_DATA_WIDTH       : positive := 16;
		CORRELATION_DATA_WIDTH : positive := 32;
		OUT_DATA_WIDTH         : positive := 32
	);
	port (
		CLK               : in std_logic;
		RESETN            : in std_logic;
		CONTROLLER_SIGS   : in Controller_Signals;
		VALID_SIGS        : out Valid_signals;

		S_AXIS_TDATA      : in std_logic_vector(PIXEL_DATA_WIDTH - 1 downto 0);

		S_DIV_AXIS_TDATA  : in std_logic_vector(39 downto 0);
		S_DIV_AXIS_TVALID : in std_logic;

		M_DIV_AXIS_TDATA  : out std_logic_vector(OUT_DATA_WIDTH - 1 downto 0);

		INPUT_COLUMN      : in std_logic_vector(NUM_BANDS * CORRELATION_DATA_WIDTH - 1 downto 0)
	);
end ShermanMorrisonDatapath;

---------------------------------------------------------------------------------	 
-- ARCHITECTURE BRAM
---------------------------------------------------------------------------------	

architecture BRAM of ShermanMorrisonDatapath is

	signal COMPONENT_IN           : std_logic_vector (PIXEL_DATA_WIDTH - 1 downto 0);
	signal COMPONENT_OUT          : std_logic_vector (PIXEL_DATA_WIDTH - 1 downto 0);
	signal COMPONENT_NUMBER       : std_logic_vector (integer(ceil(log2(real(NUM_BANDS)))) - 1 downto 0);
	signal COMPONENT_WRITE_ENABLE : std_logic;

	signal COLUMN_IN              : CorrMatrixColumn;
	signal COLUMN_OUT             : CorrMatrixColumn;
	signal COLUMN_NUMBER          : std_logic_vector (integer(ceil(log2(real(NUM_BANDS)))) - 1 downto 0);
	signal COLUMN_WRITE_ENABLE    : std_logic;
	
	--dp array signals
	signal DP_ARRAY_ENABLE        : std_logic;
	signal DP_ARRAY_IN1           : std_logic_vector (PIXEL_DATA_WIDTH - 1 downto 0);
	signal DP_ARRAY_IN2           : CorrMatrixColumn;
	signal DP_ARRAY_OUT			  : CorrMatrixColumn;
	signal DP_ARRAY_VALID		  : std_logic;
	
	--step1 SM signals
	signal STEP1_ENABLE           : std_logic;
	signal STEP1_DOTPROD          : CorrMatrixColumn;
	signal STEP1_DATA_VALID       : std_logic;
	signal STEP2_ENABLE           : std_logic;
	signal STEP2_PROD             : CorrMatrixColumn;
	signal STEP2_INPUT            : std_logic_vector(OUT_DATA_WIDTH - 1 downto 0);
	
	--signal STEP2_DATA_VALID: std_logic;

	signal TEMP_COLUMN_IN         : CorrMatrixColumn;
	signal TEMP_COLUMN_OUT        : CorrMatrixColumn;
	signal TEMP_COLUMN_NUMBER     : std_logic_vector (integer(ceil(log2(real(NUM_BANDS)))) - 1 downto 0);
	signal TEMP_WRITE_ENABLE      : std_logic;

	signal STEP3_ENABLE           : std_logic;
	signal STEP3_PROD             : CorrMatrixColumn;
	signal STEP3_INPUT            : std_logic_vector(OUT_DATA_WIDTH - 1 downto 0);
	--signal STEP3_DATA_VALID: std_logic;
	signal MULT_ARRAY_IN1         : std_logic_vector(OUT_DATA_WIDTH - 1 downto 0);
	signal MULT_ARRAY_IN2         : CorrMatrixColumn;
	signal MULT_ARRAY_ENABLE      : std_logic;
	signal MULT_ARRAY_OUT         : CorrMatrixColumn;
	signal MULT_ARRAY_VALID       : std_logic;

	signal STEP2_DIV_IN_VALID     : std_logic;
	signal DIV_CLEAR              : std_logic;
	signal STEP2_ENABLE_DIV       : std_logic;

	signal COLUMN_IN_SEL          : std_logic;
	signal MULT_ARRAY_SEL         : std_logic;

	constant ACCUMULATOR_WIDTH    : positive := (integer(ceil(log2(real(NUM_BANDS)))) + PIXEL_DATA_WIDTH + CORRELATION_DATA_WIDTH - 1);
	signal STEP2_DIV_IN           : std_logic_vector(ACCUMULATOR_WIDTH - 1 downto 0);

	signal COUNT_ST2              : std_logic;

	constant vectornumb           : std_logic_vector (CORRELATION_DATA_WIDTH - 1 downto 0) := std_logic_vector(to_unsigned(214748, CORRELATION_DATA_WIDTH));
begin
---------------------------------------------------------------------------------	 
-- INSTANCES
---------------------------------------------------------------------------------

--pixel storage
	InputPixelInst : entity work.InputPixel(BRAM)
		generic map(
			NUM_BANDS        => NUM_BANDS,
			PIXEL_DATA_WIDTH => PIXEL_DATA_WIDTH
		)
		port map(
			CLK              => CLK,
			RESETN           => RESETN,
			WRITE_ENABLE     => COMPONENT_WRITE_ENABLE,
			COMPONENT_NUMBER => COMPONENT_NUMBER,
			COMPONENT_IN     => COMPONENT_IN,
			COMPONENT_OUT    => COMPONENT_OUT
		);

--corr matrix storage
	CorrMatrixInst : entity work.CorrelationMatrix(BRAM) --CHANGE Registers architecture to BRAM if BRAM is preferred
		generic map(
			NUM_BANDS              => NUM_BANDS,
			CORRELATION_DATA_WIDTH => CORRELATION_DATA_WIDTH
		)
		port map(
			CLK           => CLK,
			RESETN        => RESETN,
			WRITE_ENABLE  => COLUMN_WRITE_ENABLE,
			COLUMN_NUMBER => COLUMN_NUMBER,
			COLUMN_IN     => COLUMN_IN,
			COLUMN_OUT    => COLUMN_OUT
		);



--dot product array
	DotProductArrayInst : entity work.DotProductArray(Behavioral)
		generic map(
			NUM_BANDS      => NUM_BANDS,
			IN1_DATA_WIDTH => PIXEL_DATA_WIDTH,
			IN2_DATA_WIDTH => CORRELATION_DATA_WIDTH,
			OUT_DATA_WIDTH => CORRELATION_DATA_WIDTH
		)
		port map(
			CLK           => CLK,
			RESETN        => RESETN,
			ENABLE        => DP_ARRAY_ENABLE,
			IN1_COMPONENT => DP_ARRAY_IN1,
			IN2_COLUMN    => DP_ARRAY_IN2,
			COLUMN_OUT    => DP_ARRAY_OUT,
			DATA_VALID    => DP_ARRAY_VALID
		);


--multiplier array
	MultiplierArrayInst : entity work.MultiplierArray(Behavioral)
		generic map(
			NUM_BANDS      => NUM_BANDS,
			IN1_DATA_WIDTH => CORRELATION_DATA_WIDTH,
			IN2_DATA_WIDTH => CORRELATION_DATA_WIDTH,
			OUT_DATA_WIDTH => CORRELATION_DATA_WIDTH
		)
		port map(
			CLK           => CLK,
			RESETN        => RESETN,
			ENABLE        => MULT_ARRAY_ENABLE,
			IN1_COMPONENT => MULT_ARRAY_IN1,
			IN2_COLUMN    => MULT_ARRAY_IN2,
			COLUMN_OUT    => MULT_ARRAY_OUT,
			DATA_VALID    => MULT_ARRAY_VALID
		);

--temporary matrix storage
	TempMatrixInst : entity work.CorrelationMatrix(BRAM) --CHANGE Registers architecture to BRAM if BRAM is preferred
		generic map(
			NUM_BANDS              => NUM_BANDS,
			CORRELATION_DATA_WIDTH => CORRELATION_DATA_WIDTH
		)
		port map(
			CLK           => CLK,
			RESETN        => RESETN,
			WRITE_ENABLE  => TEMP_WRITE_ENABLE,
			COLUMN_NUMBER => TEMP_COLUMN_NUMBER,
			COLUMN_IN     => TEMP_COLUMN_IN,
			COLUMN_OUT    => TEMP_COLUMN_OUT
		);
	
--dot product unit ADDED FOR DIVIDER
	dp_datapath_sm_inst_st2 : entity work.dp_datapath_sm(Behavioral)
		generic map(
			bit_depth_1 => PIXEL_DATA_WIDTH,
			bit_depth_2 => CORRELATION_DATA_WIDTH,
			p_bit_width => ACCUMULATOR_WIDTH
		)
		port map(
			clk     => CLK,
			en      => STEP2_ENABLE_DIV,
			clear   => DIV_CLEAR,
			reset_n => RESETN,
			in_1    => COMPONENT_OUT,
			in_2    => STEP2_INPUT,
			p       => STEP2_DIV_IN
		);

--dot product unit controller
	dp_controller_sm_inst_st2 : entity work.dp_controller_sm(Behavioral)
		generic map(
			V_LEN => NUM_BANDS
		)
		port map(
			clk     => CLK,
			en      => STEP2_ENABLE_DIV,
			reset_n => RESETN,
			p_rdy   => STEP2_DIV_IN_VALID,
			clear   => DIV_CLEAR
		);
	
---------------------------------------------------------------------------------	 
-- PACKING
---------------------------------------------------------------------------------	

	VALID_SIGS <=
		(
		STEP1_DATA_VALID   => STEP1_DATA_VALID,
		--STEP2_DATA_VALID    =>   STEP2_DATA_VALID  ,
		--STEP3_DATA_VALID    =>   STEP3_DATA_VALID  ,
		MULT_ARRAY_VALID   => MULT_ARRAY_VALID,
		STEP2_DIV_IN_VALID => STEP2_DIV_IN_VALID
		);

	STEP1_ENABLE           <= CONTROLLER_SIGS.STEP1_ENABLE;
	STEP2_ENABLE           <= CONTROLLER_SIGS.STEP2_ENABLE;
	STEP2_ENABLE_DIV       <= CONTROLLER_SIGS.STEP2_ENABLE_DIV;
	STEP3_ENABLE           <= CONTROLLER_SIGS.STEP3_ENABLE;
	COMPONENT_WRITE_ENABLE <= CONTROLLER_SIGS.COMPONENT_WRITE_ENABLE;
	COLUMN_WRITE_ENABLE    <= CONTROLLER_SIGS.COLUMN_WRITE_ENABLE;
	TEMP_WRITE_ENABLE      <= CONTROLLER_SIGS.TEMP_WRITE_ENABLE;
	MULT_ARRAY_ENABLE      <= CONTROLLER_SIGS.MULT_ARRAY_ENABLE;
	COLUMN_IN_SEL          <= CONTROLLER_SIGS.COLUMN_IN_SEL;
	MULT_ARRAY_SEL         <= CONTROLLER_SIGS.MULT_ARRAY_SEL;
	COUNT_ST2              <= CONTROLLER_SIGS.COUNT_ST2;
	COMPONENT_NUMBER       <= CONTROLLER_SIGS.COMPONENT_NUMBER;
	COLUMN_NUMBER          <= CONTROLLER_SIGS.COLUMN_NUMBER;
	
---------------------------------------------------------------------------------	 
-- ROUTING SIGNALS
---------------------------------------------------------------------------------		
	
	--DOT PRODUCT ARRAY INPUT SIGNALS
	DP_ARRAY_ENABLE        <= STEP1_ENABLE;
	DP_ARRAY_IN1           <= COMPONENT_OUT;
	DP_ARRAY_IN2           <= COLUMN_OUT;
	
	STEP1_DOTPROD          <= DP_ARRAY_OUT;
	STEP1_DATA_VALID       <= DP_ARRAY_VALID;

	
	
	
---------------------------------------------------------------------------------	 
-- MULTIPLEXING LOGIC
---------------------------------------------------------------------------------		

	--1. INPUT TO CORRELATION MATRIX, IN STATES IDLE AND WRITE VECTOR IT IS INITIALIZED; OTHERWISE UPDATED	
	process (COLUMN_OUT, STEP3_PROD, COLUMN_IN_SEL)
	begin

		case COLUMN_IN_SEL is
				--for initialization
			when '0' =>

				for i in 0 to NUM_BANDS - 1 loop

					COLUMN_IN(i) <= INPUT_COLUMN((CORRELATION_DATA_WIDTH) * (i + 1) - 1 downto (CORRELATION_DATA_WIDTH) * i);

				end loop;

			when '1' =>

				for i in 0 to NUM_BANDS - 1 loop

					COLUMN_IN(i) <= std_logic_vector(signed(COLUMN_OUT(i)) - signed(STEP3_PROD(i)));

				end loop;

			when others =>

				for i in 0 to NUM_BANDS - 1 loop

					COLUMN_IN(i) <= std_logic_vector(signed(COLUMN_OUT(i)) - signed(STEP3_PROD(i)));

				end loop;

		end case;

	end process;

	MULT_ARRAY_IN1   <= STEP2_INPUT when (MULT_ARRAY_SEL = '1') else STEP3_INPUT;
	MULT_ARRAY_IN2   <= STEP1_DOTPROD when (MULT_ARRAY_SEL = '1') else TEMP_COLUMN_OUT;

	STEP2_PROD       <= MULT_ARRAY_OUT;
	STEP3_PROD       <= MULT_ARRAY_OUT;

	TEMP_COLUMN_IN   <= STEP2_PROD;

	COMPONENT_IN     <= S_AXIS_TDATA;

	M_DIV_AXIS_TDATA <= STEP2_DIV_IN (ACCUMULATOR_WIDTH - 1 downto ACCUMULATOR_WIDTH - OUT_DATA_WIDTH);
	
	
	--STEP2/3_INPUT ASSIGNMENT
	process (CLK, RESETN)
		variable counter : integer range 0 to NUM_BANDS + 3;
	begin
		if (rising_edge (CLK)) then
			if (RESETN = '0') then

				counter := 0;
				STEP2_INPUT <= (others => '0');
				STEP3_INPUT <= (others => '0');

			else

				--step2 input
				if (COUNT_ST2 = '1' and counter < NUM_BANDS - 1) then

					counter := counter + 1;
					STEP2_INPUT <= STEP1_DOTPROD (counter);

				else

					counter := 0;

				end if;

				--step3 input
				if (S_DIV_AXIS_TVALID = '1') then

					STEP3_INPUT <= S_DIV_AXIS_TDATA (CORRELATION_DATA_WIDTH - 1 downto 0);

				end if;
			end if;
		end if;

	end process;
	
---------------------------------------------------------------------------------	 
-- CONTROL LOGIC
---------------------------------------------------------------------------------		

	--TEMPORARY RESULTS MATRIX COLUMN COUNTER (NEEDED SEPARATELY).
	process (CLK, RESETN)
	begin
		if (rising_edge (CLK)) then
			if (RESETN = '0') then

				TEMP_COLUMN_NUMBER <= (others => '0');

			else

				if (TEMP_WRITE_ENABLE = '1' or STEP3_ENABLE = '1') then

					TEMP_COLUMN_NUMBER <= std_logic_vector(unsigned(TEMP_COLUMN_NUMBER) + 1);

				else

					TEMP_COLUMN_NUMBER <= (others => '0');

				end if;

			end if;
		end if;

	end process;
end BRAM;