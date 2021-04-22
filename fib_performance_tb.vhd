-- Group 7: Anas Deis, Albert Assouad, Barry Chen
-- Date: 16/4/2021

library ieee;
use ieee.std_logic_1164.all ;
use ieee.numeric_std.all ;
use ieee.std_logic_textio.all;
use std.textio.all;
use work.definitions.all;

entity fib_performance_tb is
end fib_performance_tb ; 

architecture behavioral of fib_performance_tb is
    component Pipelined_Processor is
        generic(
			ram_size : integer := 8192;
			bit_width : integer := 32;
			mem_delay : time := 10 ns;
			clk_period : time := 1 ns
        );
        port(
            clk : in std_logic;
            initialize : in std_logic; 
            write_file : in std_logic;
			register_file : out REGISTER_BLOCK
        );
    end component;
	
	constant clock_period : time := 1 ns;
	constant TEST_NAME : string := "benchmark2";
	constant FILEPATH : STRING := "./" & TEST_NAME & "_performance.txt";
	
	signal clk : std_logic := '0';
	signal initialize : std_logic := '0';
    signal write_file : std_logic := '0';
	signal register_file : REGISTER_BLOCK;
	signal time_taken : time;
begin
	dut : Pipelined_Processor 
	port map(
		clk => clk,
		initialize => initialize,
		write_file => write_file,
		register_file => register_file
	);

	clk_process : process
	begin
		clk <= '0';
		wait for clock_period/2;
		clk <= '1';
		wait for clock_period/2;
	end process ;

	test_process : process
		file     fptr  : text;
		variable line : line;
		variable tstart, tstop : time;
	begin		
		initialize <= '1';
		wait for clock_period;
		initialize <= '0';
		
		wait for 3*clock_period;
		
		tstart := now;
		for i in 0 to 9900 loop
			wait for clock_period;
			exit when register_file(10).data = x"00000000"; -- exit when $10 = 0 for benchmark2.asm
		end loop;
		tstop := now;
		time_taken <= tstop - tstart;
		
		wait for clock_period;
		write_file <= '1';
		wait for clock_period;
		write_file <= '0';
		wait for clock_period;
		
		report "Stored output in 'register_file.txt' and 'memory.txt'";
		report "benchmark2 program.txt executed in " & time'image(time_taken);
		
		file_open(fptr, FILEPATH, WRITE_MODE);
        write(line, TEST_NAME);
        writeline(fptr, line);
        write(line, "Execution time : " & time'image(time_taken));
        writeline(fptr, line);
		file_close(fptr);
		
		wait;

	end process;
end behavioral;