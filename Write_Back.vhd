-- Group 7: Anas Deis, Albert Assouad, Barry Chen
-- Date: 16/4/2021

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.instruction_tools.all;

-- Stage 5 : Write_Back
entity Write_Back is
	port(
		-- INPUTS
		instruction_in : in instruction;
		memory_data_in : in std_logic_vector(31 downto 0);
		alu_in : in std_logic_vector(63 downto 0);
				
		-- OUTPUTS
		instruction_out : out instruction;
		wb_data_out : out std_logic_vector(63 downto 0)
	);
end Write_Back ;

architecture behavioral of Write_Back is
begin
  instruction_out <= instruction_in;
  wb_data_out <= x"00000000" & memory_data_in when instruction_in.instruction_type = LOAD_WORD else
				 alu_in;
end behavioral ; 