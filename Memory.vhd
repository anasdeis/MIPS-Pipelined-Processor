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
		read_data_2 : IN std_logic_vector (31 downto 0);
		
		-- outputs
		
		waitrequest: OUT STD_LOGIC;
		
		-- to WB
		read_data_output: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		alu_output : OUT std_logic_vector (31 downto 0)
	);
END Memory;

architecture behaviour of Memory is
component mem_file
	GENERIC(
		ram_size : INTEGER := 32768;
		mem_delay : time := 10 ns;
		clock_period : time := 1 ns
	);
	PORT (
		clk: IN STD_LOGIC;
		writedata: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		address: IN INTEGER RANGE 0 TO ram_size-1;
		memwrite: IN STD_LOGIC;
		memread: IN STD_LOGIC;
		waitrequest: OUT STD_LOGIC;
		readdata: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
    		write_text_flag : IN STD_LOGIC
	);
end component;

--signal declaration
signal next_alu: std_logic_vector (31 downto 0);
signal next_data: std_logic_vector (31 downto 0);
signal next_address: std_logic_vector (31 downto 0);

begin
process (clk)
	
	next_alu <= alu_input;
	next_data <= read_data_2;
	next_address <= to_integer(unsigned(next_alu));
	
	memory_process : data_memory port map(
		clk => clk,
		writedata => next_data,
		address => next_address,
		memwrite => 1,
		memread => 0,
		-- waitrequest=> ?, not sure about this one
		readdata => read_data_output
		write_text_flag => 1,
	);
	
	alu_output <= next_alu;
	
end process;

end behaviour;
