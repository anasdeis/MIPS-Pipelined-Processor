--Taken from the Memory.vhd file from assignment 2 and modified
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY Memory IS
	GENERIC(
		ram_size : INTEGER := 32768;
		mem_delay : time := 10 ns;
		clock_period : time := 1 ns
	);
	PORT (
		-- inputs
		clk: IN STD_LOGIC;
		writedata: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		address: IN INTEGER RANGE 0 TO ram_size-1;
		memwrite: IN STD_LOGIC;
		memread: IN STD_LOGIC;
		
		-- from EX
		alu_input : IN std_logic_vector (31 downto 0);
		-- from ID
		read_data_input : IN std_logic_vector (31 downto 0);
		
		-- outputs
		
		waitrequest: OUT STD_LOGIC;
		
		-- to WB
		read_data_output: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		alu_output : OUT std_logic_vector (31 downto 0)
	);
END Memory;

