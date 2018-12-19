----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Dordije Boskovic
-- 
-- Create Date: 14.10.2018 10:15:03
-- Design Name: 
-- Module Name: Accelerator - Behavioral
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.my_types_pkg.all;
-------------------------------------------------------------------------------------
--
--
-- Definition of Ports
-- CLK           : Synchronous clock
-- RESETN        : System reset, active low
-- S_AXIS_TREADY  : Ready to accept data in
-- S_AXIS_TDATA   :  Data in 
-- S_AXIS_TLAST   : Optional data in qualifier
-- S_AXIS_TVALID  : Data in is valid
-- DATA_OUT_VALID : Data out of accelerator is valid 
-- DATA1_OUT      : 
-- DATA2_OUT      : 
-- STOP_PIPELINE  : Stop pipeline signal from master output 
-- MATRIX_COLUMN  : full column of inverted correlation matrix
-- ROW_SELECT     : select column/row of inverted correlation matrix
-- STATIC_VECTOR_SR : sR^-1 vector element, also selected by ROW_SELECT signal

-------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Entity Section
------------------------------------------------------------------------------

entity Accelerator is
	generic (
		PIXEL_DATA_WIDTH  : positive := 18;
		BRAM_DATA_WIDTH   : positive := 25;
		ST1OUT_DATA_WIDTH : positive := 48;
		ST2IN_DATA_WIDTH  : positive := 25;
		ST2OUT_DATA_WIDTH : positive := 48;
		OUT_DATA_WIDTH    : positive := 32;
		NUM_BANDS         : positive := 16;
		BRAM_ADDR_WIDTH   : integer  := 4
	);
	port (
		CLK              : in std_logic;
		RESETN           : in std_logic;
		S_AXIS_TREADY    : out std_logic;
		S_AXIS_TDATA     : in std_logic_vector(PIXEL_DATA_WIDTH - 1 downto 0);
		S_AXIS_TLAST     : in std_logic;
		S_AXIS_TVALID    : in std_logic;
		DATA_OUT_VALID   : out std_logic;
		DATA1_OUT        : out std_logic_vector(OUT_DATA_WIDTH - 1 downto 0);
		DATA2_OUT        : out std_logic_vector(OUT_DATA_WIDTH - 1 downto 0);
		STOP_PIPELINE    : in std_logic;
		MATRIX_COLUMN    : in data_array (0 to NUM_BANDS - 1)(BRAM_DATA_WIDTH - 1 downto 0);
		ROW_SELECT       : out std_logic_vector (BRAM_ADDR_WIDTH - 1 downto 0);
		STATIC_VECTOR_SR : in std_logic_vector (BRAM_DATA_WIDTH - 1 downto 0)
	);
end Accelerator;

------------------------------------------------------------------------------
-- Architecture Section
------------------------------------------------------------------------------

architecture Behavioral of Accelerator is

	component Accelerator_Stage1 is
		generic (
			PIXEL_DATA_WIDTH  : positive := 16;
			BRAM_DATA_WIDTH   : positive := 32;
			ST1OUT_DATA_WIDTH : positive := 48;
			NUM_BANDS         : positive := 16
		);
		port (
			CLK                : in std_logic;
			RESETN             : in std_logic;
			Stage1_Enable      : in std_logic;
			Stage1_DataIn      : in std_logic_vector(PIXEL_DATA_WIDTH - 1 downto 0);
			Stage1_DataValid   : out std_logic;
			Stage1_DataOut     : out data_array (0 to NUM_BANDS - 1)(ST1OUT_DATA_WIDTH - 1 downto 0);
			Stage1_DataSROut   : out std_logic_vector (ST1OUT_DATA_WIDTH - 1 downto 0);
			CORR_MATRIX_COLUMN : in data_array (0 to NUM_BANDS - 1)(BRAM_DATA_WIDTH - 1 downto 0);
			STATIC_VECTOR_SR   : in std_logic_vector (BRAM_DATA_WIDTH - 1 downto 0)
		);
	end component;

	component Accelerator_Stage2 is
		generic (
			PIXEL_DATA_WIDTH  : positive := 16;
			ST2IN_DATA_WIDTH  : positive := 32;
			ST2OUT_DATA_WIDTH : positive := 48;
			NUM_BANDS         : positive := 8
		);
		port (
			CLK              : in std_logic;
			RESETN           : in std_logic;
			Stage2_Enable    : in std_logic;
			Stage2_DataIn    : in std_logic_vector(ST2IN_DATA_WIDTH - 1 downto 0);
			Stage2_DataSRIn  : in std_logic_vector(ST2IN_DATA_WIDTH - 1 downto 0);
			Stage2_DataShReg : in std_logic_vector(PIXEL_DATA_WIDTH - 1 downto 0);
			Stage2_DataValid : out std_logic;
			Stage2_DataOut   : out std_logic_vector(ST2OUT_DATA_WIDTH - 1 downto 0);
			Stage2_DataSROut : out std_logic_vector(ST2IN_DATA_WIDTH * 2 - 1 downto 0)
		);
	end component;
	--Data types
	-- type OutputsType is array (0 to NUM_BANDS-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
	type SHR is array (0 to NUM_BANDS + 1 + 1 ) of std_logic_vector(PIXEL_DATA_WIDTH - 1 downto 0);

	--Shift register
	signal ShReg              : SHR;

	--Stage 1 signals
	signal Stage1_DataIn	  : std_logic_vector (PIXEL_DATA_WIDTH - 1 downto 0);
	signal Stage1_Enable      : std_logic;
	signal Stage1_DataValid   : std_logic;
	signal Stage1_DataOut     : data_array (0 to NUM_BANDS - 1)(ST1OUT_DATA_WIDTH - 1 downto 0);
	signal Stage1_Repacked    : data_array (0 to NUM_BANDS - 1)(ST2IN_DATA_WIDTH - 1 downto 0);
	signal Stage1_DataSROut   : std_logic_vector (ST1OUT_DATA_WIDTH - 1 downto 0);
	
	--Stage 2 signals
	signal Stage2_Enable      : std_logic;
	signal Stage2_DataValid   : std_logic;
	signal Stage2_DataIn      : std_logic_vector(ST2IN_DATA_WIDTH - 1 downto 0);
	signal Stage2_DataIn_All  : data_array (0 to NUM_BANDS - 1)(ST2IN_DATA_WIDTH - 1 downto 0);
	signal Stage2_DataOut     : std_logic_vector(ST2OUT_DATA_WIDTH - 1 downto 0);
	signal Stage2_Count       : natural range 0 to NUM_BANDS - 1;
	signal Stage2_DataSRIn    : std_logic_vector(ST2IN_DATA_WIDTH - 1 downto 0);
	signal Stage2_DataSROut   : std_logic_vector(ST2IN_DATA_WIDTH * 2 - 1 downto 0);

	-- TLAST signal
	signal tlast              : std_logic;
	signal S_AXIS_TREADY_temp : std_logic;
	
	--STOPPED
	signal tstopped			  : std_logic;

	-- BRAM
	signal corr_row_sel       : std_logic_vector(BRAM_ADDR_WIDTH - 1 downto 0);
	-- signal stage1_out_static: std_logic_vector (DATA_WIDTH-1 downto 0);
	-- signal stage1_done_static: std_logic;
	-- signal stage2_in_data_static: std_logic_vector(DATA_WIDTH-1 downto 0);
	-- signal stage2_out_data_static: std_logic_vector(2*DATA_WIDTH-1 downto 0);
begin

	Accelerator_Stage1_inst : Accelerator_Stage1
	generic map
	(
		PIXEL_DATA_WIDTH  => PIXEL_DATA_WIDTH,
		BRAM_DATA_WIDTH   => BRAM_DATA_WIDTH,
		ST1OUT_DATA_WIDTH => ST1OUT_DATA_WIDTH,
		NUM_BANDS         => NUM_BANDS
	)
	port map
	(
		CLK                => CLK,
		RESETN             => RESETN,
		Stage1_Enable      => Stage1_Enable,
		Stage1_DataIn      => Stage1_DataIn,
		Stage1_DataValid   => Stage1_DataValid,
		Stage1_DataOut     => Stage1_DataOut,
		Stage1_DataSROut   => Stage1_DataSROut,
		CORR_MATRIX_COLUMN => MATRIX_COLUMN,
		STATIC_VECTOR_SR   => STATIC_VECTOR_SR
	);

	Accelerator_Stage2_inst : Accelerator_Stage2
	generic map
	(
		PIXEL_DATA_WIDTH  => PIXEL_DATA_WIDTH,
		ST2IN_DATA_WIDTH  => ST2IN_DATA_WIDTH,
		ST2OUT_DATA_WIDTH => ST2OUT_DATA_WIDTH,
		NUM_BANDS         => NUM_BANDS
	)
	port map
	(
		CLK              => CLK,
		RESETN           => RESETN,
		Stage2_Enable    => Stage2_Enable,
		Stage2_DataIn    => Stage2_DataIn,
		Stage2_DataSRIn  => Stage2_DataSRIn,
		Stage2_DataShReg => ShReg (NUM_BANDS + 2),
		Stage2_DataValid => Stage2_DataValid,
		Stage2_DataOut   => Stage2_DataOut,
		Stage2_DataSROut => Stage2_DataSROut

	);
	----------------------------------------------------------------------------------	 
	-- SHIFT REGISTER
	----------------------------------------------------------------------------------	
	Shift_Register : process (CLK) is
	begin
		if (rising_edge(CLK)) then
			if (RESETN = '0') then
				ShReg <= ((others => (others => '0')));
			else
			
				if (Stage1_Enable = '1') then
					ShReg <= Stage1_DataIn & ShReg (0 to NUM_BANDS + 1);
				end if;
				
			end if;
		end if;

	end process Shift_Register;

	----------------------------------------------------------------------------------	 
	--STAGE 2 CONTROL   
	----------------------------------------------------------------------------------
	repack : for i in 0 to NUM_BANDS - 1 generate
		--Stage1_Repacked (i) <= Stage1_DataOut (i)(ST1OUT_DATA_WIDTH-2-BRAM_ADDR_WIDTH downto ST1OUT_DATA_WIDTH-ST2IN_DATA_WIDTH-1-BRAM_ADDR_WIDTH);
		Stage1_Repacked (i) <= Stage1_DataOut (i)(ST1OUT_DATA_WIDTH-2 downto ST1OUT_DATA_WIDTH-ST2IN_DATA_WIDTH-1);
		--Stage1_Repacked (i) <= Stage1_DataOut (i)(41 downto 41 - ST2IN_DATA_WIDTH - 1 + 2);
	end generate;

	Stage2_DataIn <= Stage2_DataIn_All (Stage2_Count);

	Stage2 : process (CLK) is
		variable started : std_logic := '0';
	begin
		if (rising_edge(CLK)) then
			if (RESETN = '0') then
				Stage2_DataIn_All <= ((others => (others => '0')));
				Stage2_DataSRIn   <= (others => '0');
				Stage2_Count      <= 0;
				Stage2_Enable     <= '0';
				started := '0';
			else
				if (STOP_PIPELINE = '1') then
					Stage2_Enable <= '0';
				else
					if (Stage1_DataValid = '1') then
						Stage2_DataIn_All <= Stage1_Repacked;
						Stage2_DataSRIn   <= Stage1_DataSROut (ST1OUT_DATA_WIDTH - 2 downto ST1OUT_DATA_WIDTH - ST2IN_DATA_WIDTH - 1);
						Stage2_Count      <= 0;
						Stage2_Enable     <= '1';
						started := '1';
					elsif (Stage2_Count < NUM_BANDS - 1 and started = '1') then
						Stage2_Count  <= Stage2_Count + 1;
						Stage2_Enable <= '1';
					else
						started := '0';
						Stage2_Enable <= '0';
					end if;
				end if;
			end if;
		end if;

	end process Stage2;
	
	----------------------------------------------------------------------------------	 
	--AXI PROTOCOL    
	----------------------------------------------------------------------------------

	--Stage1_Enable      <= '0' when STOP_PIPELINE = '1' else (S_AXIS_TVALID and S_AXIS_TREADY_temp);

	S_AXIS_TREADY_temp <= '0' when STOP_PIPELINE = '1' else '1';
	S_AXIS_TREADY      <= S_AXIS_TREADY_temp;

	DATA_OUT_VALID     <= Stage2_DataValid;
	DATA1_OUT          <= Stage2_DataOut(ST2OUT_DATA_WIDTH - 2 downto ST2OUT_DATA_WIDTH - DATA1_OUT'length - 1);
	DATA2_OUT          <= Stage2_DataSROut (ST2IN_DATA_WIDTH*2 - 2 downto ST2IN_DATA_WIDTH*2 - DATA2_OUT'length - 1);---std_logic_vector(resize(signed(Stage2_DataSROut), DATA2_OUT'length));-
	
	----------------------------------------------------------------------------------	 
	--BRAM CORRELATION MATRIX ROW SELECTION  
	----------------------------------------------------------------------------------   

	ROW_SELECT         <= corr_row_sel;

	process (CLK) is
	begin
		if (rising_edge(CLK)) then
			
			if (RESETN = '0') then
				
				corr_row_sel 	<= (others => '0');		
				
			else
			
				if ((S_AXIS_TREADY_temp and S_AXIS_TVALID) = '1') then
				
						corr_row_sel <= std_logic_vector(unsigned(corr_row_sel)+1);
				
				end if;		
			
			end if;
			
		end if;

	end process;
	
	
	process (CLK) is
	begin
		if (rising_edge(CLK)) then
			
			if (RESETN = '0') then
			
				Stage1_DataIn <= (others => '0');
				Stage1_Enable	<= '0';
				
			else
			
				Stage1_DataIn <= S_AXIS_TDATA;
				
				if ( STOP_PIPELINE = '1') then
				
					Stage1_Enable <= '0';
					
				else
				
					Stage1_Enable <= (S_AXIS_TVALID and S_AXIS_TREADY_temp);
				
				end if;
				
			end if;
			
		end if;

	end process;
	
	
	
	
	
end architecture Behavioral;



