library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use ieee.math_real.all;

entity offset_shifter is
  generic (
    C_DATA_WIDTH   : integer := 64;
    C_BLOCK_WIDTH  : integer := 2;
    C_OFFSET_WIDTH : integer := 2
    );
  port (
    clk     : in std_logic;
    aresetn : in std_logic;

    offset        : in std_logic_vector(C_OFFSET_WIDTH-1 downto 0);
    truncate_last : in std_logic;

    in_tdata  : in  std_logic_vector(C_DATA_WIDTH-1 downto 0);
    in_tvalid : in  std_logic;
    in_tready : out std_logic;
    in_tlast  : in  std_logic;

    out_tdata  : out std_logic_vector(C_DATA_WIDTH-1 downto 0);
    out_tvalid : out std_logic;
    out_tready : in  std_logic;
    out_tlast  : out std_logic);
end offset_shifter;

architecture Behavioral of offset_shifter is
  signal prev_data_reg  : std_logic_vector(C_DATA_WIDTH-1 downto 0);
  signal last_reg       : std_logic;
  signal prev_valid_reg : std_logic;
  signal in_ready       : std_logic;
  signal in_handshake   : std_logic;
  signal out_valid      : std_logic;
  signal out_handshake  : std_logic;
  signal offset_reg : std_logic_vector(C_OFFSET_WIDTH-1 downto 0);
begin
  in_ready      <= out_tready;
  in_tready     <= in_ready;
  in_handshake  <= in_ready and in_tvalid;
  out_handshake <= out_tready and out_valid;
  out_tvalid    <= out_valid;

  -- Offset mux
  process (in_tdata, in_tlast, last_reg, in_handshake, prev_valid_reg, prev_data_reg, offset_reg, truncate_last) is
  begin
    out_tdata <= (others => '0');
    out_valid <= '0';
    out_tlast <= '0';

    for i in 0 to 2**C_OFFSET_WIDTH-1 loop
      if (unsigned(offset_reg) = i) then
        -- If offset is not 0, then we shift by 2 * offset, and we delay
        -- TLAST and TVALID by one cycle
        if (last_reg = '1') then
          out_tdata <= (C_BLOCK_WIDTH*i-1 downto 0 => '0') & prev_data_reg(C_DATA_WIDTH-1 downto C_BLOCK_WIDTH*i);
          out_valid <= prev_valid_reg;
        else
          out_tdata <= in_tdata(C_BLOCK_WIDTH*i-1 downto 0) & prev_data_reg(C_DATA_WIDTH-1 downto C_BLOCK_WIDTH*i);
          out_valid <= in_handshake and prev_valid_reg;
        end if;

        -- If the current input is the last one, and we should truncate the
        -- transfer, this will be the last word to output. Otherwise, use the
        -- delayed last signal
        if (in_tlast = '1' and truncate_last = '1') then
          out_tlast <= '1';
        else
          out_tlast <= last_reg;
        end if;
      end if;
    end loop;
  end process;

  -- Control logic
  process (clk) is
  begin
    if (rising_edge(clk)) then
      if (aresetn = '0') then
        prev_data_reg  <= (others => '0');
        prev_valid_reg <= '0';
        last_reg       <= '0';
      else
        if (in_handshake = '1') then
          last_reg <= in_tlast;
          prev_data_reg <= in_tdata;
          offset_reg <= offset;

          -- When receiving the last input word and the last output should be
          -- truncated, the next cycle will not have valid data
          if (in_tlast = '1' and truncate_last = '1') then
            prev_valid_reg <= '0';
          else
            prev_valid_reg <= '1';
          end if;
        elsif (out_handshake = '1') then
          prev_valid_reg <= '0';
        end if;
      end if;
    end if;
  end process;
end Behavioral;
