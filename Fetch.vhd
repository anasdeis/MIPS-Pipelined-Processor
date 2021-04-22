-- Group 7: Anas Deis, Albert Assouad, Barry Chen
-- Date: 16/4/2021

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.definitions.all;

-- Stage 1: Fetch
entity Fetch is
	generic(
		ram_size : INTEGER := 8192;  -- 32768/4 = 8192 lines or addresses 
		bit_width : INTEGER := 32	 -- 32-bit MIPS
	);
	port(
		-- INPUTS
		clk : in std_logic;
		reset : in std_logic;
		stall_in : in std_logic;  -- hazard stall
		branch_target_in : in integer;  -- combined with a condition test boolean to enable loading the branch target address into the PC
		branch_condition_in : in std_logic; -- condition test boolean
		
		-- OUTPUTS
		instruction_out : out INSTRUCTION;
		PC_out : out integer;

		-- Instruction Memory
		m_addr : out integer range 0 to ram_size-1;
		m_read : out std_logic;
		m_readdata : in std_logic_vector (bit_width-1 downto 0)
	);
	end Fetch;

architecture behavioral of Fetch is
	signal PC, PC_next : integer range 0 to ram_size-1 := 0;
begin 

	PC_out  <= PC; 
	PC_next <= 	PC when PC + 4 >= ram_size-1 or stall_in = '1' else PC + 4;	-- next instruction

	PC_process : process(clk, reset, branch_target_in, branch_condition_in, PC_next)
	begin
		if reset = '1' then
			PC <= 0;
		elsif rising_edge(clk) then
			if branch_condition_in = '1' then  -- branch when test condition is true
				PC <= branch_target_in;
			else
				PC <= PC_next; -- otherwise next instruction
			end if;
		end if ;
	end process; 

	memory_process : process(clk, reset, PC, m_readdata)
	variable instruction : INSTRUCTION;
	begin  
		if reset = '1' then
			instruction_out <= NO_OP;
		else	
			instruction := create_instruction(m_readdata);
			instruction_out <= instruction;
			m_addr <= PC / 4;
			m_read <= '1';	
		end if;
	end process;
end behavioral ; 