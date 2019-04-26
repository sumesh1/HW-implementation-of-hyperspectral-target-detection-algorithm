library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package funcs is
  function gcd(a_in, b_in : in integer) return integer;
end;

package body funcs is
  -- Compute Greatest Common Divisor, which is used to calculate block size and
  -- maximum count
  function gcd(a_in, b_in : in integer) return integer is
    variable t : integer := 0;
    variable a : integer := a_in;
    variable b : integer := b_in;
  begin
    while (b /= 0) loop
      t := b;
      b := a mod b;
      a := t;
    end loop;
    return a;
  end gcd;
end package body;
