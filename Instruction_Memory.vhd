-- Group 7: Anas Deis, Albert Assouad, Barry Chen
-- Date: 16/4/2021

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity instruction_Memory is
	generic(
		ram_size : integer := 8192;
		bit_width : integer := 32;
		mem_delay : time := 10 ns;
		clk_period : time := 1 ns
	);
	port (
		clk: in std_logic;
		writedata: in std_logic_vector (bit_width-1 downto 0);
		address: in integer range 0 to ram_size-1;
		memwrite: in std_logic;
		memread: in std_logic;
		readdata: out std_logic_vector (bit_width-1 downto 0);
		write_to_mem: in std_logic;
		load_program: in std_logic
	);
end instruction_Memory;

architecture rtl of instruction_Memory is
	type MEM is array(ram_size-1 downto 0) of std_logic_vector(bit_width-1 downto 0);
	constant empty_ram_block : MEM := (others => (others => '0'));
	signal ram_block: MEM := empty_ram_block; 

begin
	-- write to memory.txt
	write_mem_process: process(write_to_mem)
		file     fptr  : text;
		variable file_line : line;
	begin
		if(rising_edge(write_to_mem)) then
			file_open(fptr, "memory.txt", WRITE_MODE);
			for i in 0 to ram_size-1 loop
				write(file_line, ram_block(i));
				writeline(fptr, file_line);
			end loop;
			file_close(fptr);
		end if;
	end process;

	-- load program.txt
	read_program_process: process(load_program, memwrite, address, writedata)
		file 	 fptr: text;
		variable file_line: line;
		variable line_data: std_logic_vector(bit_width-1 downto 0);
		variable i : integer := 0;
	begin
		if(rising_edge(load_program)) then
			file_open(fptr, "program.txt", READ_MODE);
			while ((not endfile(fptr)) and (i < ram_size)) loop
				readline(fptr, file_line);
				read(file_line, line_data);
				ram_block(i) <= line_data;
				i := i + 1;	
			end loop;
			file_close(fptr);
		elsif memwrite = '1' then
			ram_block(address) <= writedata;
		end if;	
	end process;
	readdata <= ram_block(address);
end rtl;
