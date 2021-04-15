-- Group 7: Anas Deis, Albert Assouad, Barry Chen
-- Date: 16/4/2021

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.definitions.all;

entity ID_EX is
	port(
        clk: in std_logic;
        PC_in: in integer;
        PC_out: out integer;
        instruction_in: in INSTRUCTION;
        instruction_out: out INSTRUCTION;
        ra_in: in std_logic_vector(31 downto 0);
        ra_out: out std_logic_vector(31 downto 0);
        rb_in: in std_logic_vector(31 downto 0);
        rb_out: out std_logic_vector(31 downto 0);
		immediate_in: in std_logic_vector(31 downto 0);
        immediate_out: out std_logic_vector(31 downto 0)
	);
end ID_EX;

architecture behavioral of ID_EX is
    signal PC_next: integer;
    signal instruction_next: INSTRUCTION;
    signal ra_next, rb_next, immediate_next: std_logic_vector(31 downto 0);
begin
    PC_out <= PC_next;
    instruction_out <= instruction_next;
    ra_out <= ra_next;
    rb_out <= rb_next;
	immediate_out <= immediate_next;
	
    ID_EX_process: process(clk, PC_in, instruction_in, ra_in, rb_in, immediate_in)
    begin
        if rising_edge(clk) then
            PC_next <= PC_in;
            instruction_next <= instruction_in;
            ra_next <= ra_in;
            rb_next <= rb_in;
			immediate_next <= immediate_in;
        end if;
    end process;
end behavioral;
