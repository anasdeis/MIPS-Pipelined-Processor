LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

ENTITY fetch IS


port(
	clk : in std_logic;
	mux_EX : in std_logic_vector(31 downto 0); -- result from adder in EX
	selectInputs : in std_logic;
	four : in INTEGER;
	structuralStall : IN STD_LOGIC := '0';
	pcStall : IN STD_LOGIC := '0';
	
	nxt_address : out std_logic_vector(31 downto 0); -- output from PC adder to mux or adder in EX
	instruction : out std_logic_vector(31 downto 0) -- instruction going to decode stage
	);

END fetch;


architecture fetch_arch of fetch is 

-- component declaration

-- instruction memory  
component instructionMemory IS
	GENERIC(
	-- might need to change it 
		ram_size : INTEGER := 1024;
		mem_delay : time := 1 ns;
		clock_period : time := 1 ns
	);
	PORT (
		clock: IN STD_LOGIC;
		writedata: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		address: IN INTEGER RANGE 0 TO ram_size-1;
		memwrite: IN STD_LOGIC;
		memread: IN STD_LOGIC;
		readdata: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		waitrequest: OUT STD_LOGIC
	);
end component;

-- pc register
component pc is
port(clk : in std_logic;
  rst : in std_logic;
  pcOutput : out std_logic_vector(31 downto 0);
	pcInput : in std_logic_vector(31 downto 0)
	 );
end component;

-- mux 
component mux is
port(
  input_0 : in std_logic_vector(31 downto 0);
	input_1 : in std_logic_vector(31 downto 0);
	selector : in std_logic;
	output : out std_logic_vector(31 downto 0)
	 );
end component;

-- adder
component adder is
port(
  clk : in std_logic; 
	four : in integer;
	counterOutput : in std_logic_vector(31 downto 0);
	adderOutput : out std_logic_vector(31 downto 0)
	);
end component;
	
-- signals
constant clk_period : time := 1 ns;
signal writedata: std_logic_vector(31 downto 0);
signal address: INTEGER RANGE 0 TO 1024-1;
signal memwrite: STD_LOGIC := '0';
signal memread: STD_LOGIC := '0';
signal readdata: STD_LOGIC_VECTOR (31 DOWNTO 0);
signal waitrequest: STD_LOGIC;

signal pcInput : std_logic_vector(31 downto 0);
signal pcOutput : std_logic_vector(31 downto 0);
signal addOutput : STD_LOGIC_VECTOR(31 DOWNTO 0);

signal rst : std_logic := '0';

signal internal_selectOutput : STD_LOGIC_VECTOR(31 DOWNTO 0); -- LOOK IT UP

--SIGNAL FOR STALLS --> LOOK IT UP
signal stallValue : STD_LOGIC_VECTOR(31 DOWNTO 0) := "00000000000000000000000000100000";
signal memoryValue : STD_LOGIC_VECTOR(31 DOWNTO 0);
	
begin

nxt_address <= internal_selectOutput;
address <= to_integer(unsigned(addOutput(9 downto 0)))/4;


pcCounter : pc 
port map(
  clk => clk,
	rst => rst,
	pcOutput => pcOutput,
	pcInput => pcInput
);

add : adder
port map(
  clk => clk,
	four => four,
	counterOutput => pcOutput,
	adderOutput => addOutput
);

fetchMux : mux 
port map(
	 input_0 => addOutput,
	 input_1 => mux_EX,
	 selector => selectInputs,
	 output => internal_selectOutput
	 );
	 
structuralMux : mux 
port map (
input_0 => memoryValue,
input_1 => stallValue,
selector => structuralStall,
output => instruction
);

pcMux : mux 
port map (
input_0 => internal_selectOutput,
input_1 => pcOutput,
selector => pcStall,
output => pcInput
);
	 
iMem : instructionMemory
	GENERIC MAP(
            ram_size => 1024
                )
                PORT MAP(
                    clk,
                    writedata,
                    address,
                    memwrite,
                    memread,
                    memoryValue,
                    waitrequest
                );
				
	
				
end fetch_arch;




 
  


