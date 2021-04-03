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
	clk: in std_logic;
	write_file_en: in std_logic;							    -- enable writing to file
	write_reg_en_in: in std_logic; 							 -- enable writing to registry file from WB stage
	rd_in: in std_logic_vector (4 downto 0);	 			 -- register destination from WB stage
	rd_reg_data_in : in std_logic_vector (31 downto 0); -- data to write back from WB stage
	instruction_in: in std_logic_vector (31 downto 0);  -- instruction from IF stage

	
	rs_reg_data_out: out std_logic_vector (31 downto 0);	-- data associated with the register index of rs (register source)
	rt_reg_data_out: out std_logic_vector (31 downto 0);	-- data associated with the register index of rt (register target)


	-- Control lines to MEM stage
	memRead : out STD_LOGIC;
	memWrite : out STD_LOGIC; 
	regWrite : out STD_LOGIC; 
	MemToReg : out STD_LOGIC;
	
	-- Type of instruction
	RType: out STD_LOGIC;
	JType: out STD_LOGIC;
	Shift: out STD_LOGIC;
	opcode_out : out STD_LOGIC_VECTOR(5 downto 0);
	
	-- ??
	structuralStall : out STD_LOGIC;
	branch: in std_logic;
	oldBranch: in std_logic;
	
	

	-- selector for mux in EX stage 
	sel_ALU_mux1 : out STD_LOGIC; -- determine input A: register A or address (output of IF) (ALU1src)
	sel_ALU_mux2 : out STD_LOGIC; -- determine input B: register B or immediate value (ALU2src)

	-- sign extender
	immediate_out: out std_logic_vector (31 downto 0) -- output of sign extender

	
  );
end Decode;

architecture behavioral of Decode is

signal immediate_in : std_logic_vector(15 downto 0); -- for sign extender

-- Signals for decoder
signal opcode, func : std_logic_vector(5 downto 0);
--signal opcode_out : std_logic_vector(4 downto 0);


-- Signals for register file

type registers is array (0 to 31) of std_logic_vector(31 downto 0);	-- MIPS 32 32-bit registers
signal register_file: registers := (others => x"00000000"); 		   -- initialize all registers to 0, including R0

begin
	process (clk)
	
	variable rs : std_logic_vector(4 downto 0);	-- register source (rs)
	variable rt : std_logic_vector(4 downto 0);	-- register target (rt)

	begin
	
	rs := instruction_in(25 downto 21);	
	rt := instruction_in(20 downto 16);	
	
		if (clk'event and clk = '1') then
			rs_reg_data_out <= register_file(to_integer(unsigned(rs))); 
			rt_reg_data_out <= register_file(to_integer(unsigned(rt)));
			if (write_reg_en_in = '1') then 	-- update rd data if writing is enabled by WB stage
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

	opcode <= instruction_in(31 downto 26);
	opcode_out <=  opcode;
  func <= instruction_in(5 downto 0);
	
	
	sign_extender: process (instruction_in)
		begin
			--Only Sign extend at the moment
			if instruction_in(15) = '1' then
				immediate_out(31 downto 16) <= "1000000000000000";
			else
				immediate_out(31 downto 16) <= "0000000000000000";
		end if;
		immediate_out(15 downto 0) <= instruction_in(15 downto 0);
	end process;


	process(opcode, func)
		begin
		--Send empty ctrl insturctions 
		if (branch = '1') or (oldBranch = '1') then
			sel_ALU_mux1 <= '0';
			sel_ALU_mux2 <= '0';
			MemRead <= '0';
			MemWrite <= '0';
			RegWrite <= '0';
			MemToReg <= '0';
			RType <= '1';
			Shift <= '0';
			JType <= '0';
			structuralStall <= '0';
		else
		
		
		
			case opcode is
			when "000000" =>
			-- SLL   PADED BY SIGN EXTEND TO DO 
			if func = "000000" then 
			sel_ALU_mux1 <= '0';
			sel_ALU_mux2 <= '0';
			MemRead <= '0';
			MemWrite <= '0';
			RegWrite <= '1';
			MemToReg <= '0';
			RType <= '1';
			Shift <= '1';
			JType <= '0';
			structuralStall <= '0';
			
			
			--XOR ??
			elsif func = "101000" then
			sel_ALU_mux1 <= '0';
			sel_ALU_mux2 <= '1';
			MemRead <= '0';
			MemWrite <= '0';
			RegWrite <= '1';
			MemToReg <= '0';
			opcode_out <= "01010"; 
			RType <= '1';
			Shift <= '0';
			structuralStall <= '0';
			
			--AND
			elsif func =  "100100" then
			sel_ALU_mux1 <= '0';
			sel_ALU_mux2 <= '1';
			MemRead <= '0';
			MemWrite <= '0';
			RegWrite <= '1';
			MemToReg <= '0'; 
			RType <= '1';
			Shift <= '0';
			JType <= '0';
			structuralStall <= '0';
			
			--ADD
			elsif func = "100000" then
			sel_ALU_mux1 <= '0';
			sel_ALU_mux2 <= '1';
			MemRead <= '0';
			MemWrite <= '0';
			RegWrite <= '1';
			MemToReg <= '0'; 
			RType <= '1';
			Shift <= '0';
			JType <= '0';
			structuralStall <= '0';

			--SUB 
			elsif func  = "100010" then
			sel_ALU_mux1 <= '0';
			sel_ALU_mux2 <= '1';
			MemRead <= '0';
			MemWrite <= '0';
			RegWrite <= '1';
			MemToReg <= '0'; 
			RType <= '1';
			Shift <= '0';
			JType <= '0';
			structuralStall <= '0';
			
			--SLT
			elsif func  = "101010" then
			sel_ALU_mux1 <= '0';
			sel_ALU_mux2 <= '1';
			MemRead <= '0';
			MemWrite <= '0';
			RegWrite <= '1';
			MemToReg <= '0'; 
			RType <= '1';
			Shift <= '0';
			JType <= '0';
			structuralStall <= '0';
			
			--SRL PADED BY SIGN EXTEND 
			elsif func = "000010" then 
			sel_ALU_mux1 <= '0';
			sel_ALU_mux2 <= '0';
			MemRead <= '0';
			MemWrite <= '0';
			RegWrite <= '1';
			MemToReg <= '0';
			RType <= '1';
			Shift <= '1';
			JType <= '0';
			structuralStall <= '0';
			
			--OR
			elsif func = "100101" then
			sel_ALU_mux1 <= '0';
			sel_ALU_mux2 <= '1';
			MemRead <= '0';
			MemWrite <= '0';
			RegWrite <= '1';
			MemToReg <= '0'; 
			RType <= '1';
			Shift <= '0';
			JType <= '0';
			structuralStall <= '0';
			
			--NOR
			elsif func =  "100111" then 
			sel_ALU_mux1 <= '0';
			sel_ALU_mux2 <= '1';
			MemRead <= '0';
			MemWrite <= '0';
			RegWrite <= '1';
			MemToReg <= '0'; 
			RType <= '1';
			Shift <= '0';
			JType <= '0';
			structuralStall <= '0';
			
			-- JR (JUMP REGISTER)
			elsif func = "001000" then 
			sel_ALU_mux1 <= '0';
			sel_ALU_mux2 <= '0';
			MemRead <= '0';
			MemWrite <= '0';
			RegWrite <= '0';
			MemToReg <= '0';
			RType <= '1';
			Shift <= '0';
			JType <= '1';
			structuralstall <= '0';
			
			-- DIV
			elsif func = "011010" then
			sel_ALU_mux1 <= '0';
			sel_ALU_mux2 <= '1';
			MemRead <= '0';
			MemWrite <= '0';
			RegWrite <= '1';
			MemToReg <= '0';
			RType <= '1';
			Shift <= '0';
			JType <= '0';
			structuralStall <= '0';
			
			-- MULT	
			elsif func = "011000" then
			sel_ALU_mux1 <= '0';
			sel_ALU_mux2 <= '1';
			MemRead <= '0';
			MemWrite <= '0';
			RegWrite <= '1';
			MemToReg <= '0';
			RType <= '1';
			Shift <= '0';
			JType <= '0';
			structuralStall <= '0';
			
			--SRA
			elsif func = "000011" then 
			sel_ALU_mux1 <= '0';
			sel_ALU_mux2 <= '0';
			MemRead <= '0';
			MemWrite <= '0';
			RegWrite <= '1';
			MemToReg <= '0';
			RType <= '1';
			JType <= '0';
			structuralStall <= '0';
			
			-- mfhi (move from high) ?? check what does it do
			elsif func = "010000" then
			sel_ALU_mux1 <= '0';
			sel_ALU_mux2 <= '1'; -- ??
			MemRead <= '0';
			MemWrite <= '0';
			RegWrite <= '1';
			MemToReg <= '0';
			RType <= '1';
			Shift <= '0';
			JType <= '0';
			structuralStall <= '0';
			
			--mflo (move from low) ?? check what does it do
			elsif func = "010010" then 
			sel_ALU_mux1 <= '0';
			sel_ALU_mux2 <= '1'; -- ?
			MemRead <= '0';
			MemWrite <= '0';
			RegWrite <= '1';
			MemToReg <= '0';
			RType <= '1';
			Shift <= '0';
			JType <= '0';
			structuralStall <= '0';
			
			end if;
			
			--ADDI
			when "001000" => 
			sel_ALU_mux1 <= '0';
			sel_ALU_mux2 <= '0';
			MemRead <= '0';
			MemWrite <= '0';
			RegWrite <= '1';
			MemToReg <= '0'; 
			RType <= '0';
			Shift <= '0';
			JType <= '0';
			structuralStall <= '0';
				
			--SLTI
			when "001010" => 
			sel_ALU_mux1 <= '0';
			sel_ALU_mux2 <= '0';
			MemRead <= '0';
			MemWrite <= '0';
			RegWrite <= '1';
			MemToReg <= '0'; 
			RType <= '0';
			Shift <= '0';
			JType <= '0';
			structuralStall <= '0';
			
			--ANDI 
			when "001100" => 
			sel_ALU_mux1 <= '0';
			sel_ALU_mux2 <= '0';
			MemRead <= '0';
			MemWrite <= '0';
			RegWrite <= '1';
			MemToReg <= '0'; 
			RType <= '0';
			Shift <= '0';
			JType <= '0';
			structuralStall <= '0';
			
			--ORI 
			when "001101" => 
			sel_ALU_mux1 <= '0';
			sel_ALU_mux2 <= '0';
			MemRead <= '0';
			MemWrite <= '0';
			RegWrite <= '1';
			MemToReg <= '0'; 
			RType <= '0';
			Shift <= '0';
			JType <= '0';
			structuralStall <= '0';
			
			--XORI
			when "001110" => 
			sel_ALU_mux1 <= '0';
			sel_ALU_mux2 <= '0';
			MemRead <= '0';
			MemWrite <= '0';
			RegWrite <= '1';
			MemToReg <= '0';
			RType <= '0';
			Shift <= '0';
			JType <= '0';
			structuralStall <= '0';
			
			--LUI
			when "001111" => 
			sel_ALU_mux1 <= '0';
			sel_ALU_mux2 <= '0';
			MemRead <= '0';
			MemWrite <= '0';
			RegWrite <= '1';
			MemToReg <= '0'; 
			RType <= '0';
			Shift <= '0';
			JType <= '0';
			structuralStall <= '0';

			
			-- LW 
			when "100011" => 
			sel_ALU_mux1 <= '0';
			sel_ALU_mux2 <= '0';
			MemRead <= '1';
			MemWrite <= '0';
			RegWrite <= '1';
			MemToReg <= '1'; 
			RType <= '0';
			Shift <= '0';
			JType <= '0';
			structuralStall <= '1';
			
			-- SW 
			when "101011" => 
			sel_ALU_mux1 <= '0';
			sel_ALU_mux2 <= '0';
			MemRead <= '0';
			MemWrite <= '1';
			RegWrite <= '0';
			MemToReg <= '1'; 
			RType <= '0';
			Shift <= '0';
			JType <= '0';
			structuralStall <= '0';
			
			-- BEQ
			when "000100" => 
			sel_ALU_mux1 <= '1';
			sel_ALU_mux2 <= '0';
			MemRead <= '0';
			MemWrite <= '0';
			RegWrite <= '0';
			MemToReg <= '0';
			RType <= '0';
			Shift <= '0';
			JType <= '0';
			structuralStall <= '0';
			
			-- BNE
			when "000101" => 
			sel_ALU_mux1 <= '1';
			sel_ALU_mux2 <= '0';
			MemRead <= '0';
			MemWrite <= '0';
			RegWrite <= '0';
			MemToReg <= '0'; 
			RType <= '0';
			Shift <= '0';
			JType <= '0';
			structuralStall <= '0';
			
			-- J (JUMP)
			when "000010" => 
			sel_ALU_mux1 <= '1';
			sel_ALU_mux2 <= '0';
			MemRead <= '0';
			MemWrite <= '0';
			RegWrite <= '0';
			MemToReg <= '0';
			RType <= '0';
			Shift <= '0';
			JType <= '1';	
			structuralStall <= '0';
			
			-- JAL (JUMP AND LINK)  
			when "000011" => 
			sel_ALU_mux1 <= '1';
			sel_ALU_mux2 <= '0';
			MemRead <= '0';
			MemWrite <= '0';
			RegWrite <= '1';
			MemToReg <= '0'; 
			RType <= '0';
			Shift <= '0';
			JType <= '1';
			structuralStall <= '0';
			
			when others =>
			
			end case;
		end if;
	end process;
end behavioral;


