library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use ieee.math_real.all;

  --------------------------------------------------------------------------------
  -- Component address generation for block and plane transfers
  --
  -- Input values (from register interface):
  --
  -- length          - the number of components per transfer
  -- depth           - the number of planes in the cube
  -- block_width     - block width in number of pixels
  -- block_height    - block height in number of pixels
  -- width           - width of image in number of components
  -- block_skip_last - number of components to skip to get to the next block when
  --                   currently in the last block in a row
  --
  --
  -- Internal variables/signals:
  --
  -- block_y, block_x   - used to keep track of the current block being transferred
  -- x, y               - used to keep track of the current pixel within the current
  --                      block (when doing a planewise transfer)
  -- block_address      - temporary register to keep track of the start address of
  --                      the current block
  -- row_address        - temporary register to keep track of the start of the
  --                      current row
  --------------------------------------------------------------------------------

entity address_gen is
  generic (
    C_COMP_WIDTH : integer := 12;
    C_NUM_COMP   : integer := 4
    );
  port (
    clk     : in std_logic;
    aresetn : in std_logic;

    tick  : in std_logic;
    start : in std_logic;

    -- Configuration registers
    mode_block            : in std_logic;
    mode_plane            : in std_logic;
    depth                 : in std_logic_vector(11 downto 0);
    width                 : in std_logic_vector(11 downto 0);
    height                : in std_logic_vector(11 downto 0);
    block_width           : in std_logic_vector(3 downto 0);
    block_height          : in std_logic_vector(3 downto 0);
    line_skip             : in std_logic_vector(19 downto 0);
    last_block_row_length : in std_logic_vector(19 downto 0);
    comp_offset           : in std_logic_vector(7 downto 0);
    num_plane_transfers   : in std_logic_vector(7 downto 0);
    base_address          : in std_logic_vector(31 downto 0);

    -- Address output
    start_address      : out std_logic_vector(31 downto 0);
    offset             : out std_logic_vector(2 downto 0);
    truncate_last_word : out std_logic;
    length_bytes       : out std_logic_vector(22 downto 0);
    length_comps       : out std_logic_vector(23 downto 0);

    -- Control signals
    last_pixel         : out std_logic;
    last_block_in_row  : out std_logic;
    last_pix_in_block  : out std_logic;
    last_row_of_blocks : out std_logic
    );
end address_gen;

architecture rtl of address_gen is
  signal block_y              : integer range 0 to 2**9-1;
  signal block_x              : integer range 0 to 2**9-1;
  signal y                    : integer range 0 to 2**12-1;
  signal x                    : integer range 0 to 2**12-1;
  signal plane_transfers_left : integer range 0 to 2**8-1;
  signal comp_address         : unsigned(31 downto 0);
  signal length               : unsigned(23 downto 0);

  signal block_row_length  : unsigned(23 downto 0);
  signal block_row_skip    : unsigned(31 downto 0);
  signal block_height_def  : integer range 0 to 2**12;
  signal block_width_def   : integer range 0 to 2**12;
  signal block_height_mod  : integer range 0 to 2**12;
  signal block_width_mod   : integer range 0 to 2**12;
  signal block_width_last  : integer range 0 to 2**12;
  signal block_height_last : integer range 0 to 2**12;

  function comp_mod(val : unsigned; modulus : unsigned) return integer is
    type mux_arr_t is array (0 to val'high) of integer range 0 to 2**12;
    variable mux_arr : mux_arr_t;
  begin
    for i in mux_arr'range loop
      mux_arr(i) := to_integer(val(i-1 downto 0));
    end loop;

    return mux_arr(to_integer(modulus));
  end comp_mod;

  function limit(val : integer; LIM : integer) return integer is
    variable res : integer range 0 to LIM;
  begin
    res := val;
    return res;
  end limit;

begin
  block_row_length <= shift_left(resize(unsigned(depth), 24), limit(to_integer(unsigned(block_width)), 12));
  block_row_skip   <= shift_left(resize(unsigned(line_skip), 32), limit(to_integer(unsigned(block_height)), 12));

  block_width_def   <= 2**to_integer(unsigned(block_width));
  block_height_def  <= 2**to_integer(unsigned(block_height));
  block_width_mod   <= comp_mod(unsigned(width), unsigned(block_width));
  block_height_mod  <= comp_mod(unsigned(height), unsigned(block_height));
  block_width_last  <= block_width_mod  when block_width_mod /= 0  else block_width_def;
  block_height_last <= block_height_mod when block_height_mod /= 0 else block_height_def;
  process (clk)
    variable row_address       : unsigned(31 downto 0);
    variable block_address     : unsigned(31 downto 0);
    variable block_row_address : unsigned(31 downto 0);

    variable num_blocks_x : integer range 0 to 2**12-1;
    variable num_blocks_y : integer range 0 to 2**12-1;

    variable plane_offset : integer range 0 to 2**8-1;
  begin
    if (rising_edge(clk)) then
      if (aresetn = '0') then
        block_y              <= 0;
        block_x              <= 0;
        y                    <= 0;
        x                    <= 0;
        block_address        := to_unsigned(0, 32);
        row_address          := to_unsigned(0, 32);
        block_row_address    := to_unsigned(0, 32);
        comp_address         <= to_unsigned(0, 32);
        length               <= to_unsigned(0, 24);
        plane_offset         := 0;
        plane_transfers_left <= 0;
      elsif (start = '1') then

        num_blocks_x := to_integer(shift_right(unsigned(width), to_integer(unsigned(block_width))));
        if (block_width_mod /= 0) then
          num_blocks_x := num_blocks_x + 1;
        end if;
        num_blocks_y := to_integer(shift_right(unsigned(height), to_integer(unsigned(block_height))));
        if (block_height_mod /= 0) then
          num_blocks_y := num_blocks_y + 1;
        end if;

        if (mode_block = '1') then
          y      <= block_height_def - 1;
          x      <= block_width_def - 1;
          length <= block_row_length;
        else
          y      <= to_integer(unsigned(height)) - 1;
          x      <= to_integer(unsigned(width)) - 1;
          length <= resize(unsigned(line_skip), 24);
        end if;

        -- If not plane mode, we collapse blocks down to 1 transfer per row
        if (mode_plane = '0') then
          x                    <= 0;
          plane_offset         := to_integer(unsigned(comp_offset));
          plane_transfers_left <= 0;
        else
          length               <= to_unsigned(C_NUM_COMP, 24);
          plane_transfers_left <= to_integer(unsigned(num_plane_transfers)) - 1;
        end if;

        block_y           <= num_blocks_y-1;
        block_x           <= num_blocks_x-1;
        block_address     := to_unsigned(plane_offset, 32);
        row_address       := to_unsigned(plane_offset, 32);
        block_row_address := to_unsigned(plane_offset, 32);
        comp_address      <= block_address;
      else
        if (tick = '1') then

          -- Go through block
          if (x /= 0) then
            x            <= x - 1;
            comp_address <= comp_address + unsigned(depth);
          else
            if (mode_plane = '0') then
              x <= 0;
            else
              if (mode_block = '1') then
                if ((y = 0 and block_x = 1) or (y > 0 and block_x = 0)) then
                  x <= block_width_last - 1;
                else
                  x <= block_width_def - 1;
                end if;
              else
                x <= to_integer(unsigned(width))-1;
              end if;
            end if;

            if (y /= 0) then
              y           <= y - 1;
              row_address := row_address + unsigned(line_skip);
            else
              if (mode_block = '1') then
                if ((block_x = 0 and block_y = 1) or (block_x > 0 and block_y = 0)) then
                  y <= block_height_last - 1;
                else
                  y <= block_height_def - 1;
                end if;
              else
                y <= to_integer(unsigned(height))-1;
              end if;

              if (mode_block = '0') then
                plane_transfers_left <= plane_transfers_left - 1;
                plane_offset         := plane_offset + C_NUM_comp;
                row_address          := to_unsigned(plane_offset, 32);
              else
                if (block_x /= 0) then
                  block_x       <= block_x - 1;
                  block_address := block_address + block_row_length;
                else
                  block_x           <= num_blocks_x - 1;
                  block_row_address := block_row_address + block_row_skip;
                  block_address     := block_row_address;

                  if (block_y /= 0) then
                    block_y <= block_y - 1;
                  else
                    block_y              <= num_blocks_y - 1;
                    plane_transfers_left <= plane_transfers_left - 1;
                    plane_offset         := plane_offset + C_NUM_COMP;
                    block_address        := to_unsigned(plane_offset, 32);
                    row_address          := to_unsigned(plane_offset, 32);
                    block_row_address    := to_unsigned(plane_offset, 32);
                  end if;
                end if;
                row_address := block_address;
              end if;
            end if;
            comp_address <= row_address;

            if (mode_plane = '0' and mode_block = '1') then
              if (x = 0 and y = 0 and block_x = 1) then
                length <= resize(unsigned(last_block_row_length), 24);
              elsif (x = 0 and y = 0 and block_x = 0) then
                length <= unsigned(block_row_length);
              end if;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  last_block_in_row  <= '1' when (block_x = 0)     else '0';
  last_pix_in_block  <= '1' when (x = 0 and y = 0) else '0';
  last_row_of_blocks <= '1' when (block_y = 0)     else '0';
  last_pixel <= '1' when ((mode_block = '0' or (block_y = 0 and block_x = 0))
                          and x = 0 and y = 0
                          and plane_transfers_left = 0)
                          else '0';

  --------------------------------------------------------------------------------
  -- Convert component address to memory address, start offset and control signals
  --
  -- A component address has a unit of the selected component width. When
  -- converted to byte unit addresses, this results in a byte-level address (a
  -- regular memory address), and an offset within this byte.
  --
  -- The memory address is found by multiplying the component address by the
  -- component width and dividing by 8 bits. The offset is found by taking the
  -- remainder of this division.
  --------------------------------------------------------------------------------
  process (comp_address, base_address, length)
    constant C_COMP_WIDTH_BITS : integer := integer(log2(real(C_COMP_WIDTH))) + 1;

    variable bit_address  : unsigned(31 + C_COMP_WIDTH_BITS downto 0);
    variable byte_address : unsigned(31 + C_COMP_WIDTH_BITS downto 0);
    variable length_bits  : unsigned(23 + C_COMP_WIDTH_BITS downto 0);
    variable length_temp  : unsigned(23 + C_COMP_WIDTH_BITS downto 0);
  begin
    bit_address  := comp_address * to_unsigned(C_COMP_WIDTH, C_COMP_WIDTH_BITS);
    byte_address := unsigned(base_address) + bit_address/8;
    length_bits  := unsigned(length(23 downto 0)) * to_unsigned(C_COMP_WIDTH, C_COMP_WIDTH_BITS);
    length_temp  := bit_address(2 downto 0) + length_bits;

    start_address <= std_logic_vector(byte_address(31 downto 0));
    offset        <= std_logic_vector(bit_address(2 downto 0));
    length_bytes  <= std_logic_vector((length_temp(22 downto 0) + 7)/8);
    if ((length_temp(6 downto 0) + 63)/64 /= (length_bits(6 downto 0) + 63)/64) then
      truncate_last_word <= '1';
    else
      truncate_last_word <= '0';
    end if;
  end process;

  length_comps <= std_logic_vector(length);

end rtl;
