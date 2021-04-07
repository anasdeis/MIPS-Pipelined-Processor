-- Entity: mux
-- Authors: Anas Deis, Albert Assouad, Barry Chen
-- Date: 04/16/2021

library ieee;
use ieee.std_logic_1164.ALL;

entity mux is
    Port ( selector : in  std_logic;
           input_0  : in  std_logic_vector (31 downto 0);
           input_1  : in  std_logic_vector (31 downto 0);
           output   : out std_logic_vector (31 downto 0));
end mux;

architecture behavioural of mux is

begin
  
    output <= input_1 when (selector = '1') else input_0;

end behavioural;