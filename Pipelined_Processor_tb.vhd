library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Pipelined_Processor_tb is
end Pipelined_Processor_tb;

architecture behavioral of Pipelined_Processor_tb is

component Pipelined_Processor is
port(
	clk : in std_logic;
	writeToRegisterFile : in std_logic;
	writeToMemoryFile : in std_logic
); end component;

constant clk_period : time := 1 ns;
signal clk : std_logic := '0';
signal s_writeToRegisterFile : std_logic := '0';
signal s_writeToMemoryFile : std_logic := '0';

begin 

pipeline : Pipelined_Processor
port map(
	clk => clk,
	writeToMemoryFile => s_writeToRegisterFile,
	writeToRegisterFile => s_writeToMemoryFile
);

	clk_process : process
	begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
	end process;

	test_process : process
	begin
		wait for clk_period;
		report "STARTING SIMULATION \n";
		wait for  100 * clk_period;
		s_writeToRegisterFile <= '1';
		s_writeToMemoryFile <= '1';
		wait for 3*clk_period;
		s_writeToRegisterFile <= '0';
		s_writeToMemoryFile <= '0';
		wait for clk_period;
		wait;		
	end process;
end behavioral;