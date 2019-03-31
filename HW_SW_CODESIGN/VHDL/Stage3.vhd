----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Dordije Boskovic
-- 
-- Create Date: 14.10.2018 10:15:03
-- Design Name: 
-- Module Name: Stage3 - Behavioral
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
-- Stage2_Enable    	  : Data in is valid
-- Stage2_DataIn    	  : Data in 1 (from stage 1 x'R^-1)
-- Stage2_DataSRIn  	  : Data in 2 (from stage 1 s'R^-1x)
-- Stage2_DataShReg 	  : Data in from Shift Register
-- Stage2_DataValid 	  : Data out is valid
-- Stage2_DataOut         : Data Out (x'R^-1x)
-- Stage2_DataSROut 	  : Data out 2 (s'R^-1x)^2

-------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Entity Section
------------------------------------------------------------------------------

entity Accelerator_Stage3 is
	generic (
		PIXEL_DATA_WIDTH   : positive := 16;
		BRAM_DATA_WIDTH    : positive := 32;
		ST3IN_DATA_WIDTH   : positive := 32;
		ST3OUT_DATA1_WIDTH : positive := 52;
		NUM_BANDS          : positive := 16
	);
	port (
		CLK              : in std_logic;
		RESETN           : in std_logic;
		Stage3_Enable    : in std_logic;
		Stage3_DataIn1   : in std_logic_vector(ST3IN_DATA_WIDTH - 1 downto 0);
		Stage3_DataIn2   : in std_logic_vector(ST3IN_DATA_WIDTH - 1 downto 0);
		Stage3_DataSRS   : in std_logic_vector(BRAM_DATA_WIDTH  - 1 downto 0);
		Stage3_DataValid : out std_logic;
		Stage3_DataOut1  : out std_logic_vector(ST3OUT_DATA1_WIDTH - 1 downto 0);
		Stage3_DataOut2  : out std_logic_vector(ST3IN_DATA_WIDTH - 1 downto 0)
	);

end Accelerator_Stage3;

------------------------------------------------------------------------------
-- Architecture Section
------------------------------------------------------------------------------

architecture Behavioral of Accelerator_Stage3 is
	
	signal Stage3_DataSRS_XRX : std_logic_vector(ST3IN_DATA_WIDTH + BRAM_DATA_WIDTH - 1 downto 0);
	signal mult_in_1: std_logic_vector(ST3IN_DATA_WIDTH - 1 downto 0);
	signal mult_in_2: std_logic_vector(BRAM_DATA_WIDTH  - 1 downto 0);
	signal Stage3_DataValid_dly: std_logic;
	
	
begin

--Stage3_DataOut1 <= Stage3_DataSRS_XRX(ST3IN_DATA_WIDTH + BRAM_DATA_WIDTH - 2 downto ST3IN_DATA_WIDTH + BRAM_DATA_WIDTH - ST3OUT_DATA_WIDTH -1);
	Stage3_DataOut1 <= Stage3_DataSRS_XRX;
------------------------------------------------------------------------------
	--GENERATE STAGE 3 s'Rs * x'Rx MULTIPLIER 
------------------------------------------------------------------------------		 
	process (CLK) is
	begin
		if (rising_edge(CLK)) then
			if (RESETN = '0') then
				Stage3_DataSRS_XRX	<= (others => '0');
				mult_in_1			<= (others => '0');
				mult_in_2			<= (others => '0');
	
			else
			
			--pipelined multiplier
				if (Stage3_Enable = '1') then
					mult_in_1		<= Stage3_DataIn1;
					mult_in_2		<= Stage3_DataSRS;
				end if;
				
				if(Stage3_DataValid_dly = '1') then
					Stage3_DataSRS_XRX  <= std_logic_vector (signed (mult_in_1) * signed (mult_in_2));
				end if;
				
			end if;
		end if;
	end process;
	
------------------------------------------------------------------------------
	--DELAY INPUT 2 to match with input 1 multiplication, also just delay enable and form valid
------------------------------------------------------------------------------		 
	process (CLK) is
	begin
		if (rising_edge(CLK)) then
			if (RESETN = '0') then
				Stage3_DataOut2      <= (others => '0');
				Stage3_DataValid_dly <= '0';
				Stage3_DataValid	 <= '0';
	
			else
				if (Stage3_Enable = '1') then
					Stage3_DataOut2  <= Stage3_DataIn2;
				end if;
				
					Stage3_DataValid_dly <= Stage3_Enable;
					Stage3_DataValid 	 <= Stage3_DataValid_dly;
					
			end if;
		end if;
	end process;



	
end Behavioral;