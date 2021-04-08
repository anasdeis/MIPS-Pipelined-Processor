-- Entity: Decode
-- Authors: Anas Deis, Albert Assouad, Barry Chen
-- Date: 04/16/2021

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

-- Stage 2: Decode
-- Takes output from IF/ID and send it to EX for calculations.
entity Decode is
port (
	clk : in std_logic;
	
	-- IF
	instruction_in : in std_logic_vector (31 downto 0);  -- instruction from IF stage
	
	-- WB
	write_file_en : in std_logic;						  -- enable writing to file
	write_en_in : in std_logic; 						  -- enable writing to registry from WB stage
	rd_in : in std_logic_vector (4 downto 0);	 		  -- register destination from WB stage
	rd_reg_data_in : in std_logic_vector (31 downto 0);   -- data to write back from WB stage
	rs_reg_data_out : out std_logic_vector (31 downto 0); -- data associated with the register index of rs (register source)
	rt_reg_data_out : out std_logic_vector (31 downto 0); -- data associated with the register index of rt (register target)

	-- Types of instruction
	R_Type_out : out std_logic; -- R instructions
	J_Type_out : out std_logic; -- J instructions
	shift_out  : out std_logic; -- shift instructions
	
	-- Control lines
	-- MEM stage
	MemRead_out  : out std_logic; -- enables a memory read for load instructions
	MemWrite_out : out std_logic; -- enables a memory write for store instructions
	MemToReg_out   : out std_logic;	-- determines where the value to be written comes from (EX or MEM)
	RegWrite_out : out std_logic; -- enables a write to one of the registers
	
	-- PC
	structural_hazard_out : out std_logic; -- hazard: structural stall
	branch_in             : in std_logic; -- combined with a condition test boolean to enable loading the branch target address into the PC
	old_branch_in      : in std_logic;
	
	-- EX stage
	ALUOp_out : out std_logic_vector(4 downto 0); -- specifies the ALU operation to be performed
	-- selector for ALU mux in EX stage 
	sel_ALU_mux0_out : out std_logic; -- determine input A: register A or address (output of IF) (ALU1src)
	sel_ALU_mux1_out : out std_logic; -- determine input B: register B or immediate value (ALU2src)

	-- sign extender
	immediate_out: out std_logic_vector (31 downto 0) -- output of sign extended immediate address
  );
end Decode;

architecture behavioral of Decode is

-- Signals for register file
type registers is array (0 to 31) of std_logic_vector(31 downto 0);	-- MIPS 32 32-bit registers
signal register_file: registers := (others => x"00000000"); 		   -- initialize all registers to 0, including R0

begin

	update_reg_data: process (clk)
	
	variable rs : std_logic_vector(4 downto 0);	-- register source (rs)
	variable rt : std_logic_vector(4 downto 0);	-- register target (rt)

	begin
	
	rs := instruction_in(25 downto 21);	
	rt := instruction_in(20 downto 16);	
	
		if (clk'event and clk = '1') then
			rs_reg_data_out <= register_file(to_integer(unsigned(rs))); 
			rt_reg_data_out <= register_file(to_integer(unsigned(rt)));
			if (write_en_in = '1') then 	-- update rd data if writing is enabled by WB stage
				if (to_integer(unsigned(rd_in)) /= 0) then 	-- only write to other than R0
					register_file(to_integer(unsigned(rd_in))) <= rd_reg_data_in; -- write rd data into the register index of rd				
				end if;
			end if;
		end if;
	end process;

	write_file: process(write_file_en)
	FILE fptr : text;
	variable file_line : line;	
	variable idx : integer := 0;
	
	begin
	
		if write_file_en = '1' then
			file_open(fptr,"register_file.txt.", write_mode);
			idx := 0;
			while (idx < 32) loop 
				write(file_line, register_file(idx));
				writeline(fptr, file_line);
				idx := idx + 1;
			end loop;
		end if;
		
		file_close(fptr);
		
	end process;

	sign_extender: process (instruction_in)
	
	variable imm : std_logic_vector(15 downto 0);	
	
		begin
		
			imm := instruction_in(15 downto 0);	
			
			if imm(15) = '1' then
				immediate_out(31 downto 16) <= "1000000000000000";
			else
				immediate_out(31 downto 16) <= "0000000000000000";
			end if;
			
		immediate_out(15 downto 0) <= imm(15 downto 0);
	end process;


	control: process(instruction_in)
	
	variable opcode : std_logic_vector(5 downto 0);	
	variable funct : std_logic_vector(5 downto 0);	
	
	begin
	
		opcode := instruction_in(31 downto 26);	
		funct := instruction_in(5 downto 0);	
		
		-- Empty control lines values
		if (branch_in = '1') or (old_branch_in = '1') then
			MemRead_out <= '0';
			MemWrite_out <= '0';
			MemToReg_out <= '0';
			RegWrite_out <= '0';
			sel_ALU_mux0_out <= '0';
			sel_ALU_mux1_out <= '0';
			R_Type_out <= '1';
			J_Type_out <= '0';
			shift_out <= '0';
			structural_hazard_out <= '0';
			ALUOp_out <= "00000";
			
		else
		
			-- Arithmetic 
			
			-- 1 ADD 
			if (opcode = "000000") and (funct = "100000") then	
				MemRead_out <= '0';
				MemWrite_out <= '0';
				MemToReg_out <= '0'; 
				RegWrite_out <= '1';
				sel_ALU_mux0_out <= '0';
				sel_ALU_mux1_out <= '1';
				R_Type_out <= '1';
				J_Type_out <= '0';
				shift_out <= '0';
				structural_hazard_out <= '0';
				ALUOp_out <= "00001";
			
			-- 2 SUB
			elsif (opcode = "000000") and (funct = "100010") then
				MemRead_out <= '0';
				MemWrite_out <= '0';				
				MemToReg_out <= '0'; 
				RegWrite_out <= '1';
				sel_ALU_mux0_out <= '0';
				sel_ALU_mux1_out <= '1';
				R_Type_out <= '1';
				J_Type_out <= '0';
				shift_out <= '0';
				structural_hazard_out <= '0';
				ALUOp_out <= "00010";
			
			-- 3 ADDI
			elsif (opcode = "001000") then				
				MemRead_out <= '0';
				MemWrite_out <= '0';				
				MemToReg_out <= '0'; 
				RegWrite_out <= '1';
				sel_ALU_mux0_out <= '0';
				sel_ALU_mux1_out <= '0';
				R_Type_out <= '0';				
				J_Type_out <= '0';
				shift_out <= '0';
				structural_hazard_out <= '0';
				ALUOp_out <= "00011";
			
			-- 4 MULT	
			elsif (opcode = "000000") and (funct = "011000") then				
				MemRead_out <= '0';
				MemWrite_out <= '0';				
				MemToReg_out <= '0';
				RegWrite_out <= '1';
				sel_ALU_mux0_out <= '0';
				sel_ALU_mux1_out <= '1';
				R_Type_out <= '1';				
				J_Type_out <= '0';
				shift_out <= '0';
				structural_hazard_out <= '0';
				ALUOp_out <= "00100";
			
			-- 5 DIV
			elsif (opcode = "000000") and (funct = "011010") then				
				MemRead_out <= '0';
				MemWrite_out <= '0';				
				MemToReg_out <= '0';
				RegWrite_out <= '1';
				sel_ALU_mux0_out <= '0';
				sel_ALU_mux1_out <= '1';
				R_Type_out <= '1';		
				J_Type_out <= '0';
				shift_out <= '0';
				structural_hazard_out <= '0';
				ALUOp_out <= "00101";
			
			-- 6 SLT
			elsif (opcode = "000000") and (funct  = "101010") then			
				MemRead_out <= '0';
				MemWrite_out <= '0';				
				MemToReg_out <= '0';
				RegWrite_out <= '1';
				sel_ALU_mux0_out <= '0';
				sel_ALU_mux1_out <= '1';				
				R_Type_out <= '1';				
				J_Type_out <= '0';
				shift_out <= '0';
				structural_hazard_out <= '0';
				ALUOp_out <= "00110";
				
			-- 7 SLTI
			elsif funct  = "001010" then
				MemRead_out <= '0';
				MemWrite_out <= '0';			
				MemToReg_out <= '0'; 
				RegWrite_out <= '1';
				sel_ALU_mux0_out <= '0';
				sel_ALU_mux1_out <= '0';
				R_Type_out <= '0';				
				J_Type_out <= '0';
				shift_out <= '0';
				structural_hazard_out <= '0';
				ALUOp_out <= "00111";
			
			-- Logical 
			
			-- 8 AND
			elsif (opcode = "000000") and (funct =  "100100") then				
				MemRead_out <= '0';
				MemWrite_out <= '0';				
				MemToReg_out <= '0';
				RegWrite_out <= '1';				
				sel_ALU_mux0_out <= '0';
				sel_ALU_mux1_out <= '1';
				R_Type_out <= '1';		
				J_Type_out <= '0';
				shift_out <= '0';
				structural_hazard_out <= '0';	
				ALUOp_out <= "01000";
				
			-- 9 OR
			elsif (opcode = "000000") and (funct = "100101") then
				MemRead_out <= '0';
				MemWrite_out <= '0';		
				MemToReg_out <= '0'; 
				RegWrite_out <= '1';
				sel_ALU_mux0_out <= '0';
				sel_ALU_mux1_out <= '1';
				R_Type_out <= '1';
				J_Type_out <= '0';
				shift_out <= '0';
				structural_hazard_out <= '0';
				ALUOp_out <= "01001";
			
			-- 10 NOR
			elsif (opcode = "000000") and (funct =  "100111") then 			
				MemRead_out <= '0';
				MemWrite_out <= '0';			
				MemToReg_out <= '0'; 
				RegWrite_out <= '1';
				sel_ALU_mux0_out <= '0';
				sel_ALU_mux1_out <= '1';
				R_Type_out <= '1';			
				J_Type_out <= '0';
				shift_out <= '0';
				structural_hazard_out <= '0';
				ALUOp_out <= "01010";
			
			-- 11 XOR
			elsif (opcode = "000000") and (funct = "101000") then				
				MemRead_out <= '0';
				MemWrite_out <= '0';				
				MemToReg_out <= '0';
				RegWrite_out <= '1';
				sel_ALU_mux0_out <= '0';
				sel_ALU_mux1_out <= '1';
				ALUOp_out <= "01010"; 
				R_Type_out <= '1';
				J_Type_out <= '0';
				shift_out <= '0';
				structural_hazard_out <= '0';
				ALUOp_out <= "01011";
			
			-- 12 ANDI 
			elsif opcode = "001100" then
				MemRead_out <= '0';
				MemWrite_out <= '0';				
				MemToReg_out <= '0';
				RegWrite_out <= '1';
				sel_ALU_mux0_out <= '0';
				sel_ALU_mux1_out <= '0';				
				R_Type_out <= '0';
				J_Type_out <= '0';
				shift_out <= '0';
				structural_hazard_out <= '0';
				ALUOp_out <= "01100";
			
			-- 13 ORI 
			elsif opcode = "001101" then				
				MemRead_out <= '0';
				MemWrite_out <= '0';				
				MemToReg_out <= '0'; 
				RegWrite_out <= '1';
				sel_ALU_mux0_out <= '0';
				sel_ALU_mux1_out <= '0';
				R_Type_out <= '0';			
				J_Type_out <= '0';
				shift_out <= '0';
				structural_hazard_out <= '0';
				ALUOp_out <= "01101";
			
			-- 14 XORI
			elsif opcode = "001110" then				
				MemRead_out <= '0';
				MemWrite_out <= '0';		
				MemToReg_out <= '0';
				RegWrite_out <= '1';
				sel_ALU_mux0_out <= '0';
				sel_ALU_mux1_out <= '0';
				R_Type_out <= '0';				
				J_Type_out <= '0';
				shift_out <= '0';
				structural_hazard_out <= '0';
				ALUOp_out <= "01110";
			
			-- Transfer
			
			-- 15 MFHI
			elsif (opcode = "000000") and (funct = "010000") then				
				MemRead_out <= '0';
				MemWrite_out <= '0';		
				MemToReg_out <= '0';
				RegWrite_out <= '1';
				sel_ALU_mux0_out <= '0';
				sel_ALU_mux1_out <= '1'; 
				R_Type_out <= '1';				
				J_Type_out <= '0';
				shift_out <= '0';
				structural_hazard_out <= '0';
				ALUOp_out <= "01111";
			
			-- 16 MFLO
			elsif (opcode = "000000") and (funct = "010010") then 				 
				MemRead_out <= '0';
				MemWrite_out <= '0';				
				MemToReg_out <= '0';
				RegWrite_out <= '1';
				sel_ALU_mux0_out <= '0';
				sel_ALU_mux1_out <= '1';
				R_Type_out <= '1';				
				J_Type_out <= '0';
				shift_out <= '0';
				structural_hazard_out <= '0';
				ALUOp_out <= "10000";
			
			-- 17 LUI
			elsif opcode = "001111" then				
				MemRead_out <= '0';
				MemWrite_out <= '0';				
				MemToReg_out <= '0';
				RegWrite_out <= '1';
				sel_ALU_mux0_out <= '0';
				sel_ALU_mux1_out <= '0';				
				R_Type_out <= '0';			
				J_Type_out <= '0';
				shift_out <= '0';
				structural_hazard_out <= '0';
				ALUOp_out <= "10001";
			
			-- Shift
			
			-- 18 SLL
			elsif (opcode = "000000") and (funct = "000000") then 				
				MemRead_out <= '0';
				MemWrite_out <= '0';				
				MemToReg_out <= '0';
				RegWrite_out <= '1';
				sel_ALU_mux0_out <= '0';
				sel_ALU_mux1_out <= '0';
				R_Type_out <= '1';				
				J_Type_out <= '0';
				shift_out <= '1';
				structural_hazard_out <= '0';
				ALUOp_out <= "10010";
						
			-- 19 SRL
			elsif (opcode = "000000") and (funct = "000010") then 				
				MemRead_out <= '0';
				MemWrite_out <= '0';			
				MemToReg_out <= '0';
				RegWrite_out <= '1';
				sel_ALU_mux0_out <= '0';
				sel_ALU_mux1_out <= '0';
				R_Type_out <= '1';				
				J_Type_out <= '0';
				shift_out <= '1';
				structural_hazard_out <= '0';
				ALUOp_out <= "10011";
			
			-- 20 SRA
			elsif (opcode = "000000") and (funct = "000011") then 			
				MemRead_out <= '0';
				MemWrite_out <= '0';				
				MemToReg_out <= '0';
				RegWrite_out <= '1';
				sel_ALU_mux0_out <= '0';
				sel_ALU_mux1_out <= '0';
				R_Type_out <= '1';
				J_Type_out <= '0';
				structural_hazard_out <= '0';
				ALUOp_out <= "10100";
			
			-- Memory
			
			-- 21 LW 
			elsif opcode = "100011" then			
				MemRead_out <= '1';
				MemWrite_out <= '0';				
				MemToReg_out <= '1'; 
				RegWrite_out <= '1';
				sel_ALU_mux0_out <= '0';
				sel_ALU_mux1_out <= '0';
				R_Type_out <= '0';				
				J_Type_out <= '0';
				shift_out <= '0';
				structural_hazard_out <= '1';
				ALUOp_out <= "10101";
			
			-- 22 SW 
			elsif opcode = "101011" then				
				MemRead_out <= '0';
				MemWrite_out <= '1';				
				MemToReg_out <= '1'; 
				RegWrite_out <= '0';
				sel_ALU_mux0_out <= '0';
				sel_ALU_mux1_out <= '0';
				R_Type_out <= '0';			
				J_Type_out <= '0';
				shift_out <= '0';
				structural_hazard_out <= '0';
				ALUOp_out <= "10110";
			
			-- Control-flow
			
			-- 23 BEQ
			elsif opcode = "000100" then				
				MemRead_out <= '0';
				MemWrite_out <= '0';				
				MemToReg_out <= '0';
				RegWrite_out <= '0';
				sel_ALU_mux0_out <= '1';
				sel_ALU_mux1_out <= '0';
				R_Type_out <= '0';			
				J_Type_out <= '0';
				shift_out <= '0';
				structural_hazard_out <= '0';
				ALUOp_out <= "10111";
			
			-- 24 BNE
			elsif opcode = "000101" then				
				MemRead_out <= '0';
				MemWrite_out <= '0';				
				MemToReg_out <= '0'; 
				RegWrite_out <= '0';
				sel_ALU_mux0_out <= '1';
				sel_ALU_mux1_out <= '0';
				R_Type_out <= '0';			
				J_Type_out <= '0';
				shift_out <= '0';
				structural_hazard_out <= '0';
				ALUOp_out <= "11000";
			
			-- 25 J
			elsif opcode = "000010" then				
				MemRead_out <= '0';
				MemWrite_out <= '0';				
				MemToReg_out <= '0';
				RegWrite_out <= '0';
				sel_ALU_mux0_out <= '1';
				sel_ALU_mux1_out <= '0';
				R_Type_out <= '0';				
				J_Type_out <= '1';	
				shift_out <= '0';
				structural_hazard_out <= '0';
				ALUOp_out <= "11001";
			
			-- 26 JR
			elsif (opcode = "000101") and (funct = "001000") then 				
				MemRead_out <= '0';
				MemWrite_out <= '0';				
				MemToReg_out <= '0';
				RegWrite_out <= '0';
				sel_ALU_mux0_out <= '0';
				sel_ALU_mux1_out <= '0';
				R_Type_out <= '1';				
				J_Type_out <= '1';
				shift_out <= '0';
				structural_hazard_out <= '0';
				ALUOp_out <= "11010";
			
			-- 27 JAL  
			elsif opcode = "000011" then				
				MemRead_out <= '0';
				MemWrite_out <= '0';				
				MemToReg_out <= '0'; 
				RegWrite_out <= '1';
				sel_ALU_mux0_out <= '1';
				sel_ALU_mux1_out <= '0';
				R_Type_out <= '0';				
				J_Type_out <= '1';
				shift_out <= '0';
				structural_hazard_out <= '0';
				ALUOp_out <= "11011";

			end if;			
		end if;
	end process;
end behavioral;


