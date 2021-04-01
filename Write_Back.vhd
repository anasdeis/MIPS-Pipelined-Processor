-- Entity: Write_Back
-- Authors: Anas Deis, Albert Assouad, Barry Chen
-- Date: 04/16/2021

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Stage 5: Write Back
-- Takes output from EX/MEM and send it to ID to update registers.
entity Write_Back is
port (
	mem_op_en_in: in std_logic;					    -- enable using result from MEM (lw,sw), otherwise use result from EX
	register_file_en_in: in std_logic;				 -- enable writing to register_file.txt if opcode is not a branch or jump
	EX_in : in std_logic_vector (31 downto 0);	 -- result from EX
	MEM_in: in std_logic_vector (31 downto 0);	 -- result from MEM
	IR_in: in std_logic_vector (4 downto 0);		 -- instruction in
	
	register_file_en_out: out std_logic;			 -- enable writing to register_file.txt if opcode is not a branch or jump
	MUX_out : out std_logic_vector (31 downto 0); -- data to write back
	IR_out: out std_logic_vector (4 downto 0)		 -- instruction out
  );
end wb;

architecture behavioral of Write_Back is

begin
	process(mem_op_en_in, EX_in, MEM_in, register_file_en_out)
	begin
		register_file_en_out <= register_file_en_in;	 -- enable writing
		IR_OUT <= IR_IN;								       -- destination register address
		
		-- check opcode if (lw,sw) or otherwise
		case mem_op_en_in is
			-- use result from EX stage
			when '0' => 
				MUX_out <= EX_in;
			-- use result from MEM stage
			when '1' => 
				MUX_out <= MEM_in;
			-- else unknown
			when others => 
				MUX_out <= x"XXXXXXXX"; 
		end case;
	end process;
end behavioral;