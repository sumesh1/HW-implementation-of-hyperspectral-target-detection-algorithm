library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package compdecls is
  component axi_protocol_converter_mm2s
    port (
      aclk           : in  std_logic;
      aresetn        : in  std_logic;
      s_axi_araddr   : in  std_logic_vector(31 downto 0);
      s_axi_arlen    : in  std_logic_vector(7 downto 0);
      s_axi_arsize   : in  std_logic_vector(2 downto 0);
      s_axi_arburst  : in  std_logic_vector(1 downto 0);
      s_axi_arlock   : in  std_logic_vector(0 downto 0);
      s_axi_arcache  : in  std_logic_vector(3 downto 0);
      s_axi_arprot   : in  std_logic_vector(2 downto 0);
      s_axi_arregion : in  std_logic_vector(3 downto 0);
      s_axi_arqos    : in  std_logic_vector(3 downto 0);
      s_axi_arvalid  : in  std_logic;
      s_axi_arready  : out std_logic;
      s_axi_rdata    : out std_logic_vector(63 downto 0);
      s_axi_rresp    : out std_logic_vector(1 downto 0);
      s_axi_rlast    : out std_logic;
      s_axi_rvalid   : out std_logic;
      s_axi_rready   : in  std_logic;
      m_axi_araddr   : out std_logic_vector(31 downto 0);
      m_axi_arlen    : out std_logic_vector(3 downto 0);
      m_axi_arsize   : out std_logic_vector(2 downto 0);
      m_axi_arburst  : out std_logic_vector(1 downto 0);
      m_axi_arlock   : out std_logic_vector(1 downto 0);
      m_axi_arcache  : out std_logic_vector(3 downto 0);
      m_axi_arprot   : out std_logic_vector(2 downto 0);
      m_axi_arqos    : out std_logic_vector(3 downto 0);
      m_axi_arvalid  : out std_logic;
      m_axi_arready  : in  std_logic;
      m_axi_rdata    : in  std_logic_vector(63 downto 0);
      m_axi_rresp    : in  std_logic_vector(1 downto 0);
      m_axi_rlast    : in  std_logic;
      m_axi_rvalid   : in  std_logic;
      m_axi_rready   : out std_logic
      );
  end component;

  component axi_datamover_mm2s
    port (
      m_axi_mm2s_aclk            : in  std_logic;
      m_axi_mm2s_aresetn         : in  std_logic;
      mm2s_err                   : out std_logic;
      m_axis_mm2s_cmdsts_aclk    : in  std_logic;
      m_axis_mm2s_cmdsts_aresetn : in  std_logic;
      s_axis_mm2s_cmd_tvalid     : in  std_logic;
      s_axis_mm2s_cmd_tready     : out std_logic;
      s_axis_mm2s_cmd_tdata      : in  std_logic_vector(71 downto 0);
      m_axis_mm2s_sts_tvalid     : out std_logic;
      m_axis_mm2s_sts_tready     : in  std_logic;
      m_axis_mm2s_sts_tdata      : out std_logic_vector(7 downto 0);
      m_axis_mm2s_sts_tkeep      : out std_logic_vector(0 downto 0);
      m_axis_mm2s_sts_tlast      : out std_logic;
      m_axi_mm2s_araddr          : out std_logic_vector(31 downto 0);
      m_axi_mm2s_arlen           : out std_logic_vector(7 downto 0);
      m_axi_mm2s_arsize          : out std_logic_vector(2 downto 0);
      m_axi_mm2s_arburst         : out std_logic_vector(1 downto 0);
      m_axi_mm2s_arprot          : out std_logic_vector(2 downto 0);
      m_axi_mm2s_arcache         : out std_logic_vector(3 downto 0);
      m_axi_mm2s_aruser          : out std_logic_vector(3 downto 0);
      m_axi_mm2s_arvalid         : out std_logic;
      m_axi_mm2s_arready         : in  std_logic;
      m_axi_mm2s_rdata           : in  std_logic_vector(63 downto 0);
      m_axi_mm2s_rresp           : in  std_logic_vector(1 downto 0);
      m_axi_mm2s_rlast           : in  std_logic;
      m_axi_mm2s_rvalid          : in  std_logic;
      m_axi_mm2s_rready          : out std_logic;
      m_axis_mm2s_tdata          : out std_logic_vector(63 downto 0);
      m_axis_mm2s_tkeep          : out std_logic_vector(7 downto 0);
      m_axis_mm2s_tlast          : out std_logic;
      m_axis_mm2s_tvalid         : out std_logic;
      m_axis_mm2s_tready         : in  std_logic
      );
  end component;

  component axi_protocol_converter_s2mm
    port (
      aclk           : in  std_logic;
      aresetn        : in  std_logic;
      s_axi_awaddr   : in  std_logic_vector(31 downto 0);
      s_axi_awlen    : in  std_logic_vector(7 downto 0);
      s_axi_awsize   : in  std_logic_vector(2 downto 0);
      s_axi_awburst  : in  std_logic_vector(1 downto 0);
      s_axi_awlock   : in  std_logic_vector(0 downto 0);
      s_axi_awcache  : in  std_logic_vector(3 downto 0);
      s_axi_awprot   : in  std_logic_vector(2 downto 0);
      s_axi_awregion : in  std_logic_vector(3 downto 0);
      s_axi_awqos    : in  std_logic_vector(3 downto 0);
      s_axi_awvalid  : in  std_logic;
      s_axi_awready  : out std_logic;
      s_axi_wdata    : in  std_logic_vector(63 downto 0);
      s_axi_wstrb    : in  std_logic_vector(7 downto 0);
      s_axi_wlast    : in  std_logic;
      s_axi_wvalid   : in  std_logic;
      s_axi_wready   : out std_logic;
      s_axi_bresp    : out std_logic_vector(1 downto 0);
      s_axi_bvalid   : out std_logic;
      s_axi_bready   : in  std_logic;
      m_axi_awaddr   : out std_logic_vector(31 downto 0);
      m_axi_awlen    : out std_logic_vector(3 downto 0);
      m_axi_awsize   : out std_logic_vector(2 downto 0);
      m_axi_awburst  : out std_logic_vector(1 downto 0);
      m_axi_awlock   : out std_logic_vector(1 downto 0);
      m_axi_awcache  : out std_logic_vector(3 downto 0);
      m_axi_awprot   : out std_logic_vector(2 downto 0);
      m_axi_awqos    : out std_logic_vector(3 downto 0);
      m_axi_awvalid  : out std_logic;
      m_axi_awready  : in  std_logic;
      m_axi_wdata    : out std_logic_vector(63 downto 0);
      m_axi_wstrb    : out std_logic_vector(7 downto 0);
      m_axi_wlast    : out std_logic;
      m_axi_wvalid   : out std_logic;
      m_axi_wready   : in  std_logic;
      m_axi_bresp    : in  std_logic_vector(1 downto 0);
      m_axi_bvalid   : in  std_logic;
      m_axi_bready   : out std_logic
      );
  end component;

  component axi_datamover_s2mm
    port (
      m_axi_s2mm_aclk            : in  std_logic;
      m_axi_s2mm_aresetn         : in  std_logic;
      s2mm_err                   : out std_logic;
      m_axis_s2mm_cmdsts_awclk   : in  std_logic;
      m_axis_s2mm_cmdsts_aresetn : in  std_logic;
      s_axis_s2mm_cmd_tvalid     : in  std_logic;
      s_axis_s2mm_cmd_tready     : out std_logic;
      s_axis_s2mm_cmd_tdata      : in  std_logic_vector(71 downto 0);
      m_axis_s2mm_sts_tvalid     : out std_logic;
      m_axis_s2mm_sts_tready     : in  std_logic;
      m_axis_s2mm_sts_tdata      : out std_logic_vector(31 downto 0);
      m_axis_s2mm_sts_tkeep      : out std_logic_vector(3 downto 0);
      m_axis_s2mm_sts_tlast      : out std_logic;
      m_axi_s2mm_awaddr          : out std_logic_vector(31 downto 0);
      m_axi_s2mm_awlen           : out std_logic_vector(7 downto 0);
      m_axi_s2mm_awsize          : out std_logic_vector(2 downto 0);
      m_axi_s2mm_awburst         : out std_logic_vector(1 downto 0);
      m_axi_s2mm_awprot          : out std_logic_vector(2 downto 0);
      m_axi_s2mm_awcache         : out std_logic_vector(3 downto 0);
      m_axi_s2mm_awuser          : out std_logic_vector(3 downto 0);
      m_axi_s2mm_awvalid         : out std_logic;
      m_axi_s2mm_awready         : in  std_logic;
      m_axi_s2mm_wdata           : out std_logic_vector(63 downto 0);
      m_axi_s2mm_wstrb           : out std_logic_vector(7 downto 0);
      m_axi_s2mm_wlast           : out std_logic;
      m_axi_s2mm_wvalid          : out std_logic;
      m_axi_s2mm_wready          : in  std_logic;
      m_axi_s2mm_bresp           : in  std_logic_vector(1 downto 0);
      m_axi_s2mm_bvalid          : in  std_logic;
      m_axi_s2mm_bready          : out std_logic;
      s_axis_s2mm_tdata          : in  std_logic_vector(63 downto 0);
      s_axis_s2mm_tkeep          : in  std_logic_vector(7 downto 0);
      s_axis_s2mm_tlast          : in  std_logic;
      s_axis_s2mm_tvalid         : in  std_logic;
      s_axis_s2mm_tready         : out std_logic
      );
  end component;
end compdecls;
