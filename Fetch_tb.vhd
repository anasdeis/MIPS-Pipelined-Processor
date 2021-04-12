  
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

ENTITY Fetch_tb IS
END Fetch_tb;

architecture behavioral of Fetch_tb is

component Fetch IS
	port(
		clk : in std_logic;
		mux_in : in std_logic_vector(31 downto 0);
		fetch_sel : in std_logic;		
		next_address_out : out std_logic_vector(31 downto 0);
		instruction_out : out std_logic_vector(31 downto 0)
		);
end component;

	constant clk_period : time := 1 ns;
    
	signal clk : std_logic := '0';
	signal s_mux, s_address_output, s_instruction : std_logic_vector(31 DOWNTO 0);
	signal s_SEL : std_logic;
	
begin

	dut : Fetch 
	port map(
		clk => clk,
		mux_in => s_mux,
		fetch_sel => s_SEL,	
		next_address_out => s_address_output,
		instruction_out => s_instruction	
	);

    stim_process : process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

	 test_process : process
    begin   
		s_mux <= "00000000000000000000000000000001";
		s_SEL <= '0';

		wait;
		
	end process;
end behavioral;