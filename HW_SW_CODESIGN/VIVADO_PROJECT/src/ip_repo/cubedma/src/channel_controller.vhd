package sts_width is
  function sts_width(s2mm : boolean) return integer;
end sts_width;

package body sts_width is
  function sts_width(s2mm : boolean) return integer is
  begin
    if (s2mm) then
      return 32;
    else
      return 8;
    end if;
  end sts_width;
end sts_width;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use ieee.math_real.all;
use work.sts_width.all;

entity channel_controller is
  generic (
    C_COMP_WIDTH : integer := 0;
    C_NUM_COMP   : integer := 0;
    C_S2MM       : boolean := false
    );
  port (
    clk     : in std_logic;
    aresetn : in std_logic;

    -- CMD interface
    cmd_tvalid : out std_logic;
    cmd_tready : in  std_logic;
    cmd_tdata  : out std_logic_vector(71 downto 0);

    -- STS interface
    sts_tvalid : in std_logic;
    sts_tdata  : in std_logic_vector(sts_width(C_S2MM)-1 downto 0);

    -- Reset output
    channel_aresetn : out std_logic;
    channel_error   : in  std_logic;

    -- Unpacker configuration
    config_data  : out std_logic_vector(11 downto 0);
    config_wr    : out std_logic;
    config_ready : in  std_logic;

    -- Control / status
    control_length_reg : in  std_logic_vector(31 downto 0);
    base_reg           : in  std_logic_vector(31 downto 0);
    dimension_reg      : in  std_logic_vector(31 downto 0);
    block_reg          : in  std_logic_vector(31 downto 0);
    line_skip_reg      : in  std_logic_vector(31 downto 0);
    status_reg_rd      : out std_logic_vector(31 downto 0);
    status_reg_wr      : in  std_logic_vector(31 downto 0);
    length_reg_rd      : out std_logic_vector(31 downto 0);

    -- IRQ output
    irq_out : out std_logic
    );
end channel_controller;

architecture impl of channel_controller is
  -- Regs
  signal start_address    : std_logic_vector(31 downto 0);
  signal length_bytes     : std_logic_vector(22 downto 0);
  signal bytes_recv_total : unsigned(31 downto 0);

  -- Control signals from state machine
  signal start_pulse   : std_logic;
  signal en_cnt        : std_logic;
  signal clr_sts       : std_logic;
  signal reset_channel : std_logic;
  signal cmd_valid     : std_logic;

  -- Control signals to state machine
  signal cmd_handshake  : std_logic;
  signal sts_handshake  : std_logic;
  signal last_pixel     : std_logic;
  signal transfer_done  : std_logic;
  signal reset_complete : std_logic;

  signal status_bits : std_logic_vector(3 downto 0);
  signal bytes_recv  : unsigned(22 downto 0);

  signal completion_tally : integer range -128 to 127;

  -- Bits in control registers
  signal depth                 : std_logic_vector(11 downto 0);
  signal width                 : std_logic_vector(11 downto 0);
  signal height                : std_logic_vector(11 downto 0);
  signal block_width           : std_logic_vector(3 downto 0);
  signal block_height          : std_logic_vector(3 downto 0);
  signal line_skip             : std_logic_vector(19 downto 0);
  signal last_block_row_length : std_logic_vector(19 downto 0);
  signal num_plane_transfers   : std_logic_vector(7 downto 0);
  signal comp_offset           : std_logic_vector(7 downto 0);
  signal start                 : std_logic;
  signal irq_mask              : std_logic_vector(1 downto 0);
  signal irq_clear             : std_logic_vector(1 downto 0);
  signal irq_status            : std_logic_vector(1 downto 0);
  signal mode_block            : std_logic;
  signal mode_plane            : std_logic;

  signal hard_error_pulse    : std_logic;
  signal sts_error           : std_logic;
  signal sts_error_pulse     : std_logic;
  signal transfer_done_pulse : std_logic;

  signal irq_triggers : std_logic_vector(1 downto 0);
begin

  --------------------------------------------------------------------------------
  -- Get settings from control registers and put status bits in status register
  --------------------------------------------------------------------------------
  width              <= dimension_reg(11 downto 0);
  height             <= dimension_reg(23 downto 12);
  depth(7 downto 0)  <= dimension_reg(31 downto 24);
  depth(11 downto 8) <= block_reg(11 downto 8);

  block_width           <= block_reg(3 downto 0);
  block_height          <= block_reg(7 downto 4);
  last_block_row_length <= block_reg(31 downto 12);

  line_skip <= line_skip_reg(19 downto 0);

  start               <= control_length_reg(0);
  mode_block          <= control_length_reg(2);
  mode_plane          <= control_length_reg(3);
  irq_mask            <= control_length_reg(5 downto 4);
  num_plane_transfers <= control_length_reg(15 downto 8);
  comp_offset         <= control_length_reg(23 downto 16);

  status_reg_rd(3 downto 0) <= status_bits;
  status_reg_rd(5 downto 4) <= irq_status;
  length_reg_rd             <= std_logic_vector(bytes_recv_total) when C_S2MM else (others => '0');

  irq_clear <= status_reg_wr(5 downto 4);

  --------------------------------------------------------------------------------
  -- Create pulses when certain signals are asserted
  --------------------------------------------------------------------------------
  b_start : block is
    signal start_reg         : std_logic;
    signal hard_error_reg    : std_logic;
    signal sts_error_reg     : std_logic;
    signal transfer_done_reg : std_logic;
  begin
    process (clk) is
    begin
      if (rising_edge(clk)) then
        if (aresetn = '0') then
          start_reg         <= '0';
          hard_error_reg    <= '0';
          sts_error_reg     <= '0';
          transfer_done_reg <= '0';
        else
          start_reg         <= start;
          hard_error_reg    <= channel_error;
          sts_error_reg     <= sts_error;
          transfer_done_reg <= transfer_done;
        end if;
      end if;
    end process;

    start_pulse         <= '1' when start_reg = '0' and start = '1'                 else '0';
    hard_error_pulse    <= '1' when hard_error_reg = '0' and channel_error = '1'    else '0';
    sts_error_pulse     <= '1' when sts_error_reg = '0' and sts_error = '1'         else '0';
    transfer_done_pulse <= '1' when transfer_done_reg = '0' and transfer_done = '1' else '0';
  end block b_start;

  --------------------------------------------------------------------------------
  -- Datamover channel reset
  --
  -- The reset needs to be held low for at least three clocks
  --------------------------------------------------------------------------------
  b_chn_reset : block is
    signal count : integer range 0 to 3;
  begin
    process (clk) is
    begin
      if (rising_edge(clk)) then
        if (aresetn = '0') then
          count          <= 0;
          reset_complete <= '0';
        else
          if (reset_channel = '1' and count < 3) then
            count <= count + 1;
          end if;
          -- Generate 1 cycle pulse when reset_complete
          if (reset_complete = '0' and count = 3) then
            reset_complete <= '1';
            count          <= 0;
          else
            reset_complete <= '0';
          end if;
        end if;
      end if;
    end process;

    channel_aresetn <= not reset_channel;
  end block b_chn_reset;

  irq_triggers(0) <= hard_error_pulse or sts_error_pulse;
  irq_triggers(1) <= transfer_done_pulse;

  i_irq_gen : entity work.irq_generator
    generic map (
      C_N_TRIGGERS => 2)
    port map (
      clk     => clk,
      aresetn => aresetn,

      mask     => irq_mask,
      triggers => irq_triggers,
      clear    => irq_clear,

      status => irq_status,
      irq    => irq_out
      );

  --------------------------------------------------------------------------------
  -- DataMover command interface
  --------------------------------------------------------------------------------
  process (last_pixel, start_address, length_bytes, cmd_valid, cmd_tready) is
    alias cmd_tag is cmd_tdata(67 downto 64);
    alias cmd_saddr is cmd_tdata(63 downto 32);
    alias cmd_drr is cmd_tdata(31);
    alias cmd_eof is cmd_tdata(30);
    alias cmd_dsa is cmd_tdata(29 downto 24);
    alias cmd_type is cmd_tdata(23);
    alias cmd_btt is cmd_tdata(22 downto 0);
  begin
    cmd_tdata <= (others => '0');

    -- We want to issue INCR transfers to/from the memory map, where the
    -- address is incremented instead of reading from the same location
    -- over and over
    cmd_type <= '1';

    -- When we are at the last pixel, we tag the command with 1 instead of
    -- 0, so we can later recognize the status word that tells us that the
    -- whole transfer is done. We also set the EOF flag to 1, so that the
    -- Datamover will assert TLAST on the final transfer.
    cmd_tag <= "000" & last_pixel;

    -- We need the DataMover to assert TLAST at the end of every transfer, so
    -- that the unpacker knows when to pop the next configuration data off the
    -- FIFO
    if (not C_S2MM) then
      cmd_eof <= '1';
    else
      cmd_eof <= '0';
    end if;

    cmd_saddr <= start_address;
    cmd_btt   <= length_bytes;

    cmd_drr <= '1';

    cmd_tvalid    <= cmd_valid;
    cmd_handshake <= cmd_valid and cmd_tready;
  end process;

  --------------------------------------------------------------------------------
  -- State machine
  --------------------------------------------------------------------------------
  b_fsm : block is
    type t_state is (S_IDLE, S_RUNNING, S_WAIT_COMPLETE, S_HARD_ERROR, S_RESET_CHN, S_STS_ERROR);
    signal state      : t_state;
    signal next_state : t_state;
  begin
    process (state, start_pulse, cmd_handshake, config_ready, last_pixel,
             transfer_done, hard_error_pulse, sts_handshake, sts_error, sts_error_pulse,
             reset_complete, completion_tally)
    begin
      cmd_valid     <= '0';
      next_state    <= state;
      clr_sts       <= '0';
      reset_channel <= '0';
      en_cnt        <= '0';
      config_wr     <= '0';

      case state is
        when S_RUNNING =>
          if (C_S2MM) then
            if (completion_tally = 0) then
              cmd_valid <= '1';
            end if;
            if (transfer_done = '1') then
              next_state <= S_IDLE;
            elsif (sts_handshake = '1') then
              en_cnt <= '1';
            end if;

          else
            -- Only accept new commands if the unpacker is ready
            if (config_ready = '1') then
              cmd_valid <= '1';
            end if;

            if (cmd_handshake = '1') then
              config_wr <= '1';
              if (last_pixel = '1') then
                next_state <= S_WAIT_COMPLETE;
              else
                en_cnt <= '1';
              end if;
            end if;
          end if;

        when S_IDLE =>
          if start_pulse = '1' then
            next_state <= S_RUNNING;
            clr_sts    <= '1';
          end if;

        when S_WAIT_COMPLETE =>
          if (transfer_done = '1') then
            next_state <= S_IDLE;
          end if;

        -- When in the internal error state, we will wait for the status word to get
        -- back so we can know the reason for the failure, and then reset the channel
        when S_HARD_ERROR =>
          if (sts_error = '1') then
            next_state <= S_RESET_CHN;
          end if;

        when S_RESET_CHN =>
          reset_channel <= '1';
          if (reset_complete = '1') then
            next_state <= S_IDLE;
          end if;

        -- If we got an error in one of the status words, we will wait until we have
        -- gotten as many status words as the number of commands we have issued.
        when S_STS_ERROR =>
          if (completion_tally = 0) then
            next_state <= S_IDLE;
          end if;
      end case;

      -- Always handle hard errors (assertion of channel error line), but errors
      -- in status words should not be handled if we are already in any of the
      -- states related to handling hard errors.
      if (hard_error_pulse = '1') then
        next_state <= S_HARD_ERROR;
      elsif (state /= S_HARD_ERROR and state /= S_RESET_CHN and sts_error_pulse = '1') then
        next_state <= S_STS_ERROR;
      end if;
    end process;

    process (clk)
    begin
      if rising_edge(clk) then
        if aresetn = '0' then
          state <= S_IDLE;
        else
          state <= next_state;
        end if;
      end if;
    end process;
  end block b_fsm;

  g_address_gen_block : if (not C_S2MM) generate
    signal truncate_last_word : std_logic;
    signal offset             : std_logic_vector(2 downto 0);
    signal length_comps       : std_logic_vector(23 downto 0);
    signal last_block_in_row  : std_logic;
    signal last_pix_in_block  : std_logic;
    signal last_row_of_blocks : std_logic;
  begin

    i_address_gen : entity work.address_gen
      generic map (
        C_COMP_WIDTH => C_COMP_WIDTH,
        C_NUM_COMP   => C_NUM_COMP
        )
      port map (
        clk     => clk,
        aresetn => aresetn,

        tick  => en_cnt,
        start => start_pulse,

        mode_block            => mode_block,
        mode_plane            => mode_plane,
        depth                 => depth,
        width                 => width,
        height                => height,
        block_width           => block_width,
        block_height          => block_height,
        line_skip             => line_skip,
        last_block_row_length => last_block_row_length,
        comp_offset           => comp_offset,
        num_plane_transfers   => num_plane_transfers,
        base_address          => base_reg,

        start_address      => start_address,
        offset             => offset,
        truncate_last_word => truncate_last_word,
        length_comps       => length_comps,
        length_bytes       => length_bytes,
        last_pixel         => last_pixel,
        last_block_in_row  => last_block_in_row,
        last_pix_in_block  => last_pix_in_block,
        last_row_of_blocks => last_row_of_blocks
        );

    config_data <= last_block_in_row
                   & last_pix_in_block
                   & last_row_of_blocks
                   & truncate_last_word
                   & length_comps(4 downto 0)
                   & std_logic_vector(offset(2 downto 1))
                   & last_pixel;

  end generate g_address_gen_block;

  --------------------------------------------------------------------------------
  -- Indeterminate transfers (S2MM)
  --
  -- For indeterminate transfers, length_bytes is always the maximum value, and
  -- start_address is incremented by the received number of bytes in the
  -- previous transfer
  --------------------------------------------------------------------------------
  g_address_gen_indet : if (C_S2MM) generate
    constant C_TRANSFER_BITS   : integer                              := 23;
    constant C_TRANSFER_LENGTH : unsigned(C_TRANSFER_BITS-1 downto 0) := '1' & (C_TRANSFER_BITS-2 downto 0 => '0');
  begin
    process (clk)
    begin
      length_bytes <= std_logic_vector(resize(C_TRANSFER_LENGTH, 23));

      if (rising_edge(clk)) then
        if (aresetn = '0') then
          start_address    <= (others => '0');
          bytes_recv_total <= to_unsigned(0, 32);
        else
          if (start_pulse = '1') then
            start_address    <= base_reg;
            bytes_recv_total <= to_unsigned(0, 32);
          elsif (en_cnt = '1') then
            start_address    <= std_logic_vector(unsigned(start_address) + C_TRANSFER_LENGTH);
            bytes_recv_total <= bytes_recv_total + C_TRANSFER_LENGTH;
          elsif (transfer_done_pulse = '1') then
            bytes_recv_total <= bytes_recv_total + bytes_recv;
          end if;
        end if;
      end if;
    end process;
    last_pixel <= '0';
  end generate g_address_gen_indet;

  --------------------------------------------------------------------------------
  -- Status word interface
  --
  -- In normal operation, the latest status received will be kept in
  -- the sts_reg register.
  --
  -- When an error status is received, that value is latched until clr_sts is
  -- asserted by the control logic.
  --
  --------------------------------------------------------------------------------
  b_sts : block is
    alias sts_okay is sts_tdata(7);
    alias sts_slv_err is sts_tdata(6);
    alias sts_dec_err is sts_tdata(5);
    alias sts_int_err is sts_tdata(4);
    alias sts_tag is sts_tdata(3 downto 0);
  begin

    process (clk)
    begin
      if (rising_edge(clk)) then
        if (aresetn = '0' or clr_sts = '1') then
          status_bits <= (others => '0');
        elsif (sts_tvalid = '1') then
          -- Only overwrite status word register if no error in previous
          if (status_bits(3 downto 1) = "000") then
            status_bits <= sts_slv_err & sts_dec_err & sts_int_err & transfer_done;
          end if;
        end if;
      end if;
    end process;

    sts_error <= sts_slv_err or sts_dec_err or sts_int_err;

    -- The STS interface is always ready, so a handshake occurs whenever valid
    -- is high
    sts_handshake <= sts_tvalid;

    -- For the S2MM channel we may be receiving an unknown amount, so we need
    -- to extract some extra information to know if we're done, and if so,
    -- how much data was received.
    process (sts_handshake, sts_tdata)
    begin
      if (C_S2MM) then
        -- Specifically check for '1' since STS from DataMover is often 'U'
        if (sts_handshake = '1' and sts_tdata(31) = '1') then
          transfer_done <= '1';
        else
          transfer_done <= '0';
        end if;
        bytes_recv <= unsigned(sts_tdata(30 downto 8));
      else
        -- We are done when we get an OKAY status word back with 1 as the tag
        if (sts_handshake = '1' and sts_tag = x"1" and sts_okay = '1') then
          transfer_done <= '1';
        else
          transfer_done <= '0';
        end if;
        bytes_recv <= (others => '0');
      end if;
    end process;
  end block b_sts;

  --------------------------------------------------------------------------------
  -- Completion tally
  --
  -- Keeps track of the number of issued commands vs the number of received
  -- status words. When 0, the two are balanced.
  --------------------------------------------------------------------------------
  process (clk)
    variable incr : integer range -1 to 1 := 0;
  begin
    if (rising_edge(clk)) then
      if (aresetn = '0' or clr_sts = '1') then
        completion_tally <= 0;
      else
        incr := 0;
        if (cmd_handshake = '1') then
          incr := 1;
        end if;
        if (sts_handshake = '1') then
          incr := incr - 1;
        end if;
        completion_tally <= completion_tally + incr;
      end if;
    end if;
  end process;
end impl;
