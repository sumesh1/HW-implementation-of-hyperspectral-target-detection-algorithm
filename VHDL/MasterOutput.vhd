----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09.10.2018 22:02:54
-- Design Name: 
-- Module Name: MasterOutput - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity MasterOutput is
	generic (
		DATA_WIDTH  : positive := 32;
		PACKET_SIZE : positive := 8
	);
	port (
		CLK           : in std_logic;
		RESETN        : in std_logic;
		DATA_IN       : in std_logic_vector(DATA_WIDTH - 1 downto 0);
		DATA_IN_VALID : in std_logic;
		M_AXIS_TVALID : out std_logic;
		M_AXIS_TDATA  : out std_logic_vector(DATA_WIDTH - 1 downto 0);
		M_AXIS_TLAST  : out std_logic;
		M_AXIS_TREADY : in std_logic;
		STOP_PIPELINE : out std_logic
	);
end MasterOutput;

architecture Behavioral of MasterOutput is

	type STATE_TYPE is (Idle, Write_Outputs);
	signal state : STATE_TYPE;

	type Output_Array_Type is array (0 to PACKET_SIZE - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);
	signal Output_Array          : Output_Array_Type;

	signal read_vectors          : natural range 0 to PACKET_SIZE - 1;
	signal written_vectors       : natural range 0 to PACKET_SIZE - 1;
	signal tlast                 : std_logic;
	signal Write_Outputs_Delayed : std_logic;
	signal Full                  : std_logic;
	signal stop_pipeline_temp    : std_logic;

begin
	M_AXIS_TLAST       <= tlast;
	M_AXIS_TVALID      <= '1' when (Write_Outputs_Delayed = '1') else '0';
	stop_pipeline_temp <= '1' when (FULL = '1' and M_AXIS_TREADY = '0') else '0';
	STOP_PIPELINE      <= stop_pipeline_temp;
	Input_Module : process (CLK) is
	begin
		if (rising_edge(CLK)) then
			if (RESETN = '0') then
				read_vectors <= 0;
				Full         <= '0';
				Output_Array <= (others => (others => '0'));

			else
				if (DATA_IN_VALID = '1' and stop_pipeline_temp = '0') then
					Output_Array (read_vectors) <= DATA_IN;
					if (read_vectors = PACKET_SIZE - 1) then
						read_vectors <= 0;
						Full         <= '1';
					else
						read_vectors <= read_vectors + 1;
					end if;
				end if;
				if (written_vectors = PACKET_SIZE - 1 and M_AXIS_TREADY = '1') then
					Full <= '0';
				end if;
			end if;
		end if;
	end process Input_Module;
	
	
	Output_Module : process (CLK) is
	begin
		if (rising_edge(CLK)) then
			if (RESETN = '0') then
				tlast                 <= '0';
				written_vectors       <= 0;
				Write_Outputs_Delayed <= '0';
				state                 <= Idle;
			else
				case state is
					when Idle =>
						Write_Outputs_Delayed <= '0';
						tlast                 <= '0';
						if (Full = '1') then
							state                 <= Write_Outputs;
							Write_Outputs_Delayed <= '1';
							M_AXIS_TDATA          <= Output_Array (written_vectors);
							written_vectors       <= written_vectors + 1;
						end if;

					when Write_Outputs =>
						Write_Outputs_Delayed <= '1';
						--M_AXIS_TDATA <= Output_Array (written_vectors);
						if (M_AXIS_TREADY = '1') then
							if (written_vectors = PACKET_SIZE - 1) then
								M_AXIS_TDATA    <= Output_Array (written_vectors);
								tlast           <= '1';
								written_vectors <= 0;
								state           <= Idle;
							else
								M_AXIS_TDATA    <= Output_Array (written_vectors);
								written_vectors <= written_vectors + 1;
							end if;
						end if;
				end case;
			end if;
		end if;


	end process Output_Module;


	-- Output_Module : process (CLK) is
	-- begin 
	-- if (rising_edge(CLK)) then     
	-- if (RESETN = '0') then               
	-- tlast        <= '0';
	-- written_vectors <= 0;
	-- Write_Outputs_Delayed <= '0';
	-- state <= Idle;
	-- read_vectors <= 0;
	-- Full <= '0';
	-- Output_Array <= (others =>(others=> '0'));
	-- else
	-- case state is
	-- when Idle =>
	-- Write_Outputs_Delayed <= '0';
	-- tlast<= '0';
	-- if (Full = '1') then
	-- state <= Write_Outputs;
	-- Write_Outputs_Delayed <= '1';
	-- M_AXIS_TDATA <= Output_Array (written_vectors);
	-- written_vectors <= written_vectors + 1;
	-- end if;

	-- when Write_Outputs =>
	-- Write_Outputs_Delayed <= '1';
	-- --M_AXIS_TDATA <= Output_Array (written_vectors);
	-- if (M_AXIS_TREADY = '1') then
	-- if( written_vectors = PACKET_SIZE-1) then
	-- M_AXIS_TDATA <= Output_Array (written_vectors);
	-- tlast <= '1';
	-- written_vectors <= 0;
	-- state <= Idle;
	-- else
	-- M_AXIS_TDATA <= Output_Array (written_vectors);
	-- written_vectors <= written_vectors + 1;
	-- end if;	
	-- end if; 
	-- end case;
	-- --INPUT PART
	-- if(DATA_IN_VALID = '1' and stop_pipeline_temp = '0') then
	-- Output_Array (read_vectors) <= DATA_IN;

	-- if (read_vectors = PACKET_SIZE-1) then
	-- read_vectors <= 0;
	-- Full <= '1';
	-- else 
	-- read_vectors <= read_vectors + 1;
	-- end if;
	-- end if;

	-- end if;
	-- end if;	


	-- end process Output_Module;

end architecture Behavioral;