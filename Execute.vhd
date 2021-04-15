-- Group 7: Anas Deis, Albert Assouad, Barry Chen
-- Date: 16/4/2021

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.INSTRUCTION_TOOLS.all;

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
		case instruction_in.INSTRUCTION_TYPE is
			when ADD | SUBTRACT | MULTIPLY | DIVIDE | SET_LESS_THAN | BITWISE_AND | BITWISE_OR | BITWISE_NOR | BITWISE_XOR =>
				rs <= ra_in; 
				rt <= rb_in; 
			when ADD_IMMEDIATE | SET_LESS_THAN_IMMEDIATE | BITWISE_AND_IMMEDIATE | BITWISE_OR_IMMEDIATE | BITWISE_XOR_IMMEDIATE | LOAD_WORD | STORE_WORD =>
				rs <= ra_in; 
				rt <= signExtend(instruction_in.immediate_vect);
			when MOVE_FROM_HI | MOVE_FROM_LOW | LOAD_UPPER_IMMEDIATE =>
				rs <= ra_in;
				rt <= rb_in;
			when SHIFT_LEFT_LOGICAL | SHIFT_RIGHT_LOGICAL | SHIFT_RIGHT_ARITHMETIC =>
				rs <= (31 downto 5 => '0') & instruction_in.shamt_vect;
				rt <= rb_in;
			when BRANCH_IF_EQUAL | BRANCH_IF_NOT_EQUAL =>
				rs <= std_logic_vector(to_unsigned(PC_in, 32)); 
				rt <= immediate_in;
			when JUMP | JUMP_AND_LINK =>
				rs <= std_logic_vector(to_unsigned(PC_in,32)); 
				rt <= "000000" & instruction_in.address_vect;
			when JUMP_TO_REGISTER =>
				rs <= ra_in;
				rt <= rb_in;
			when UNKNOWN =>
				null;
		end case;
	end process; 
	
	compute_process : process(instruction_in.instruction_type, rs, rt)
		variable shamt, address : integer := 0; 
		variable j_address : std_logic_vector(31 downto 0);
	
	begin

		shamt := to_integer(unsigned(rs(4 downto 0)));

		case instruction_in.INSTRUCTION_TYPE is
		  
			when ADD | ADD_IMMEDIATE | LOAD_WORD | STORE_WORD  =>
				alu_output <= conv_32_to_64(std_logic_vector(signed(rs) + signed(rt))); 
			  
			when SUBTRACT =>
				alu_output <= conv_32_to_64(std_logic_vector(signed(rs) - signed(rt))); 

			when MULTIPLY =>
				alu_output <= std_logic_vector(signed(rs) * signed(rt)); 
			  
			when DIVIDE =>  
				alu_output(63 downto 32) <= std_logic_vector(signed(rs) rem signed(rt));
				alu_output(31 downto 0) <= std_logic_vector(signed(rs) / signed(rt));

			when SET_LESS_THAN | SET_LESS_THAN_IMMEDIATE =>
				if signed(rs) < signed(rt) then 
					alu_output <= x"0000000000000001";
				else 
					alu_output <= x"0000000000000000";
				end if;  
			  
			when BITWISE_AND | BITWISE_AND_IMMEDIATE=>
				alu_output <= conv_32_to_64(rs and rt);
			  
			when BITWISE_OR | BITWISE_OR_IMMEDIATE =>
				alu_output <= conv_32_to_64(rs or rt);
			  
			when BITWISE_NOR =>
				alu_output <= conv_32_to_64(rs nor rt);
			  
			when BITWISE_XOR | BITWISE_XOR_IMMEDIATE =>
				alu_output <= conv_32_to_64(rs xor rt);
			  
			when MOVE_FROM_HI | MOVE_FROM_LOW | LOAD_UPPER_IMMEDIATE =>
				alu_output <= conv_32_to_64(rs);
				
			when SHIFT_LEFT_LOGICAL =>
				alu_output <= conv_32_to_64(std_logic_vector(shift_left(unsigned(rt), shamt))); 

			when SHIFT_RIGHT_LOGICAL =>
				alu_output <= conv_32_to_64(std_logic_vector(shift_right(unsigned(rt), shamt)));
			  
			when SHIFT_RIGHT_ARITHMETIC =>
				alu_output <= conv_32_to_64(std_logic_vector(shift_right(signed(rt), shamt)));
			
			when BRANCH_IF_EQUAL | BRANCH_IF_NOT_EQUAL =>
				address := to_integer(unsigned(rs)) + 4 + to_integer(shift_left(signed(rt), 2)); -- target + address offset
				alu_output <= conv_32_to_64(std_logic_vector(to_unsigned(address, 32)));
				
			when JUMP | JUMP_AND_LINK =>
				j_address := rs(31 downto 28) & rt(25 downto 0) & "00";
				alu_output <= conv_32_to_64(j_address);
			  
			when JUMP_TO_REGISTER =>
				alu_output <= conv_32_to_64(rs);

			when UNKNOWN =>
				null;
		end case;
	end process; 
	
	-- propagate signals
	branch_out <=	'1' when instruction_in.INSTRUCTION_TYPE = BRANCH_IF_EQUAL and ra_in = rb_in else
					'1' when instruction_in.INSTRUCTION_TYPE = BRANCH_IF_NOT_EQUAL and ra_in /= rb_in else
					'1' when instruction_in.INSTRUCTION_TYPE = JUMP or instruction_in.INSTRUCTION_TYPE = JUMP_TO_REGISTER
						or instruction_in.INSTRUCTION_TYPE = JUMP_AND_LINK else
					'0';

	rb_out <= rb_in;
	PC_out <= PC_in;
	alu_out <= alu_output;
	instruction_out <= instruction_in; 
	branch_target_out <= alu_output(31 downto 0);
	
end behavioral ; 