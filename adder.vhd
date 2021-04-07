-- Entity: adder
-- Authors: Anas Deis, Albert Assouad, Barry Chen
-- Date: 04/16/2021

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder is
port(
	 A : in std_logic_vector(31 downto 0);	-- input A vector
	 B : in INTEGER;	                    -- input B integer
	 S : out std_logic_vector(31 downto 0)	-- output S: A + B
	 );
end adder;

architecture behavioural of adder is

signal sum : integer;

begin

	sum <= B + to_integer(unsigned(A)); -- get integer sum A + B 
	S <= std_logic_vector(to_unsigned(sum, S'length)); 	-- convert sum to vector S
	
end behavioural;
