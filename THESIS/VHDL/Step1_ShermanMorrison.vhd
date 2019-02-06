----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01.02.2019 15:52:09
-- Design Name: 
-- Module Name: ShermanMorrison - Behavioral
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
use IEEE.NUMERIC_STD.all;
use IEEE.math_real.all;
-------------------------------------------------------------------------------------
-- Definition of Ports
-- CLK              	  : Synchronous clock
-- RESETN           	  : System reset, active low
-- S_AXIS_TREADY     	  : accelerator ready
-- S_AXIS_TDATA      	  : Data in 
-- S_AXIS_TLAST      	  : Last pixel component
-- S_AXIS_TVALID     	  : Data in valid
-- M_AXIS_TVALID    	  : Data out is valid
-- M_AXIS_TDATA          : Data Out 
-- M_AXIS_TLAST     	  : Data out last packet
-- M_AXIS_TREADY         : receiver ready
-------------------------------------------------------------------------------


entity ShermanMorrison is
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
		M_AXIS_TVALID   : out std_logic;
		M_AXIS_TDATA    : out std_logic_vector(OUT_DATA_WIDTH - 1 downto 0);
		M_AXIS_TLAST    : out std_logic;
		M_AXIS_TREADY   : in std_logic
	);
end ShermanMorrison;

architecture Behavioral of ShermanMorrison is


	component dp_controller is
		generic (
			V_LEN : integer 
		);
		port (
			clk     : in std_logic;
			en      : in std_logic;
			reset_n : in std_logic;
			p_rdy   : out std_logic;
			ripple  : out std_logic
		);
	end component;

	component dp_datapath is
		generic (
			bit_depth_1 : positive;
			bit_depth_2 : positive;
			P_BIT_WIDTH : positive 
		);
		port (
			clk     : in std_logic;
			en      : in std_logic;
			ripple  : in std_logic;
			reset_n : in std_logic;
			in_1    : in std_logic_vector (bit_depth_1 - 1 downto 0);
			in_2    : in std_logic_vector (bit_depth_2 - 1 downto 0);
			p       : out std_logic_vector (P_bit_width - 1 downto 0)
		);
	end component;
	
	
	component mult_controller is
		generic (
			PIPELINE_DEPTH : integer 
		);
		port (
			clk     : in std_logic;
			en      : in std_logic;
			reset_n : in std_logic;
			p_rdy   : out std_logic
		);
	end component;

	component mult_datapath is
		generic (
			bit_depth_1 : positive;
			bit_depth_2 : positive;
			P_BIT_WIDTH : positive 
		);
		port (
			clk     : in std_logic;
			en      : in std_logic;
			reset_n : in std_logic;
			in_1    : in std_logic_vector (bit_depth_1 - 1 downto 0);
			in_2    : in std_logic_vector (bit_depth_2 - 1 downto 0);
			p       : out std_logic_vector (P_bit_width - 1 downto 0)
		);
	end component;


constant STEP1OUT_DATA_WIDTH : integer := integer(ceil(real(CORRELATION_DATA_WIDTH + PIXEL_DATA_WIDTH) + log2(real(NUM_BANDS))));
constant STEP2OUT_DATA_WIDTH : integer := OUT_DATA_WIDTH;

--CORRELATION MATRIX 
type CorrMatrixColumn is array (0 to NUM_BANDS-1) of std_logic_vector(CORRELATION_DATA_WIDTH-1 downto 0);
type CorrMatrixType is array (0 to NUM_BANDS-1) of CorrMatrixColumn;

constant vectorzero: std_logic_vector (CORRELATION_DATA_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(0, CORRELATION_DATA_WIDTH));
constant vectornumb: std_logic_vector (CORRELATION_DATA_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(500000000, CORRELATION_DATA_WIDTH));

signal CORR_MATRIX : CorrMatrixType := (others => (others => vectornumb));


--STEP 1 
type Step1DataOutType is array (0 to NUM_BANDS-1) of std_logic_vector(STEP1OUT_DATA_WIDTH-1 downto 0);
type Step1DataOutType_CUT is array (0 to NUM_BANDS-1) of std_logic_vector(OUT_DATA_WIDTH-1 downto 0);


signal STEP1_ENABLE: std_logic;
signal RIPPLE: std_logic;
signal STEP1_DATA_VALID: std_logic;
signal CORR_MATRIX_COLUMN: CorrMatrixColumn;
signal PIXEL_DATA: std_logic_vector(PIXEL_DATA_WIDTH - 1 downto 0);
signal STEP1_DATA_OUT: Step1DataOutType;
signal STEP1_DATA_OUT_CUT: Step1DataOutType_CUT;

signal COLUMN_COUNTER: std_logic_vector(5 downto 0);
signal S_AXIS_TREADY_temp: std_logic;

--STEP 2

type PixelType is array (0 to NUM_BANDS-1) of std_logic_vector(PIXEL_DATA_WIDTH-1 downto 0);

signal TEMP_MATRIX : CorrMatrixType := (others => (others => vectorzero));
signal STEP2_ENABLE: std_logic;
signal STEP2_DATA_OUT: CorrMatrixColumn;
signal STEP2_DATA_IN: Step1DataOutType_CUT;
signal STEP2_DATA_IN2: std_logic_vector(OUT_DATA_WIDTH-1 downto 0);
signal STEP2_DATA_VALID: std_logic;

signal PIXEL_SAVING: PixelType ;
signal PIXEL_SAVED: PixelType ;
signal STEP2_DATA_OUT2: CorrMatrixColumn;
signal STEP2_ADD_DIV: std_logic_vector (integer(ceil(real(OUT_DATA_WIDTH) + log2(real(NUM_BANDS))))-1 downto 0);

--STEP 3

signal STEP3_ENABLE: std_logic;
signal STEP3_DATA_OUT: CorrMatrixColumn;
signal STEP3_DATA_IN: CorrMatrixColumn;
signal STEP3_DATA_IN2: std_logic_vector(OUT_DATA_WIDTH-1 downto 0);
signal STEP3_DATA_VALID: std_logic;
signal STEP2_DATA_VALID_dly: std_logic;

signal MATRIX_UPDATED: std_logic;

begin

	
---------------------------------------------------------------------------------	 
	-- INPUT SLAVE CONTROL
---------------------------------------------------------------------------------

	S_AXIS_TREADY_temp <= '1';
	S_AXIS_TREADY <= S_AXIS_TREADY_temp;
	STEP1_ENABLE <= S_AXIS_TREADY_temp and S_AXIS_TVALID;
	PIXEL_DATA <= S_AXIS_TDATA;
	
	process (CLK, RESETN)
	variable pixel_count: integer range 0 to NUM_BANDS := 0;
	begin
		if (rising_edge (CLK)) then
			if (RESETN = '0') then
				pixel_count := 0;
				PIXEL_SAVED  <= (others => (others => '0'));
				PIXEL_SAVING <= (others => (others => '0'));
				
			elsif (STEP1_ENABLE = '1') then

				PIXEL_SAVING(pixel_count) <= S_AXIS_TDATA;
				
				if(pixel_count = NUM_BANDS - 1) then
					pixel_count:= 0;
					PIXEL_SAVED <= PIXEL_SAVING;
					
				else 
					pixel_count := pixel_count + 1;
				
				end if;
				
				
				
				
			
			end if;
		end if;

	end process;

---------------------------------------------------------------------------------	 
	-- Dot product datapaths
---------------------------------------------------------------------------------
	GEN_DP : for I in 0 to NUM_BANDS - 1 generate
	begin
		dp_datapath_inst : dp_datapath
		generic map(
			bit_depth_1 => PIXEL_DATA_WIDTH,
			bit_depth_2 => CORRELATION_DATA_WIDTH,
			p_bit_width => STEP1OUT_DATA_WIDTH
		)
		port map(
			clk     => CLK,
			en      => STEP1_ENABLE,
			ripple  => RIPPLE,
			reset_n => RESETN,
			in_1    => PIXEL_DATA,
			in_2    => CORR_MATRIX_COLUMN(I),
			p       => STEP1_DATA_OUT(I)
		);
	end generate GEN_DP;
	
	
	
	
---------------------------------------------------------------------------------	 
	-- Dot product controller
---------------------------------------------------------------------------------	 

	dp_controller_inst : dp_controller
	generic map(
		V_LEN => NUM_BANDS
	)
	port map(
		clk     => CLK,
		en      => STEP1_ENABLE,
		reset_n => RESETN,
		p_rdy   => STEP1_DATA_VALID,
		ripple  => RIPPLE
	);
	
---------------------------------------------------------------------------------	 
	-- MATRIX CONTROLLER
---------------------------------------------------------------------------------	 	
	CORR_MATRIX_COLUMN <= CORR_MATRIX (to_integer(unsigned(COLUMN_COUNTER)));
	
	process (CLK, RESETN)
	begin
		if (rising_edge (CLK)) then
			if (RESETN = '0') then
				COLUMN_COUNTER <= (others => '0');
			elsif (STEP1_ENABLE = '1') then

				if (unsigned(COLUMN_COUNTER) = (NUM_BANDS-1)) then
					COLUMN_COUNTER <= (others => '0');
				else
					COLUMN_COUNTER <= std_logic_vector(unsigned(COLUMN_COUNTER) + 1);
				end if;
				
			end if;
		end if;

	end process;
	

	
---------------------------------------------------------------------------------	 
	-- STEP 2 MULTIPLIERS
---------------------------------------------------------------------------------
	GEN_MULT : for I in 0 to NUM_BANDS - 1 generate
	begin
		mult_datapath_inst : mult_datapath
		generic map(
			bit_depth_1 => OUT_DATA_WIDTH,
			bit_depth_2 => OUT_DATA_WIDTH,
			p_bit_width => STEP2OUT_DATA_WIDTH
		)
		port map(
			clk     => CLK,
			en      => STEP2_ENABLE,
			reset_n => RESETN,
			in_1    => STEP2_DATA_IN2,
			in_2    => STEP2_DATA_IN(I),
			p       => STEP2_DATA_OUT(I)
		);
	end generate GEN_MULT;
	

	GEN_MULT_FOR_DIV : for I in 0 to NUM_BANDS - 1 generate
	begin
		mult_datapath_inst_for_div : mult_datapath
		generic map(
			bit_depth_1 => OUT_DATA_WIDTH,
			bit_depth_2 => PIXEL_DATA_WIDTH,
			p_bit_width => STEP2OUT_DATA_WIDTH
		)
		port map(
			clk     => CLK,
			en      => STEP2_ENABLE,
			reset_n => RESETN,
			in_1    => STEP2_DATA_IN(I),
			in_2    => PIXEL_SAVED(I),
			p       => STEP2_DATA_OUT2(I)
		);
	end generate GEN_MULT_FOR_DIV;
	
---------------------------------------------------------------------------------	 
	-- STEP 2 CONTROL
---------------------------------------------------------------------------------	
		
	mult_controller_inst : mult_controller
	generic map(
		PIPELINE_DEPTH => 2
	)
	port map(
		clk     => CLK,
		en      => STEP2_ENABLE,
		reset_n => RESETN,
		p_rdy   => STEP2_DATA_VALID
	);	
			
	resize_TT : for i in 0 to NUM_BANDS - 1 generate
		STEP1_DATA_OUT_CUT (i) <= STEP1_DATA_OUT(i) (STEP1OUT_DATA_WIDTH-2 downto STEP1OUT_DATA_WIDTH-OUT_DATA_WIDTH-1);
	end generate;



	process (CLK, RESETN)
	begin
		if (rising_edge (CLK)) then
			if (RESETN = '0') then
				
				STEP2_DATA_IN <= (others => (others => '0'));
				STEP2_ENABLE <= '0';
			
			else 
			
				if (STEP1_DATA_VALID = '1') then

					STEP2_ENABLE <= '1';
					STEP2_DATA_IN <= STEP1_DATA_OUT_CUT;
					
				end if;			
				
			end if;
		end if;

	end process;
	
	process (CLK, RESETN)
	variable cntst2: integer range 0 to NUM_BANDS := 0 ;
	begin
		if (rising_edge (CLK)) then
			if (RESETN = '0') then
				
				STEP2_DATA_IN2 <= (others => '0');
				cntst2 := 0;
			
			else 
			
				if (STEP1_DATA_VALID = '1') then
						
					STEP2_DATA_IN2 <= STEP1_DATA_OUT_CUT (0);
					cntst2 := 1;	
					
				else
				
					STEP2_DATA_IN2 <= STEP2_DATA_IN (cntst2);
				
					cntst2 := cntst2 + 1;
				
					if( cntst2 = NUM_BANDS) then
						cntst2 := 0;
					end if;	
					
					
					
				end if;			
				
			end if;
		end if;

	end process;
	
---------------------------------------------------------------------------------	 
	-- STEP 2 MATRIX WRITE
---------------------------------------------------------------------------------		
	
	process (CLK, RESETN)
	variable tmpmatcnt: integer range 0 to NUM_BANDS := 0;
	begin
		if (rising_edge (CLK)) then
			if (RESETN = '0') then
				
				tmpmatcnt:= 0;
				
			else 
				if (STEP2_DATA_VALID = '1') then
				
					TEMP_MATRIX(tmpmatcnt) <= STEP2_DATA_OUT;
					
					tmpmatcnt:= tmpmatcnt + 1;
				
					if(tmpmatcnt = NUM_BANDS) then
						tmpmatcnt := 0;
					end if;	
					
				end if;
				
			end if;
		end if;

	end process;
	
---------------------------------------------------------------------------------	 
	-- STEP 2 ADD FOR DIV
---------------------------------------------------------------------------------
	
	process (CLK, RESETN)
		variable STEP2_ADD_DIV_temp: std_logic_vector (integer(ceil(real(OUT_DATA_WIDTH) + log2(real(NUM_BANDS))))-1 downto 0);
	begin
		if (rising_edge (CLK)) then
			if (RESETN = '0') then
				
				STEP2_ADD_DIV_temp := (others => '0');
				STEP2_ADD_DIV <= (others => '0');
				
			else 
				
				if (STEP2_DATA_VALID = '1') then 
				
					add_loop: for i in 0 to NUM_BANDS/4-1 loop
				
						STEP2_ADD_DIV_temp := std_logic_vector(resize(signed(STEP2_DATA_OUT2(i*4)), STEP2_ADD_DIV_temp'length)+signed(STEP2_DATA_OUT2(i*4+1))+signed(STEP2_DATA_OUT2(i*4+2)) + signed(STEP2_DATA_OUT2(i*4+3)));
				
					end loop add_loop;
					
					STEP2_ADD_DIV <= std_logic_vector(signed(STEP2_ADD_DIV_temp) + signed(STEP2_ADD_DIV));
				
				end if;
			end if;
		end if;

	end process;
	
	
---------------------------------------------------------------------------------	 
	-- STEP 3 MULTIPLIERS
---------------------------------------------------------------------------------	
	
	
	GEN_MULT_2 : for I in 0 to NUM_BANDS - 1 generate
	begin
		mult_2_datapath_inst : mult_datapath
		generic map(
			bit_depth_1 => OUT_DATA_WIDTH,
			bit_depth_2 => OUT_DATA_WIDTH,
			p_bit_width => STEP2OUT_DATA_WIDTH
		)
		port map(
			clk     => CLK,
			en      => STEP3_ENABLE,
			reset_n => RESETN,
			in_1    => vectornumb,  --just temporary instead of division result
			in_2    => STEP3_DATA_IN(I),
			p       => STEP3_DATA_OUT(I)
		);
	end generate GEN_MULT_2;
	

---------------------------------------------------------------------------------	 
	-- STEP 3 CONTROL
---------------------------------------------------------------------------------
	
	mult_2_controller_inst : mult_controller
	generic map(
		PIPELINE_DEPTH => 2
	)
	port map(
		clk     => CLK,
		en      => STEP3_ENABLE,
		reset_n => RESETN,
		p_rdy   => STEP3_DATA_VALID
	);	
	
	
	process (CLK, RESETN)
	variable cntst3: integer range 0 to NUM_BANDS := 0;
	begin
		if (rising_edge (CLK)) then
			if (RESETN = '0') then
				
				STEP2_DATA_VALID_dly <= '0';
				STEP3_DATA_IN <= (others => (others => '0'));
				STEP3_ENABLE <= '0';
				cntst3 := 0;
				
			else 
			

				if (STEP2_DATA_VALID_dly = '1') then
				
					STEP3_ENABLE <= '1';
					STEP3_DATA_IN <= TEMP_MATRIX (cntst3);
					
					cntst3:= cntst3 + 1;
				
					if(cntst3 = NUM_BANDS) then
						cntst3 := 0;
					end if;					
				
				end if;	
				
				STEP2_DATA_VALID_dly <= STEP2_DATA_VALID;
				
			end if;
		end if;

	end process;
	
---------------------------------------------------------------------------------	 
	-- STEP END 
---------------------------------------------------------------------------------	
	
	process (CLK, RESETN)
	variable finalcnt: integer range 0 to NUM_BANDS := 0;
	begin
		if (rising_edge (CLK)) then
			if (RESETN = '0') then
				
				 finalcnt := 0;
				MATRIX_UPDATED <= '0';
				
			else 
			

				if (STEP3_DATA_VALID = '1') then
					
					sub_loop: for i in 0 to NUM_BANDS-1 loop
				
						CORR_MATRIX  (finalcnt)(i) <= std_logic_vector( signed( CORR_MATRIX(finalcnt)(i)) - signed(  STEP3_DATA_OUT(i)));
						
					end loop sub_loop;
					
					finalcnt:= finalcnt + 1;
				
					if(finalcnt = NUM_BANDS) then
						MATRIX_UPDATED <= '1';
						finalcnt := 0;
					end if;		
					
				end if;	
				
				
			end if;
		end if;

	end process;
	
---------------------------------------------------------------------------------	 
	-- OUTPUT CONTROLLER
---------------------------------------------------------------------------------	 		

	M_AXIS_TLAST <= '0';

	process (CLK, RESETN)
	variable outcnt: integer range 0 to NUM_BANDS := 0;
	begin
		if (rising_edge (CLK)) then
			if (RESETN = '0') then
				
				M_AXIS_TDATA <= (others => '0');
				M_AXIS_TVALID <= '0';
				outcnt := 0;
			
			else 
			
				if (STEP3_DATA_VALID = '1' and M_AXIS_TREADY = '1') then

					M_AXIS_TVALID <= '1';
					M_AXIS_TDATA <= CORR_MATRIX (outcnt)(outcnt);
					
					outcnt:= outcnt + 1;
				
					if(outcnt = NUM_BANDS) then
						outcnt := 0;
					end if;		
				
				
				else 
				
					M_AXIS_TVALID <= '0';
					
				end if;			
				
			end if;
		end if;

	end process;


end Behavioral;
