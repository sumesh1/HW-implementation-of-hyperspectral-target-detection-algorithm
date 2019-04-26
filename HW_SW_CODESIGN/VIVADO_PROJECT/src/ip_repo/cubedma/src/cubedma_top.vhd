library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real."ceil";

use work.compdecls.all;

entity cubedma_top is
  generic (
    C_MM2S_AXIS_WIDTH : integer := 64;
    C_MM2S_COMP_WIDTH : integer := 8;
    C_MM2S_NUM_COMP   : integer := 8;
    C_TINYMOVER       : boolean := false;
    C_S2MM_AXIS_WIDTH : integer := 48;
    C_S2MM_COMP_WIDTH : integer := 48;
    C_S2MM_NUM_COMP   : integer := 1
    );
  port (
    clk     : in std_logic;
    aresetn : in std_logic;

    -- Memory interface (read and write)
    m_axi_mem_araddr  : out std_logic_vector(31 downto 0);
    m_axi_mem_arlen   : out std_logic_vector(3 downto 0);
    m_axi_mem_arsize  : out std_logic_vector(2 downto 0);
    m_axi_mem_arburst : out std_logic_vector(1 downto 0);
    m_axi_mem_arprot  : out std_logic_vector(2 downto 0);
    m_axi_mem_arcache : out std_logic_vector(3 downto 0);
    m_axi_mem_arvalid : out std_logic;
    m_axi_mem_arready : in  std_logic;
    m_axi_mem_rdata   : in  std_logic_vector(63 downto 0);
    m_axi_mem_rresp   : in  std_logic_vector(1 downto 0);
    m_axi_mem_rlast   : in  std_logic;
    m_axi_mem_rvalid  : in  std_logic;
    m_axi_mem_rready  : out std_logic;

    m_axi_mem_awaddr  : out std_logic_vector(31 downto 0);
    m_axi_mem_awlen   : out std_logic_vector(3 downto 0);
    m_axi_mem_awsize  : out std_logic_vector(2 downto 0);
    m_axi_mem_awburst : out std_logic_vector(1 downto 0);
    m_axi_mem_awprot  : out std_logic_vector(2 downto 0);
    m_axi_mem_awcache : out std_logic_vector(3 downto 0);
    m_axi_mem_awvalid : out std_logic;
    m_axi_mem_awready : in  std_logic;
    m_axi_mem_wdata   : out std_logic_vector(63 downto 0);
    m_axi_mem_wstrb   : out std_logic_vector(7 downto 0);
    m_axi_mem_wlast   : out std_logic;
    m_axi_mem_wvalid  : out std_logic;
    m_axi_mem_wready  : in  std_logic;
    m_axi_mem_bresp   : in  std_logic_vector(1 downto 0);
    m_axi_mem_bvalid  : in  std_logic;
    m_axi_mem_bready  : out std_logic;

    -- MM2S stream data interface
    m_axis_mm2s_tdata  : out std_logic_vector(C_MM2S_AXIS_WIDTH-1 downto 0);
    m_axis_mm2s_tlast  : out std_logic;
    m_axis_mm2s_tvalid : out std_logic;
    m_axis_mm2s_tready : in  std_logic;
    mm2s_ctrl          : out std_logic_vector(C_MM2S_NUM_COMP * 2 - 1 downto 0);

    -- S2MM stream data interface
    s_axis_s2mm_tdata  : in  std_logic_vector(C_S2MM_AXIS_WIDTH-1 downto 0);
    s_axis_s2mm_tlast  : in  std_logic;
    s_axis_s2mm_tvalid : in  std_logic;
    s_axis_s2mm_tready : out std_logic;

    -- Register interface
    s_axi_ctrl_status_awaddr  : in  std_logic_vector(5 downto 0);
    s_axi_ctrl_status_awprot  : in  std_logic_vector(2 downto 0);
    s_axi_ctrl_status_awvalid : in  std_logic;
    s_axi_ctrl_status_awready : out std_logic;
    s_axi_ctrl_status_wdata   : in  std_logic_vector(31 downto 0);
    s_axi_ctrl_status_wstrb   : in  std_logic_vector(3 downto 0);
    s_axi_ctrl_status_wvalid  : in  std_logic;
    s_axi_ctrl_status_wready  : out std_logic;
    s_axi_ctrl_status_bresp   : out std_logic_vector(1 downto 0);
    s_axi_ctrl_status_bvalid  : out std_logic;
    s_axi_ctrl_status_bready  : in  std_logic;
    s_axi_ctrl_status_araddr  : in  std_logic_vector(5 downto 0);
    s_axi_ctrl_status_arprot  : in  std_logic_vector(2 downto 0);
    s_axi_ctrl_status_arvalid : in  std_logic;
    s_axi_ctrl_status_arready : out std_logic;
    s_axi_ctrl_status_rdata   : out std_logic_vector(31 downto 0);
    s_axi_ctrl_status_rresp   : out std_logic_vector(1 downto 0);
    s_axi_ctrl_status_rvalid  : out std_logic;
    s_axi_ctrl_status_rready  : in  std_logic;

    mm2s_irq : out std_logic;
    s2mm_irq : out std_logic
    );
end cubedma_top;

architecture Behavioral of cubedma_top is
  constant C_MM2S_DATA_WIDTH : integer := C_MM2S_NUM_COMP * C_MM2S_COMP_WIDTH;
  constant C_S2MM_DATA_WIDTH : integer := C_S2MM_NUM_COMP * C_S2MM_COMP_WIDTH;

  -- Control / status registers
  signal mm2s_control_length_reg : std_logic_vector(31 downto 0);
  signal mm2s_base_reg           : std_logic_vector(31 downto 0);
  signal mm2s_dimension_reg      : std_logic_vector(31 downto 0);
  signal mm2s_block_reg          : std_logic_vector(31 downto 0);
  signal mm2s_line_skip_reg      : std_logic_vector(31 downto 0);
  signal mm2s_status_reg_rd      : std_logic_vector(31 downto 0);
  signal mm2s_status_reg_wr      : std_logic_vector(31 downto 0);

  signal s2mm_control_length_reg : std_logic_vector(31 downto 0);
  signal s2mm_base_reg           : std_logic_vector(31 downto 0);
  signal s2mm_status_reg_rd      : std_logic_vector(31 downto 0);
  signal s2mm_status_reg_wr      : std_logic_vector(31 downto 0);
  signal s2mm_length_reg_rd      : std_logic_vector(31 downto 0);
begin

  --------------------------------------------------------------------------------
  -- Control / status register interface/decoder
  --------------------------------------------------------------------------------
  i_register_interface : entity work.register_interface
    port map (
      s_axi_aclk    => clk,
      s_axi_aresetn => aresetn,

      s_axi_awaddr  => s_axi_ctrl_status_awaddr,
      s_axi_awprot  => s_axi_ctrl_status_awprot,
      s_axi_awvalid => s_axi_ctrl_status_awvalid,
      s_axi_awready => s_axi_ctrl_status_awready,

      s_axi_wdata  => s_axi_ctrl_status_wdata,
      s_axi_wstrb  => s_axi_ctrl_status_wstrb,
      s_axi_wvalid => s_axi_ctrl_status_wvalid,
      s_axi_wready => s_axi_ctrl_status_wready,

      s_axi_bresp  => s_axi_ctrl_status_bresp,
      s_axi_bvalid => s_axi_ctrl_status_bvalid,
      s_axi_bready => s_axi_ctrl_status_bready,

      s_axi_araddr  => s_axi_ctrl_status_araddr,
      s_axi_arprot  => s_axi_ctrl_status_arprot,
      s_axi_arvalid => s_axi_ctrl_status_arvalid,
      s_axi_arready => s_axi_ctrl_status_arready,

      s_axi_rdata  => s_axi_ctrl_status_rdata,
      s_axi_rresp  => s_axi_ctrl_status_rresp,
      s_axi_rvalid => s_axi_ctrl_status_rvalid,
      s_axi_rready => s_axi_ctrl_status_rready,

      -- Register outputs
      mm2s_control_length_reg => mm2s_control_length_reg,
      mm2s_base_reg           => mm2s_base_reg,
      mm2s_dimension_reg      => mm2s_dimension_reg,
      mm2s_block_reg          => mm2s_block_reg,
      mm2s_line_skip_reg      => mm2s_line_skip_reg,
      mm2s_status_reg_wr      => mm2s_status_reg_wr,

      s2mm_control_length_reg => s2mm_control_length_reg,
      s2mm_base_reg           => s2mm_base_reg,
      s2mm_status_reg_wr      => s2mm_status_reg_wr,

      -- Register inputs
      s2mm_status_reg_rd => s2mm_status_reg_rd,
      mm2s_status_reg_rd => mm2s_status_reg_rd,
      s2mm_length_reg_rd => s2mm_length_reg_rd
      );

  --------------------------------------------------------------------------------
  -- MM2S
  --------------------------------------------------------------------------------
  b_mm2s : block is
    -- Stream from datamover
    signal from_mover_tdata  : std_logic_vector(63 downto 0);
    signal from_mover_tvalid : std_logic;
    signal from_mover_tready : std_logic;
    signal from_mover_tlast  : std_logic;

    signal cmd_tvalid : std_logic;
    signal cmd_tready : std_logic;

    signal sts_tvalid : std_logic;

    -- MM2S unpacker configuration
    signal unpacker_config_data  : std_logic_vector(11 downto 0);
    signal unpacker_config_wr    : std_logic;
    signal unpacker_config_ready : std_logic;

  begin

    --------------------------------------------------------------------------------
    -- DataMover implementation
    --------------------------------------------------------------------------------
    g_datamover : if (not C_TINYMOVER) generate
      signal cmd_tdata         : std_logic_vector(71 downto 0);
      signal sts_tdata         : std_logic_vector(7 downto 0);
      signal datamover_error   : std_logic;
      signal datamover_aresetn : std_logic;
      signal force_aresetn     : std_logic;
    begin
      i_mm2s_controller : entity work.channel_controller
        generic map (
          C_COMP_WIDTH => C_MM2S_COMP_WIDTH,
          C_NUM_COMP   => C_MM2S_NUM_COMP
          )
        port map (
          clk     => clk,
          aresetn => aresetn,

          cmd_tvalid => cmd_tvalid,
          cmd_tready => cmd_tready,
          cmd_tdata  => cmd_tdata,

          sts_tvalid => sts_tvalid,
          sts_tdata  => sts_tdata,

          channel_aresetn => force_aresetn,
          channel_error   => datamover_error,

          config_data  => unpacker_config_data,
          config_wr    => unpacker_config_wr,
          config_ready => unpacker_config_ready,

          control_length_reg => mm2s_control_length_reg,
          base_reg           => mm2s_base_reg,
          dimension_reg      => mm2s_dimension_reg,
          block_reg          => mm2s_block_reg,
          line_skip_reg      => mm2s_line_skip_reg,
          status_reg_rd      => mm2s_status_reg_rd,
          status_reg_wr      => mm2s_status_reg_wr,
          length_reg_rd      => open,

          irq_out => mm2s_irq
          );

      -- Reset if external reset is applied or if the controller forces it
      -- when recovering from an error condition
      datamover_aresetn <= aresetn and force_aresetn;

      i_datamover_mm2s : axi_datamover_mm2s
        port map (
          m_axi_mm2s_aclk    => clk,
          m_axi_mm2s_aresetn => datamover_aresetn,

          mm2s_err => datamover_error,

          m_axis_mm2s_cmdsts_aclk    => clk,
          m_axis_mm2s_cmdsts_aresetn => datamover_aresetn,

          s_axis_mm2s_cmd_tvalid => cmd_tvalid,
          s_axis_mm2s_cmd_tready => cmd_tready,
          s_axis_mm2s_cmd_tdata  => cmd_tdata,

          m_axis_mm2s_sts_tvalid => sts_tvalid,
          m_axis_mm2s_sts_tready => '1',
          m_axis_mm2s_sts_tdata  => sts_tdata,
          m_axis_mm2s_sts_tkeep  => open,
          m_axis_mm2s_sts_tlast  => open,

          m_axi_mm2s_araddr            => m_axi_mem_araddr,
          m_axi_mm2s_arlen(3 downto 0) => m_axi_mem_arlen,
          m_axi_mm2s_arlen(7 downto 4) => open,
          m_axi_mm2s_arsize            => m_axi_mem_arsize,
          m_axi_mm2s_arburst           => m_axi_mem_arburst,
          m_axi_mm2s_arprot            => m_axi_mem_arprot,
          m_axi_mm2s_arcache           => m_axi_mem_arcache,
          m_axi_mm2s_aruser            => open,
          m_axi_mm2s_arvalid           => m_axi_mem_arvalid,
          m_axi_mm2s_arready           => m_axi_mem_arready,
          m_axi_mm2s_rdata             => m_axi_mem_rdata,
          m_axi_mm2s_rresp             => m_axi_mem_rresp,
          m_axi_mm2s_rlast             => m_axi_mem_rlast,
          m_axi_mm2s_rvalid            => m_axi_mem_rvalid,
          m_axi_mm2s_rready            => m_axi_mem_rready,

          m_axis_mm2s_tdata  => from_mover_tdata,
          m_axis_mm2s_tkeep  => open,
          m_axis_mm2s_tlast  => from_mover_tlast,
          m_axis_mm2s_tvalid => from_mover_tvalid,
          m_axis_mm2s_tready => from_mover_tready
          );
    end generate;

    --------------------------------------------------------------------------------
    -- TinyMover implementation
    --------------------------------------------------------------------------------
    g_tinymover : if (C_TINYMOVER) generate
      signal cmd_tdata : std_logic_vector(40 downto 0);
      signal sts_tdata : std_logic_vector(3 downto 0);
    begin

      i_tiny_chn_controller : entity work.tiny_chn_controller
        generic map (
          C_COMP_WIDTH => C_MM2S_COMP_WIDTH,
          C_NUM_COMP   => C_MM2S_NUM_COMP
          )
        port map (
          clk     => clk,
          aresetn => aresetn,

          cmd_tvalid => cmd_tvalid,
          cmd_tready => cmd_tready,
          cmd_tdata  => cmd_tdata,

          sts_tvalid => sts_tvalid,
          sts_tdata  => sts_tdata,

          config_data  => unpacker_config_data,
          config_wr    => unpacker_config_wr,
          config_ready => unpacker_config_ready,

          control_length_reg => mm2s_control_length_reg,
          base_reg           => mm2s_base_reg,
          dimension_reg      => mm2s_dimension_reg,
          block_reg          => mm2s_block_reg,
          line_skip_reg      => mm2s_line_skip_reg,
          status_reg_rd      => mm2s_status_reg_rd,
          status_reg_wr      => mm2s_status_reg_wr,

          irq_out => mm2s_irq
          );

      i_tinymover : entity work.tinymover
        port map (
          clk     => clk,
          aresetn => aresetn,

          cmd_tdata  => cmd_tdata,
          cmd_tready => cmd_tready,
          cmd_tvalid => cmd_tvalid,

          sts_tvalid => sts_tvalid,
          sts_tdata  => sts_tdata,

          m_axi_araddr  => m_axi_mem_araddr,
          m_axi_arvalid => m_axi_mem_arvalid,
          m_axi_arready => m_axi_mem_arready,
          m_axi_arlen   => m_axi_mem_arlen,
          m_axi_arsize  => m_axi_mem_arsize,
          m_axi_arburst => m_axi_mem_arburst,
          m_axi_rdata   => m_axi_mem_rdata,
          m_axi_rready  => m_axi_mem_rready,
          m_axi_rvalid  => m_axi_mem_rvalid,
          m_axi_rlast   => m_axi_mem_rlast,
          m_axi_rresp   => m_axi_mem_rresp,

          m_axis_tdata  => from_mover_tdata,
          m_axis_tvalid => from_mover_tvalid,
          m_axis_tready => from_mover_tready,
          m_axis_tlast  => from_mover_tlast
          );

      m_axi_mem_arprot  <= (others => '0');
      m_axi_mem_arcache <= "0011";
    end generate;

    i_unpacker : entity work.unpacker
      generic map (
        C_IN_DATA_WIDTH  => 64,
        C_OUT_DATA_WIDTH => C_MM2S_DATA_WIDTH,
        C_COMP_WIDTH     => C_MM2S_COMP_WIDTH,
        C_NUM_COMP       => C_MM2S_NUM_COMP,
        C_NUM_CTRL_BITS  => 2
        )
      port map (
        clk     => clk,
        aresetn => aresetn,

        config_data  => unpacker_config_data,
        config_wr    => unpacker_config_wr,
        config_ready => unpacker_config_ready,

        in_tdata  => from_mover_tdata,
        in_tvalid => from_mover_tvalid,
        in_tready => from_mover_tready,
        in_tlast  => from_mover_tlast,

        out_tdata  => m_axis_mm2s_tdata(C_MM2S_DATA_WIDTH-1 downto 0),
        out_ctrl   => mm2s_ctrl,
        out_tvalid => m_axis_mm2s_tvalid,
        out_tready => m_axis_mm2s_tready,
        out_tlast  => m_axis_mm2s_tlast
        );

    m_axis_mm2s_tdata(C_MM2S_AXIS_WIDTH-1 downto C_MM2S_DATA_WIDTH) <= (others => '0');

  end block b_mm2s;

  --------------------------------------------------------------------------------
  -- S2MM
  --------------------------------------------------------------------------------
  b_s2mm : block is

    signal m_axi_s2mm_awaddr  : std_logic_vector(31 downto 0);
    signal m_axi_s2mm_awlen   : std_logic_vector(7 downto 0);
    signal m_axi_s2mm_awsize  : std_logic_vector(2 downto 0);
    signal m_axi_s2mm_awburst : std_logic_vector(1 downto 0);
    signal m_axi_s2mm_awprot  : std_logic_vector(2 downto 0);
    signal m_axi_s2mm_awcache : std_logic_vector(3 downto 0);
    signal m_axi_s2mm_awvalid : std_logic;
    signal m_axi_s2mm_awready : std_logic;
    signal m_axi_s2mm_wdata   : std_logic_vector(63 downto 0);
    signal m_axi_s2mm_wstrb   : std_logic_vector(7 downto 0);
    signal m_axi_s2mm_wlast   : std_logic;
    signal m_axi_s2mm_wvalid  : std_logic;
    signal m_axi_s2mm_wready  : std_logic;
    signal m_axi_s2mm_bresp   : std_logic_vector(1 downto 0);
    signal m_axi_s2mm_bvalid  : std_logic;
    signal m_axi_s2mm_bready  : std_logic;

    -- Command bus
    signal cmd_tvalid : STD_LOGIC;
    signal cmd_tready : STD_LOGIC;
    signal cmd_tdata  : STD_LOGIC_VECTOR(71 DOWNTO 0);

    -- Status bus
    signal sts_tvalid : STD_LOGIC;
    signal sts_tdata  : STD_LOGIC_VECTOR(31 DOWNTO 0);

    signal datamover_error   : std_logic;
    signal datamover_aresetn : std_logic;
    signal force_aresetn     : std_logic;

    signal to_datamover_tdata  : std_logic_vector(63 downto 0);
    signal to_datamover_tvalid : std_logic;
    signal to_datamover_tready : std_logic;
    signal to_datamover_tlast  : std_logic;

    constant C_INCL_PACKER : boolean := C_S2MM_COMP_WIDTH mod 8 /= 0 or C_S2MM_COMP_WIDTH * C_S2MM_NUM_COMP /= 64;
  begin

    g_packer : if (C_INCL_PACKER) generate
      i_packer : entity work.packer
        generic map (
          C_IN_DATA_WIDTH  => C_S2MM_DATA_WIDTH,
          C_OUT_DATA_WIDTH => 64,
          C_COMP_WIDTH     => C_S2MM_COMP_WIDTH,
          C_NUM_COMP       => C_S2MM_NUM_COMP)
        port map (
          clk     => clk,
          aresetn => aresetn,

          in_tdata  => s_axis_s2mm_tdata(C_S2MM_DATA_WIDTH-1 downto 0),
          in_tvalid => s_axis_s2mm_tvalid,
          in_tready => s_axis_s2mm_tready,
          in_tlast  => s_axis_s2mm_tlast,

          out_tdata  => to_datamover_tdata,
          out_tvalid => to_datamover_tvalid,
          out_tready => to_datamover_tready,
          out_tlast  => to_datamover_tlast
          );
    end generate;

    g_nopacker : if (not C_INCL_PACKER) generate
      to_datamover_tdata  <= s_axis_s2mm_tdata;
      to_datamover_tvalid <= s_axis_s2mm_tvalid;
      to_datamover_tlast  <= s_axis_s2mm_tlast;
      s_axis_s2mm_tready  <= to_datamover_tready;
    end generate;

    i_s2mm_controller : entity work.channel_controller
      generic map (
        C_S2MM => true
        )
      port map (
        clk     => clk,
        aresetn => aresetn,

        cmd_tvalid => cmd_tvalid,
        cmd_tready => cmd_tready,
        cmd_tdata  => cmd_tdata,

        sts_tvalid => sts_tvalid,
        sts_tdata  => sts_tdata,

        channel_aresetn => force_aresetn,
        channel_error   => datamover_error,

        config_data  => open,
        config_wr    => open,
        config_ready => '1',

        control_length_reg => s2mm_control_length_reg,
        base_reg           => s2mm_base_reg,
        dimension_reg      => (others => '0'),
        block_reg          => (others => '0'),
        line_skip_reg      => (others => '0'),
        status_reg_rd      => s2mm_status_reg_rd,
        status_reg_wr      => s2mm_status_reg_wr,
        length_reg_rd      => s2mm_length_reg_rd,

        irq_out => s2mm_irq
        );

    -- Reset if external reset is applied or if the controller forces it
    -- when recovering from an error condition
    datamover_aresetn <= aresetn and force_aresetn;

    i_datamover_s2mm : axi_datamover_s2mm
      port map (
        m_axi_s2mm_aclk    => clk,
        m_axi_s2mm_aresetn => datamover_aresetn,

        s2mm_err => datamover_error,

        m_axis_s2mm_cmdsts_awclk   => clk,
        m_axis_s2mm_cmdsts_aresetn => aresetn,

        s_axis_s2mm_cmd_tvalid => cmd_tvalid,
        s_axis_s2mm_cmd_tready => cmd_tready,
        s_axis_s2mm_cmd_tdata  => cmd_tdata,

        m_axis_s2mm_sts_tvalid => sts_tvalid,
        m_axis_s2mm_sts_tready => '1',
        m_axis_s2mm_sts_tdata  => sts_tdata,
        m_axis_s2mm_sts_tkeep  => open,
        m_axis_s2mm_sts_tlast  => open,

        m_axi_s2mm_awaddr            => m_axi_mem_awaddr,
        m_axi_s2mm_awlen(3 downto 0) => m_axi_mem_awlen,
        m_axi_s2mm_awlen(7 downto 4) => open,
        m_axi_s2mm_awsize            => m_axi_mem_awsize,
        m_axi_s2mm_awburst           => m_axi_mem_awburst,
        m_axi_s2mm_awprot            => m_axi_mem_awprot,
        m_axi_s2mm_awcache           => m_axi_mem_awcache,
        m_axi_s2mm_awuser            => open,
        m_axi_s2mm_awvalid           => m_axi_mem_awvalid,
        m_axi_s2mm_awready           => m_axi_mem_awready,
        m_axi_s2mm_wdata             => m_axi_mem_wdata,
        m_axi_s2mm_wstrb             => m_axi_mem_wstrb,
        m_axi_s2mm_wlast             => m_axi_mem_wlast,
        m_axi_s2mm_wvalid            => m_axi_mem_wvalid,
        m_axi_s2mm_wready            => m_axi_mem_wready,
        m_axi_s2mm_bresp             => m_axi_mem_bresp,
        m_axi_s2mm_bvalid            => m_axi_mem_bvalid,
        m_axi_s2mm_bready            => m_axi_mem_bready,

        s_axis_s2mm_tdata  => to_datamover_tdata,
        s_axis_s2mm_tkeep  => (others => '1'),
        s_axis_s2mm_tlast  => to_datamover_tlast,
        s_axis_s2mm_tvalid => to_datamover_tvalid,
        s_axis_s2mm_tready => to_datamover_tready
        );
  end block b_s2mm;

end Behavioral;
