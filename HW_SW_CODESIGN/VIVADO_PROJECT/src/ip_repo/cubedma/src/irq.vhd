  --------------------------------------------------------------------------------
  -- IRQ generator
  --
  -- Latches corresponding bits in irq_reg when trigger events happen. Bits are
  -- cleared when the corresponding bit in irq_clear is set. The output signal,
  -- irq_out, is asserted whenever a bit in irq_reg is set and the
  -- corresponding bit in irq_mask is set.
  --------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity irq_generator is
  generic (
    C_N_TRIGGERS : integer
    );
  port (
    clk     : in std_logic;
    aresetn : in std_logic;

    mask     : in std_logic_vector(C_N_TRIGGERS-1 downto 0);
    triggers : in std_logic_vector(C_N_TRIGGERS-1 downto 0);
    clear    : in std_logic_vector(C_N_TRIGGERS-1 downto 0);

    status : out std_logic_vector(C_N_TRIGGERS-1 downto 0);
    irq    : out std_logic
    );

end irq_generator;

architecture rtl of irq_generator is
  signal irq_reg : std_logic_vector(C_N_TRIGGERS-1 downto 0);
begin
  process (clk) is
  begin
    if (rising_edge(clk)) then
      if (aresetn = '0') then
        irq_reg <= (others => '0');
      else
        for i in 0 to C_N_TRIGGERS-1 loop
          if (triggers(i) = '1') then
            irq_reg(i) <= '1';
          elsif (clear(i) = '1') then
            irq_reg(i) <= '0';
          end if;
        end loop;
      end if;
    end if;
  end process;

  -- The IRQ output is the OR of every bit in irq_reg anded with the
  -- corresponding mask bit
  process (irq_reg, mask) is
    variable irq_masked : std_logic;
  begin
    irq_masked := '0';
    for i in 0 to irq_reg'high loop
      irq_masked := irq_masked or (irq_reg(i) and mask(i));
    end loop;
    irq <= irq_masked;
  end process;

  status <= irq_reg;
end rtl;
