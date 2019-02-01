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


constant STEP1OUT_DATA_WIDTH : integer := integer(ceil(real(CORRELATION_DATA_WIDTH + PIXEL_DATA_WIDTH) + log2(real(NUM_BANDS))));


--CORRELATION MATRIX 
type CorrMatrixColumn is array (0 to NUM_BANDS-1) of std_logic_vector(CORRELATION_DATA_WIDTH-1 downto 0);
type CorrMatrixType is array (0 to NUM_BANDS-1) of CorrMatrixColumn;

constant vectorzero: std_logic_vector (CORRELATION_DATA_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(50000, CORRELATION_DATA_WIDTH));

signal CORR_MATRIX : CorrMatrixType := (others => (others => vectorzero));

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

begin

	
---------------------------------------------------------------------------------	 
	-- INPUT SLAVE CONTROL
---------------------------------------------------------------------------------

	S_AXIS_TREADY_temp <= '1';
	S_AXIS_TREADY <= S_AXIS_TREADY_temp;
	STEP1_ENABLE <= S_AXIS_TREADY_temp and S_AXIS_TVALID;
	PIXEL_DATA <= S_AXIS_TDATA;

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
	-- OUTPUT CONTROLLER
---------------------------------------------------------------------------------	 		

M_AXIS_TLAST <= '0';
	resize_TT : for i in 0 to NUM_BANDS - 1 generate
		STEP1_DATA_OUT_CUT (i) <= STEP1_DATA_OUT(i) (STEP1OUT_DATA_WIDTH-2 downto STEP1OUT_DATA_WIDTH-OUT_DATA_WIDTH-1);
	end generate;



	process (CLK, RESETN)
	begin
		if (rising_edge (CLK)) then
			if (RESETN = '0') then
				
				M_AXIS_TDATA <= (others => '0');
				M_AXIS_TVALID <= '0';
			
			else 
			
				if (STEP1_DATA_VALID = '1' and M_AXIS_TREADY = '1') then

					M_AXIS_TVALID <= '1';
					M_AXIS_TDATA <= STEP1_DATA_OUT_CUT(counter);
				
				else 
				
					M_AXIS_TVALID <= '0';
					
				end if;			
				
			end if;
		end if;

	end process;



end Behavioral;
