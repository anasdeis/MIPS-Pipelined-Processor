library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mux is
    Port ( selector : in  STD_LOGIC;
           input_0   : in  STD_LOGIC_VECTOR (31 downto 0);
           input_1   : in  STD_LOGIC_VECTOR (31 downto 0);
           output   : out STD_LOGIC_VECTOR (31 downto 0));
end mux;

architecture mux_arch of mux is

begin
  
    output <= input_1 when (selector = '1') else input_0;

end mux_arch;