-- Group 7: Anas Deis, Albert Assouad, Barry Chen
-- Date: 16/4/2021

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.definitions.all;

-- Stage 3 : Execute
entity Execute is
	port (
		-- INPUTS
		PC_in : in integer; 
		instruction_in : in INSTRUCTION;
		ra_in : in std_logic_vector(31 downto 0);
		rb_in : in std_logic_vector(31 downto 0);
		immediate_in : in std_logic_vector(31 downto 0);
		
		-- OUTPUTS
		PC_out : out integer;
		instruction_out : out INSTRUCTION;
		branch_out : out std_logic;
		branch_target_out : out std_logic_vector(31 downto 0);
		rb_out : out std_logic_vector(31 downto 0);
		alu_out : out std_logic_vector(63 downto 0)
	);
	end Execute ;

architecture behavioral of Execute is
	signal rs,rt: std_logic_vector(31 downto 0);
	signal alu_output : std_logic_vector(63 downto 0);
begin
	evaluate_inputs_process : process(PC_in, instruction_in, ra_in, rb_in, immediate_in)
	begin
		case instruction_in.name is
			when ADD | SUB | MULT | DIV | SLT | BITWISE_AND | BITWISE_OR | BITWISE_NOR | BITWISE_XOR =>
				rs <= ra_in; 
				rt <= rb_in; 
			when ADDI | SLTI | ANDI | ORI | XORI | LW | SW =>
				rs <= ra_in; 
				rt <= sign_extend(instruction_in.immediate_vect);
			when MFHI | MFLO | LUI =>
				rs <= ra_in;
				rt <= rb_in;
			when SHIFT_LL | SHIFT_RL | SHIFT_RA =>
				rs <= (31 downto 5 => '0') & instruction_in.shamt_vect;
				rt <= rb_in;
			when BEQ | BNE =>
				rs <= std_logic_vector(to_unsigned(PC_in, 32)); 
				rt <= immediate_in;
			when J | JAL =>
				rs <= std_logic_vector(to_unsigned(PC_in,32)); 
				rt <= "000000" & instruction_in.address_vect;
			when JR =>
				rs <= ra_in;
				rt <= rb_in;
			when UNKNOWN =>
				null;
		end case;
	end process; 
	
	compute_process : process(instruction_in.name, rs, rt)
		variable shamt, address : integer := 0; 
		variable j_address : std_logic_vector(31 downto 0);
	begin
		shamt := to_integer(unsigned(rs(4 downto 0)));
		case instruction_in.name is	  
			when ADD | ADDI | LW | SW  =>
				alu_output <= conv_32_to_64(std_logic_vector(signed(rs) + signed(rt))); 
			  
			when SUB =>
				alu_output <= conv_32_to_64(std_logic_vector(signed(rs) - signed(rt))); 

			when MULT =>
				alu_output <= std_logic_vector(signed(rs) * signed(rt)); 
			  
			when DIV =>  
				alu_output(63 downto 32) <= std_logic_vector(signed(rs) rem signed(rt));
				alu_output(31 downto 0) <= std_logic_vector(signed(rs) / signed(rt));

			when SLT | SLTI =>
				if signed(rs) < signed(rt) then 
					alu_output <= x"0000000000000001";
				else 
					alu_output <= x"0000000000000000";
				end if;  
			  
			when BITWISE_AND | ANDI =>
				alu_output <= conv_32_to_64(rs and rt);
			  
			when BITWISE_OR | ORI =>
				alu_output <= conv_32_to_64(rs or rt);
			  
			when BITWISE_NOR =>
				alu_output <= conv_32_to_64(rs nor rt);
			  
			when BITWISE_XOR | XORI =>
				alu_output <= conv_32_to_64(rs xor rt);
			  
			when MFHI | MFLO | LUI =>
				alu_output <= conv_32_to_64(rs);
				
			when SHIFT_LL =>
				alu_output <= conv_32_to_64(std_logic_vector(shift_left(unsigned(rt), shamt))); 

			when SHIFT_RL =>
				alu_output <= conv_32_to_64(std_logic_vector(shift_right(unsigned(rt), shamt)));
			  
			when SHIFT_RA =>
				alu_output <= conv_32_to_64(std_logic_vector(shift_right(signed(rt), shamt)));
			
			when BEQ | BNE =>
				address := to_integer(unsigned(rs)) + 4 + to_integer(shift_left(signed(rt), 2)); -- target + address offset
				alu_output <= conv_32_to_64(std_logic_vector(to_unsigned(address, 32)));
				
			when J | JAL =>
				j_address := rs(31 downto 28) & rt(25 downto 0) & "00";
				alu_output <= conv_32_to_64(j_address);
			  
			when JR =>
				alu_output <= conv_32_to_64(rs);

			when UNKNOWN =>
				null;
		end case;
	end process; 
	
	-- propagate signals
	branch_out <= '1' when (instruction_in.name = BEQ and ra_in = rb_in) or
				  (instruction_in.name = BNE and ra_in /= rb_in) or
				  is_jump(instruction_in) else '0';
	rb_out <= rb_in;
	PC_out <= PC_in;
	alu_out <= alu_output;
	instruction_out <= instruction_in; 
	branch_target_out <= alu_output(31 downto 0);
	
end behavioral ; 