library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity adder is
port(
   clk : in std_logic; 
	 four : in integer;
	 counterOutput : in std_logic_vector(31 downto 0);
	 adderOutput : out std_logic_vector(31 downto 0)
	 );
end adder;

architecture adder_arch of adder is

signal add : integer;

begin

  -- convert vector input to unsigned integer
	add <= four + to_integer(unsigned(counterOutput)); 
	-- convert sum to vector for output
	adderOutput <= std_logic_vector(to_unsigned(add, adderOutput'length));


	
end adder_arch;
