library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library xpm;
use xpm.vcomponents.all;

--------------------------------------------------------------------------------
-- TinyMover Core
--
-- The TinyMover core is a replacement for the Xilinx DataMover usable for
-- small (within one burst) transfers where minimal latency between read requests
-- is important. It accepts commands (read address and length) and issues read
-- requests as quickly as the memory infrastructure is ready.
--
-- Maximum transfer length is 8 * 16 = 128 bytes (8 is burst size, 16 is
-- maximum burst length)
--
-- As specified in the AXI standard, transactions that cross a 4KB boundary are
-- split into two separate read requests. When the read data is received, the
-- two transactions are joined together (last in the first transaction is ignored).
--
-- The core also performs byte level realignment of the data stream, since
-- unaligned transfers are not supported in AXI.
--------------------------------------------------------------------------------

entity tinymover is
  port (
    clk     : in std_logic;
    aresetn : in std_logic;

    -- Command interface
    cmd_tdata  : in  std_logic_vector(40 downto 0);
    cmd_tready : out std_logic;
    cmd_tvalid : in  std_logic;

    -- Status interface
    sts_tvalid : out std_logic;
    sts_tdata  : out std_logic_vector(3 downto 0);

    -- Read Address Channel
    m_axi_araddr  : out std_logic_vector(31 downto 0);
    m_axi_arvalid : out std_logic;
    m_axi_arready : in  std_logic;
    m_axi_arlen   : out std_logic_vector(3 downto 0);
    m_axi_arsize  : out std_logic_vector(2 downto 0);
    m_axi_arburst : out std_logic_vector(1 downto 0);

    -- Read Data Channel
    m_axi_rdata  : in  std_logic_vector(63 downto 0);
    m_axi_rready : out std_logic;
    m_axi_rvalid : in  std_logic;
    m_axi_rlast  : in  std_logic;
    m_axi_rresp  : in  std_logic_vector(1 downto 0);

    -- Stream Output
    m_axis_tdata  : out std_logic_vector(63 downto 0);
    m_axis_tvalid : out std_logic;
    m_axis_tready : in  std_logic;
    m_axis_tlast  : out std_logic
    );
end tinymover;

architecture Behavioral of tinymover is
  component fifo_generator_1
    port (
      clk   : in  std_logic;
      srst  : in  std_logic;
      din   : in  std_logic_vector(0 downto 0);
      wr_en : in  std_logic;
      rd_en : in  std_logic;
      dout  : out std_logic_vector(0 downto 0);
      full  : out std_logic;
      empty : out std_logic
      );
  end component;

  signal start_address : std_logic_vector(31 downto 0);
  signal length        : std_logic_vector(7 downto 0);

  signal addr_post_done      : std_logic;
  signal addr_first_in_split : std_logic;

  signal read_new_transfer : std_logic;
  signal read_err_clear    : std_logic;

  signal cmd_data_reg : std_logic_vector(40 downto 0);
  signal cmd_pending  : std_logic;

  signal num_words       : std_logic_vector(3 downto 0);
  signal num_words_fetch : std_logic_vector(3 downto 0);

  -- Number of words to fetch in each transfer when we're doing a split transfer
  signal split_transaction    : std_logic;
  signal num_words_first      : std_logic_vector(3 downto 0);
  signal num_words_second     : std_logic_vector(3 downto 0);
  signal start_address_second : std_logic_vector(31 downto 0);

  -- Transaction FIFO
  signal fifo_rd          : std_logic;
  signal fifo_wr          : std_logic;
  signal fifo_full        : std_logic;
  signal from_fifo_split  : std_logic;
  signal from_fifo_tagged : std_logic;

  -- Configuration for byte realignment
  signal truncate_last_word : std_logic;
  signal byte_offset        : std_logic_vector(2 downto 0);

  -- Stream from memory
  signal from_mem_tdata  : std_logic_vector(63 downto 0);
  signal from_mem_tvalid : std_logic;
  signal from_mem_tlast  : std_logic;
  signal from_mem_tready : std_logic;
begin

  --------------------------------------------------------------------------------
  -- Command Interface
  --
  -- Accept new commands as long as there are either no commands pending, or
  -- the pending read request will be posted this cycle
  --------------------------------------------------------------------------------
  b_cmd : block is
    signal cmd_ready     : std_logic;
    signal cmd_handshake : std_logic;
  begin
    cmd_handshake <= cmd_tvalid and cmd_ready;
    cmd_ready     <= addr_post_done or (not cmd_pending);
    cmd_tready    <= cmd_ready;

    process (clk) is
    begin
      if (rising_edge(clk)) then
        if (aresetn = '0') then
          cmd_data_reg <= (others => '0');
          cmd_pending  <= '0';
        else
          if (cmd_handshake = '1') then
            cmd_data_reg <= cmd_tdata;
            cmd_pending  <= '1';
          elsif (addr_post_done = '1') then
            cmd_pending <= '0';
          end if;
        end if;
      end if;
    end process;

    read_err_clear <= cmd_handshake;
  end block b_cmd;

  --------------------------------------------------------------------------------
  -- Byte address calculations
  --------------------------------------------------------------------------------
  start_address <= cmd_data_reg(31 downto 0);
  length        <= cmd_data_reg(39 downto 32);
  byte_offset   <= start_address(2 downto 0);

  process (length, byte_offset)
    variable temp : unsigned(7 downto 0);
  begin
    temp := unsigned(byte_offset) + unsigned(length) - 1;

    -- Calculate the number of words to fetch
    if (unsigned(byte_offset) + unsigned(length) <= 8) then
      num_words_fetch <= (others => '0');
    else
      num_words_fetch <= std_logic_vector(temp(6 downto 3));
    end if;
  end process;

  process (length, num_words_fetch)
  begin
    if ((unsigned(length)-1)/8 /= unsigned(num_words_fetch)) then
      truncate_last_word <= '1';
    else
      truncate_last_word <= '0';
    end if;
  end process;

  -- When crossing 4KB boundaries, the AXI standard dictates that transfers
  -- need to be split up into two requests
  process (start_address, length)
    variable end_address      : unsigned(31 downto 0);
    variable start_word_index : integer range 0 to 4096/8-1;
    variable end_word_index   : integer range 0 to 4096/8-1;
    variable second_block     : unsigned(19 downto 0);
  begin
    end_address := unsigned(start_address) + unsigned(length);

    -- Which 64-bit word in the 4KB block is the first
    start_word_index := to_integer(unsigned(start_address(11 downto 3)));
    -- Which 64-bit word in the 4KB block is the last
    end_word_index   := to_integer(end_address(11 downto 3));

    -- Find out if we have a split transaction case by looking at the indices;
    -- if end is less than start, then we must have crossed a boundary.
    if (end_word_index < start_word_index) then
      split_transaction <= '1';
    else
      split_transaction <= '0';
    end if;

    -- Number of words in first transfer is the distance from 4KB boundary to
    -- the start index
    num_words_first  <= std_logic_vector(to_unsigned(16#1ff# - start_word_index, 4));
    -- Number of words in the second transfer is the rest
    num_words_second <= std_logic_vector(to_unsigned(end_word_index, 4));

    -- Calculate start address of second 4KB block where the second transfer
    -- starts from
    second_block         := unsigned(start_address(31 downto 12)) + 1;
    start_address_second <= std_logic_vector(second_block) & (11 downto 0 => '0');
  end process;

  --------------------------------------------------------------------------------
  -- Address Posting Interface
  --
  -- Put address on Read Address Channel. If split_transaction = 1, we need to
  -- split this into two transactions. split_phase indicates if we are
  -- currently sending the request for the first part or the second part.
  --------------------------------------------------------------------------------
  b_addr : block is

    signal arvalid     : std_logic;
    signal handshake   : std_logic;
    signal split_phase : std_logic;
  begin
    handshake           <= arvalid and m_axi_arready;
    addr_first_in_split <= (not split_phase) and split_transaction;

    process (clk)
    begin
      if (rising_edge(clk)) then
        if (aresetn = '0') then
          split_phase <= '0';
        else
          if (split_transaction = '1' and handshake = '1') then
            split_phase <= not split_phase;
          end if;
        end if;
      end if;
    end process;

    m_axi_arsize  <= "011";             -- 8 bytes per transfer
    m_axi_arburst <= "01";              -- INCR mode
    m_axi_arvalid <= arvalid;
    arvalid       <= '1' when cmd_pending = '1' and fifo_full = '0' else '0';

    process (start_address, start_address_second, num_words_first, num_words_second, num_words_fetch,
             split_transaction, split_phase, handshake)
    begin

      -- Address posting is done if we're handshaking on the Read Address
      -- Channel, except if sending the first read request in a split transfer
      -- (handled below)
      addr_post_done <= handshake;
      fifo_wr        <= handshake;

      -- Select start address and burst length based on whether we
      -- are in a single transaction or we are in a split transaction. If the
      -- latter, the address and length is chosen depending on which phase of the
      -- transaction we are in (first or second part).
      if (split_transaction = '1') then
        if (split_phase = '0') then
          m_axi_araddr   <= start_address;
          m_axi_arlen    <= num_words_first;
          -- We're not done with address posting yet
          addr_post_done <= '0';
        else
          m_axi_araddr <= start_address_second;
          m_axi_arlen  <= num_words_second;
        end if;
      else
        m_axi_araddr <= start_address;
        m_axi_arlen  <= num_words_fetch;
      end if;
    end process;
  end block b_addr;

  --------------------------------------------------------------------------------
  -- Read Data Channel to Stream interface
  --------------------------------------------------------------------------------
  b_read : block is
    signal transfer_complete  : std_logic;
    signal last               : std_logic;
    signal handshake          : std_logic;
    signal from_mem_handshake : std_logic;
    signal stage_reg_ready    : std_logic;
    signal rlast_delayed      : std_logic;
    signal rresp_delayed      : std_logic_vector(1 downto 0);
  begin
    handshake <= m_axi_rvalid and stage_reg_ready;

    m_axi_rready <= stage_reg_ready;

    --------------------------------------------------------------------------------
    -- First stage
    --
    -- Register if a transfer is complete. This is necessary to do in a
    -- separate clock cycle so that the transaction data can be popped from the
    -- FIFO and be ready in the next cycle
    --------------------------------------------------------------------------------
    process (clk)
    begin
      if (rising_edge(clk)) then
        if (aresetn = '0') then
          transfer_complete <= '1';
        else
          -- Latch when a transfer has completed, so that we can detect when a
          -- new transfer starts
          if (handshake = '1' and m_axi_rlast = '1') then
            transfer_complete <= '1';
          elsif (handshake = '1') then
            transfer_complete <= '0';
          end if;
        end if;
      end if;
    end process;

    -- Read from FIFO when we're receiving the first handshake after a completed
    -- transfer
    fifo_rd <= transfer_complete and handshake;

    --------------------------------------------------------------------------------
    -- Second stage
    --
    -- Forward the read data to the stream interface. If the current
    -- transaction is the first part in a split transaction, the last signal is
    -- ignored in the output stream (so they appear as one transaction).
    --------------------------------------------------------------------------------
    process (clk)
    begin
      if (rising_edge(clk)) then
        if (aresetn = '0') then
          from_mem_tdata  <= (others => '0');
          from_mem_tvalid <= '0';
          rlast_delayed   <= '0';
          rresp_delayed   <= (others => '0');
        else
          if (handshake = '1') then
            from_mem_tdata  <= m_axi_rdata;
            rlast_delayed   <= m_axi_rlast;
            rresp_delayed   <= m_axi_rresp;
            from_mem_tvalid <= '1';
          elsif (from_mem_handshake = '1') then
            from_mem_tvalid <= '0';
          end if;
        end if;
      end if;
    end process;

    process (from_mem_tvalid, from_mem_handshake)
    begin
      stage_reg_ready <= '0';
      if (from_mem_tvalid = '0' or from_mem_handshake = '1') then
        stage_reg_ready <= '1';
      end if;
    end process;

    from_mem_handshake <= from_mem_tvalid and from_mem_tready;
    from_mem_tlast     <= rlast_delayed and last;

    -- Ignore rlast if the current response currently being received is the
    -- first in a split transaction
    process (from_mem_handshake, rlast_delayed, from_fifo_split)
    begin
      last <= '0';
      if (from_mem_handshake = '1' and rlast_delayed = '1') then
        if (from_fifo_split = '1') then
          last <= '0';
        else
          last <= '1';
        end if;
      end if;
    end process;

    -- Report status word on last beat of transfer
    process (rresp_delayed, last, from_fifo_tagged)
      variable sts_mask : std_logic_vector(2 downto 0);
    begin
      -- On the last beat of a transfer, put out a valid set of status bits
      case rresp_delayed is
        when "00"   => sts_mask := "001";
        when "01"   => sts_mask := "001";
        when "10"   => sts_mask := "010";
        when "11"   => sts_mask := "100";
        when others => sts_mask := "000";
      end case;

      sts_tdata  <= from_fifo_tagged & sts_mask;
      sts_tvalid <= last;
    end process;
  end block b_read;

  --------------------------------------------------------------------------------
  -- Byte Realignment
  --------------------------------------------------------------------------------
  b_realign : block is
    signal reset                   : std_logic;
    signal tlast                   : std_logic;
    signal fifo_in                 : std_logic_vector(5 downto 0);
    signal fifo_out                : std_logic_vector(5 downto 0);
    signal from_fifo_offset        : std_logic_vector(2 downto 0);
    signal from_fifo_truncate_last : std_logic;
    signal tagged                  : std_logic;
  begin
    reset        <= not aresetn;
    m_axis_tlast <= tlast;

    tagged       <= cmd_data_reg(40);
    fifo_in      <= tagged & addr_first_in_split & truncate_last_word & byte_offset;

    from_fifo_tagged        <= fifo_out(5);
    from_fifo_split         <= fifo_out(4);
    from_fifo_truncate_last <= fifo_out(3);
    from_fifo_offset        <= fifo_out(2 downto 0);

    i_fifo : xpm_fifo_sync
      generic map (
        FIFO_MEMORY_TYPE    => "auto",
        ECC_MODE            => "no_ecc",
        FIFO_WRITE_DEPTH    => 128,
        WRITE_DATA_WIDTH    => 6,
        WR_DATA_COUNT_WIDTH => 8,
        PROG_FULL_THRESH    => 120,
        FULL_RESET_VALUE    => 0,
        READ_MODE           => "std",
        FIFO_READ_LATENCY   => 1,
        READ_DATA_WIDTH     => 6,
        RD_DATA_COUNT_WIDTH => 8,
        PROG_EMPTY_THRESH   => 10,
        DOUT_RESET_VALUE    => "0",
        WAKEUP_TIME         => 0
        )
      port map (
        rst           => reset,
        wr_clk        => clk,
        wr_en         => fifo_wr,
        din           => fifo_in,
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

    i_shifter : entity work.offset_shifter
      generic map (
        C_DATA_WIDTH   => 64,
        C_BLOCK_WIDTH  => 8,
        C_OFFSET_WIDTH => 3
        )
      port map (
        clk     => clk,
        aresetn => aresetn,

        offset        => from_fifo_offset,
        truncate_last => from_fifo_truncate_last,

        in_tdata  => from_mem_tdata,
        in_tready => from_mem_tready,
        in_tvalid => from_mem_tvalid,
        in_tlast  => from_mem_tlast,

        out_tdata  => m_axis_tdata,
        out_tready => m_axis_tready,
        out_tvalid => m_axis_tvalid,
        out_tlast  => tlast
        );
  end block b_realign;

end Behavioral;
