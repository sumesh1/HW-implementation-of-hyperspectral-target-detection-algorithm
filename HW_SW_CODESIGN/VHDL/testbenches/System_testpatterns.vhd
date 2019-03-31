----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08.10.2018 14:17:50
-- Design Name: 
-- Module Name: testbench - Behavioral
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
use IEEE.math_real.all;
use ieee.std_logic_unsigned.all;



entity VHDL_testbench is
	generic(
	PIXEL_DATA_WIDTH  : positive  := 16;
	BRAM_DATA_WIDTH   : positive  := 32;
	NUM_BANDS         : positive  := 16;
	OUT_DATA_WIDTH    : positive  := 32
	);
	
	port(
	CLK                : out std_logic;
	RESETN             : out std_logic;
	S_AXIS_TREADY      : in std_logic;
	S_AXIS_TDATA       : out std_logic_vector(PIXEL_DATA_WIDTH - 1 downto 0);
	S_AXIS_TLAST       : out std_logic;
	S_AXIS_TVALID      : out std_logic;
	M_AXIS_TVALID      : in std_logic;
	M_AXIS_TDATA       : in std_logic_vector(OUT_DATA_WIDTH - 1 downto 0);
	M_AXIS_TLAST       : in std_logic;
	M_AXIS_TREADY      : out std_logic;
	START			   : in std_logic
	);
	
	
	
end VHDL_testbench;

architecture Behavioral of VHDL_testbench is


	constant BRAM_ADDR_WIDTH  : integer  := integer(ceil(log2(real(NUM_BANDS))));
	constant BRAM_ROW_WIDTH   : positive := BRAM_DATA_WIDTH * (2 ** BRAM_ADDR_WIDTH);


	
	--signal matrix             : data_matrix (0 to NUM_BANDS - 1)(0 to NUM_BANDS - 1)(BRAM_DATA_WIDTH - 1 downto 0);
	--signal Stat_Vector        : data_array (0 to NUM_BANDS - 1)(BRAM_DATA_WIDTH - 1 downto 0);
	file file_VECTORS         : text;
	file file_RESULTS         : text;
	--file file_RESULTS2         : text;
	--file file_MATRIX          : text;

	--file file_STAT            : text;
	signal STOP_SIM : std_logic := '0';
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
	
		if( STOP_SIM = '0') then
			CLK <= '0';
			wait for 10 NS;
			CLK <= '1';
			wait for 10 NS;
		else
			wait;
		end if;
			
	end process;

	process (CLK)
	begin
		if(rising_edge(CLK)) then
			STOP_SIM <= M_AXIS_TLAST;	
		end if;
		
	end process;
	---------------------------------------------------------------------------------	 
	-- INPUT FILE HANDLING
	---------------------------------------------------------------------------------

	-- process is
		-- variable v_ILINE : line;
		-- variable v_data  : std_logic_vector(BRAM_DATA_WIDTH - 1 downto 0);
		-- variable v_SPACE : character;
		-- variable i       : integer;
		-- variable j       : integer;
	-- begin
		-- i := 0;
		-- j := 0;
		-- file_open(file_MATRIX, "matrix.txt", read_mode);

		-- while not endfile(file_MATRIX) loop
			-- readline(file_MATRIX, v_ILINE);
			-- hread(v_ILINE, v_data);

			-- -- Pass the variable to a signal to allow the ripple-carry to use it

			-- matrix(i)(j) <= v_data;

			-- if (j = NUM_BANDS - 1) then
				-- j := 0;
				-- i := i + 1;
			-- else
				-- j := j + 1;
			-- end if;
		-- end loop;

		-- file_close(file_MATRIX);
		-- wait;
	-- end process;
	
	
	-- process is
		-- variable v_ILINE : line;
		-- variable v_data  : std_logic_vector(BRAM_DATA_WIDTH - 1 downto 0);
		-- variable v_SPACE : character;
		-- variable i       : integer;

	-- begin
		-- i := 0;

		-- file_open(file_STAT, "stat.txt", read_mode);

		-- while not endfile(file_STAT) loop
			-- readline(file_STAT, v_ILINE);
			-- hread(v_ILINE, v_data);

			-- -- Pass the variable to a signal to allow the ripple-carry to use it

			-- Stat_Vector(i) <= v_data;
			-- i := i + 1;
		-- end loop;

		-- file_close(file_STAT);

		-- wait;
	-- end process;


	--file handling
	process is
		variable v_ILINE : line;
		variable v_data  : std_logic_vector(PIXEL_DATA_WIDTH - 1 downto 0);
		variable v_SPACE : character;
		variable temp    : std_logic_vector(31 downto 0);

	begin
		--count <= 0;
		S_AXIS_TLAST <= '0';
		file_open(file_VECTORS, "cube.txt", read_mode);
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
				
				--count <= count + 1;
				
				wait until CLK = '1' and CLK'event;

			end loop;
			
			S_AXIS_TLAST <= '1';

		file_close(file_VECTORS);
		
		wait until CLK = '1' and CLK'event;
		S_AXIS_TLAST <= '0';
		
		wait;
	end process;
	
	
	
	
	-- process (CLK) is
		-- variable k                : integer := 0;
		-- variable MATRIX_COLUMNtmp : std_logic_vector(BRAM_ROW_WIDTH - 1 downto 0);
	-- begin

		-- if (rising_edge(CLK)) then

			-- -- if (S_AXIS_TREADY = '1' and S_AXIS_TVALID = '1') then
			
				-- -- i := i + 1;
				
				-- -- if (i = NUM_BANDS) then
				
					-- -- i := 0;
					
				-- -- end if;
				
			-- -- end if;

			-- for k in 0 to NUM_BANDS - 1 loop
			
				-- MATRIX_COLUMNtmp(BRAM_DATA_WIDTH * (k + 1) - 1 downto BRAM_DATA_WIDTH * (k)) := matrix(conv_integer(ROW_SELECT))(k);
				
			-- end loop;
			
			-- MATRIX_COLUMN    <= MATRIX_COLUMNtmp;
			-- STATIC_VECTOR_SR <= Stat_Vector (conv_integer(ROW_SELECT));

		-- end if;
	-- end process;
	
	
	
	
	-- process (CLK) is

	-- begin

		-- if (rising_edge(CLK)) then
			-- if (RESETN = '0') then
				-- S_AXIS_TLAST <= '0';
				-- cnt          <= 0;
			-- elsif (S_AXIS_TREADY = '1' and S_AXIS_TVALID = '1') then
				-- if (cnt = 6) then
					-- S_AXIS_TLAST <= '1';
					-- cnt          <= cnt + 1;
				-- elsif (cnt = 7) then
					-- S_AXIS_TLAST <= '0';
					-- cnt          <= 0;
				-- else
					-- cnt <= cnt + 1;
				-- end if;
			-- end if;
		-- end if;

	-- end process;

	process is
	begin
		S_AXIS_TVALID <= '0';
		wait until RESETN = '1' and RESETN'event;
		wait until RESETN = '1' and RESETN'event;
		wait until CLK = '1' and CLK'event;
		
		wait until START = '1';
		S_AXIS_TVALID <= '1';
		-- wait until CLK = '1' and CLK'event;
		-- wait until CLK = '1' and CLK'event;
		
		-- wait until CLK = '1' and CLK'event;
		-- wait until CLK = '1' and CLK'event;
		-- S_AXIS_TVALID <= '0';
		-- wait until CLK = '1' and CLK'event;

		-- S_AXIS_TVALID <= '1';
		-- wait for 1500 NS;
		-- --wait until count = 300;
		-- S_AXIS_TVALID <= '0';
		-- wait for 200 NS;
		-- S_AXIS_TVALID<='0';
		-- wait for 180 NS;
		-- S_AXIS_TVALID<='1';
		-- wait for 520 NS;
		-- S_AXIS_TVALID<='0';
		-- wait for 1820 NS;
		-- S_AXIS_TVALID<='1';
		-- wait for 5250 NS;
		-- -- S_AXIS_TVALID<='0';
		wait;
	end process;

	process is
		variable v_OLINE : line;
		variable v_data  : std_logic_vector(OUT_DATA_WIDTH - 1 downto 0);
		variable v_SPACE : character;
		variable count   : integer;
	begin
		file_open(file_RESULTS, "C:\res.txt", write_mode);
		wait until RESETN = '1' and RESETN'event;
		wait until RESETN = '1' and RESETN'event;
		wait until CLK = '1' and CLK'event;
		count := 0;
		while (true) loop
			--report "The value of 'count' is " & integer'image(count);

			if (M_AXIS_TVALID = '1' and M_AXIS_TREADY = '1') then
				hwrite(v_OLINE, M_AXIS_TDATA, right, 8);
				writeline(file_RESULTS, v_OLINE);
				count := count + 1;
				-- else 
				-- wait until M_AXIS_TVALID = '1';
				-- hwrite(v_OLINE, M_AXIS_TDATA, right, 8);
				-- writeline(file_RESULTS, v_OLINE);
				-- count := count+1;
			end if;

			wait until CLK = '1' and CLK'event;
		end loop;

		file_close(file_RESULTS);
		wait;
	end process;
	
	-- process is
		-- variable v_OLINE : line;
		-- variable v_data  : std_logic_vector(OUT_DATA_WIDTH - 1 downto 0);
		-- variable v_SPACE : character;
		-- variable count   : integer;
	-- begin
		-- file_open(file_RESULTS2, "C:\Users\Dordije\Desktop\res2.txt", write_mode);
		-- wait until RESETN = '1' and RESETN'event;
		-- wait until RESETN = '1' and RESETN'event;
		-- wait until CLK = '1' and CLK'event;
		-- count := 0;
		-- while (true) loop
			-- --report "The value of 'count' is " & integer'image(count);

			-- if (M2_AXIS_TVALID = '1' and M2_AXIS_TREADY = '1') then
				-- hwrite(v_OLINE, M2_AXIS_TDATA, right, 8);
				-- writeline(file_RESULTS2, v_OLINE);
				-- count := count + 1;
				-- -- else 
				-- -- wait until M_AXIS_TVALID = '1';
				-- -- hwrite(v_OLINE, M_AXIS_TDATA, right, 8);
				-- -- writeline(file_RESULTS, v_OLINE);
				-- -- count := count+1;
			-- end if;

			-- wait until CLK = '1' and CLK'event;
		-- end loop;

		-- file_close(file_RESULTS2);
		-- wait;
	-- end process;
	-- process (CLK) is
	-- begin
	-- if(rising_edge(CLK)) then
	-- if(RESETN='0') then
	-- S_AXIS_TDATA <= (others=>'0');
	-- elsif (S_AXIS_TREADY = '1' and S_AXIS_TVALID='1') then
	-- S_AXIS_TDATA <= std_logic_vector(signed(S_AXIS_TDATA)+1);
	-- end if;
	-- end if;
	-- end process;

	process is
	begin
		M_AXIS_TREADY <= '0';
		wait until START = '1';
		M_AXIS_TREADY <= '1';
		-- M1_AXIS_TREADY <= '0';
		-- M2_AXIS_TREADY <= '0';
		-- wait for 1000 NS;
		-- M1_AXIS_TREADY <= '1';
		-- M2_AXIS_TREADY <= '1';
		-- wait for 3000 NS;
		-- M1_AXIS_TREADY <= '0';
		-- M2_AXIS_TREADY <= '0';
		-- wait for 4000 NS;
		-- M1_AXIS_TREADY <= '1';
		-- M2_AXIS_TREADY <= '1';
		-- wait for 550 NS;
		-- M1_AXIS_TREADY <= '0';
		-- M2_AXIS_TREADY <= '0';
		-- wait for 400 NS;
		-- M1_AXIS_TREADY <= '1';
		-- M2_AXIS_TREADY <= '1';
		wait;
	end process;



end Behavioral;