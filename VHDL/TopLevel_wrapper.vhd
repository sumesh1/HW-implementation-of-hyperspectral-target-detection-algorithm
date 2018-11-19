----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 31.10.2018 23:55:07
-- Design Name: 
-- Module Name: TopLevel_wrapper - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.all;
use ieee.math_real.all;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TopLevel_wrapper is
	generic
	(
		PIXEL_DATA_WIDTH : positive := 16;
		BRAM_DATA_WIDTH  : positive := 32;
		ST2IN_DATA_WIDTH : positive := 32;
		NUM_BANDS        : positive := 16;
		PACKET_SIZE      : positive := 16;
		OUT_DATA_WIDTH   : positive := 32;
		BRAM_ADDR_WIDTH  : integer  := 4;--integer(ceil(log2(real(NUM_BANDS))));
		BRAM_ROW_WIDTH   : positive := 512--BRAM_DATA_WIDTH*(2**BRAM_ADDR_WIDTH)
	);
	port
	(
		CLK              : in std_logic;
		RESETN           : in std_logic;
		S_AXIS_TREADY    : out std_logic;
		S_AXIS_TDATA     : in std_logic_vector(PIXEL_DATA_WIDTH - 1 downto 0);
		S_AXIS_TLAST     : in std_logic;
		S_AXIS_TVALID    : in std_logic;
		M1_AXIS_TVALID   : out std_logic;
		M1_AXIS_TDATA    : out std_logic_vector(OUT_DATA_WIDTH - 1 downto 0);
		M1_AXIS_TLAST    : out std_logic;
		M1_AXIS_TREADY   : in std_logic;
		M2_AXIS_TVALID   : out std_logic;
		M2_AXIS_TDATA    : out std_logic_vector(OUT_DATA_WIDTH - 1 downto 0);
		M2_AXIS_TLAST    : out std_logic;
		M2_AXIS_TREADY   : in std_logic;
		MATRIX_ROW       : in std_logic_vector (BRAM_ROW_WIDTH - 1 downto 0);
		ROW_SELECT       : out std_logic_vector (BRAM_ADDR_WIDTH - 1 downto 0);
		STATIC_VECTOR_SR : in std_logic_vector (BRAM_DATA_WIDTH - 1 downto 0)
	);
end TopLevel_wrapper;

architecture Behavioral of TopLevel_wrapper is

	component TopLevel_Accelerator is
		generic
		(
			PIXEL_DATA_WIDTH : positive := 16;
			BRAM_DATA_WIDTH  : positive := 32;
			ST2IN_DATA_WIDTH : positive := 16;
			NUM_BANDS        : positive := 16;
			PACKET_SIZE      : positive := 16;
			OUT_DATA_WIDTH   : positive := 32;
			BRAM_ADDR_WIDTH  : integer  := 4; --integer(ceil(log2(real(NUM_BANDS))));
			BRAM_ROW_WIDTH   : positive := 512--BRAM_DATA_WIDTH*(2**BRAM_ADDR_WIDTH)
		);
		port
		(
			CLK              : in std_logic;
			RESETN           : in std_logic;
			S_AXIS_TREADY    : out std_logic;
			S_AXIS_TDATA     : in std_logic_vector(PIXEL_DATA_WIDTH - 1 downto 0);
			S_AXIS_TLAST     : in std_logic;
			S_AXIS_TVALID    : in std_logic;
			M1_AXIS_TVALID   : out std_logic;
			M1_AXIS_TDATA    : out std_logic_vector(OUT_DATA_WIDTH - 1 downto 0);
			M1_AXIS_TLAST    : out std_logic;
			M1_AXIS_TREADY   : in std_logic;
			M2_AXIS_TVALID   : out std_logic;
			M2_AXIS_TDATA    : out std_logic_vector(OUT_DATA_WIDTH - 1 downto 0);
			M2_AXIS_TLAST    : out std_logic;
			M2_AXIS_TREADY   : in std_logic;
			MATRIX_ROW       : in std_logic_vector (BRAM_ROW_WIDTH - 1 downto 0);
			ROW_SELECT       : out std_logic_vector (BRAM_ADDR_WIDTH - 1 downto 0);
			STATIC_VECTOR_SR : in std_logic_vector (BRAM_DATA_WIDTH - 1 downto 0)
		);
	end component;
	
begin

	TopLevel_inst : TopLevel_Accelerator
	generic map(
	PIXEL_DATA_WIDTH => PIXEL_DATA_WIDTH,
	BRAM_DATA_WIDTH  => BRAM_DATA_WIDTH,
	ST2IN_DATA_WIDTH => ST2IN_DATA_WIDTH,
	NUM_BANDS        => NUM_BANDS,
	PACKET_SIZE      => PACKET_SIZE,
	OUT_DATA_WIDTH   => OUT_DATA_WIDTH,
	BRAM_ADDR_WIDTH  => BRAM_ADDR_WIDTH,
	BRAM_ROW_WIDTH   => BRAM_ROW_WIDTH
	)
	port map
	(
		CLK              => CLK,
		RESETN           => RESETN,
		S_AXIS_TREADY    => S_AXIS_TREADY,
		S_AXIS_TDATA     => S_AXIS_TDATA,
		S_AXIS_TLAST     => S_AXIS_TLAST,
		S_AXIS_TVALID    => S_AXIS_TVALID,
		M1_AXIS_TVALID   => M1_AXIS_TVALID,
		M1_AXIS_TDATA    => M1_AXIS_TDATA,
		M1_AXIS_TLAST    => M1_AXIS_TLAST,
		M1_AXIS_TREADY   => M1_AXIS_TREADY,
		M2_AXIS_TVALID   => M2_AXIS_TVALID,
		M2_AXIS_TDATA    => M2_AXIS_TDATA,
		M2_AXIS_TLAST    => M2_AXIS_TLAST,
		M2_AXIS_TREADY   => M2_AXIS_TREADY,
		MATRIX_ROW       => MATRIX_ROW,
		ROW_SELECT       => ROW_SELECT,
		STATIC_VECTOR_SR => STATIC_VECTOR_SR
	);

end Behavioral;