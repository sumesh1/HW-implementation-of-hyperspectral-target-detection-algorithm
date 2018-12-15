library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.math_real.all;

package my_types_pkg is
	type data_array is array (natural range <>) of std_logic_vector;
	type data_matrix is array (natural range <>) of data_array;
end package;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.my_types_pkg.all;
use IEEE.math_real.all;
entity TopLevel_Accelerator is
	generic (
		PIXEL_DATA_WIDTH : positive := 16;
		BRAM_DATA_WIDTH  : positive := 32;
		ST2IN_DATA_WIDTH : positive := 16;
		NUM_BANDS        : positive := 16;
		PACKET_SIZE      : positive := 16;
		OUT_DATA_WIDTH   : positive := 32;
		BRAM_ADDR_WIDTH  : integer  := integer(ceil(log2(real(NUM_BANDS))));
		BRAM_ROW_WIDTH   : positive := BRAM_DATA_WIDTH * (2 ** BRAM_ADDR_WIDTH)
	);
	port (

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
end TopLevel_Accelerator;

architecture Behavioral of TopLevel_Accelerator is

	constant ST1OUT_DATA_WIDTH : integer := integer(ceil(real(BRAM_DATA_WIDTH + PIXEL_DATA_WIDTH) + log2(real(NUM_BANDS))));
	constant ST2OUT_DATA_WIDTH : integer := integer(ceil(real(ST2IN_DATA_WIDTH + PIXEL_DATA_WIDTH) + log2(real(NUM_BANDS))));
	--constant BRAM_ADDR_WIDTH: integer := integer(ceil(log2(real(NUM_BANDS))));
	--constant BRAM_ROW_WIDTH: positive :=BRAM_DATA_WIDTH*(2**BRAM_ADDR_WIDTH);

	component Accelerator is
		generic (
			PIXEL_DATA_WIDTH  : positive := 16;
			BRAM_DATA_WIDTH   : positive := 16;
			ST1OUT_DATA_WIDTH : positive := 16;
			ST2IN_DATA_WIDTH  : positive := 16;
			ST2OUT_DATA_WIDTH : positive := 16;
			OUT_DATA_WIDTH    : positive := 16;
			NUM_BANDS         : positive := 8;
			BRAM_ADDR_WIDTH   : integer  := 4
		);
		port (
			CLK              : in std_logic;
			RESETN           : in std_logic;
			S_AXIS_TREADY    : out std_logic;
			S_AXIS_TDATA     : in std_logic_vector(PIXEL_DATA_WIDTH - 1 downto 0);
			S_AXIS_TLAST     : in std_logic;
			S_AXIS_TVALID    : in std_logic;
			DATA_OUT_VALID   : out std_logic;
			DATA1_OUT        : out std_logic_vector(OUT_DATA_WIDTH - 1 downto 0);
			DATA2_OUT        : out std_logic_vector(OUT_DATA_WIDTH - 1 downto 0);
			STOP_PIPELINE    : in std_logic;
			MATRIX_COLUMN    : in data_array (0 to NUM_BANDS - 1)(BRAM_DATA_WIDTH - 1 downto 0);
			ROW_SELECT       : out std_logic_vector (BRAM_ADDR_WIDTH - 1 downto 0);
			STATIC_VECTOR_SR : in std_logic_vector (BRAM_DATA_WIDTH - 1 downto 0)
		);
	end component;

	component MasterOutput is
		generic (
			DATA_WIDTH  : positive := 32;
			PACKET_SIZE : positive := 8
		);
		port (
			CLK           : in std_logic;
			RESETN        : in std_logic;
			DATA_IN       : in std_logic_vector(DATA_WIDTH - 1 downto 0);
			DATA_IN_VALID : in std_logic;
			M_AXIS_TVALID : out std_logic;
			M_AXIS_TDATA  : out std_logic_vector(DATA_WIDTH - 1 downto 0);
			M_AXIS_TLAST  : out std_logic;
			M_AXIS_TREADY : in std_logic;
			STOP_PIPELINE : out std_logic;
			LAST_PIXEL	  : in std_logic
		);
	end component;

	signal DATA_IN_VALID  : std_logic;
	signal DATA1_IN       : std_logic_vector(OUT_DATA_WIDTH - 1 downto 0);
	signal DATA2_IN       : std_logic_vector(OUT_DATA_WIDTH - 1 downto 0);
	signal DATA_OUT_VALID : std_logic;
	signal DATA1_OUT      : std_logic_vector(OUT_DATA_WIDTH - 1 downto 0);
	signal DATA2_OUT      : std_logic_vector(OUT_DATA_WIDTH - 1 downto 0);
	signal STOP1_PIPELINE : std_logic;
	signal STOP2_PIPELINE : std_logic;
	signal STOP_PIPELINE  : std_logic;
	signal MATRIX_COLUMN  : data_array (0 to NUM_BANDS - 1)(BRAM_DATA_WIDTH - 1 downto 0);

begin
	Accelerator_Inst : Accelerator
	generic map
	(
		PIXEL_DATA_WIDTH  => PIXEL_DATA_WIDTH,
		BRAM_DATA_WIDTH   => BRAM_DATA_WIDTH,
		ST1OUT_DATA_WIDTH => ST1OUT_DATA_WIDTH,
		ST2IN_DATA_WIDTH  => ST2IN_DATA_WIDTH,
		ST2OUT_DATA_WIDTH => ST2OUT_DATA_WIDTH,
		OUT_DATA_WIDTH    => OUT_DATA_WIDTH,
		NUM_BANDS         => NUM_BANDS,
		BRAM_ADDR_WIDTH   => BRAM_ADDR_WIDTH
	)
	port map(
		CLK              => CLK,
		RESETN           => RESETN,
		S_AXIS_TREADY    => S_AXIS_TREADY,
		S_AXIS_TDATA     => S_AXIS_TDATA,
		S_AXIS_TLAST     => S_AXIS_TLAST,
		S_AXIS_TVALID    => S_AXIS_TVALID,
		DATA1_OUT        => DATA1_OUT,
		DATA2_OUT        => DATA2_OUT,
		DATA_OUT_VALID   => DATA_OUT_VALID,
		STOP_PIPELINE    => STOP_PIPELINE,
		MATRIX_COLUMN    => MATRIX_COLUMN,
		ROW_SELECT       => ROW_SELECT,
		STATIC_VECTOR_SR => STATIC_VECTOR_SR
	);

	MasterOutput1_Inst : MasterOutput
	generic map
	(
		DATA_WIDTH  => OUT_DATA_WIDTH,
		PACKET_SIZE => PACKET_SIZE
	)
	port map(
		CLK           => CLK,
		RESETN        => RESETN,
		DATA_IN       => DATA1_IN,
		DATA_IN_VALID => DATA_IN_VALID,
		M_AXIS_TVALID => M1_AXIS_TVALID,
		M_AXIS_TDATA  => M1_AXIS_TDATA,
		M_AXIS_TLAST  => M1_AXIS_TLAST,
		M_AXIS_TREADY => M1_AXIS_TREADY,
		STOP_PIPELINE => STOP1_PIPELINE,
		LAST_PIXEL    => S_AXIS_TLAST
	);

	MasterOutput2_Inst : MasterOutput
	generic map
	(
		DATA_WIDTH  => OUT_DATA_WIDTH,
		PACKET_SIZE => PACKET_SIZE
	)
	port map(
		CLK           => CLK,
		RESETN        => RESETN,
		DATA_IN       => DATA2_IN,
		DATA_IN_VALID => DATA_IN_VALID,
		M_AXIS_TVALID => M2_AXIS_TVALID,
		M_AXIS_TDATA  => M2_AXIS_TDATA,
		M_AXIS_TLAST  => M2_AXIS_TLAST,
		M_AXIS_TREADY => M2_AXIS_TREADY,
		STOP_PIPELINE => STOP2_PIPELINE,
		LAST_PIXEL    => S_AXIS_TLAST
	);
	
	
	
	
	DATA1_IN      <= DATA1_OUT;
	DATA2_IN      <= DATA2_OUT;
	DATA_IN_VALID <= DATA_OUT_VALID;
	STOP_PIPELINE <= STOP1_PIPELINE or STOP2_PIPELINE;
	
	
	unpack : for i in 0 to NUM_BANDS - 1 generate
		MATRIX_COLUMN (i) <= MATRIX_ROW ((BRAM_DATA_WIDTH) * (i + 1) - 1 downto (BRAM_DATA_WIDTH) * i);
	end generate;
	
end architecture Behavioral;