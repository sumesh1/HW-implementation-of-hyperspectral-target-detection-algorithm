
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

entity FIFOtestbench is
--  Port ( );
end FIFOtestbench;

architecture Behavioral of FIFOtestbench is

constant DATA_WIDTH :integer := 8;
constant ADDR_WIDTH :integer := 4;


 signal  clk      :std_logic; -- Clock input
 signal  resetn   :std_logic; -- Active low
 signal  data_in  :std_logic_vector (DATA_WIDTH-1 downto 0); -- Data input
 signal  rd_en    :std_logic; -- Read enable
 signal  wr_en    :std_logic; -- Write Enable
 signal  data_out :std_logic_vector (DATA_WIDTH-1 downto 0); -- Data Output
 signal  empty    :std_logic; -- FIFO empty
 signal  full     :std_logic;  -- FIFO full

begin

syn_fifo_inst: entity WORK.syn_fifo(rtl)
	generic map(
	DATA_WIDTH=>DATA_WIDTH,
	ADDR_WIDTH=> ADDR_WIDTH
		)
	port map
	(
		
		CLK			=>	 CLK,
 RESETN			=>     RESETN,
  data_in   =>     data_in ,
  rd_en      =>      rd_en   ,
  wr_en      =>      wr_en   ,
  data_out   =>      data_out,
  empty      =>      empty   ,
  full       =>      full    
 
	);




process is
begin
RESETN<='1';
wait for 1 NS;
RESETN<='0';
wait for 50 NS;
RESETN<='1';
wait;
end process;

process is
begin
CLK<='0';
wait for 10 NS;
CLK<='1';
wait for 10 NS;
end process;


process (CLK) is
begin
	if(rising_edge(CLK)) then
		if(RESETN='0') then
			data_in <= (others=>'0');
		elsif (wr_en='1') then
			data_in <= std_logic_vector(signed(data_in)+1);
		end if;
	end if;
end process;

process is
begin
wr_en<='0';
rd_en<='0';

wait for 100 NS;
wr_en<='1';
wait for 200 NS;
wr_en<= '0';
wait for 100 NS;
rd_en<= '1';
wait for 100 NS;
rd_en<= '0';
wait for 100 NS;
wr_en<= '1';
wait for 200 NS;
wr_en<= '0';
wait for 100 NS;
rd_en<= '1';
wait;
end process;


end Behavioral;
