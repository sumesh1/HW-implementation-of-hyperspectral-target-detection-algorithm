--------------------------------------------------------------------------------
--
-- Component aligner
--
-- The component aligner takes a stream of pixel components, as stored in
-- memory, and breaks the data up such that each beat on the output stream
-- contains a maximum number of whole components. For instance, if data width
-- is 64 bits and the component width is 12 bits, the output stream will
-- contain 5 components (60 bits).
--
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use ieee.math_real.all;

use work.funcs."gcd";

entity component_aligner is
  generic (
    C_IN_DATA_WIDTH : integer := 64;
    C_OUT_DATA_WIDTH : integer := 64;
    C_COMP_WIDTH    : integer := 12
    );
  port (
    clk     : in std_logic;
    aresetn : in std_logic;

    num_last : in std_logic_vector(4 downto 0);

    in_tdata  : in  std_logic_vector(C_IN_DATA_WIDTH-1 downto 0);
    in_tvalid : in  std_logic;
    in_tready : out std_logic;
    in_tlast  : in  std_logic;

    out_num_valid : out integer range 0 to C_OUT_DATA_WIDTH/C_COMP_WIDTH-1;

    out_tdata     : out std_logic_vector(C_OUT_DATA_WIDTH-1 downto 0);
    out_tvalid    : out std_logic;
    out_tready    : in  std_logic;
    out_tlast     : out std_logic
    );
end component_aligner;

architecture Behavioral of component_aligner is
  constant C_COUNT_MAX : integer := C_COMP_WIDTH / gcd(C_IN_DATA_WIDTH, C_COMP_WIDTH) - 1;

  signal count          : integer range 0 to C_COUNT_MAX;
  signal buf_reg        : std_logic_vector(C_COMP_WIDTH-3 downto 0);
  signal buf_nxt        : std_logic_vector(C_COMP_WIDTH-3 downto 0);
  signal in_handshake   : std_logic;
  signal out_last       : std_logic;
  signal num_valid      : integer range 0 to C_IN_DATA_WIDTH/8-1;
  signal num_valid_last : integer range 0 to C_IN_DATA_WIDTH/8-1;
  signal in_ready       : std_logic;
begin
  in_tready <= in_ready;

  out_tvalid <= in_tvalid;
  out_last   <= in_tlast;
  out_tlast  <= out_last;
  in_ready   <= out_tready;

  in_handshake <= in_ready and in_tvalid;

  -- Conversion logic
  process (in_handshake, in_tdata, buf_reg, count) is
    -- The number of bits in the incoming word that are left over when the
    -- maximum number of whole components have been extracted
    constant C_LEFTOVER : integer := C_IN_DATA_WIDTH mod C_COMP_WIDTH;

    variable FROM_BUFFER_SIZE : integer;  -- How many bits to take from buffer register
    variable NUM_OUT          : integer;  -- How many components are output
                                          -- this cycle
    variable OUT_SIZE         : integer;  -- How many bits are output this cycle
  begin
    out_tdata <= (others => '0');
    buf_nxt   <= buf_reg;
    num_valid <= 0;

    for i in 0 to C_COUNT_MAX loop
      if (count = i) then
        FROM_BUFFER_SIZE := i*C_LEFTOVER mod C_COMP_WIDTH;
        NUM_OUT          := ((i+1)*C_IN_DATA_WIDTH)/C_COMP_WIDTH - (i*C_IN_DATA_WIDTH)/C_COMP_WIDTH;
        OUT_SIZE         := NUM_OUT * C_COMP_WIDTH;

        out_tdata(FROM_BUFFER_SIZE-1 downto 0)        <= buf_reg(buf_reg'length-1 downto buf_reg'length - FROM_BUFFER_SIZE);
        out_tdata(OUT_SIZE-1 downto FROM_BUFFER_SIZE) <= in_tdata(OUT_SIZE-FROM_BUFFER_SIZE-1 downto 0);

        num_valid <= NUM_OUT - 1;
      end if;
    end loop;
    if (in_handshake = '1') then
      buf_nxt <= in_tdata(C_IN_DATA_WIDTH-1 downto C_IN_DATA_WIDTH - buf_reg'length);
    end if;
  end process;

  process (in_tlast, num_last, num_valid, count) is
    constant C_BLOCK_SIZE      : integer := C_IN_DATA_WIDTH / gcd(C_IN_DATA_WIDTH, C_COMP_WIDTH);
    constant C_BLOCK_SIZE_BITS : integer := integer(log2(real(C_BLOCK_SIZE)));

    variable LOWEST_COMP : integer;
    variable remains     : integer range 0 to C_BLOCK_SIZE-1;
  begin
    remains        := to_integer(unsigned(num_last(C_BLOCK_SIZE_BITS-1 downto 0)));
    num_valid_last <= 0;

    for i in 0 to C_COUNT_MAX loop
      LOWEST_COMP := (i*C_IN_DATA_WIDTH)/C_COMP_WIDTH;
      if (count = i and in_tlast = '1') then
        if (remains = 0 or remains = LOWEST_COMP) then
          num_valid_last <= num_valid;
        else
          num_valid_last <= remains - LOWEST_COMP - 1;
        end if;
      end if;
    end loop;
  end process;

  out_num_valid <= num_valid_last when in_tlast = '1' else num_valid;

  process (clk) is
  begin
    if (rising_edge(clk)) then
      if (aresetn = '0') then
        buf_reg <= (others => '0');
        count <= 0;
      else
        buf_reg <= buf_nxt;
        if (in_handshake = '1') then
          if (count = C_COUNT_MAX or out_last = '1') then
            count <= 0;
          else
            count <= count + 1;
          end if;
        end if;
      end if;
    end if;
  end process;

end Behavioral;
