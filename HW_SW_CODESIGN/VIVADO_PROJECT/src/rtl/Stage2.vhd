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
-- Revision: 10.04.2019.
-- Revision 
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE . STD_LOGIC_1164 . all;
use ieee . numeric_std . all;

Library UNISIM;
use UNISIM.vcomponents.all;

Library UNIMACRO;
use UNIMACRO.vcomponents.all;
-------------------------------------------------------------------------------------
-- Definition of Ports
-- CLK            : Synchronous clock
-- RESET_N        : System reset, active low
-- ALGORITHM_SELECT : select algorithm ACER, ASMF, ASMF2 
-- Stage2_Enable    	  : Data in is valid
-- Stage2_DataIn    	  : Data in 1 (from stage 1 x'R^-1)
-- Stage2_DataSRIn  	  : Data in 2 (from stage 1 s'R^-1x)
-- Stage2_DataShReg 	  : Data in from Shift Register
-- Stage2_DataValid 	  : Data out is valid
-- Stage2_DataOutP1         : Data Out (x'R^-1x)
-- Stage2_DataOutP2 	  : Data out 2 (s'R^-1x)^2

-------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Entity Section
------------------------------------------------------------------------------

entity Accelerator_Stage2 is
	generic (
		PIXEL_DATA_WIDTH  	  	: positive := 16;
		ST2IN_DATA_WIDTH  	  	: positive := 32;
		ST2OUT_DATA_WIDTH 	  	: positive := 52;
		ST2_ASMF2_DATA_SLIDER 	: positive := 72;
		ST2_ASMF2SR_DATA_SLIDER	: positive := 46;
 		NUM_BANDS             	: positive := 16
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

	signal ripple                    : std_logic;
	signal Stage2_DataOutP2_delayed  : std_logic_vector(ST2IN_DATA_WIDTH * 2 - 1 downto 0);
	signal Stage2_DataOutP2_delayed1 : std_logic_vector(ST2IN_DATA_WIDTH * 2 - 1 downto 0);
	signal Stage2_DataOutP2_delayed2 : std_logic_vector(ST2IN_DATA_WIDTH * 2 - 1 downto 0);
	signal Stage2_DataOutP2_delayed3 : std_logic_vector(ST2IN_DATA_WIDTH * 2 - 1 downto 0);
	signal Stage2_DataOutP2_delayed4 : std_logic_vector(ST2IN_DATA_WIDTH * 2 - 1 downto 0);

	signal Stage2_DataOutP1_temp : std_logic_vector(ST2OUT_DATA_WIDTH - 1 downto 0);
	signal Stage2_DataOutP2_temp : std_logic_vector(ST2IN_DATA_WIDTH * 2 - 1 downto 0);
	signal Stage2_xRx 			 : std_logic_vector(ST2OUT_DATA_WIDTH - 1 downto 0);
	signal Stage2_DataValid_temp : std_logic; 

	signal Stage2_ASMF2			 : std_logic_vector(ST2OUT_DATA_WIDTH*2 - 1 downto 0);
	signal Stage2_ASMF2_M_IN1	 : std_logic_vector(ST2OUT_DATA_WIDTH - 1 downto 0);
	signal Stage2_ASMF2_M_IN2	 : std_logic_vector(ST2OUT_DATA_WIDTH - 1 downto 0);
	signal Stage2_ASMF2_valid	 : std_logic;
	signal Stage2_ASMF2_valid_dly: std_logic;

	signal Stage2_ASMF2_SR		 : std_logic_vector(ST2IN_DATA_WIDTH*2 - 1 downto 0);
	signal Stage2_ASMF2_SR_dly	 : std_logic_vector(ST2IN_DATA_WIDTH*2 - 1 downto 0);
	signal Stage2_SR_M_IN1 		 : std_logic_vector(ST2IN_DATA_WIDTH - 1 downto 0);
	signal Stage2_SR_M_IN2 		 : std_logic_vector(ST2IN_DATA_WIDTH - 1 downto 0);
	signal Stage2_ASMF2_SR_M_IN1 : std_logic_vector(ST2IN_DATA_WIDTH - 1 downto 0);
	signal Stage2_ASMF2_SR_M_IN2 : std_logic_vector(ST2IN_DATA_WIDTH - 1 downto 0);

	signal RST: std_logic;


begin

	
	----------------------------------------------------------------------------------	 
	-- Signal Routing for different algorithms
	----------------------------------------------------------------------------------	

	Stage2_DataOutP1 <=	Stage2_DataOutP1_temp;
	

	process (ALGORITHM_SELECT,Stage2_Enable,Stage2_xRx,Stage2_DataValid_temp,Stage2_ASMF2_valid,Stage2_ASMF2) is
	begin

		case ALGORITHM_SELECT is

			--ACE-R
			when "00" =>
				Stage2_DataOutP1_temp <= Stage2_xRx;
				Stage2_DataValid 	  <= Stage2_DataValid_temp;

			--ASMF	
			when "01" =>
				Stage2_DataOutP1_temp <= std_logic_vector (abs(signed(Stage2_xRx)));
				Stage2_DataValid 	  <= Stage2_DataValid_temp;

			--ASMF with n=2
			when "10" =>
				Stage2_DataOutP1_temp <= Stage2_ASMF2(ST2_ASMF2_DATA_SLIDER downto ST2_ASMF2_DATA_SLIDER - ST2OUT_DATA_WIDTH + 1);  -- ST2OUT_DATA_WIDTH+20 downto 21);
				Stage2_DataValid 	  <= Stage2_ASMF2_valid;

			--CEM
			when "11" =>
				Stage2_DataOutP1_temp <= (others => '0');
				Stage2_DataValid 	  <= Stage2_Enable;	

			when others => 
				Stage2_DataOutP1_temp <= Stage2_xRx;
				Stage2_DataValid 	  <= Stage2_DataValid_temp;

		end case;

	end process;



	----------------------------------------------------------------------------------	 
	--ASMF 2
	----------------------------------------------------------------------------------	

	process (CLK) is
	begin
		if (rising_edge(CLK)) then
			if (RESETN = '0') then
				Stage2_ASMF2 			<= (others => '0');
				Stage2_ASMF2_M_IN1  	<= (others => '0');
				Stage2_ASMF2_M_IN2		<= (others => '0');
				Stage2_ASMF2_valid  	<= '0';
				Stage2_ASMF2_valid_dly 	<= '0';
			else

				if(Stage2_DataValid_temp = '1') then
					Stage2_ASMF2_M_IN1	<= Stage2_xRx;
					Stage2_ASMF2_M_IN2  <= Stage2_xRx;
					
				end if;
				Stage2_ASMF2 			<= std_logic_vector (signed (Stage2_ASMF2_M_IN1) * signed (Stage2_ASMF2_M_IN2));
				Stage2_ASMF2_valid_dly  <= Stage2_DataValid_temp;
				Stage2_ASMF2_valid 		<= Stage2_ASMF2_valid_dly;

			end if;
		end if;
	end process;



	----------------------------------------------------------------------------------	 
	-- Dot product controller & datapath to calculate x R^-1 x
	----------------------------------------------------------------------------------	

	dp_controller_inst : dp_controller
	generic map(
		V_LEN => NUM_BANDS
	)
	port map(
		clk     => CLK,
		en      => Stage2_Enable,
		reset_n => RESETN,
		p_rdy   => Stage2_DataValid_temp,
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
		p       => Stage2_xRx
	);




	------------------------------------------------------------------------------
	--GENERATE STAGE 2 sTR^-1x MULTIPLIER SQUARE
	------------------------------------------------------------------------------	

	Stage2_DataOutP2 		  <=	Stage2_DataOutP2_temp;

	process (CLK) is
	begin
		if (rising_edge(CLK)) then
			if (RESETN = '0') then
				Stage2_DataOutP2_temp     <= (others => '0');
				Stage2_DataOutP2_delayed  <= (others => '0');
				Stage2_DataOutP2_delayed1 <= (others => '0');
				Stage2_DataOutP2_delayed2 <= (others => '0');
				Stage2_DataOutP2_delayed3 <= (others => '0');
				Stage2_DataOutP2_delayed4 <= (others => '0');
				Stage2_ASMF2_SR			  <= (others => '0');
				Stage2_ASMF2_SR_dly		  <= (others => '0');
				Stage2_SR_M_IN1     	  <= (others => '0');
				Stage2_SR_M_IN2	  		  <= (others => '0');
				Stage2_ASMF2_SR_M_IN1     <= (others => '0');
				Stage2_ASMF2_SR_M_IN2	  <= (others => '0');
			else
				if (Stage2_Enable = '1') then


					case ALGORITHM_SELECT is

						--ACE-R
						when "00" =>
							Stage2_SR_M_IN1	  		  <= Stage2_DataSRIn;
							Stage2_SR_M_IN2     	  <= Stage2_DataSRIn;
			
							Stage2_DataOutP2_temp     <= Stage2_DataOutP2_delayed;
						
						--ASMF	
						when "01" =>
							Stage2_SR_M_IN1	  		  <= Stage2_DataSRIn;
							Stage2_SR_M_IN2     	  <= std_logic_vector(abs(signed(Stage2_DataSRIn)));
			
							Stage2_DataOutP2_temp     <= Stage2_DataOutP2_delayed;
							
						--ASMF with n=2
						when "10" =>

							Stage2_SR_M_IN1	  		  <= Stage2_DataSRIn;
							Stage2_SR_M_IN2     	  <= Stage2_DataSRIn;
							
							Stage2_ASMF2_SR_dly		  <= Stage2_DataOutP2_delayed;
							Stage2_ASMF2_SR_M_IN1     <= Stage2_DataSRIn;
							Stage2_ASMF2_SR_M_IN2     <= Stage2_ASMF2_SR_dly(ST2_ASMF2SR_DATA_SLIDER downto ST2_ASMF2SR_DATA_SLIDER - ST2IN_DATA_WIDTH + 1);  --(ST2IN_DATA_WIDTH*2 - 2 -16 downto ST2IN_DATA_WIDTH-1-16);
						
							Stage2_DataOutP2_delayed2 <= Stage2_DataOutP2_delayed1;
							Stage2_DataOutP2_delayed3 <= Stage2_DataOutP2_delayed2;
							Stage2_DataOutP2_temp     <= Stage2_DataOutP2_delayed3;
						
						--CEM
						when "11" =>
							Stage2_DataOutP2_temp 	  <= ((Stage2_DataSRIn) & (ST2IN_DATA_WIDTH - 1 downto 0   => '0'));

						when others => 
							Stage2_SR_M_IN1	  		  <= Stage2_DataSRIn;
							Stage2_SR_M_IN2     	  <= Stage2_DataSRIn;
							
							Stage2_DataOutP2_temp     <= Stage2_DataOutP2_delayed;
							
					end case;

				end if;

							Stage2_DataOutP2_delayed  <= std_logic_vector (signed (Stage2_SR_M_IN1) * signed (Stage2_SR_M_IN2));
							Stage2_DataOutP2_delayed1 <= std_logic_vector (signed (Stage2_ASMF2_SR_M_IN1) * signed (Stage2_ASMF2_SR_M_IN2));
							


			end if;
		end if;
	end process;





	
end Behavioral;