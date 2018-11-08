-- Modified by: Dordije Boskovic
-- Single-Port BRAM with Byte-wide Write Enable
-- Source: ftp://ftp.xilinx.com/pub/documentation/misc/xstug_examples.zip
-- File: HDL_Coding_Techniques/rams/bytewrite_ram_1b.vhd
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity BRAM is
generic (
	SIZE : integer := 16;
	ADDR_WIDTH : integer := 4;
	COL_WIDTH : integer := 32;
	NB_COL : integer := 16
	);
port (
	clk : in std_logic;
	we : in std_logic_vector(NB_COL-1 downto 0);
	r_addr : in std_logic_vector(ADDR_WIDTH-1 downto 0);
	w_addr : in std_logic_vector(ADDR_WIDTH-1 downto 0);
	din : in std_logic_vector(COL_WIDTH-1 downto 0);
	dout : out std_logic_vector (NB_COL*COL_WIDTH-1 downto 0)
	);
end BRAM;

architecture behavioral of BRAM is

	type ram_type is array (SIZE-1 downto 0) of std_logic_vector (NB_COL*COL_WIDTH-1 downto 0);
	signal RAM : ram_type := (others => (others => '0'));

begin
	process (clk)
	begin
		if rising_edge(clk) then
			dout  <= RAM (conv_integer(r_addr));
			for i in 0 to NB_COL-1 loop
				if we(i) = '1' then
					RAM (conv_integer(w_addr))((i+1)*COL_WIDTH-1 downto i*COL_WIDTH) <= din;
				end if;
			end loop;
		end if;
	end process;

end behavioral;
