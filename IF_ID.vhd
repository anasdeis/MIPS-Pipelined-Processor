-- Group 7: Anas Deis, Albert Assouad, Barry Chen
-- Date: 16/4/2021

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.definitions.all;

entity IF_ID is
	port(
        clk: in std_logic;
		stall_in: in std_logic;
        PC_in: in integer;
        PC_out: out integer;
        instruction_in: in INSTRUCTION;
        instruction_out: out INSTRUCTION
	);
end IF_ID;

architecture behavioral of IF_ID is
    signal PC_next: integer;
    signal instruction_next: INSTRUCTION;
begin
    PC_out <= PC_next;
    instruction_out <= instruction_next;
	
    IF_ID_process: process (clk, stall_in, PC_in, instruction_in)
    begin
        if(rising_edge(clk)) then
            if(stall_in = '0') then -- propagate signals if no stall
                PC_next <= PC_in; 
                instruction_next <= instruction_in;
            end if;
        end if;
    end process;
end behavioral;
