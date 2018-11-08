
-------------------------------------------------------
-- Design Name : syn_fifo
-- File Name   : syn_fifo.vhd
-- Function    : Synchronous (single clock) FIFO
-- Coder       : Deepak Kumar Tala (Verilog)
-- Translator  : Alexander H Pham (VHDL)
-------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;

entity syn_fifo is
    generic (
        DATA_WIDTH :integer := 8;
        ADDR_WIDTH :integer := 4
    );
    port (
        clk      :in  std_logic; -- Clock input
        resetn   :in  std_logic; -- Active low
        data_in  :in  std_logic_vector (DATA_WIDTH-1 downto 0); -- Data input
        rd_en    :in  std_logic; -- Read enable
        wr_en    :in  std_logic; -- Write Enable
        data_out :out std_logic_vector (DATA_WIDTH-1 downto 0); -- Data Output
        empty    :out std_logic; -- FIFO empty
        full     :out std_logic  -- FIFO full
    );
end entity;
architecture rtl of syn_fifo is
    -------------Internal variables-------------------
    constant RAM_DEPTH :integer := 2**ADDR_WIDTH;

    signal wr_pointer   :std_logic_vector (ADDR_WIDTH-1 downto 0);
    signal rd_pointer   :std_logic_vector (ADDR_WIDTH-1 downto 0);
    signal status_cnt   :std_logic_vector (ADDR_WIDTH   downto 0);
    signal data_ram_in  :std_logic_vector (DATA_WIDTH-1 downto 0);
    signal data_ram_out :std_logic_vector (DATA_WIDTH-1 downto 0);
    
	signal we: std_logic_vector(0 downto 0);

	component BRAM is
	generic (
		SIZE : integer := 16;
		ADDR_WIDTH : integer := 4;
		COL_WIDTH : integer := 32;
		NB_COL : integer := 16);
	port (
		clk : in std_logic;
		we : in std_logic_vector(NB_COL-1 downto 0);
		r_addr : in std_logic_vector(ADDR_WIDTH-1 downto 0);
		w_addr : in std_logic_vector(ADDR_WIDTH-1 downto 0);
		din : in std_logic_vector(COL_WIDTH-1 downto 0);
		dout : out std_logic_vector (NB_COL*COL_WIDTH-1 downto 0)
		);
	
end component;
    
begin

 BRAM_FIFO_INST : BRAM
    generic map (
        COL_WIDTH => DATA_WIDTH,
        ADDR_WIDTH => ADDR_WIDTH,
		SIZE  => 2**ADDR_WIDTH,
		NB_COL => 1
    )
    port map (
		clk => CLK,
        w_addr => wr_pointer,    -- address_0 input
        din    => data_ram_in,   -- data_0 bi-directional
        we      => we,         -- write enable
        r_addr => rd_pointer,    -- address_q input
        dout    => data_ram_out  -- data_1 bi-directional
    );




    -------------Code Start---------------------------
    full  <= '1' when (status_cnt = (RAM_DEPTH-1)) else '0';
    empty <= '1' when (status_cnt = 0) else '0';
	we(0) <= wr_en;
	
    WRITE_POINTER:
    process (clk) begin
		if (rising_edge(clk)) then
			if (resetn = '0') then
				wr_pointer <= (others=>'0');
			else
				if (wr_en = '1') then
					wr_pointer <= wr_pointer + 1;
				end if;
			end if;
        end if;
    end process;
    
    READ_POINTER:
    process (clk) begin
		if (rising_edge(clk)) then
			if (resetn  = '0') then
				rd_pointer <= (others=>'0');
			else
				if (rd_en = '1') then
					rd_pointer <= rd_pointer + 1;
				end if;
			end if;
		end if;	
    end process;


    STATUS_COUNTER:
    process (clk) begin
		if (rising_edge(clk)) then
			if (resetn = '0') then
				status_cnt <= (others=>'0');
			
			else
				-- Read but no write.
				if ((rd_en = '1') and not(wr_en = '1') and (status_cnt /= 0)) then
					status_cnt <= status_cnt - 1;
				-- Write but no read.
				elsif ((wr_en = '1') and not (rd_en = '1') and (status_cnt /= RAM_DEPTH)) then
					status_cnt <= status_cnt + 1;
				end if;
			end if;
		end if;			
    end process;
    
    data_ram_in <= data_in;
	data_out <= data_ram_out;
   
    
end architecture;