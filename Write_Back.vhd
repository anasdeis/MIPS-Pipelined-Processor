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
	-- INPUTS
	mem_op_en_in: in std_logic;					  -- enable using result from MEM (lw,sw), otherwise use result from EX
	register_file_en_in: in std_logic;		      -- enable writing to register_file.txt if opcode is not a branch or jump
	ex_in : in std_logic_vector (31 downto 0);	  -- result from EX
	mem_in: in std_logic_vector (31 downto 0);	  -- result from MEM
	ir_in: in std_logic_vector (4 downto 0);      -- instruction in
	
	-- OUTPUTS
	register_file_en_out: out std_logic;		  -- enable writing to register_file.txt if opcode is not a branch or jump
	mux_out : out std_logic_vector (31 downto 0); -- data to write back
	ir_out: out std_logic_vector (4 downto 0)	  -- instruction out
);
end Write_Back;

architecture behavioral of Write_Back is

begin
	process(mem_op_en_in, register_file_en_in, ex_in, mem_in)
	begin	
		-- check opcode if (lw,sw) or otherwise
		case mem_op_en_in is
			-- use result from EX stage
			when '0' => 
				mux_out <= ex_in;
			-- use result from MEM stage
			when '1' => 
				mux_out <= mem_in;
			-- else unknown
			when others => 
				mux_out <= "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"; 
		end case;
		
		register_file_en_out <= register_file_en_in; -- enable writing
		ir_out <= ir_in;							 -- destination register address
	end process;
end behavioral;