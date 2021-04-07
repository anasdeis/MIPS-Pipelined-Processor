library ieee;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use work.definitions.all;
use std.textio.all;
use ieee.std_logic_textio.all;


entity ex is
port (
    -- inputs
    
    clk : in std_logic;
    -- From IF
    adder_in : std_logic_vector(31 downto 0);
    
	  -- From decode
    aluOp_in : in std_logic_vector(4 downto 0);
    immediate_in : in std_logic_vector(31 downto 0);
    read_data_1 : in std_logic_vector(31 downto 0);
    read_data_2 : in std_logic_vector(31 downto 0);

    -- output

    -- To IF
    adder_result : out(31 downto 0);

    -- To Memory
    alu_result : out(31 downto 0) 
    );
end ex;

architecture behavioral of ex is

--component declaration
component mux port (
    clk : in std_logic;
    selector : in  STD_LOGIC;
    input_0   : in  STD_LOGIC_VECTOR (31 downto 0);
    input_1   : in  STD_LOGIC_VECTOR (31 downto 0);
    output   : out STD_LOGIC_VECTOR (31 downto 0));

); end component;
  
component alu port (
    clk : in std_logic;
    in_a : in STD_LOGIC_VECTOR (31 downto 0);
    in_b : in STD_LOGIC_VECTOR (31 downto 0);
    instruction : in STD_LOGIC_VECTOR (4 downto 0);
    output : out STD_LOGIC_VECTOR(31 downto 0));
); end component;

component adder port (
    clk : in std_logic;
    four : in integer;
    counterOutput : in std_logic_vector(31 downto 0);
    adderOutput : out std_logic_vector(31 downto 0)
); end component;


--signal declaration
signal muxResult : word_type;
signal muxSelect : std_logic_vector (1 downto 0);


begin 

inputOne <= store_in;
load_out <= load_in;
dest_register_out <= dest_register_in;
write_back_out <= write_back_in;

exMux : mux port map(
    clk => clk,
    selector => muxSelect,
    input_0 => read_data_2,
    input_1 => std_logic_vector(rotate_left(unsigned(immediate_in), 2)),
    output => muxResult);	

exAlu : alu port map(
    clk => clk,
    in_a => read_data_1,
    in_b => muxResult,
    instruction => aluOp_in,
    output => alu_result);


exAdder : adder port map( 
    clk => clk,
    four => adder_in,
    counterOutput => std_logic_vector(rotate_left(unsigned(immediate_in), 2)),
    adderOutput => adder_result);

end architecture;
