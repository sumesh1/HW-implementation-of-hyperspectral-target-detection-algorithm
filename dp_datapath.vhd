library IEEE ;
use IEEE . STD_LOGIC_1164 . ALL ;
use ieee . numeric_std . all ;

entity dp_datapath is
generic (
	bit_depth_1 : positive := 12;
	bit_depth_2 : positive := 32;
	P_BIT_WIDTH : positive := 48
 );
 Port (
	 clk 		: in std_logic ;
	 en 		: in std_logic ;
	 ripple 	: in std_logic;
	 reset_n 	: in std_logic ;
	 in_1 		: in std_logic_vector ( bit_depth_1 -1 downto 0);
	 in_2 		: in std_logic_vector ( bit_depth_2 -1 downto 0);
	 p 		: out std_logic_vector ( P_bit_width -1 downto 0)
 );
 end dp_datapath;

 architecture Behavioral of dp_datapath is

 signal mul_r : std_logic_vector (( bit_depth_1 + bit_depth_2 - 1) downto 0);
 signal add_r : std_logic_vector (( P_BIT_WIDTH - 1) downto 0);

 begin

	p <= add_r;--std_logic_vector ( resize ( signed ( add_r ),p' length ));

 process (clk , reset_n )
 begin
	if ( rising_edge ( clk )) then
		if( reset_n = '0') then
			mul_r <= ( others => '0');
			add_r <= ( others => '0');
		elsif (en = '1') then
			-- Calculate multiplication between RAW and G.
			mul_r <= std_logic_vector ( signed ( in_1 )* signed ( in_2 ));
			if( ripple = '1') then
			-- Initially set accumulator reg to first multiplication between RAW and G
				add_r <= std_logic_vector (resize( signed ( mul_r ),add_r'length));
			else
			-- Accumulutator reg set to current multiplication between RAW and G added with acummulated result
				add_r <= std_logic_vector (signed ( mul_r )+ signed ( add_r ));--std_logic_vector ( resize ( signed ( mul_r )+ signed ( add_r ),add_r ' length ));
			end if;
		end if;
	end if;
	
 end process ;
 end Behavioral ;