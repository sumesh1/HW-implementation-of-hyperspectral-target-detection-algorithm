library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use ieee.math_real.all;
use work.funcs."gcd";

entity component_joiner is
  generic (
    C_IN_DATA_WIDTH  : integer := 64;
    C_OUT_DATA_WIDTH : integer := 64;
    C_COMP_WIDTH     : integer := 12
    );
  port (
    clk     : in std_logic;
    aresetn : in std_logic;

    in_tdata  : in  std_logic_vector(C_IN_DATA_WIDTH-1 downto 0);
    in_tvalid : in  std_logic;
    in_tready : out std_logic;
    in_tlast  : in  std_logic;

    out_num_req : out integer range 0 to C_OUT_DATA_WIDTH/C_COMP_WIDTH;

    out_tdata  : out std_logic_vector(C_OUT_DATA_WIDTH-1 downto 0);
    out_tvalid : out std_logic;
    out_tready : in  std_logic;
    out_tlast  : out std_logic
    );
end component_joiner;

architecture Behavioral of component_joiner is
  constant C_COUNT_MAX : integer := C_COMP_WIDTH / gcd(C_OUT_DATA_WIDTH, C_COMP_WIDTH) - 1;

  signal count        : integer range 0 to C_COUNT_MAX;
  signal buf_reg      : std_logic_vector(C_COMP_WIDTH-3 downto 0);
  signal buf_nxt      : std_logic_vector(C_COMP_WIDTH-3 downto 0);
  signal in_handshake : std_logic;
  signal out_last     : std_logic;
  signal in_ready     : std_logic;
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
    variable FROM_BUFFER_SIZE : integer;  -- How many bits to take from buffer register
    variable TO_BUFFER_SIZE   : integer;  -- How many bits to put in buffer register
    variable NUM_IN           : integer;  -- How many components are output
                                          -- this cycle
    variable IN_SIZE          : integer;  -- How many bits are output this cycle
  begin
    out_tdata   <= (others => '0');
    buf_nxt     <= buf_reg;
    out_num_req <= 0;

    for i in 0 to C_COUNT_MAX loop
      NUM_IN         := ((i+1)*C_OUT_DATA_WIDTH)/C_COMP_WIDTH - (i*C_OUT_DATA_WIDTH)/C_COMP_WIDTH;
      IN_SIZE        := NUM_IN*C_COMP_WIDTH;
      TO_BUFFER_SIZE := i*C_OUT_DATA_WIDTH mod C_COMP_WIDTH;
      FROM_BUFFER_SIZE := (i+1)*C_OUT_DATA_WIDTH mod C_COMP_WIDTH;

      if (count = i) then
        out_tdata(FROM_BUFFER_SIZE-1 downto 0)                <= buf_reg(FROM_BUFFER_SIZE-1 downto 0);
        out_tdata(C_OUT_DATA_WIDTH-1 downto FROM_BUFFER_SIZE) <= in_tdata(C_OUT_DATA_WIDTH-FROM_BUFFER_SIZE-1 downto 0);

        if (in_handshake = '1') then
          buf_nxt(TO_BUFFER_SIZE-1 downto 0) <= in_tdata(IN_SIZE-1 downto IN_SIZE - TO_BUFFER_SIZE);
        end if;

        out_num_req <= NUM_IN - 1;
      end if;
    end loop;
  end process;

  process (clk) is
  begin
    if (rising_edge(clk)) then
      if (aresetn = '0') then
        buf_reg <= (others => '0');
        count   <= C_COUNT_MAX;
      else
        buf_reg <= buf_nxt;
        if (in_handshake = '1') then
          if (count = 0 or out_last = '1') then
            count <= C_COUNT_MAX;
          else
            count <= count - 1;
          end if;
        end if;
      end if;
    end if;
  end process;

end Behavioral;
