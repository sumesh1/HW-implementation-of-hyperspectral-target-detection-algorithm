----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Dordije Boskovic
-- 
-- Create Date: 14.10.2018 10:15:03
-- Design Name: 
-- Module Name: Stage2 - Behavioral
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
use IEEE . STD_LOGIC_1164 . all;
use ieee . numeric_std . all;
-------------------------------------------------------------------------------------
-- Definition of Ports
-- CLK            : Synchronous clock
-- RESET_N        : System reset, active low
-- EN  			  : Data in is valid
-- IN_1  		  : Data in 1
-- IN_2   		  : Data in 2
-- V_LEN		  : Length of input array
-- P_RDY		  : Data out is valid
-- P		      : Data Out
-------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Entity Section
------------------------------------------------------------------------------

entity Accelerator_Stage2 is
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

end Accelerator_Stage2;

------------------------------------------------------------------------------
-- Architecture Section
------------------------------------------------------------------------------

architecture Behavioral of Accelerator_Stage2 is
	component dp_controller is
		generic (
			V_LEN : integer := 16
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
			bit_depth_1 : positive := 12;
			bit_depth_2 : positive := 32;
			P_BIT_WIDTH : positive := 48
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

	signal ripple                   : std_logic;
	signal Stage2_DataSROut_delayed : std_logic_vector(ST2IN_DATA_WIDTH * 2 - 1 downto 0);
	signal Stage2_DataSROut_delayed2 : std_logic_vector(ST2IN_DATA_WIDTH * 2 - 1 downto 0);

begin

	----------------------------------------------------------------------------------	 
	-- Dot product controller & datapath
	----------------------------------------------------------------------------------	

	dp_controller_inst : dp_controller
	generic map(
		V_LEN => NUM_BANDS
	)
	port map(
		clk     => CLK,
		en      => Stage2_Enable,
		reset_n => RESETN,
		p_rdy   => Stage2_DataValid,
		ripple  => ripple
	);

	dp_datapath_inst : dp_datapath
	generic map(
		bit_depth_1 => PIXEL_DATA_WIDTH,
		bit_depth_2 => ST2IN_DATA_WIDTH,
		p_bit_width => ST2OUT_DATA_WIDTH
	)
	port map(
		clk     => CLK,
		en      => Stage2_Enable,
		ripple  => ripple,
		reset_n => RESETN,
		in_1    => Stage2_DataShReg,
		in_2    => Stage2_DataIn,
		p       => Stage2_DataOut
	);
	------------------------------------------------------------------------------
	--GENERATE STAGE 2 sTR^-1x MULTIPLIER SQUARE
	------------------------------------------------------------------------------		 
	process (CLK) is
	begin
		if (rising_edge(CLK)) then
			if (RESETN = '0') then
				Stage2_DataSROut         <= (others         => '0');
				Stage2_DataSROut_delayed <= (others => '0');
				Stage2_DataSROut_delayed2 <= (others => '0');
			else
				if (Stage2_Enable = '1') then
					Stage2_DataSROut_delayed <= std_logic_vector (signed (Stage2_DataSRIn) * signed (Stage2_DataSRIn));
					Stage2_DataSROut_delayed2 <= Stage2_DataSROut_delayed;
					Stage2_DataSROut         <= Stage2_DataSROut_delayed2;
				end if;
			end if;
		end if;
	end process;
	
end Behavioral;