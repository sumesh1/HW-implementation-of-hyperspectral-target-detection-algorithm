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
-- Revision: 10.04.2019
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
-- STATIC_VECTOR_SR  : sR^-1 vector element, also selected by ROW_SELECT signal
-- STATIC_SRS		 : sR^-1s 
-- ALGORITHM_SELECT  : select algorithm, ACER, ASMF,ASMF2

-------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Entity Section
------------------------------------------------------------------------------

entity Accelerator is
	generic (
		PIXEL_DATA_WIDTH   : positive := 18;
		BRAM_DATA_WIDTH    : positive := 32;
		ST1OUT_DATA_WIDTH  : positive := 48;
		ST2IN_DATA_SLIDER  : positive := 32;
		ST2IN_DATA_WIDTH   : positive := 32;
		ST2_ASMF2_DATA_SLIDER 	: positive := 72;
		ST2_ASMF2SR_DATA_SLIDER	: positive := 46;
		ST2OUT_DATA_WIDTH  : positive := 48;
		ST3IN_DATA1_SLIDER : positive := 32;
		ST3IN_DATA2_SLIDER : positive := 32;
		ST3IN_DATA_WIDTH   : positive := 32;
		ST3OUT_DATA1_WIDTH : positive := 32;
		OUT_DATA_WIDTH     : positive := 32;
		OUT_DATA1_SLIDER   : positive := 32;
		OUT_DATA2_SLIDER   : positive := 32;
		NUM_BANDS          : positive := 16;
		BRAM_ADDR_WIDTH    : integer  := 4
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
		MATRIX_COLUMN    : in data_array_bram;
		ROW_SELECT       : out std_logic_vector (BRAM_ADDR_WIDTH - 1 downto 0);
		STATIC_VECTOR_SR : in std_logic_vector (BRAM_DATA_WIDTH - 1 downto 0);
		STATIC_SRS		 : in std_logic_vector (BRAM_DATA_WIDTH - 1 downto 0);
		ALGORITHM_SELECT : in std_logic_vector(1 downto 0)
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
			Stage1_DataOut     : out data_array_st1;
			Stage1_DataSROut   : out std_logic_vector (ST1OUT_DATA_WIDTH - 1 downto 0);
			CORR_MATRIX_COLUMN : in data_array_bram;
			STATIC_VECTOR_SR   : in std_logic_vector (BRAM_DATA_WIDTH - 1 downto 0)
		);
	end component;

	component Accelerator_Stage2 is
		generic (
			PIXEL_DATA_WIDTH  : positive := 16;
			ST2IN_DATA_WIDTH  : positive := 32;
			ST2OUT_DATA_WIDTH : positive := 48;
			ST2_ASMF2_DATA_SLIDER 	: positive := 72;
			ST2_ASMF2SR_DATA_SLIDER	: positive := 46;
			NUM_BANDS         : positive := 8
		);
		port (
			CLK              : in std_logic;
			RESETN           : in std_logic;
			ALGORITHM_SELECT : in std_logic_vector(1 downto 0);
			Stage2_Enable    : in std_logic;
			Stage2_DataIn    : in std_logic_vector(ST2IN_DATA_WIDTH - 1 downto 0);
			Stage2_DataSRIn  : in std_logic_vector(ST2IN_DATA_WIDTH - 1 downto 0);
			Stage2_DataShReg : in std_logic_vector(PIXEL_DATA_WIDTH - 1 downto 0);
			Stage2_DataValid : out std_logic;
			Stage2_DataOutP1 : out std_logic_vector(ST2OUT_DATA_WIDTH - 1 downto 0);
			Stage2_DataOutP2 : out std_logic_vector(ST2IN_DATA_WIDTH * 2 - 1 downto 0)
		);
	end component;
	
	component Accelerator_Stage3 is
		generic (
			PIXEL_DATA_WIDTH   : positive := 16;
			BRAM_DATA_WIDTH	   : positive := 32;
			ST3IN_DATA_WIDTH   : positive := 32;
			ST3OUT_DATA1_WIDTH : positive := 32;
			NUM_BANDS          : positive := 8
		);
		port (
			CLK              : in std_logic;
			RESETN           : in std_logic;
			Stage3_Enable    : in std_logic;
			Stage3_DataIn1   : in std_logic_vector(ST3IN_DATA_WIDTH - 1 downto 0);
			Stage3_DataIn2   : in std_logic_vector(ST3IN_DATA_WIDTH - 1 downto 0);
			Stage3_DataSRS   : in std_logic_vector(BRAM_DATA_WIDTH - 1 downto 0);
			Stage3_DataValid : out std_logic;
			Stage3_DataOut1  : out std_logic_vector(ST3OUT_DATA1_WIDTH - 1 downto 0);
			Stage3_DataOut2  : out std_logic_vector(ST3IN_DATA_WIDTH - 1 downto 0)
		);
	end component;
	
	
	
	
	--Data types
	type SHR is array (0 to NUM_BANDS + 1 + 1 ) of std_logic_vector(PIXEL_DATA_WIDTH - 1 downto 0);

	--Shift register
	signal ShReg              : SHR;

	--Stage 1 signals
	signal Stage1_DataIn	  : std_logic_vector (PIXEL_DATA_WIDTH - 1 downto 0);
	signal Stage1_Enable      : std_logic;
	signal Stage1_DataValid   : std_logic;
	signal Stage1_DataOut     : data_array_st1;
	signal Stage1_Repacked    : data_array_st1r;
	signal Stage1_DataSROut   : std_logic_vector (ST1OUT_DATA_WIDTH - 1 downto 0);
	
	--Stage 2 signals
	signal Stage2_Enable      : std_logic;
	signal Stage2_DataValid   : std_logic;
	signal Stage2_DataIn      : std_logic_vector(ST2IN_DATA_WIDTH - 1 downto 0);
	signal Stage2_DataIn_All  : data_array_st1r;
	signal Stage2_DataOut     : std_logic_vector(ST2OUT_DATA_WIDTH - 1 downto 0);
	signal Stage2_Count       : natural range 0 to NUM_BANDS - 1;
	signal Stage2_DataSRIn    : std_logic_vector(ST2IN_DATA_WIDTH - 1 downto 0);
	signal Stage2_DataSROut   : std_logic_vector(ST2IN_DATA_WIDTH * 2 - 1 downto 0);
	
	--Stage 3 signals
	signal Stage3_Enable    : std_logic;
	signal Stage3_DataIn1   : std_logic_vector(ST3IN_DATA_WIDTH - 1 downto 0);
	signal Stage3_DataIn2   : std_logic_vector(ST3IN_DATA_WIDTH - 1 downto 0);
	signal Stage3_DataSRS   : std_logic_vector(BRAM_DATA_WIDTH - 1 downto 0);
	signal Stage3_DataValid : std_logic;
	signal Stage3_DataOut1  : std_logic_vector(ST3OUT_DATA1_WIDTH - 1 downto 0);
	signal Stage3_DataOut2  : std_logic_vector(ST3IN_DATA_WIDTH - 1 downto 0);

	-- TLAST signal
	signal tlast              : std_logic;
	signal S_AXIS_TREADY_temp : std_logic;
	signal LAST_PROCESS		  : std_logic;
	
	--STOPPED
	signal tstopped			  : std_logic;

	-- BRAM
	signal corr_row_sel       : std_logic_vector(BRAM_ADDR_WIDTH - 1 downto 0);
	
	
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
		PIXEL_DATA_WIDTH  		=> PIXEL_DATA_WIDTH,
		ST2IN_DATA_WIDTH  		=> ST2IN_DATA_WIDTH,
		ST2OUT_DATA_WIDTH 		=> ST2OUT_DATA_WIDTH,
		ST2_ASMF2_DATA_SLIDER 	=> ST2_ASMF2_DATA_SLIDER ,
		ST2_ASMF2SR_DATA_SLIDER => ST2_ASMF2SR_DATA_SLIDER,
		NUM_BANDS        		=> NUM_BANDS
	)
	port map
	(
		CLK              => CLK,
		RESETN           => RESETN,
		ALGORITHM_SELECT => ALGORITHM_SELECT,
		Stage2_Enable    => Stage2_Enable,
		Stage2_DataIn    => Stage2_DataIn,
		Stage2_DataSRIn  => Stage2_DataSRIn,
		Stage2_DataShReg => ShReg (NUM_BANDS + 2),
		Stage2_DataValid => Stage2_DataValid,
		Stage2_DataOutP1 => Stage2_DataOut,
		Stage2_DataOutP2 => Stage2_DataSROut

	);
	
	Accelerator_Stage3_inst : Accelerator_Stage3
	generic map
	(
		PIXEL_DATA_WIDTH   => PIXEL_DATA_WIDTH,
		BRAM_DATA_WIDTH	   => BRAM_DATA_WIDTH,
		ST3IN_DATA_WIDTH   => ST2IN_DATA_WIDTH,
		ST3OUT_DATA1_WIDTH => ST3OUT_DATA1_WIDTH,
		NUM_BANDS          => NUM_BANDS
	)
	port map
	(
		CLK              => CLK,
		RESETN           => RESETN,
		Stage3_Enable    => Stage3_Enable,   
		Stage3_DataIn1   => Stage3_DataIn1,  
		Stage3_DataIn2   => Stage3_DataIn2 , 
		Stage3_DataSRS   => Stage3_DataSRS,  
		Stage3_DataValid => Stage3_DataValid,
		Stage3_DataOut1  => Stage3_DataOut1 ,
		Stage3_DataOut2  => Stage3_DataOut2 

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
			
				if (Stage1_Enable = '1'  or LAST_PROCESS = '1') then
					ShReg <= Stage1_DataIn & ShReg (0 to NUM_BANDS + 1);
				end if;
				
			end if;
		end if;

	end process Shift_Register;

	----------------------------------------------------------------------------------	 
	--STAGE 2 CONTROL   
	----------------------------------------------------------------------------------
	repack : for i in 0 to NUM_BANDS - 1 generate
		Stage1_Repacked (i) <= Stage1_DataOut (i)(ST2IN_DATA_SLIDER downto ST2IN_DATA_SLIDER - ST2IN_DATA_WIDTH + 1);
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
						Stage2_DataSRIn   <= Stage1_DataSROut (ST2IN_DATA_SLIDER downto ST2IN_DATA_SLIDER - ST2IN_DATA_WIDTH + 1);
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
	
	--------------------------------------------------------------------------------	 
	--STAGE 3 Signals   
	----------------------------------------------------------------------------------
	
	Stage3_Enable    <= Stage2_DataValid;
	
	Stage3_DataIn1   <= Stage2_DataOut   (ST3IN_DATA1_SLIDER downto ST3IN_DATA1_SLIDER - ST3IN_DATA_WIDTH + 1);
	Stage3_DataIn2   <= Stage2_DataSROut (ST3IN_DATA2_SLIDER downto ST3IN_DATA2_SLIDER - ST3IN_DATA_WIDTH + 1);
	Stage3_DataSRS   <= STATIC_SRS;

	
	----------------------------------------------------------------------------------	 
	--AXI PROTOCOL    
	----------------------------------------------------------------------------------

	
	S_AXIS_TREADY_temp <= '0' when STOP_PIPELINE = '1' else '1';
	S_AXIS_TREADY      <= S_AXIS_TREADY_temp;

	DATA_OUT_VALID 	   <= Stage1_DataValid when ALGORITHM_SELECT = "11" else Stage3_DataValid;
	
--truncate here OUT_DATA_SLIDER OUT_DATA_WIDTH
--DIFFERENT OUTPUTS FOR CEM ALGORITHM AND ACER, ASMF on the other side
--CEM OUTPUTS ARE INVERTED, MAYBE CHANGE LATER
	DATA1_OUT 		   <= Stage1_DataSROut (ST2IN_DATA_SLIDER downto ST2IN_DATA_SLIDER - ST2IN_DATA_WIDTH + 1) when ALGORITHM_SELECT = "11" 
						  else Stage3_DataOut1 (OUT_DATA1_SLIDER downto OUT_DATA1_SLIDER - OUT_DATA_WIDTH + 1);

	DATA2_OUT	 	   <= std_logic_vector(resize(signed(STATIC_SRS), DATA2_OUT'length)) when ALGORITHM_SELECT = "11" 
						  else Stage3_DataOut2 (OUT_DATA2_SLIDER downto OUT_DATA2_SLIDER - OUT_DATA_WIDTH + 1);

	
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
			
				if (((S_AXIS_TREADY_temp and S_AXIS_TVALID) or LAST_PROCESS ) = '1') then
				
						corr_row_sel <= std_logic_vector(unsigned(corr_row_sel) + 1);
				
				end if;		
			
			end if;
			
		end if;

	end process;
	
	
	process (CLK) is
	variable counter : integer := 0;
	begin
		if (rising_edge(CLK)) then
			
			if (RESETN = '0') then
			
				Stage1_DataIn <= (others => '0');
				Stage1_Enable <= '0';
				LAST_PROCESS  <= '0';
				counter  	  := 0; 
				
				
			else
			
				Stage1_DataIn <= S_AXIS_TDATA;
				
				if ( STOP_PIPELINE = '1') then
				
					Stage1_Enable <= '0';
					counter := 0;

				elsif(LAST_PROCESS = '1' and counter < 2*NUM_BANDS ) then
					
					Stage1_Enable <= '1';
					counter := counter + 1;

				else

					LAST_PROCESS <= '0';
					Stage1_Enable <= (S_AXIS_TVALID and S_AXIS_TREADY_temp);
					counter := 0;
				
				end if;

				if (S_AXIS_TLAST = '1') then 

					Stage1_Enable <= '1';
					LAST_PROCESS  <= '1';
					counter := 0;

				end if;
				
			end if;
			
		end if;

	end process;
	
	
	
	
	
end architecture Behavioral;



