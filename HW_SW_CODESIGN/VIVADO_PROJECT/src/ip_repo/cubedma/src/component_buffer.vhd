library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity component_buffer is
  generic (
    C_IN_DATA_WIDTH  : integer := 64;
    C_OUT_DATA_WIDTH : integer := 64;
    C_COMP_WIDTH     : integer := 12;
    C_MAX_NUM_OUTPUT : integer := 3;
    C_FIXED_OUTPUT   : boolean := false
    );
  port (
    clk     : in std_logic;
    aresetn : in std_logic;

    in_tdata     : in  std_logic_vector(C_IN_DATA_WIDTH-1 downto 0);
    in_tvalid    : in  std_logic;
    in_tready    : out std_logic;
    in_tlast     : in  std_logic;
    in_num_valid : in  integer range 0 to C_IN_DATA_WIDTH/8-1;

    out_num_req : in  integer range 0 to C_OUT_DATA_WIDTH/8-1;
    out_tdata   : out std_logic_vector(C_OUT_DATA_WIDTH-1 downto 0);
    out_tvalid  : out std_logic;
    out_tready  : in  std_logic;
    out_tlast   : out std_logic;
    out_num     : out integer range 0 to C_OUT_DATA_WIDTH/8-1
    );
end component_buffer;

architecture Behavioral of component_buffer is
  constant C_MAX_COMP_PER_WORD : integer := C_IN_DATA_WIDTH / C_COMP_WIDTH;
  constant C_INPUT_WIDTH       : integer := C_MAX_COMP_PER_WORD * C_COMP_WIDTH;
  constant C_MAX_LEFTOVER      : integer := C_MAX_NUM_OUTPUT - 1;
  constant C_BUFFER_CAPACITY   : integer := C_MAX_LEFTOVER + C_MAX_COMP_PER_WORD;
  constant C_REG_WIDTH         : integer := C_BUFFER_CAPACITY * C_COMP_WIDTH;
  constant C_BITS_OUTPUT       : integer := C_COMP_WIDTH * C_MAX_NUM_OUTPUT;

  signal buffer_reg     : std_logic_vector(C_REG_WIDTH-1 downto 0);
  signal buffer_reg_nxt : std_logic_vector(C_REG_WIDTH-1 downto 0);
  signal buffer_top     : integer range 0 to C_BUFFER_CAPACITY;
  signal out_data       : std_logic_vector(C_OUT_DATA_WIDTH-1 downto 0);

  signal in_ready      : std_logic;
  signal in_last       : std_logic;
  signal in_handshake  : std_logic;
  signal out_valid     : std_logic;
  signal out_handshake : std_logic;
  signal out_last      : std_logic;
  signal last_reg      : std_logic;
begin
  in_tready  <= in_ready;
  in_last    <= in_tlast;
  out_tvalid <= out_valid;
  out_tdata  <= out_data;

  in_handshake  <= in_ready and in_tvalid;
  out_handshake <= out_tready and out_valid;

  -- Generate muxes for selecting how to order the data in the component
  -- register in the next cycle
  process (out_num_req, in_tdata, buffer_reg, buffer_top, in_handshake, out_handshake) is
  begin
    buffer_reg_nxt <= buffer_reg;
    out_data       <= (others => '0');

    if (C_FIXED_OUTPUT) then
      out_data(C_BITS_OUTPUT-1 downto 0) <= buffer_reg(C_BITS_OUTPUT-1 downto 0);
      if (out_handshake = '1') then
        buffer_reg_nxt(C_REG_WIDTH-C_BITS_OUTPUT-1 downto 0) <= buffer_reg(C_REG_WIDTH-1 downto C_BITS_OUTPUT);
      end if;
    else
      for i in 0 to C_MAX_NUM_OUTPUT-1 loop
        if (out_num_req = i) then
          if (out_handshake = '1') then
            buffer_reg_nxt(C_REG_WIDTH-(i+1)*C_COMP_WIDTH-1 downto 0) <= buffer_reg(C_REG_WIDTH-1 downto (i+1)*C_COMP_WIDTH);
          end if;

          out_data((i+1)*C_COMP_WIDTH-1 downto 0) <= buffer_reg((i+1)*C_COMP_WIDTH-1 downto 0);
        end if;
      end loop;
    end if;

    if (in_handshake = '1') then
      for i in 0 to C_MAX_LEFTOVER loop
        if ((out_handshake = '1' and buffer_top - out_num_req - 1 = i) or
            (out_handshake = '0' and buffer_top = i)) then
          buffer_reg_nxt(C_COMP_WIDTH * i + C_INPUT_WIDTH - 1 downto C_COMP_WIDTH * i) <= in_tdata(C_INPUT_WIDTH-1 downto 0);
        end if;
      end loop;
    end if;
  end process;

  -- Stream input control
  process (out_num_req, buffer_top, out_handshake, last_reg) is
  begin
    -- We are ready to receive data when we either have free space already, or
    -- if we will complete a transaction on the output this cycle that will
    -- leave enough space
    if (last_reg = '1') then
      in_ready <= '0';
    elsif (buffer_top <= C_MAX_LEFTOVER) then
      in_ready <= '1';
    elsif (out_handshake = '1' and buffer_top - out_num_req - 1 <= C_MAX_LEFTOVER) then
      in_ready <= '1';
    else
      in_ready <= '0';
    end if;
  end process;

  -- Stream output control
  process (out_num_req, buffer_top, in_handshake, out_last, last_reg) is
  begin
    -- The output is valid if we have enough data lined up, which is the case
    -- when we have at least num_output components in the buffer, or we are in
    -- the last case and there is *something* in the buffer
    if (buffer_top >= out_num_req + 1) then
      out_valid <= '1';
      out_num   <= out_num_req + 1;
    elsif (last_reg = '1' and buffer_top > 0) then
      out_valid <= '1';
      out_num   <= buffer_top;
    else
      out_valid <= '0';
      out_num   <= 0;
    end if;

  end process;

  process (clk) is
    variable next_buffer_top : integer range 0 to C_BUFFER_CAPACITY;
  begin
    if (rising_edge(clk)) then
      if (aresetn = '0') then
        buffer_reg <= (others => '0');
        buffer_top <= 0;
        last_reg   <= '0';
      else
        buffer_reg <= buffer_reg_nxt;

        next_buffer_top := buffer_top;
        if (out_handshake = '1') then
          next_buffer_top := next_buffer_top - out_num_req - 1;
        end if;
        if (in_handshake = '1') then
          next_buffer_top := next_buffer_top + in_num_valid + 1;
        end if;

        if (out_last = '1') then
          buffer_top <= 0;
        else
          buffer_top <= next_buffer_top;
        end if;

        -- If we are handshaking on the last input word, then we'll keep last_reg
        -- high in the next cycles, until the last transfer occurs on the output.
        if (in_last = '1' and in_handshake = '1') then
          last_reg <= '1';
        elsif (out_last = '1') then
          last_reg <= '0';
        end if;

      end if;
    end if;
  end process;

  out_last  <= '1' when last_reg = '1' and out_handshake = '1' and buffer_top <= out_num_req + 1 else '0';
  out_tlast <= out_last;

end Behavioral;
