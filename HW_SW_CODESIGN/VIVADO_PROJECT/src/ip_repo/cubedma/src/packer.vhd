library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use ieee.math_real.all;

entity packer is
  generic (
    C_IN_DATA_WIDTH  : integer := 64;
    C_OUT_DATA_WIDTH : integer := 64;
    C_COMP_WIDTH     : integer := 8;
    C_NUM_COMP       : integer := 8
    );
  port (
    clk     : in std_logic;
    aresetn : in std_logic;

    in_tdata  : in  std_logic_vector(C_IN_DATA_WIDTH-1 downto 0);
    in_tvalid : in  std_logic;
    in_tready : out std_logic;
    in_tlast  : in  std_logic;

    out_tdata  : out std_logic_vector(C_OUT_DATA_WIDTH-1 downto 0);
    out_tvalid : out std_logic;
    out_tready : in  std_logic;
    out_tlast  : out std_logic
    );
end packer;

architecture Behavioral of packer is
  constant C_BUFFER_MAX_OUT  : integer := integer(ceil(real(C_OUT_DATA_WIDTH)/real(C_COMP_WIDTH)));
  constant C_JOINER_IN_WIDTH : integer := C_BUFFER_MAX_OUT * C_COMP_WIDTH;

  signal from_buffer_tdata   : std_logic_vector(C_JOINER_IN_WIDTH-1 downto 0);
  signal from_buffer_num_req : integer range 0 to C_BUFFER_MAX_OUT - 1;
  signal from_buffer_tvalid  : std_logic;
  signal from_buffer_tready  : std_logic;
  signal from_buffer_tlast   : std_logic;
begin

  i_buffer : entity work.component_buffer
    generic map (
      C_IN_DATA_WIDTH  => C_IN_DATA_WIDTH,
      C_OUT_DATA_WIDTH => C_JOINER_IN_WIDTH,
      C_COMP_WIDTH     => C_COMP_WIDTH,
      C_MAX_NUM_OUTPUT => C_BUFFER_MAX_OUT)
    port map (
      clk     => clk,
      aresetn => aresetn,

      in_tdata     => in_tdata,
      in_tvalid    => in_tvalid,
      in_tready    => in_tready,
      in_tlast     => in_tlast,
      in_num_valid => C_NUM_COMP-1,

      out_num_req      => from_buffer_num_req,
      out_tdata        => from_buffer_tdata,
      out_tvalid       => from_buffer_tvalid,
      out_tready       => from_buffer_tready,
      out_tlast        => from_buffer_tlast,
      out_num          => open
      );

  g_joiner : if (C_OUT_DATA_WIDTH mod C_COMP_WIDTH /= 0) generate
    signal from_joiner_tdata  : std_logic_vector(C_OUT_DATA_WIDTH-1 downto 0);
    signal from_joiner_tvalid : std_logic;
    signal from_joiner_tready : std_logic;
    signal from_joiner_tlast  : std_logic;
  begin
    i_comp_joiner : entity work.component_joiner
      generic map (
        C_IN_DATA_WIDTH  => C_JOINER_IN_WIDTH,
        C_OUT_DATA_WIDTH => C_OUT_DATA_WIDTH,
        C_COMP_WIDTH     => C_COMP_WIDTH
        )
      port map (
        clk     => clk,
        aresetn => aresetn,

        in_tdata  => from_buffer_tdata,
        in_tvalid => from_buffer_tvalid,
        in_tready => from_buffer_tready,
        in_tlast  => from_buffer_tlast,

        out_num_req => from_buffer_num_req,

        out_tdata  => out_tdata,
        out_tvalid => out_tvalid,
        out_tready => out_tready,
        out_tlast  => out_tlast
        );
  end generate g_joiner;

  g_nojoiner : if (C_OUT_DATA_WIDTH mod C_COMP_WIDTH = 0) generate
    from_buffer_num_req <= C_BUFFER_MAX_OUT-1;
    out_tdata           <= (C_OUT_DATA_WIDTH-1 downto C_JOINER_IN_WIDTH => '0') & from_buffer_tdata;
    out_tvalid          <= from_buffer_tvalid;
    from_buffer_tready  <= out_tready;
    out_tlast           <= from_buffer_tlast;
  end generate g_nojoiner;

end Behavioral;

