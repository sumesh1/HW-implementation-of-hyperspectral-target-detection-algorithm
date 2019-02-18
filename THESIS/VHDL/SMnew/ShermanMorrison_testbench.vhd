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
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.td_package.all;


entity ShermanMorrison_testbench is

end ShermanMorrison_testbench;

architecture Behavioral of ShermanMorrison_testbench is

	constant PIXEL_DATA_WIDTH : positive := 16;
	constant CORRELATION_DATA_WIDTH : positive := 32;
	constant NUM_BANDS        : positive := 16;
	constant OUT_DATA_WIDTH   : positive := 32;

	signal CLK                : std_logic;
	signal RESETN             : std_logic;
	signal S_AXIS_TREADY      : std_logic;
	signal S_AXIS_TDATA       : std_logic_vector(PIXEL_DATA_WIDTH - 1 downto 0);
	--signal S_AXIS_TLAST       : std_logic;
	signal S_AXIS_TVALID      : std_logic;

	signal S_AXIS_DIVIDEND_tdata  : STD_LOGIC_VECTOR ( 7 downto 0 );
--	signal S_AXIS_DIVIDEND_tready : std_logic;
	signal S_AXIS_DIVIDEND_tvalid : std_logic;
	
	
	
--	signal	S_DIV_AXIS_TREADY : std_logic;
	--signal	S_DIV_AXIS_TDATA  :std_logic_vector(39 downto 0);
--	signal  S_DIV_AXIS_TLAST  : std_logic;
	--signal  S_DIV_AXIS_TVALID : std_logic;
	
--	signal OUTPUT_COLUMN	 : CorrMatrixColumn;
--	signal OUTPUT_VALID     :  std_logic;
--	signal OUTPUT_DATA :std_logic_vector(OUT_DATA_WIDTH-1 downto 0);
--	signal OUTPUT_VALID2     :  std_logic;
	
	
	-- signal M_AXIS_TVALID     : std_logic;
	-- signal M_AXIS_TDATA      : std_logic_vector(OUT_DATA_WIDTH - 1 downto 0);
	-- signal M_AXIS_TLAST      : std_logic;
	-- signal M_AXIS_TREADY     : std_logic;

begin


-- SMInstance : entity WORK.ShermanMorrisonTopLevel(BRAM)
		-- generic map(
			-- PIXEL_DATA_WIDTH => PIXEL_DATA_WIDTH,
			-- OUT_DATA_WIDTH   => OUT_DATA_WIDTH,
			-- CORRELATION_DATA_WIDTH  => CORRELATION_DATA_WIDTH,
			-- NUM_BANDS        => NUM_BANDS
		-- )
		-- port map
		-- (

			-- CLK              => CLK,
			-- RESETN           => RESETN,
			-- S_AXIS_TREADY    => S_AXIS_TREADY,
			-- S_AXIS_TDATA     => S_AXIS_TDATA,
			-- S_AXIS_TLAST     => S_AXIS_TLAST,
			-- S_AXIS_TVALID    => S_AXIS_TVALID,
			-- --OUTPUT_COLUMN   => OUTPUT_COLUMN,
			
			-- S_DIV_AXIS_TREADY    =>  S_DIV_AXIS_TREADY  ,
			-- S_DIV_AXIS_TDATA    =>   S_DIV_AXIS_TDATA   ,
			-- S_DIV_AXIS_TLAST    =>   S_DIV_AXIS_TLAST   ,
			-- S_DIV_AXIS_TVALID   =>   S_DIV_AXIS_TVALID  ,
			
			
			-- OUTPUT_VALID    =>   OUTPUT_VALID,
			-- OUTPUT_DATA   => OUTPUT_DATA,
			-- OUTPUT_VALID2    =>   OUTPUT_VALID2
		-- );

	SMWRAPPERINSTANCE: entity WORK.sys_wrapper(STRUCTURE)
  port map (
    
	CLK              => CLK,
	RESETN           => RESETN,
	S_AXIS_TREADY    => S_AXIS_TREADY,
	S_AXIS_TDATA     => S_AXIS_TDATA,
	--S_AXIS_TLAST     => S_AXIS_TLAST,
	S_AXIS_TVALID    => S_AXIS_TVALID,
    S_AXIS_DIVIDEND_tdata   =>  S_AXIS_DIVIDEND_tdata ,
   -- S_AXIS_DIVIDEND_tready  =>  S_AXIS_DIVIDEND_tready,
    S_AXIS_DIVIDEND_tvalid  =>  S_AXIS_DIVIDEND_tvalid

  );

		

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
		CLK <= '0';
		wait for 10 NS;
		CLK <= '1';
		wait for 10 NS;
	end process;
	
	process is
	begin
	
	S_AXIS_TVALID <= '1';
	--S_AXIS_TLAST  <= '0';
	S_AXIS_DIVIDEND_tvalid <= '1';
	S_AXIS_DIVIDEND_tdata <= "00000001";
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
	
	process is
	begin
		wait until CLK'event and CLK = '1';
		if (RESETN = '0') then
			S_AXIS_TDATA <= std_logic_vector(to_unsigned(25000, PIXEL_DATA_WIDTH));
		elsif ( (S_AXIS_TVALID and S_AXIS_TREADY) = '1') then
			S_AXIS_TDATA <= std_logic_vector(unsigned(S_AXIS_TDATA) + 10);
		end if;

	end process;
	
	


---------------------------------------------------------------------------------	 
	-- FILE HANDLING
---------------------------------------------------------------------------------	

	-- process is
		-- variable v_ILINE : line;
		-- variable v_data  : std_logic_vector(PIXEL_DATA_WIDTH - 1 downto 0);
		-- variable v_SPACE : character;
		-- variable temp    : std_logic_vector(31 downto 0);

	-- begin
		-- count <= 0;
		-- S_AXIS_TLAST <= '0';
		-- file_open(file_VECTORS, "cube.txt", read_mode);
		
		-- wait until RESETN = '1' and RESETN'event;
		-- wait until RESETN = '1' and RESETN'event;
		-- S_AXIS_TDATA <= (others => '0');
		-- wait until CLK = '1' and CLK'event;


		-- wait until (S_AXIS_TREADY = '1' and S_AXIS_TVALID = '1');
			-- while not endfile(file_VECTORS) loop
			
				-- readline(file_VECTORS, v_ILINE);
				-- hread(v_ILINE, v_data);
				-- --report "The value of 'a' is " & integer'image(to_integer(unsigned(v_data)));
				-- --hread(v_ILINE, v_SPACE);           -- read in the space character
				-- --hread(v_ILINE, v_ADD_TERM2);

				-- -- Pass the variable to a signal to allow the ripple-carry to use it
				-- if (S_AXIS_TREADY = '1' and S_AXIS_TVALID = '1') then
					-- --temp := std_logic_vector (signed (v_data) * 2);
					-- --S_AXIS_TDATA <= temp (15 downto 0);
					-- S_AXIS_TDATA <= v_data;

				-- else
				
					-- wait until (S_AXIS_TREADY = '1' and S_AXIS_TVALID = '1');
					-- wait until CLK = '1' and CLK'event;
					-- --temp := std_logic_vector (signed (v_data) * 2);
					-- --S_AXIS_TDATA <= temp (15 downto 0);
					-- S_AXIS_TDATA <= v_data;
					
				-- end if;
				
				-- count <= count + 1;
				
				-- wait until CLK = '1' and CLK'event;

			-- end loop;
			
			-- S_AXIS_TLAST <= '1';

		-- file_close(file_VECTORS);
		
		-- wait until CLK = '1' and CLK'event;
		-- S_AXIS_TLAST <= '0';
		
		-- wait;
	-- end process;
	
	
	
	


end Behavioral;
