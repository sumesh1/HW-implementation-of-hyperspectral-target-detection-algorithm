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
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


package td_package is 

type CorrMatrixColumn is array (0 to 16-1) of std_logic_vector(32-1 downto 0);
type CorrMatrixType is array (0 to 16-1) of CorrMatrixColumn;


--global variables for simulation and verification in MATLAB - only VHDL 2008
signal STEP1_RESULT : CorrMatrixColumn;
signal STEP1_RESULT_VALID : std_logic ;

signal STEP2_RESULT : CorrMatrixColumn;
signal STEP2_RESULT_VALID : std_logic ;

signal STEP3_RESULT : CorrMatrixColumn;
signal STEP3_RESULT_VALID : std_logic ;

end td_package;   --end of package.

