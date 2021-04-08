-- Entity: Fetch
-- Authors: Anas Deis, Albert Assouad, Barry Chen
-- Date: 04/16/2021

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

-- Stage 1: Fetch

entity Fetch is
port(
	clk : in std_logic;
	fetch_sel : in std_logic;
	structural_stall_in : in std_logic := '0';
	pc_stall_in : in std_logic := '0';	
	mux_in : in std_logic_vector(31 downto 0);       -- result from adder in EX
	next_address_out : out std_logic_vector(31 downto 0); -- output from PC adder to mux or adder in EX
	instruction_out : out std_logic_vector(31 downto 0)  -- instruction going to decode stage
);
end Fetch;

architecture behavioral of Fetch is 

-- instruction memory  
component Instruction_Memory IS
GENERIC(
	ram_size : INTEGER := 1024;
	mem_delay : time := 1 ns;
	clock_period : time := 1 ns
);
port (
	clock: in std_logic;
	writedata: in std_logic_vector (31 DOWNTO 0);
	address: in INTEGER range 0 to ram_size-1;
	memwrite: in std_logic;
	memread: in std_logic;
	readdata: out std_logic_vector (31 DOWNTO 0);
	waitrequest: out std_logic
);
end component;

-- mux 
component mux is
port(
	input_0 : in std_logic_vector(31 downto 0);
	input_1 : in std_logic_vector(31 downto 0);
	selector : in std_logic;
	output : out std_logic_vector(31 downto 0)
); end component;

-- adder
component adder is
port(
	A : in std_logic_vector(31 downto 0);
	B : in INTEGER;
	S : out std_logic_vector(31 downto 0)
); end component;
	
-- signals
-- instruction memory
constant clk_period : time := 1 ns;
signal writedata: std_logic_vector(31 downto 0);
signal address: INTEGER RANGE 0 TO 1024-1;
signal memwrite: std_logic := '0';
signal memread: std_logic := '0';
signal readdata: std_logic_vector (31 DOWNTO 0);
signal waitrequest: std_logic;

-- PC + Add
signal pc_input : std_logic_vector(31 downto 0);
signal pc_output : std_logic_vector(31 downto 0);
signal add_output : std_logic_vector(31 DOWNTO 0);
signal fetch_output : std_logic_vector(31 DOWNTO 0);

-- either stall or output memory data
signal stall : std_logic_vector(31 DOWNTO 0) := x"00000020";
signal memory_data : std_logic_vector(31 DOWNTO 0);
	
begin

	address <= to_integer(unsigned(add_output(9 downto 0)))/4;
	next_address_out <= fetch_output;

	PC: process (clk)
	begin
		if (clk'event and clk = '1') then 	-- set PC to next instruction
			pc_output <= pc_input;
		end if;
		
	end process;

	add_4 : adder
	port map(
		A => pc_output,
		B => 4,
		S => add_output
	);

	fetch_mux : mux 
	port map(
		 input_0 => add_output,
		 input_1 => mux_in,
		 selector => fetch_sel,
		 output => fetch_output
	);
		 
	pc_mux : mux 
	port map (
		input_0 => fetch_output,
		input_1 => pc_output,
		selector => pc_stall_in,
		output => pc_input
	);

	structural_mux : mux 
	port map (
		input_0 => memory_data,
		input_1 => stall,
		selector => structural_stall_in,
		output => instruction_out
	);
		 
	instr_mem : Instruction_Memory
	GENERIC map(
		ram_size => 1024
	)
	port map(
		clk,
		writedata,
		address,
		memwrite,
		memread,
		memory_data,
		waitrequest
	);		
end behavioral;




 
  


