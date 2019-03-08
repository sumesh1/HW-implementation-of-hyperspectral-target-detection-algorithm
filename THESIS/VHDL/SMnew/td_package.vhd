----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.02.2019 12:11:36
-- Design Name: 
-- Module Name: PACKAGE
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
use IEEE.NUMERIC_STD.all;
use IEEE.math_real.all;
package td_package is

	constant C_S_AXI_DATA_WIDTH     : integer  := 32;
	constant C_S_AXI_ADDR_WIDTH     : integer  := 4;
	constant NUM_BANDS              : positive := 16;
	constant PIXEL_DATA_WIDTH       : positive := 16;
	constant CORRELATION_DATA_WIDTH : positive := 32;
	constant OUT_DATA_WIDTH         : positive := 32;

	type CorrMatrixColumn is array (0 to 16 - 1) of std_logic_vector(32 - 1 downto 0);
	type CorrMatrixType is array (0 to 16 - 1) of CorrMatrixColumn;
	--global variables for simulation and verification in MATLAB - only VHDL 2008
	signal STEP1_RESULT       : CorrMatrixColumn;
	signal STEP1_RESULT_VALID : std_logic;

	signal STEP2_RESULT       : CorrMatrixColumn;
	signal STEP2_RESULT_VALID : std_logic;

	signal STEP3_RESULT       : CorrMatrixColumn;
	signal STEP3_RESULT_VALID : std_logic;

	type Controller_Signals is record
		STEP1_ENABLE           : std_logic;
		STEP2_ENABLE           : std_logic;
		STEP2_ENABLE_DIV       : std_logic;
		STEP3_ENABLE           : std_logic;
		STEP3_ENABLE_TD        : std_logic;

		COMPONENT_WRITE_ENABLE : std_logic;
		COLUMN_WRITE_ENABLE    : std_logic;
		TEMP_WRITE_ENABLE      : std_logic;

		MULT_ARRAY_ENABLE      : std_logic;
		DP_ARRAY_ENABLE		   : std_logic;

		COLUMN_IN_SEL          : std_logic;
		MULT_ARRAY_SEL         : std_logic;
		DP_ARRAY_SEL		   : std_logic;
		DIV_SEL				   : std_logic; 
		
		COUNT_ST2              : std_logic;
		COUNT_RS			   : std_logic;
		DP_ARRAY_SAVE		   : std_logic;
		

		COMPONENT_NUMBER       : std_logic_vector (integer(ceil(log2(real(NUM_BANDS)))) - 1 downto 0);
		COLUMN_NUMBER          : std_logic_vector (integer(ceil(log2(real(NUM_BANDS)))) - 1 downto 0);

	end record;

	type Valid_signals is record
		--STEP1_DATA_VALID   : std_logic;
		--STEP2_DATA_VALID  : std_logic;
		--STEP3_DATA_VALID  : std_logic;
		MULT_ARRAY_VALID   : std_logic;
		STEP2_DIV_IN_VALID : std_logic;
	end record;
	
	type S_AXI_FROM_MASTER is record 
		-- Write address (issued by master, acceped by Slave)
		S_AXI_AWADDR           : std_logic_vector(C_S_AXI_ADDR_WIDTH - 1 downto 0);
		-- Write channel Protection type. This signal indicates the
		-- privilege and security level of the transaction, and whether
		-- the transaction is a data access or an instruction access.
		S_AXI_AWPROT           : std_logic_vector(2 downto 0);
		-- Write address valid. This signal indicates that the master signaling
		-- valid write address and control information.
		S_AXI_AWVALID          : std_logic;
		-- Write data (issued by master, acceped by Slave) 
		S_AXI_WDATA            : std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
		-- Write strobes. This signal indicates which byte lanes hold
		-- valid data. There is one write strobe bit for each eight
		-- bits of the write data bus.    
		S_AXI_WSTRB            : std_logic_vector((C_S_AXI_DATA_WIDTH/8) - 1 downto 0);
		-- Write valid. This signal indicates that valid write
		-- data and strobes are available.
		S_AXI_WVALID           : std_logic;
		-- Response ready. This signal indicates that the master
		-- can accept a write response.
		S_AXI_BREADY           : std_logic;
		-- Read address (issued by master, acceped by Slave)
		S_AXI_ARADDR           : std_logic_vector(C_S_AXI_ADDR_WIDTH - 1 downto 0);
		-- Protection type. This signal indicates the privilege
		-- and security level of the transaction, and whether the
		-- transaction is a data access or an instruction access.
		S_AXI_ARPROT           : std_logic_vector(2 downto 0);
		-- Read address valid. This signal indicates that the channel
		-- is signaling valid read address and control information.
		S_AXI_ARVALID          : std_logic;
		-- Read ready. This signal indicates that the master can
		-- accept the read data and response information.
		S_AXI_RREADY           : std_logic;
	end record;
	
	type S_AXI_TO_MASTER is record
		-- Write address ready. This signal indicates that the slave is ready
		-- to accept an address and associated control signals.
		S_AXI_AWREADY          : std_logic;
		-- Write ready. This signal indicates that the slave
		-- can accept the write data.
		S_AXI_WREADY           : std_logic;
		-- Write response. This signal indicates the status
		-- of the write transaction.
		S_AXI_BRESP            : std_logic_vector(1 downto 0);
		-- Write response valid. This signal indicates that the channel
		-- is signaling a valid write response.
		S_AXI_BVALID           : std_logic;
			-- Read address ready. This signal indicates that the slave is
		-- ready to accept an address and associated control signals.
		S_AXI_ARREADY          : std_logic;
		-- Read data (issued by slave)
		S_AXI_RDATA            : std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
		-- Read response. This signal indicates the status of the
		-- read transfer.
		S_AXI_RRESP            : std_logic_vector(1 downto 0);
		-- Read valid. This signal indicates that the channel is
		-- signaling the required read data.
		S_AXI_RVALID           : std_logic;
	end record;

end td_package; --end of package.