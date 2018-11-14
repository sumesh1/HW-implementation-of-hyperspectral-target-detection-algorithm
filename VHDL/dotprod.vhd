library IEEE;
use IEEE . STD_LOGIC_1164 . all;
use ieee . numeric_std . all;

entity dot_product is
	generic (
		bit_depth_1 : positive := 12;
		bit_depth_2 : positive := 32;
		P_BIT_WIDTH : positive := 48
	);
	port (
		clk     : in std_logic;
		en      : in std_logic;
		reset_n : in std_logic;
		in_1    : in std_logic_vector (bit_depth_1 - 1 downto 0);
		in_2    : in std_logic_vector (bit_depth_2 - 1 downto 0);
		v_len   : in std_logic_vector (11 downto 0);
		p_rdy   : out std_logic;
		p       : out std_logic_vector (P_bit_width - 1 downto 0)
	);
end dot_product;

architecture Behavioral of dot_product is

	signal mul_r   : std_logic_vector ((bit_depth_1 + bit_depth_2 - 1) downto 0);
	signal add_r   : std_logic_vector ((P_BIT_WIDTH - 1) downto 0);
	signal counter : integer range 0 to 400;
	signal out_rdy : std_logic;

begin

	out_rdy <= '1' when ((counter = to_integer (unsigned (v_len)) + 1) and en = '1') else '0';
	p       <= add_r;--std_logic_vector ( resize ( signed ( add_r ),p' length ));
	p_rdy   <= out_rdy;

	process (clk, reset_n)
	begin
		if (rising_edge (clk)) then
			if (reset_n = '0') then
				mul_r   <= (others => '0');
				add_r   <= (others => '0');
				counter <= 0;
			elsif (en = '1') then
				counter <= counter + 1;
				-- Calculate multiplication between RAW and G.
				mul_r   <= std_logic_vector (signed (in_1) * signed (in_2));
				if (counter = (to_integer (unsigned (v_len)) + 1)) then
					-- Initially set accumulator reg to first multiplication
					-- between RAW and G
					add_r   <= std_logic_vector (resize(signed (mul_r), add_r'length));
					counter <= 2;
				else
					-- Accumulutator reg set to current multiplication
					-- between RAW and G added with acummulated result
					add_r <= std_logic_vector (signed (mul_r) + signed (add_r));--std_logic_vector ( resize ( signed ( mul_r )+ signed ( add_r ),add_r ' length ));
				end if;
			end if;
		end if;

	end process;
	
end Behavioral;