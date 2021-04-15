-- Group 7: Anas Deis, Albert Assouad, Barry Chen
-- Date: 16/4/2021

library ieee;
use ieee.std_logic_1164.all ;
use ieee.numeric_std.all ;
use work.INSTRUCTION_TOOLS.all;

entity Pipelined_Processor_tb is
end Pipelined_Processor_tb ; 

architecture behavioral of Pipelined_Processor_tb is
    component Pipelined_Processor is
        generic(
			ram_size : integer := 8192;
			mem_delay : time := 0.1 ns;
			clk_period : time := 1 ns;
			predict_taken : boolean := false
        );
        port(
            clk : in std_logic;
            initialize : in std_logic; 
            write_file : in std_logic
        );
    end component;
	
	constant clock_period : time := 1 ns;
	
	signal clk : std_logic := '0';
	signal initialize : std_logic := '0';
    signal write_file : std_logic := '0';
	signal predict_taken : boolean := false;

begin

	dut : Pipelined_Processor 
	generic map(
		predict_taken => predict_taken
	)
	port map(
		clk => clk,
		initialize => initialize,
		write_file => write_file
	);

	clk_process : process
	begin
		clk <= '0';
		wait for clock_period/2;
		clk <= '1';
		wait for clock_period/2;
	end process ;

	test_process : process
	begin
		if predict_taken then
			report "Test using Predict Taken";
		else
			report "Test using Predict Not-Taken";
		end if;
		
		initialize <= '1';
		wait for clock_period;
		initialize <= '0';
		wait for clock_period;

		wait for 9900 ns;
		
		write_file <= '1';
		wait for clock_period;
		write_file <= '0';
		wait for clock_period;
		
		report "Stored output in 'register_file.txt' and 'memory.txt'";
		wait;

	end process;
end behavioral;