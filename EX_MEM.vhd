-- Group 7: Anas Deis, Albert Assouad, Barry Chen
-- Date: 16/4/2021

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.definitions.all;

entity EX_MEM is
	port (
        clk: in std_logic;
        PC_in: in INTEGER;
        PC_out: out integer;
        instruction_in: in INSTRUCTION;
        instruction_out: out INSTRUCTION;
        branch_in: in std_logic;
        branch_out: out std_logic;
		branch_target_in : in std_logic_vector(31 downto 0);
        branch_target_out : out std_logic_vector(31 downto 0);
		rb_in: in std_logic_vector(31 downto 0);
        rb_out: out std_logic_vector(31 downto 0);
        alu_in: in std_logic_vector(63 downto 0);
        alu_out: out std_logic_vector(63 downto 0)
	);
end EX_MEM;

architecture behavioral of EX_MEM is
    signal PC_next: integer;
    signal instruction_next: INSTRUCTION;
    signal branch_next: std_logic;
    signal branch_target_next, rb_next: std_logic_vector(31 downto 0);
	signal alu_next: std_logic_vector(63 downto 0);
begin
    PC_out <= PC_next;
    instruction_out <= instruction_next;
    branch_out <= branch_next;
	branch_target_out <= branch_target_next;
	rb_out <= rb_next;
    alu_out <= alu_next;

    EX_MEM_process: process (clk, PC_in, instruction_in, branch_in, branch_target_in, rb_in, alu_in)
    begin
        if rising_edge(clk) then
            PC_next <= PC_in;
            instruction_next <= instruction_in;
            branch_next <= branch_in;
			branch_target_next <= branch_target_in;
			rb_next <= rb_in;
            alu_next <= alu_in; 
        end if;
    end process;
end behavioral;
