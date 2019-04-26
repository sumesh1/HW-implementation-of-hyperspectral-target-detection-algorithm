library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use ieee.math_real.all;

entity tiny_chn_controller is
  generic (
    C_COMP_WIDTH : integer;
    C_NUM_COMP   : integer
    );
  port (
    clk     : in std_logic;
    aresetn : in std_logic;

    -- CMD interface
    cmd_tvalid : out std_logic;
    cmd_tready : in  std_logic;
    cmd_tdata  : out std_logic_vector(40 downto 0);

    -- STS interface
    sts_tvalid : in std_logic;
    sts_tdata  : in std_logic_vector(3 downto 0);

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

    -- IRQ output
    irq_out : out std_logic
    );
end tiny_chn_controller;

architecture impl of tiny_chn_controller is
  type t_state is (S_IDLE, S_RUNNING, S_WAIT_COMPLETE, S_ERROR);

  -- Regs
  signal start_address : std_logic_vector(31 downto 0);
  signal length_bytes  : std_logic_vector(22 downto 0);

  -- Control signals from state machine
  signal start_pulse   : std_logic;
  signal next_state    : t_state;
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

  signal sts_error_mask : std_logic_vector(1 downto 0);
  signal irq_reg        : std_logic_vector(1 downto 0);

  signal completion_tally : integer range -128 to 127;

  -- Bits in control registers
  signal depth               : std_logic_vector(11 downto 0);
  signal width               : std_logic_vector(11 downto 0);
  signal height              : std_logic_vector(11 downto 0);
  signal block_width         : std_logic_vector(3 downto 0);
  signal block_height        : std_logic_vector(3 downto 0);
  signal line_skip           : std_logic_vector(19 downto 0);
  signal num_plane_transfers : std_logic_vector(7 downto 0);
  signal comp_offset         : std_logic_vector(7 downto 0);
  signal start               : std_logic;
  signal irq_mask            : std_logic_vector(1 downto 0);
  signal irq_clear           : std_logic_vector(1 downto 0);
  signal irq_status          : std_logic_vector(1 downto 0);
  signal mode_block          : std_logic;

  signal sts_error           : std_logic;
  signal sts_error_pulse     : std_logic;
  signal transfer_done_pulse : std_logic;

  signal irq_triggers : std_logic_vector(1 downto 0);

begin

  --------------------------------------------------------------------------------
  -- Registers
  --------------------------------------------------------------------------------
  width             <= dimension_reg(11 downto 0);
  height            <= dimension_reg(23 downto 12);
  depth(7 downto 0) <= dimension_reg(31 downto 24);

  block_width  <= block_reg(3 downto 0);
  block_height <= block_reg(7 downto 4);

  line_skip <= line_skip_reg(19 downto 0);

  start               <= control_length_reg(0);
  mode_block          <= control_length_reg(2);
  irq_mask            <= control_length_reg(5 downto 4);
  num_plane_transfers <= control_length_reg(15 downto 8);
  comp_offset         <= control_length_reg(23 downto 16);

  status_reg_rd(0)           <= transfer_done;
  status_reg_rd(2 downto 1)  <= sts_error_mask;
  status_reg_rd(5 downto 4)  <= irq_reg;
  status_reg_rd(31 downto 6) <= (others => '0');

  irq_clear <= status_reg_wr(5 downto 4);

  --------------------------------------------------------------------------------
  -- Pulse generators
  --------------------------------------------------------------------------------
  b_start : block is
    signal start_reg         : std_logic;
    signal sts_error_reg     : std_logic;
    signal transfer_done_reg : std_logic;
  begin
    process (clk) is
    begin
      if (rising_edge(clk)) then
        if (aresetn = '0') then
          start_reg         <= '0';
          sts_error_reg     <= '0';
          transfer_done_reg <= '0';
        else
          start_reg         <= start;
          sts_error_reg     <= sts_error;
          transfer_done_reg <= transfer_done;
        end if;
      end if;
    end process;

    start_pulse         <= '1' when start_reg = '0' and start = '1'                 else '0';
    sts_error_pulse     <= '1' when sts_error_reg = '0' and sts_error = '1'         else '0';
    transfer_done_pulse <= '1' when transfer_done_reg = '0' and transfer_done = '1' else '0';
  end block b_start;

  irq_triggers(0) <= sts_error_pulse;
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
  -- Set up command word for TinyMover
  --------------------------------------------------------------------------------
  process (last_pixel, start_address, length_bytes, cmd_valid, cmd_tready) is
    alias cmd_saddr is cmd_tdata(31 downto 0);
    alias cmd_length is cmd_tdata(39 downto 32);
    alias cmd_tagged is cmd_tdata(40);
  begin
    cmd_saddr  <= std_logic_vector(start_address);
    cmd_length <= std_logic_vector(length_bytes(7 downto 0));
    cmd_tagged <= last_pixel;

    cmd_tvalid    <= cmd_valid;
    cmd_handshake <= cmd_valid and cmd_tready;
  end process;

  --------------------------------------------------------------------------------
  -- State machine
  --------------------------------------------------------------------------------
  b_fsm : block is
    type t_state is (S_IDLE, S_RUNNING, S_WAIT_COMPLETE, S_ERROR);
    signal state      : t_state;
    signal next_state : t_state;
  begin
    process (state, start_pulse, cmd_handshake, config_ready, last_pixel,
             transfer_done, sts_error_pulse, completion_tally)
    begin
      cmd_valid     <= '0';
      next_state    <= state;
      clr_sts       <= '0';
      reset_channel <= '0';
      en_cnt        <= '0';
      config_wr     <= '0';

      case state is
        when S_RUNNING =>
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

        when S_IDLE =>
          if start_pulse = '1' then
            next_state <= S_RUNNING;
            clr_sts    <= '1';
          end if;

        when S_WAIT_COMPLETE =>
          if (transfer_done = '1') then
            next_state <= S_IDLE;
          end if;

        -- If we got an error in one of the status words, we will wait until we have
        -- gotten as many status words as the number of commands we have issued.
        when S_ERROR =>
          if (completion_tally = 0) then
            next_state <= S_IDLE;
          end if;
      end case;

      -- Always handle hard errors (assertion of channel error line), but errors
      -- in status words should not be handled if we are already in any of the
      -- states related to handling hard errors.
      if (sts_error_pulse = '1') then
        next_state <= S_ERROR;
      end if;
    end process;

    process (clk) is
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

  b_address_gen : block is
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
        mode_plane            => '1',
        depth                 => depth,
        width                 => width,
        height                => height,
        block_width           => block_width,
        block_height          => block_height,
        line_skip             => line_skip,
        last_block_row_length => (others => '0'),
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

  end block b_address_gen;


  --------------------------------------------------------------------------------
  --
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
    signal sts_reg : std_logic_vector(3 downto 0);
    alias sts_last is sts_reg(3);
    alias sts_slv_err is sts_reg(2);
    alias sts_dec_err is sts_reg(1);
    alias sts_okay is sts_reg(0);
  begin
    p_sts : process (clk)
    begin
      if (rising_edge(clk)) then
        if (aresetn = '0' or clr_sts = '1') then
          sts_reg <= (others => '0');
        elsif (sts_tvalid = '1') then
          -- Only overwrite status word register if no error in previous
          if (sts_error = '0') then
            sts_reg <= sts_tdata;
          end if;
        end if;
      end if;
    end process p_sts;

    sts_error      <= sts_slv_err or sts_dec_err;
    sts_error_mask <= sts_reg(2 downto 1);

    -- The STS interface is always ready, so a handshake occurs whenever valid
    -- is high
    sts_handshake <= sts_tvalid;

    -- We are done when we get an OKAY status word back with 1 as the tag
    transfer_done <= '1' when sts_last = '1' and sts_okay = '1' else '0';
  end block b_sts;

  --------------------------------------------------------------------------------
  -- Completion tally
  --
  -- Keeps track of the number of issued commands vs the number of received
  -- status words. When 0, the two are balanced.
  --------------------------------------------------------------------------------
  process (clk) is
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
