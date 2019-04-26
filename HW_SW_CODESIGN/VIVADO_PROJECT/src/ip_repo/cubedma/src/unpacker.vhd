library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;

library xpm;
use xpm.vcomponents.all;

entity unpacker is
  generic (
    C_IN_DATA_WIDTH  : integer := 64;
    C_OUT_DATA_WIDTH : integer := 64;
    C_COMP_WIDTH     : integer := 8;
    C_NUM_COMP       : integer := 8;
    C_NUM_CTRL_BITS  : integer := 2
    );
  port (
    clk     : in std_logic;
    aresetn : in std_logic;

    config_data  : in  std_logic_vector(11 downto 0);
    config_wr    : in  std_logic;
    config_ready : out std_logic;

    in_tdata  : in  std_logic_vector(C_IN_DATA_WIDTH-1 downto 0);
    in_tvalid : in  std_logic;
    in_tready : out std_logic;
    in_tlast  : in  std_logic;

    out_tdata  : out std_logic_vector(C_OUT_DATA_WIDTH-1 downto 0);
    out_ctrl   : out std_logic_vector(C_NUM_COMP * C_NUM_CTRL_BITS - 1 downto 0);
    out_tvalid : out std_logic;
    out_tready : in  std_logic;
    out_tlast  : out std_logic
    );
end unpacker;

architecture Behavioral of unpacker is
  constant C_COMP_PER_WORD      : integer := C_IN_DATA_WIDTH / C_COMP_WIDTH;
  constant C_TO_BUFFER_NUM_COMP : integer := integer(ceil(real(C_IN_DATA_WIDTH)/real(C_COMP_WIDTH)));
  constant C_TO_BUFFER_WIDTH    : integer := C_TO_BUFFER_NUM_COMP * C_COMP_WIDTH;

  signal in_delay_tdata     : std_logic_vector(C_IN_DATA_WIDTH-1 downto 0);
  signal in_delay_tvalid    : std_logic;
  signal in_delay_tready    : std_logic;
  signal in_delay_tlast     : std_logic;
  signal in_delay_handshake : std_logic;

  signal to_buffer_tdata        : std_logic_vector(C_TO_BUFFER_WIDTH-1 downto 0);
  signal to_buffer_tvalid       : std_logic;
  signal to_buffer_tready       : std_logic;
  signal to_buffer_tlast        : std_logic;
  signal to_buffer_num_valid    : integer range 0 to C_TO_BUFFER_NUM_COMP-1;
  signal to_buffer_ctrl_signals : std_logic_vector(C_NUM_CTRL_BITS - 1 downto 0);

  signal to_buffer_annotated   : std_logic_vector((C_COMP_WIDTH + C_NUM_CTRL_BITS) * C_TO_BUFFER_NUM_COMP - 1 downto 0);
  signal from_buffer_annotated : std_logic_vector((C_COMP_WIDTH + C_NUM_CTRL_BITS) * C_NUM_COMP - 1 downto 0);

  signal in_ready     : std_logic;
  signal in_handshake : std_logic;

  signal out_num_valid   : integer range 0 to C_NUM_COMP;
  signal from_buffer_num : integer range 0 to C_NUM_COMP;

  type config_t is record
    last               : std_logic;
    offset             : std_logic_vector(1 downto 0);
    num_last           : std_logic_vector(4 downto 0);
    truncate_last_word : std_logic;
    last_block_in_row  : std_logic;
    last_pix_in_block  : std_logic;
    last_row_of_blocks : std_logic;
  end record;

  constant CONFIG_INIT : config_t := (
    last               => '0',
    offset             => "00",
    num_last           => "00000",
    truncate_last_word => '0',
    last_block_in_row  => '0',
    last_pix_in_block  => '0',
    last_row_of_blocks => '0'
    );

  type config_arr_t is array (0 to 2) of config_t;
  signal config_regs : config_arr_t;

  signal transfer_complete : std_logic;
begin
  in_handshake <= in_ready and in_tvalid;
  in_tready    <= in_ready;

  -- Configuration FIFO
  b_config_fifo : block is
    signal reset     : std_logic;
    signal fifo_rd   : std_logic;
    signal fifo_out  : std_logic_vector(11 downto 0);
    signal fifo_full : std_logic;
  begin
    reset <= not aresetn;

    config_regs(0).last_block_in_row  <= fifo_out(11);
    config_regs(0).last_pix_in_block  <= fifo_out(10);
    config_regs(0).last_row_of_blocks <= fifo_out(9);
    config_regs(0).truncate_last_word <= fifo_out(8);
    config_regs(0).num_last           <= fifo_out(7 downto 3);
    config_regs(0).offset             <= fifo_out(2 downto 1);
    config_regs(0).last               <= fifo_out(0);

    config_ready <= not fifo_full;

    i_fifo : xpm_fifo_sync
      generic map (
        FIFO_MEMORY_TYPE    => "auto",
        ECC_MODE            => "no_ecc",
        FIFO_WRITE_DEPTH    => 128,
        WRITE_DATA_WIDTH    => 12,
        WR_DATA_COUNT_WIDTH => 8,
        PROG_FULL_THRESH    => 120,
        FULL_RESET_VALUE    => 0,
        READ_MODE           => "std",
        FIFO_READ_LATENCY   => 1,
        READ_DATA_WIDTH     => 12,
        RD_DATA_COUNT_WIDTH => 8,
        PROG_EMPTY_THRESH   => 10,
        DOUT_RESET_VALUE    => "0",
        WAKEUP_TIME         => 0
        )
      port map (
        rst           => reset,
        wr_clk        => clk,
        wr_en         => config_wr,
        din           => config_data,
        full          => fifo_full,
        overflow      => open,
        wr_rst_busy   => open,
        rd_en         => fifo_rd,
        dout          => fifo_out,
        empty         => open,
        underflow     => open,
        rd_rst_busy   => open,
        prog_full     => open,
        wr_data_count => open,
        prog_empty    => open,
        rd_data_count => open,
        sleep         => '0',
        injectsbiterr => '0',
        injectdbiterr => '0',
        sbiterr       => open,
        dbiterr       => open
        );

    process (clk)
    begin
      if (rising_edge(clk)) then
        if (aresetn = '0') then
          transfer_complete <= '1';
        else
          if (in_handshake = '1' and in_tlast = '1') then
            transfer_complete <= '1';
          elsif (in_handshake = '1') then
            transfer_complete <= '0';
          end if;
        end if;
      end if;
    end process;

    fifo_rd <= in_handshake and transfer_complete;
  end block b_config_fifo;

  -- Delay the stream to align with FIFO
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (aresetn = '0') then
        in_delay_tdata  <= (others => '0');
        in_delay_tvalid <= '0';
        in_delay_tlast  <= '0';
      else
        if (in_handshake = '1') then
          in_delay_tdata  <= in_tdata;
          in_delay_tvalid <= in_tvalid;
          in_delay_tlast  <= in_tlast;
        elsif (in_delay_handshake = '1') then
          in_delay_tvalid <= '0';
        end if;
      end if;
    end if;
  end process;

  in_delay_handshake <= in_delay_tvalid and in_delay_tready;

  process (in_delay_tvalid, in_delay_handshake)
  begin
    in_ready <= '0';
    if (in_delay_tvalid = '0' or in_delay_handshake = '1') then
      in_ready <= '1';
    end if;
  end process;

  g_aligner : if (C_COMP_WIDTH mod 8 /= 0) generate
    signal from_aligner_tlast    : std_logic;
    signal to_restructure_tlast  : std_logic;
    signal to_restructure_tvalid : std_logic;
    signal to_restructure_tready : std_logic;
    signal to_restructure_tdata  : std_logic_vector(C_IN_DATA_WIDTH-1 downto 0);
    signal last                  : std_logic;
    signal num_last              : std_logic_vector(4 downto 0);
  begin

    i_shifter : entity work.offset_shifter
      generic map (
        C_DATA_WIDTH   => C_IN_DATA_WIDTH,
        C_BLOCK_WIDTH  => 2,
        C_OFFSET_WIDTH => 2
        )
      port map (
        clk     => clk,
        aresetn => aresetn,

        offset        => config_regs(0).offset,
        truncate_last => config_regs(0).truncate_last_word,

        in_tdata  => in_delay_tdata,
        in_tvalid => in_delay_tvalid,
        in_tready => in_delay_tready,
        in_tlast  => in_delay_tlast,

        out_tdata  => to_restructure_tdata,
        out_tvalid => to_restructure_tvalid,
        out_tready => to_restructure_tready,
        out_tlast  => to_restructure_tlast
        );


    process (clk)
    begin
      if (rising_edge(clk)) then
        if (aresetn = '0') then
          config_regs(1) <= CONFIG_INIT;
        elsif (in_delay_handshake = '1') then
          config_regs(1) <= config_regs(0);
        end if;
      end if;
    end process;
    i_comp_aligner : entity work.component_aligner
      generic map (
        C_IN_DATA_WIDTH  => C_IN_DATA_WIDTH,
        C_OUT_DATA_WIDTH => C_TO_BUFFER_WIDTH,
        C_COMP_WIDTH     => C_COMP_WIDTH
        )
      port map (
        clk     => clk,
        aresetn => aresetn,

        num_last => config_regs(1).num_last,

        in_tdata  => to_restructure_tdata,
        in_tvalid => to_restructure_tvalid,
        in_tready => to_restructure_tready,
        in_tlast  => to_restructure_tlast,

        out_tdata     => to_buffer_tdata,
        out_tvalid    => to_buffer_tvalid,
        out_tready    => to_buffer_tready,
        out_tlast     => from_aligner_tlast,
        out_num_valid => to_buffer_num_valid
        );

    to_buffer_tlast        <= from_aligner_tlast and config_regs(1).last;
    to_buffer_ctrl_signals <= (config_regs(1).last_block_in_row and config_regs(1).last_pix_in_block)
                              & config_regs(1).last_row_of_blocks;
  end generate g_aligner;

  g_noaligner : if (C_COMP_WIDTH mod 8 = 0) generate
    signal num_valid_last : integer range 0 to C_COMP_PER_WORD-1;
  begin
    num_valid_last      <= to_integer(unsigned(config_regs(0).num_last(2 downto 0)));
    to_buffer_tdata     <= in_delay_tdata;
    to_buffer_tvalid    <= in_delay_tvalid;
    in_delay_tready     <= to_buffer_tready;
    to_buffer_tlast     <= in_delay_tlast and config_regs(0).last;
    to_buffer_num_valid <= num_valid_last - 1 when in_delay_tlast = '1' and num_valid_last /= 0
                           else C_COMP_PER_WORD-1;
    to_buffer_ctrl_signals <= (config_regs(0).last_block_in_row and config_regs(0).last_pix_in_block)
                              & config_regs(0).last_row_of_blocks;
  end generate g_noaligner;

  -- Stick control signals onto ecah component
  process (to_buffer_tdata, to_buffer_ctrl_signals)
    constant TOT_WIDTH : integer := C_COMP_WIDTH + C_NUM_CTRL_BITS;
  begin
    for i in 0 to C_TO_BUFFER_NUM_COMP-1 loop
      to_buffer_annotated((i+1)*TOT_WIDTH-C_NUM_CTRL_BITS-1 downto i*TOT_WIDTH)
        <= to_buffer_tdata((i+1)*C_COMP_WIDTH-1 downto i*C_COMP_WIDTH);
      to_buffer_annotated((i+1)*TOT_WIDTH-1 downto (i+1)*TOT_WIDTH-C_NUM_CTRL_BITS) <= to_buffer_ctrl_signals;
    end loop;
  end process;

  i_buffer : entity work.component_buffer
    generic map (
      C_IN_DATA_WIDTH  => C_TO_BUFFER_WIDTH + C_TO_BUFFER_NUM_COMP * C_NUM_CTRL_BITS,
      C_OUT_DATA_WIDTH => (C_COMP_WIDTH + C_NUM_CTRL_BITS) * C_NUM_COMP,
      C_COMP_WIDTH     => C_COMP_WIDTH + C_NUM_CTRL_BITS,
      C_MAX_NUM_OUTPUT => C_NUM_COMP,
      C_FIXED_OUTPUT   => true)
    port map (
      clk     => clk,
      aresetn => aresetn,

      in_tdata     => to_buffer_annotated,
      in_tvalid    => to_buffer_tvalid,
      in_tready    => to_buffer_tready,
      in_tlast     => to_buffer_tlast,
      in_num_valid => to_buffer_num_valid,

      out_num_req => C_NUM_COMP-1,
      out_tdata   => from_buffer_annotated,
      out_tvalid  => out_tvalid,
      out_tready  => out_tready,
      out_tlast   => out_tlast,
      out_num     => from_buffer_num);

  -- Split up output data from buffer
  process (from_buffer_annotated)
    constant TOT_WIDTH : integer := C_COMP_WIDTH + C_NUM_CTRL_BITS;
  begin
    for i in 0 to C_NUM_COMP-1 loop
      out_ctrl((i+1)*C_NUM_CTRL_BITS-1 downto i*C_NUM_CTRL_BITS) <= from_buffer_annotated((i+1)*TOT_WIDTH-1 downto (i+1)*TOT_WIDTH-C_NUM_CTRL_BITS);

      out_tdata((i+1)*C_COMP_WIDTH-1 downto i*C_COMP_WIDTH) <= from_buffer_annotated((i+1)*TOT_WIDTH-C_NUM_CTRL_BITS-1 downto i*TOT_WIDTH);

    end loop;
  end process;

end Behavioral;
