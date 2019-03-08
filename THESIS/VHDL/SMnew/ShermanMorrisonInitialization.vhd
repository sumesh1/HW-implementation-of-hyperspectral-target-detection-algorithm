----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Dordije Boskovic
-- 
-- Create Date: 
-- Design Name: 
-- Module Name:  via AXI LITE - Behavioral
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
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.td_package.all;

entity AXI_CONTROL is
	generic (
		-- Width of S_AXI data bus
		C_S_AXI_DATA_WIDTH     : integer  := 32;
		-- Width of S_AXI address bus
		C_S_AXI_ADDR_WIDTH     : integer  := 4;
		--BRAM PARAMETERS
		CORRELATION_DATA_WIDTH : positive := 32;
		PIXEL_DATA_WIDTH       : positive := 16;
		NUM_BANDS              : integer  := 16;
		ADDR_WIDTH             : integer  := 4		--integer(ceil(log2(real(NUM_BANDS))))
	);
	port (
	
		-- Global Clock Signal
		S_AXI_ACLK             : std_logic;
		-- Global Reset Signal. This Signal is Active LOW
		S_AXI_ARESETN          : std_logic;
		
		S_AXI_IN			   : in S_AXI_FROM_MASTER;
		S_AXI_OUT			   : out S_AXI_TO_MASTER;
		
		--TEMPORARY COLUMN
		TEMP_INIT_COLUMN       : out std_logic_vector(NUM_BANDS * CORRELATION_DATA_WIDTH - 1 downto 0);
		TEMP_INIT_COLUMN_VALID : out std_logic;
		
		--SIGNATURE--TARGET TO BE DETECTED
		SIGNATURE_VECTOR       : out std_logic_vector(NUM_BANDS * PIXEL_DATA_WIDTH - 1 downto 0);
		
		--ENABLE CORE
		ENABLE_CORE			   : out std_logic

	);
end AXI_CONTROL;

architecture arch_imp of AXI_CONTROL is

	-- Write address (issued by master, acceped by Slave)
	signal S_AXI_AWADDR           : std_logic_vector(C_S_AXI_ADDR_WIDTH - 1 downto 0);
	-- Write channel Protection type. This signal indicates the
	-- privilege and security level of the transaction, and whether
	-- the transaction is a data access or an instruction access.
	signal S_AXI_AWPROT           : std_logic_vector(2 downto 0);
	-- Write address valid. This signal indicates that the master signaling
	-- valid write address and control information.
	signal S_AXI_AWVALID          : std_logic;
	-- Write data (issued by master, acceped by Slave) 
	signal S_AXI_WDATA            : std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
	-- Write strobes. This signal indicates which byte lanes hold
	-- valid data. There is one write strobe bit for each eight
	-- bits of the write data bus.    
	signal S_AXI_WSTRB            : std_logic_vector((C_S_AXI_DATA_WIDTH/8) - 1 downto 0);
	-- Write valid. This signal indicates that valid write
	-- data and strobes are available.
	signal S_AXI_WVALID           : std_logic;
	-- Response ready. This signal indicates that the master
	-- can accept a write response.
	signal S_AXI_BREADY           : std_logic;
	-- Read address (issued by master, acceped by Slave)
	signal S_AXI_ARADDR           : std_logic_vector(C_S_AXI_ADDR_WIDTH - 1 downto 0);
	-- Protection type. This signal indicates the privilege
	-- and security level of the transaction, and whether the
	-- transaction is a data access or an instruction access.
	signal S_AXI_ARPROT           : std_logic_vector(2 downto 0);
	-- Read address valid. This signal indicates that the channel
	-- is signaling valid read address and control information.
	signal S_AXI_ARVALID          : std_logic;
	-- Read ready. This signal indicates that the master can
	-- accept the read data and response information.
	signal S_AXI_RREADY           : std_logic;
	-- Write address ready. This signal indicates that the slave is ready
	-- to accept an address and associated control signals.
	signal S_AXI_AWREADY          : std_logic;
	-- Write ready. This signal indicates that the slave
	-- can accept the write data.
	signal S_AXI_WREADY           : std_logic;
	-- Write response. This signal indicates the status
	-- of the write transaction.
	signal S_AXI_BRESP            : std_logic_vector(1 downto 0);
	-- Write response valid. This signal indicates that the channel
	-- is signaling a valid write response.
	signal S_AXI_BVALID           : std_logic;
		-- Read address ready. This signal indicates that the slave is
	-- ready to accept an address and associated control signals.
	signal S_AXI_ARREADY          : std_logic;
	-- Read data (issued by slave)
	signal S_AXI_RDATA            : std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
	-- Read response. This signal indicates the status of the
	-- read transfer.
	signal S_AXI_RRESP            : std_logic_vector(1 downto 0);
	-- Read valid. This signal indicates that the channel is
	-- signaling the required read data.
	signal S_AXI_RVALID           : std_logic;



	-- AXI4LITE signals
	signal axi_awaddr          : std_logic_vector(C_S_AXI_ADDR_WIDTH - 1 downto 0);
	signal axi_awready         : std_logic;
	signal axi_wready          : std_logic;
	signal axi_bresp           : std_logic_vector(1 downto 0);
	signal axi_bvalid          : std_logic;
	signal axi_araddr          : std_logic_vector(C_S_AXI_ADDR_WIDTH - 1 downto 0);
	signal axi_arready         : std_logic;
	signal axi_rdata           : std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
	signal axi_rresp           : std_logic_vector(1 downto 0);
	signal axi_rvalid          : std_logic;

	-- Example-specific design signals
	-- local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	-- ADDR_LSB is used for addressing 32/64 bit registers/memories
	-- ADDR_LSB = 2 for 32 bits (n downto 2)
	-- ADDR_LSB = 3 for 64 bits (n downto 3)
	constant ADDR_LSB          : integer := (C_S_AXI_DATA_WIDTH/32) + 1;
	constant OPT_MEM_ADDR_BITS : integer := 1;
	------------------------------------------------
	---- Signals for user logic register space example
	--------------------------------------------------
	---- Number of Slave Registers 4
	signal slv_reg0            : std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
	signal slv_reg1            : std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
	signal slv_reg2            : std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
	signal slv_reg3            : std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
	signal slv_reg_rden        : std_logic;
	signal slv_reg_wren        : std_logic;
	signal slv_reg_wren_dly    : std_logic;
	signal axi_awaddr_dly      : std_logic_vector(OPT_MEM_ADDR_BITS downto 0);
	signal reg_data_out        : std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
	signal byte_index          : integer;
	signal aw_en               : std_logic;
begin

---------------------------------------------------------------------------------	 
-- PACKING
---------------------------------------------------------------------------------	

	S_AXI_OUT <=
		(
		S_AXI_AWREADY      => S_AXI_AWREADY,
		S_AXI_WREADY       => S_AXI_WREADY ,
		S_AXI_BRESP        => S_AXI_BRESP  ,
		S_AXI_BVALID       => S_AXI_BVALID ,
		S_AXI_ARREADY      => S_AXI_ARREADY,
		S_AXI_RDATA        => S_AXI_RDATA  ,
		S_AXI_RRESP        => S_AXI_RRESP  ,
		S_AXI_RVALID       => S_AXI_RVALID 
		);
		
	S_AXI_AWADDR     <= S_AXI_IN.S_AXI_AWADDR  ;
	S_AXI_AWPROT     <= S_AXI_IN.S_AXI_AWPROT  ;
	S_AXI_AWVALID 	 <= S_AXI_IN.S_AXI_AWVALID ;
	S_AXI_WDATA      <= S_AXI_IN.S_AXI_WDATA   ;
	S_AXI_WSTRB      <= S_AXI_IN.S_AXI_WSTRB   ;
	S_AXI_WVALID     <= S_AXI_IN.S_AXI_WVALID  ;
	S_AXI_BREADY     <= S_AXI_IN.S_AXI_BREADY  ;
	S_AXI_ARADDR     <= S_AXI_IN.S_AXI_ARADDR  ;
	S_AXI_ARPROT     <= S_AXI_IN.S_AXI_ARPROT  ;
	S_AXI_ARVALID    <= S_AXI_IN.S_AXI_ARVALID ;
	S_AXI_RREADY     <= S_AXI_IN.S_AXI_RREADY  ;
	                
	
---------------------------------------------------------------------------------	 
-- MODULE
---------------------------------------------------------------------------------	



	-- I/O Connections assignments

	S_AXI_AWREADY <= axi_awready;
	S_AXI_WREADY  <= axi_wready;
	S_AXI_BRESP   <= axi_bresp;
	S_AXI_BVALID  <= axi_bvalid;
	S_AXI_ARREADY <= axi_arready;
	S_AXI_RDATA   <= axi_rdata;
	S_AXI_RRESP   <= axi_rresp;
	S_AXI_RVALID  <= axi_rvalid;
	-- Implement axi_awready generation
	-- axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	-- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	-- de-asserted when reset is low.

	process (S_AXI_ACLK)
	begin
		if rising_edge(S_AXI_ACLK) then
			if S_AXI_ARESETN = '0' then
				axi_awready <= '0';
				aw_en       <= '1';
			else
				if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' and aw_en = '1') then
					-- slave is ready to accept write address when
					-- there is a valid write address and write data
					-- on the write address and data bus. This design 
					-- expects no outstanding transactions. 
					axi_awready <= '1';
				elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then
					aw_en       <= '1';
					axi_awready <= '0';
				else
					axi_awready <= '0';
				end if;
			end if;
		end if;
	end process;

	-- Implement axi_awaddr latching
	-- This process is used to latch the address when both 
	-- S_AXI_AWVALID and S_AXI_WVALID are valid. 

	process (S_AXI_ACLK)
	begin
		if rising_edge(S_AXI_ACLK) then
			if S_AXI_ARESETN = '0' then
				axi_awaddr <= (others => '0');
			else
				if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' and aw_en = '1') then
					-- Write Address latching
					axi_awaddr <= S_AXI_AWADDR;
				end if;
			end if;
		end if;
	end process;

	-- Implement axi_wready generation
	-- axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	-- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	-- de-asserted when reset is low. 

	process (S_AXI_ACLK)
	begin
		if rising_edge(S_AXI_ACLK) then
			if S_AXI_ARESETN = '0' then
				axi_wready <= '0';
			else
				if (axi_wready = '0' and S_AXI_WVALID = '1' and S_AXI_AWVALID = '1' and aw_en = '1') then
					-- slave is ready to accept write data when 
					-- there is a valid write address and write data
					-- on the write address and data bus. This design 
					-- expects no outstanding transactions.           
					axi_wready <= '1';
				else
					axi_wready <= '0';
				end if;
			end if;
		end if;
	end process;

	-- Implement memory mapped register select and write logic generation
	-- The write data is accepted and written to memory mapped registers when
	-- axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	-- select byte enables of slave registers while writing.
	-- These registers are cleared when reset (active low) is applied.
	-- Slave register write enable is asserted when valid address and data are available
	-- and the slave is ready to accept the write address and write data.
	slv_reg_wren <= axi_wready and S_AXI_WVALID and axi_awready and S_AXI_AWVALID;

	process (S_AXI_ACLK)
		variable loc_addr : std_logic_vector(OPT_MEM_ADDR_BITS downto 0);
	begin
		if rising_edge(S_AXI_ACLK) then
			if S_AXI_ARESETN = '0' then
				slv_reg0 <= (others => '0');
				slv_reg1 <= (others => '0');
				slv_reg2 <= (others => '0');
				slv_reg3 <= (others => '0');
			else
				loc_addr := axi_awaddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
				if (slv_reg_wren = '1') then
					case loc_addr is
						when b"00" =>
							for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8 - 1) loop
								if (S_AXI_WSTRB(byte_index) = '1') then
									-- Respective byte enables are asserted as per write strobes                   
									-- slave registor 0
									slv_reg0(byte_index * 8 + 7 downto byte_index * 8) <= S_AXI_WDATA(byte_index * 8 + 7 downto byte_index * 8);
								end if;
							end loop;
						when b"01" =>
							for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8 - 1) loop
								if (S_AXI_WSTRB(byte_index) = '1') then
									-- Respective byte enables are asserted as per write strobes                   
									-- slave registor 1
									slv_reg1(byte_index * 8 + 7 downto byte_index * 8) <= S_AXI_WDATA(byte_index * 8 + 7 downto byte_index * 8);
								end if;
							end loop;
						when b"10" =>
							for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8 - 1) loop
								if (S_AXI_WSTRB(byte_index) = '1') then
									-- Respective byte enables are asserted as per write strobes                   
									-- slave registor 2
									slv_reg2(byte_index * 8 + 7 downto byte_index * 8) <= S_AXI_WDATA(byte_index * 8 + 7 downto byte_index * 8);
								end if;
							end loop;
						when b"11" =>
							for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8 - 1) loop
								if (S_AXI_WSTRB(byte_index) = '1') then
									-- Respective byte enables are asserted as per write strobes                   
									-- slave registor 3
									slv_reg3(byte_index * 8 + 7 downto byte_index * 8) <= S_AXI_WDATA(byte_index * 8 + 7 downto byte_index * 8);
								end if;
							end loop;
						when others =>
							slv_reg0 <= slv_reg0;
							slv_reg1 <= slv_reg1;
							slv_reg2 <= slv_reg2;
							slv_reg3 <= slv_reg3;
					end case;
				end if;
			end if;
		end if;
	end process;

	-- Implement write response logic generation
	-- The write response and response valid signals are asserted by the slave 
	-- when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	-- This marks the acceptance of address and indicates the status of 
	-- write transaction.

	process (S_AXI_ACLK)
	begin
		if rising_edge(S_AXI_ACLK) then
			if S_AXI_ARESETN = '0' then
				axi_bvalid <= '0';
				axi_bresp  <= "00"; --need to work more on the responses
			else
				if (axi_awready = '1' and S_AXI_AWVALID = '1' and axi_wready = '1' and S_AXI_WVALID = '1' and axi_bvalid = '0') then
					axi_bvalid <= '1';
					axi_bresp  <= "00";
				elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then --check if bready is asserted while bvalid is high)
					axi_bvalid <= '0';                                   -- (there is a possibility that bready is always asserted high)
				end if;
			end if;
		end if;
	end process;

	-- Implement axi_arready generation
	-- axi_arready is asserted for one S_AXI_ACLK clock cycle when
	-- S_AXI_ARVALID is asserted. axi_awready is 
	-- de-asserted when reset (active low) is asserted. 
	-- The read address is also latched when S_AXI_ARVALID is 
	-- asserted. axi_araddr is reset to zero on reset assertion.

	process (S_AXI_ACLK)
	begin
		if rising_edge(S_AXI_ACLK) then
			if S_AXI_ARESETN = '0' then
				axi_arready <= '0';
				axi_araddr  <= (others => '1');
			else
				if (axi_arready = '0' and S_AXI_ARVALID = '1') then
					-- indicates that the slave has acceped the valid read address
					axi_arready <= '1';
					-- Read Address latching 
					axi_araddr  <= S_AXI_ARADDR;
				else
					axi_arready <= '0';
				end if;
			end if;
		end if;
	end process;

	-- Implement axi_arvalid generation
	-- axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	-- S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	-- data are available on the axi_rdata bus at this instance. The 
	-- assertion of axi_rvalid marks the validity of read data on the 
	-- bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	-- is deasserted on reset (active low). axi_rresp and axi_rdata are 
	-- cleared to zero on reset (active low).  
	process (S_AXI_ACLK)
	begin
		if rising_edge(S_AXI_ACLK) then
			if S_AXI_ARESETN = '0' then
				axi_rvalid <= '0';
				axi_rresp  <= "00";
			else
				if (axi_arready = '1' and S_AXI_ARVALID = '1' and axi_rvalid = '0') then
					-- Valid read data is available at the read data bus
					axi_rvalid <= '1';
					axi_rresp  <= "00"; -- 'OKAY' response
				elsif (axi_rvalid = '1' and S_AXI_RREADY = '1') then
					-- Read data is accepted by the master
					axi_rvalid <= '0';
				end if;
			end if;
		end if;
	end process;

	-- Implement memory mapped register select and read logic generation
	-- Slave register read enable is asserted when valid address is available
	-- and the slave is ready to accept the read address.
	slv_reg_rden <= axi_arready and S_AXI_ARVALID and (not axi_rvalid);

	process (slv_reg0, slv_reg1, slv_reg2, slv_reg3, axi_araddr, S_AXI_ARESETN, slv_reg_rden)
		variable loc_addr : std_logic_vector(OPT_MEM_ADDR_BITS downto 0);
	begin
		-- Address decoding for reading registers
		loc_addr := axi_araddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
		case loc_addr is
			when b"00" =>
				reg_data_out <= slv_reg0;
			when b"01" =>
				reg_data_out <= slv_reg1;
			when b"10" =>
				reg_data_out <= slv_reg2;
			when b"11" =>
				reg_data_out <= slv_reg3;
			when others             =>
				reg_data_out <= (others => '0');
		end case;
	end process;

	-- Output register or memory read data
	process (S_AXI_ACLK) is
	begin
		if (rising_edge (S_AXI_ACLK)) then
			if (S_AXI_ARESETN = '0') then
				axi_rdata <= (others => '0');
			else
				if (slv_reg_rden = '1') then
					-- When there is a valid read address (S_AXI_ARVALID) with 
					-- acceptance of read address by the slave (axi_arready), 
					-- output the read dada 
					-- Read address mux
					axi_rdata <= reg_data_out; -- register read data
				end if;
			end if;
		end if;
	end process;
	------------------------------------------------------------------------------
	-- BRAM HANDLING
	------------------------------------------------------------------------------
	process (S_AXI_ACLK) is
	begin
		if (rising_edge (S_AXI_ACLK)) then

			if (S_AXI_ARESETN = '0') then

				slv_reg_wren_dly <= '0';
				axi_awaddr_dly   <= (others => '0');

			else

				axi_awaddr_dly   <= axi_awaddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
				slv_reg_wren_dly <= slv_reg_wren;

			end if;

		end if;
	end process;
	
	
	
	process (S_AXI_ACLK) is
		variable vector_count : integer := 0;
		variable sig_count	  : integer := 0;
	begin
		if (rising_edge (S_AXI_ACLK)) then
			if (S_AXI_ARESETN = '0') then

				TEMP_INIT_COLUMN_VALID <= '0';
				TEMP_INIT_COLUMN       <= (others => '0');

			else
				
				if (vector_count = NUM_BANDS) then

					TEMP_INIT_COLUMN_VALID <= '1';
					vector_count := 0;

				else

					TEMP_INIT_COLUMN_VALID <= '0';

				end if;
				
				
				
				-- ENABLE SIGNAL
				if (slv_reg_wren_dly = '1' and axi_awaddr_dly = b"00") then

					ENABLE_CORE  <= slv_reg0(0);

				end if;

				--VECTOR handling - keyhole writing to slv_reg1
				if (slv_reg_wren_dly = '1' and vector_count < NUM_BANDS and axi_awaddr_dly = b"01") then

					TEMP_INIT_COLUMN_VALID                                                                                              <= '0';
					TEMP_INIT_COLUMN ((CORRELATION_DATA_WIDTH) * (vector_count + 1) - 1 downto (CORRELATION_DATA_WIDTH) * vector_count) <= slv_reg1;

					vector_count := vector_count + 1;

				end if;
				
				--SIGNATURE handling - keyhole writing to slv_reg2
				if (slv_reg_wren_dly = '1' and sig_count < NUM_BANDS and axi_awaddr_dly = b"10") then

					SIGNATURE_VECTOR ((PIXEL_DATA_WIDTH) * (sig_count + 1) - 1 downto (PIXEL_DATA_WIDTH) * sig_count) <= slv_reg2(PIXEL_DATA_WIDTH-1 downto 0);

					sig_count := sig_count + 1;

				end if;
				

			end if;
		end if;
	end process;

end arch_imp;