library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity pc is
port(clk : in std_logic;
	 rst : in std_logic;
	 pcOutput : out std_logic_vector(31 downto 0);
	 pcInput : in std_logic_vector(31 downto 0) := x"00000000"
	 );
end pc;

architecture pc_arch of pc is

 
begin

process (clk,rst)
begin
	
	if (rst = '1') then -- set PC to first instruction
		pcOutput <= x"00000000";
	elsif (clk'event and clk = '1') then 	-- set PC to next instruction
		pcOutput <= pcInput;

	end if;
	
	
	end process;


	
end pc_arch;
