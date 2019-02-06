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


package td_package is --name of the package is "test_pkg"

type CorrMatrixColumn is array (0 to 16-1) of std_logic_vector(32-1 downto 0);
type CorrMatrixType is array (0 to 16-1) of CorrMatrixColumn;



--Define a data type called t1(totally 32 bits contains 3 different fields)
type t1 is  
    record
        a : unsigned(11 downto 0);  --12 bit field.
        b : unsigned(15 downto 0);  --16 bit field.
        c : unsigned(3 downto 0);   --4 bit field.
    end record;

--Declare a function named "add".
function xored (a2 : t1; b2: t1) return t1;

end td_package;   --end of package.

package body td_package is  --start of package body

--definition of function we declared above
--The function take two t1 data types and calculate the xor of each fields.
function  xored (a2 : t1; b2: t1) return t1 is
    variable temp : t1;
begin -- Just name the fields in order...
    temp.a:=a2.a xor b2.a;
    temp.b:=a2.b xor b2.b;
    temp.c:=a2.c xor b2.c;
    return temp;
end xored;
--end function

end td_package;  --end of the package body
