----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.02.2019 13:30:23
-- Design Name: 
-- Module Name: ShermanMorrisonTopLevel - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.math_real.all;
use ieee.numeric_std.all;
library work;
use work.td_package.all;
entity ShermanMorrisonTopLevel is
	generic (
		NUM_BANDS              : positive := 16;
		PIXEL_DATA_WIDTH       : positive := 16;
		CORRELATION_DATA_WIDTH : positive := 32;
		OUT_DATA_WIDTH         : positive := 32;
		C_S_AXI_DATA_WIDTH     : integer  := 32;
		C_S_AXI_ADDR_WIDTH     : integer  := 4
	);
	port (
		CLK                : in std_logic;
		RESETN             : in std_logic;

		--pixel stream from DMA
		S_AXIS_TDATA       : in std_logic_vector(PIXEL_DATA_WIDTH - 1 downto 0);
		S_AXIS_TVALID      : in std_logic;
		S_AXIS_TREADY      : out std_logic;

		--stream from divider
		S_DIV_AXIS_TDATA   : in std_logic_vector(39 downto 0);
		S_DIV_AXIS_TVALID  : in std_logic;

		--stream to divider
		M_DIV_AXIS_TDATA   : out std_logic_vector(OUT_DATA_WIDTH - 1 downto 0);
		M_DIV_AXIS_TVALID  : out std_logic;
		
		--S AXI
		S_AXI_AWADDR       : in std_logic_vector(C_S_AXI_ADDR_WIDTH - 1 downto 0);
		S_AXI_AWPROT       : in std_logic_vector(2 downto 0);
		S_AXI_AWVALID      : in std_logic;
		S_AXI_WDATA        : in std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);   
		S_AXI_WSTRB        : in std_logic_vector((C_S_AXI_DATA_WIDTH/8) - 1 downto 0);
		S_AXI_WVALID       : in std_logic;
		S_AXI_BREADY       : in std_logic;
		S_AXI_ARADDR       : in std_logic_vector(C_S_AXI_ADDR_WIDTH - 1 downto 0);
		S_AXI_ARPROT       : in std_logic_vector(2 downto 0);
		S_AXI_ARVALID      : in std_logic;
		S_AXI_RREADY       : in std_logic;
		S_AXI_AWREADY      : out std_logic;
		S_AXI_WREADY       : out std_logic;
		S_AXI_BRESP        : out std_logic_vector(1 downto 0);
		S_AXI_BVALID       : out std_logic;
		S_AXI_ARREADY      : out std_logic;
		S_AXI_RDATA        : out std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
		S_AXI_RRESP        : out std_logic_vector(1 downto 0);
		S_AXI_RVALID       : out std_logic
	);
end ShermanMorrisonTopLevel;


architecture Behavioral of ShermanMorrisonTopLevel is

	signal CONTROLLER_SIGS    : Controller_Signals;
	signal VALID_SIGS      	  : Valid_signals;
	
	signal INIT_COLUMN        : std_logic_vector(NUM_BANDS * CORRELATION_DATA_WIDTH - 1 downto 0);
	signal INIT_COLUMN_VALID  : std_logic;
	signal SIGNATURE_VECTOR   : std_logic_vector(NUM_BANDS * PIXEL_DATA_WIDTH - 1 downto 0);
	 
	signal ENABLE_CORE		  : std_logic;
	signal S_AXI_IN			  : S_AXI_FROM_MASTER;
	signal S_AXI_OUT		  : S_AXI_TO_MASTER;
	
begin

---------------------------------------------------------------------------------	 
-- INSTANCES
---------------------------------------------------------------------------------

	ShermanMorrisonControllerInst : entity work.ShermanMorrisonController(Behavioral)
		generic map(
			NUM_BANDS => NUM_BANDS
		)
		port map(
			CLK                => CLK,
			RESETN             => RESETN,
			VALID_SIGS         => VALID_SIGS,
			S_AXIS_TVALID      => S_AXIS_TVALID,
			S_AXIS_TREADY      => S_AXIS_TREADY,
			CONTROLLER_SIGS    => CONTROLLER_SIGS,
			INPUT_COLUMN_VALID => INIT_COLUMN_VALID,
			S_DIV_AXIS_TVALID  => S_DIV_AXIS_TVALID,
			M_DIV_AXIS_TVALID  => M_DIV_AXIS_TVALID,
			ENABLE_CORE        => ENABLE_CORE
		);

	ShermanMorrisonDatapathInst : entity work.ShermanMorrisonDatapath(BRAM)
		generic map(
			NUM_BANDS              => NUM_BANDS,
			PIXEL_DATA_WIDTH       => PIXEL_DATA_WIDTH,
			CORRELATION_DATA_WIDTH => CORRELATION_DATA_WIDTH,
			OUT_DATA_WIDTH         => OUT_DATA_WIDTH
		)
		port map(
			CLK               => CLK,
			RESETN            => RESETN,
			CONTROLLER_SIGS   => CONTROLLER_SIGS,
			VALID_SIGS        => VALID_SIGS,
			S_AXIS_TDATA      => S_AXIS_TDATA,
			S_DIV_AXIS_TDATA  => S_DIV_AXIS_TDATA,
			S_DIV_AXIS_TVALID => S_DIV_AXIS_TVALID,
			M_DIV_AXIS_TDATA  => M_DIV_AXIS_TDATA,
			INPUT_COLUMN      => INIT_COLUMN
		);
		
	AxiControlInst : entity work.AXI_CONTROL(arch_imp)
		generic map (
			C_S_AXI_DATA_WIDTH     => C_S_AXI_DATA_WIDTH,
			C_S_AXI_ADDR_WIDTH     => C_S_AXI_ADDR_WIDTH,
			CORRELATION_DATA_WIDTH => CORRELATION_DATA_WIDTH,
			PIXEL_DATA_WIDTH       => PIXEL_DATA_WIDTH,
			NUM_BANDS              => NUM_BANDS,
			ADDR_WIDTH             => integer(ceil(log2(real(NUM_BANDS))))
		)
		port map (
		
			S_AXI_ACLK             => CLK,
			S_AXI_ARESETN          => RESETN,
			S_AXI_IN			   => S_AXI_IN,
			S_AXI_OUT			   => S_AXI_OUT,
			TEMP_INIT_COLUMN       => INIT_COLUMN,
			TEMP_INIT_COLUMN_VALID => INIT_COLUMN_VALID,
			SIGNATURE_VECTOR       => SIGNATURE_VECTOR,
			ENABLE_CORE			   => ENABLE_CORE
		);

---------------------------------------------------------------------------------	 
-- PACKING
---------------------------------------------------------------------------------	

	S_AXI_IN <=
		(
		S_AXI_AWADDR      => S_AXI_AWADDR  ,
		S_AXI_AWPROT      => S_AXI_AWPROT  ,
		S_AXI_AWVALID     => S_AXI_AWVALID ,
		S_AXI_WDATA       => S_AXI_WDATA   ,
		S_AXI_WSTRB       => S_AXI_WSTRB   ,
		S_AXI_WVALID      => S_AXI_WVALID  ,
		S_AXI_BREADY      => S_AXI_BREADY  ,
		S_AXI_ARADDR      => S_AXI_ARADDR  ,
		S_AXI_ARPROT  	  => S_AXI_ARPROT  ,
		S_AXI_ARVALID     => S_AXI_ARVALID ,
		S_AXI_RREADY      => S_AXI_RREADY  
		);
		
	S_AXI_AWREADY    <= S_AXI_OUT.S_AXI_AWREADY;
	S_AXI_WREADY     <= S_AXI_OUT.S_AXI_WREADY ;
	S_AXI_BRESP   	 <= S_AXI_OUT.S_AXI_BRESP  ;
	S_AXI_BVALID     <= S_AXI_OUT.S_AXI_BVALID ;
	S_AXI_ARREADY    <= S_AXI_OUT.S_AXI_ARREADY;
	S_AXI_RDATA      <= S_AXI_OUT.S_AXI_RDATA  ;
	S_AXI_RRESP      <= S_AXI_OUT.S_AXI_RRESP  ;
	S_AXI_RVALID     <= S_AXI_OUT.S_AXI_RVALID ;

	     

		
		
end Behavioral;