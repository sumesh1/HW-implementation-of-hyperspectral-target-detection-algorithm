----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01.02.2019 16:51:40
-- Design Name: 
-- Module Name: ShermanMorrison_testbench - Behavioral
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
use IEEE.NUMERIC_STD.all;
use STD.textio.all;
use ieee.std_logic_textio.all;  
library work;
use work.td_package.all; 

entity ShermanMorrison_testbench is

generic(
	PIXEL_DATA_WIDTH       : positive  := 16;
	CORRELATION_DATA_WIDTH : positive  := 32;
	NUM_BANDS              : positive  := 16;
	OUT_DATA_WIDTH         : positive  := 32
);

port(
	signal CLK                      : out std_logic;
	signal RESETN                   : out std_logic;
	signal S_AXIS_TREADY            : in std_logic;
	signal S_AXIS_TDATA             : out std_logic_vector(PIXEL_DATA_WIDTH - 1 downto 0);
	signal S_AXIS_TVALID            : out std_logic
);

end ShermanMorrison_testbench;

architecture Behavioral of ShermanMorrison_testbench is

	signal END_SIMULATION           : std_logic := '0';

	file file_CORRINIT              : text;
	file file_VECTORS               : text;
	file file_RESULTS               : text;
	file file_RESULTS2              : text;
	file file_RESULTS3              : text;

	--SIMULATION GLOBAL VARIABLES FOR EXTRACTION TO FILES

	--signal S_DIV_AXIS_TREADY : std_logic;
	--signal S_DIV_AXIS_TDATA  : std_logic_vector(39 downto 0);
	--signal S_DIV_AXIS_TLAST  : std_logic;
	--signal S_DIV_AXIS_TVALID : std_logic;

begin

		
	process is
	begin
		RESETN <= '1';
		wait for 1 NS;
		RESETN <= '0';
		wait for 50 NS;
		RESETN <= '1';
		wait;
	end process;

	process is
	begin

		if (END_SIMULATION = '0') then

			CLK <= '0';
			wait for 10 NS;
			CLK <= '1';
			wait for 10 NS;

		else
			wait;
		end if;

	end process;

	process is
	begin

		S_AXIS_TVALID      <= '0';
		--S_AXIS_DIVIDEND_tvalid <= '1';
		--S_AXIS_DIVIDEND_tdata  <= "000000000000000010000000000000000000000000000000"; --reciprocal
		
		wait until RESETN = '1' and RESETN'event;
		wait until RESETN = '1' and RESETN'event;
		wait until CLK = '1' and CLK'event;

		
		S_AXIS_TVALID <= '1';
		-- wait for 200 NS;
		-- S_AXIS_TVALID <= '0';
		-- wait for 300 NS;
		-- S_AXIS_TVALID <= '1';
		-- wait for 300 NS;
		-- S_AXIS_TVALID <= '0';
		-- wait for 500 NS;
		-- S_AXIS_TVALID <= '1';
		-- wait for 1200 NS;
		-- S_AXIS_TVALID <= '0';
		-- wait for 300 NS;
		-- S_AXIS_TVALID <= '1';
		wait;
	end process;


	---------------------------------------------------------------------------------	 
	-- INPUT FILE HANDLING
	---------------------------------------------------------------------------------	
	--pixel stream
	process is
		variable v_ILINE : line;
		variable v_data  : std_logic_vector(PIXEL_DATA_WIDTH - 1 downto 0);
		variable v_SPACE : character;
		variable count   : integer := 0;
		--variable temp    : std_logic_vector(31 downto 0);

	begin

		END_SIMULATION <= '0'; 

		--S_AXIS_TLAST <= '0';

		file_open(file_VECTORS, "D:\hymaphex.txt", read_mode);  

		wait until RESETN = '1' and RESETN'event;
		wait until RESETN = '1' and RESETN'event;
		S_AXIS_TDATA <= (others => '0');
		wait until CLK = '1' and CLK'event;
		wait until (S_AXIS_TREADY = '1' and S_AXIS_TVALID = '1');
		while not endfile(file_VECTORS) loop

			readline(file_VECTORS, v_ILINE);
			hread(v_ILINE, v_data);
			--report "The value of 'a' is " & integer'image(to_integer(unsigned(v_data)));
			--hread(v_ILINE, v_SPACE);           -- read in the space character
			--hread(v_ILINE, v_ADD_TERM2);

			-- Pass the variable to a signal to allow the ripple-carry to use it
			if (S_AXIS_TREADY = '1' and S_AXIS_TVALID = '1') then
				--temp := std_logic_vector (signed (v_data) * 2);
				--S_AXIS_TDATA <= temp (15 downto 0);
				S_AXIS_TDATA <= v_data;

			else

				wait until (S_AXIS_TREADY = '1' and S_AXIS_TVALID = '1');
				wait until CLK = '1' and CLK'event; 
				--temp := std_logic_vector (signed (v_data) * 2);
				--S_AXIS_TDATA <= temp (15 downto 0);
				S_AXIS_TDATA <= v_data;

			end if;

			count := count + 1;

			wait until CLK = '1' and CLK'event;

		end loop;

		--S_AXIS_TLAST <= '1';

		file_close(file_VECTORS);

		wait until CLK = '1' and CLK'event;
		--S_AXIS_TLAST <= '0';

		END_SIMULATION <= '1';
		wait;
	end process;
	
	
	 -- ---------------------------------------------------------------------------------	 
	 -- --RESULTS FILE HANDLING
	 -- ---------------------------------------------------------------------------------		
	 --step 1	
	 process is
		 variable v_OLINE : line;
		 variable v_data  : std_logic_vector(OUT_DATA_WIDTH - 1 downto 0);
		 variable v_SPACE : character;
		 variable count   : integer;
	 begin
		 file_open(file_RESULTS, "D:\SmallSAT\HW-implementation-of-hyperspectral-target-detection-algorithm\MATLAB\SM_FP_Testing\res_step1.txt", write_mode);

		 wait until RESETN = '1' and RESETN'event;
		 wait until RESETN = '1' and RESETN'event;
		 wait until CLK = '1' and CLK'event;
		 count := 0;
		 while (true) loop
			 --report "The value of 'count' is " & integer'image(count);

			 if (STEP1_RESULT_VALID = '1') then

				 for i in 0 to NUM_BANDS - 1 loop
					 hwrite(v_OLINE, STEP1_RESULT(i), right, 8);
				 end loop;

				 writeline(file_RESULTS, v_OLINE);
				 count := count + 1;

			 end if;

			 wait until STEP1_RESULT_VALID = '1' and STEP1_RESULT_VALID'event;
		 end loop;

		 file_close(file_RESULTS);
		 wait;
	 end process;

	 --step 2	
	 process is
		 variable v_OLINE : line;
		 variable v_data  : std_logic_vector(OUT_DATA_WIDTH - 1 downto 0);
		 variable v_SPACE : character;
		 variable count   : integer;
	 begin
		 file_open(file_RESULTS2, "D:\SmallSAT\HW-implementation-of-hyperspectral-target-detection-algorithm\MATLAB\SM_FP_Testing\res_step2.txt", write_mode);

		 wait until RESETN = '1' and RESETN'event;
		 wait until RESETN = '1' and RESETN'event;
		 wait until CLK = '1' and CLK'event;
		 count := 0;
		 while (true) loop
			 --report "The value of 'count' is " & integer'image(count);

			 if (STEP2_RESULT_VALID = '1') then

				 for i in 0 to NUM_BANDS - 1 loop
					 hwrite(v_OLINE, STEP2_RESULT(i), right, 8);
				 end loop;

				 writeline(file_RESULTS2, v_OLINE);
				 count := count + 1;

			 end if;

			 wait until CLK = '1' and CLK'event;
		 end loop;

		 file_close(file_RESULTS2);
		 wait;
	 end process;

	 --step 3	
	 process is
		 variable v_OLINE : line;
		 variable v_data  : std_logic_vector(OUT_DATA_WIDTH - 1 downto 0);
		 variable v_SPACE : character;
		 variable count   : integer;
	 begin
		 file_open(file_RESULTS3, "D:\SmallSAT\HW-implementation-of-hyperspectral-target-detection-algorithm\MATLAB\SM_FP_Testing\res_step3.txt", write_mode);

		 wait until RESETN = '1' and RESETN'event;
		 wait until RESETN = '1' and RESETN'event;
		 wait until CLK = '1' and CLK'event;
		 count := 0;
		 while (true) loop
			 --report "The value of 'count' is " & integer'image(count);

			 if (STEP3_RESULT_VALID = '1') then

				 for i in 0 to NUM_BANDS - 1 loop
					 hwrite(v_OLINE, STEP3_RESULT(i), right, 8);
				 end loop;

				 writeline(file_RESULTS3, v_OLINE);
				 count := count + 1;

			 end if;

			 wait until CLK = '1' and CLK'event;
		 end loop;

		 file_close(file_RESULTS3);
		 wait;
	 end process;
end Behavioral;