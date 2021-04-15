-- Group 7: Anas Deis, Albert Assouad, Barry Chen
-- Date: 16/4/2021

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.definitions.all;

entity MEM_WB is
	port(
        clk: in std_logic;
        instruction_in: in INSTRUCTION;
        instruction_out: out INSTRUCTION;
        alu_in: in std_logic_vector(63 downto 0);
        alu_out: out std_logic_vector(63 downto 0);
        mem_in: in std_logic_vector(31 downto 0);
        mem_out: out std_logic_vector(31 downto 0)
	);
end MEM_WB;

architecture behavioral of MEM_WB is
    signal instruction_next: INSTRUCTION;
    signal alu_next: std_logic_vector(63 downto 0);
    signal mem_next: std_logic_vector(31 downto 0);
begin
    instruction_out <= instruction_next;
    alu_out <= alu_next;
	mem_out <= mem_next;

    MEM_WB_process: process (clk, instruction_in, alu_in, mem_in)
    begin
        if(rising_edge(clk)) then
            instruction_next <= instruction_in;           
            alu_next <= alu_in;
			mem_next <= mem_in;
        end if;
    end process;
end behavioral;
