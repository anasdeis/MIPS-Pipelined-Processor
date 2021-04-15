-- Group 7: Anas Deis, Albert Assouad, Barry Chen
-- Date: 16/4/2021

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio;

package definitions is

	-- CONSTANTS
	constant NUM_REGISTERS : integer := 32;	-- MIPS has 32 registers
    
	-- instruction set opcode/funct
    -- R-type opcode:
    constant RTYPE_OP : std_logic_vector(5 downto 0) := "000000";

    -- R-Type funct:
    constant ADD_FN : std_logic_vector(5 downto 0)   := "100000"; 
    constant SUB_FN : std_logic_vector(5 downto 0)   := "100010";
    constant MULT_FN : std_logic_vector(5 downto 0)  := "011000"; 
    constant DIV_FN : std_logic_vector(5 downto 0)   := "011010"; 
    constant SLT_FN : std_logic_vector(5 downto 0)   := "101010";
    constant AND_FN : std_logic_vector(5 downto 0)   := "100100"; 
    constant OR_FN : std_logic_vector(5 downto 0)    := "100101"; 
    constant NOR_FN : std_logic_vector(5 downto 0)   := "100111"; 
    constant XOR_FN : std_logic_vector(5 downto 0)   := "100110"; 
    constant MFHI_FN : std_logic_vector(5 downto 0)  := "010000"; 
    constant MFLO_FN : std_logic_vector(5 downto 0)  := "010010"; 
    constant SLL_FN : std_logic_vector(5 downto 0)   := "000000";
    constant SRL_FN : std_logic_vector(5 downto 0)   := "000010";
    constant SRA_FN : std_logic_vector(5 downto 0)   := "000011";
    constant JR_FN : std_logic_vector(5 downto 0)    := "001000"; 
	
	-- I-type opcode:
    constant ADDI_OP : std_logic_vector(5 downto 0)  := "001000";
	constant SLTI_OP : std_logic_vector(5 downto 0)  := "001010"; 
    constant ANDI_OP : std_logic_vector(5 downto 0)  := "001100"; 	
	constant ORI_OP : std_logic_vector(5 downto 0)   := "001101"; 
	constant XORI_OP : std_logic_vector(5 downto 0)  := "001110"; 
    constant LUI_OP : std_logic_vector(5 downto 0)   := "001111"; 
    constant LW_OP : std_logic_vector(5 downto 0)    := "100011";
    constant SW_OP : std_logic_vector(5 downto 0)    := "101011"; 
    constant BEQ_OP : std_logic_vector(5 downto 0)   := "000100"; 
    constant BNE_OP : std_logic_vector(5 downto 0)   := "000101";

    -- J-type opcode: 
	constant J_OP : std_logic_vector(5 downto 0)     := "000010";
    constant JAL_OP : std_logic_vector(5 downto 0)   := "000011";
	
	-- TYPES
	-- Instructions
    type INSTRUCTION_FORMAT is (R_TYPE, J_TYPE, I_TYPE, UNKNOWN);
    type INSTRUCTION_SET is (
        ADD,SUB,ADDI,MULT,DIV,SLT,SLTI,  -- Arithmetic
        BITWISE_AND,BITWISE_OR,BITWISE_NOR,BITWISE_XOR,ANDI,ORI,XORI, -- Logical
        MFHI,MFLO,LUI, 					 -- Transfer
        SHIFT_LL,SHIFT_RL,SHIFT_RA, 	 -- Shift
        LW,SW,BEQ,BNE,J,JR,JAL, 		 -- Memory
		UNKNOWN  						 -- Other/Unknown
    );
    type INSTRUCTION is
    record
        format : INSTRUCTION_FORMAT;
		name : INSTRUCTION_SET;
        rs : integer range 0 to 31;
		rs_vect : std_logic_vector(4 downto 0);
        rt : integer range 0 to 31;
		rt_vect : std_logic_vector(4 downto 0);
        rd : integer range 0 to 31;
		rd_vect : std_logic_vector(4 downto 0);
        shamt : integer range 0 to 31;
		shamt_vect : std_logic_vector(4 downto 0);
        immediate : integer;
		immediate_vect : std_logic_vector(15 downto 0);
        address : integer;   
        address_vect : std_logic_vector(25 downto 0);
        vector : std_logic_vector(31 downto 0);
    end record;
    type INSTRUCTION_ARRAY is ARRAY (1 downto 0) of INSTRUCTION;
	
	constant NO_OP : INSTRUCTION;
	
	-- Registers
    type REGISTER_ENTRY is
    record
        busy : std_logic;
        data : std_logic_vector(31 downto 0);
    end record;
    type REGISTER_BLOCK is array (NUM_REGISTERS-1 downto 0) of REGISTER_ENTRY; -- register block data structure

	-- FUNCTIONS 
	-- get instruction name
    function get_name(instruction : std_logic_vector(31 downto 0))
        return INSTRUCTION_SET;
		
	-- get instruction format (R-Type, J-Type, I-Type)
    function get_format(instruction : std_logic_vector(31 downto 0))
        return INSTRUCTION_FORMAT;

	-- create instruction object from the instruction vector
    function create_instruction(instruction_vect : std_logic_vector(31 downto 0))
        return INSTRUCTION;
	
	-- create R-Type instruction
    function create_instruction(opcode : std_logic_vector (5 downto 0); rs: integer; rt : integer; rd : integer; shamt : integer; funct : std_logic_vector(5 downto 0))
        return INSTRUCTION;
		
	-- create I-Type instruction
    function create_instruction(opcode : std_logic_vector (5 downto 0); rs: integer; rt : integer; immediate : integer)
        return INSTRUCTION;

	-- create J-Type instruction
    function create_instruction(opcode : std_logic_vector(5 downto 0); address : integer)
        return INSTRUCTION;

	-- check to see if the instruction is a branch instruction
    function is_branch(instruction : INSTRUCTION) 
		return boolean;
		
	-- check to see if the instruction is a jump instruction
    function is_jump(instruction : INSTRUCTION) 
		return boolean;
	
	-- sign extend immediate value
    function sign_extend(immediate : std_logic_vector(15 downto 0)) 
		return std_logic_vector;
		
	-- convert 32 bit to 64 bit
	function conv_32_to_64(vect_32 : std_logic_vector(31 downto 0))
		return std_logic_vector;

end definitions;

package body definitions is 

    function get_name(instruction : std_logic_vector(31 downto 0))
        return INSTRUCTION_SET is
        variable opcode : std_logic_vector(5 downto 0) := instruction(31 downto 26);
        variable funct : std_logic_vector(5 downto 0) := instruction(5 downto 0);
    begin
		case opcode is
			when RTYPE_OP => 
				case funct is
				   when ADD_FN  => return ADD;
				   when SUB_FN  => return SUB;
				   when MULT_FN => return MULT;
				   when DIV_FN  => return DIV;
				   when SLT_FN  => return SLT;
				   when AND_FN  => return BITWISE_AND;
				   when OR_FN   => return BITWISE_OR;
				   when NOR_FN  => return BITWISE_NOR;
				   when XOR_FN  => return BITWISE_XOR;
				   when MFHI_FN => return MFHI;
				   when MFLO_FN => return MFLO;
				   when SLL_FN  => return SHIFT_LL;
				   when SRL_FN  => return SHIFT_RL;
				   when SRA_FN  => return SHIFT_RA;
				   when JR_FN   => return JR;
				   when others  => return UNKNOWN;
				end case;
			when ADDI_OP    =>  return ADDI;
			when SLTI_OP    =>  return SLTI;
			when ANDI_OP    =>  return ANDI;
			when ORI_OP     =>  return ORI;
			when XORI_OP    =>  return XORI;
			when LUI_OP     =>  return LUI;
			when LW_op      =>  return LW;
			when SW_OP      =>  return SW;
			when BEQ_OP     =>  return BEQ;
			when BNE_OP     =>  return BNE;
			when J_OP       =>  return J;
			when JAL_OP     =>  return JAL;
			when others     =>  return UNKNOWN;
		end case;
    end get_name;
	
    function get_format(instruction : std_logic_vector(31 downto 0))
        return INSTRUCTION_FORMAT is
        variable opcode : std_logic_vector(5 downto 0) := instruction(31 downto 26);
    begin
		case opcode is
			when RTYPE_OP => 
				return R_TYPE;
			when ADDI_OP | SLTI_OP | ANDI_OP | ORI_OP | XORI_OP | LUI_OP | LW_OP | SW_OP | BEQ_OP | BNE_OP =>
				return I_TYPE;
			when J_OP | JAL_OP =>
				return J_TYPE;
			when others =>
				return UNKNOWN;
		end case;
    end get_format;

    function create_instruction(instruction_vect : std_logic_vector(31 downto 0))
        return INSTRUCTION is
        variable inst : INSTRUCTION;
    begin
        inst.format := get_format(instruction_vect);  -- set instruction format
		inst.name := get_name(instruction_vect);  -- set instruction name

        -- set all instruction fields in vector and integer formats
        inst.rs_vect := instruction_vect(25 downto 21);
		inst.rs := to_integer(unsigned(inst.rs_vect));
        inst.rt_vect := instruction_vect(20 downto 16);
		inst.rt := to_integer(unsigned(inst.rt_vect));
        inst.rd_vect := instruction_vect(15 downto 11);
		inst.rd := to_integer(unsigned(inst.rd_vect));
        inst.shamt_vect := instruction_vect(10 downto 6);
		inst.shamt := to_integer(unsigned(inst.shamt_vect));
        inst.immediate_vect := instruction_vect(15 downto 0);
		inst.immediate := to_integer(unsigned(inst.immediate_vect));
        inst.address_vect := instruction_vect(25 downto 0);
        inst.address := to_integer(unsigned(inst.address_vect));
        inst.vector := instruction_vect;
		
        return inst;
    end create_instruction;

    function create_instruction(opcode : std_logic_vector(5 downto 0); rs: integer; rt : integer; rd : integer; shamt : integer; funct : std_logic_vector(5 downto 0))
        return INSTRUCTION is
        variable instruction : INSTRUCTION;
		variable instruction_vect : std_logic_vector(31 downto 0);
    begin	
        instruction_vect := opcode(5 downto 0) & std_logic_vector(to_unsigned(rs, 5)) & std_logic_vector(to_unsigned(rt, 5)) 
		& std_logic_vector(to_unsigned(rd, 5)) & std_logic_vector(to_unsigned(shamt, 5)) & funct(5 downto 0);
        instruction := create_instruction(instruction_vect);	
        return instruction;
    end create_instruction;

    function create_instruction(opcode : std_logic_vector(5 downto 0); rs: integer; rt : integer; immediate : integer)
        return INSTRUCTION is
        variable instruction : INSTRUCTION;
		variable instruction_vect : std_logic_vector(31 downto 0);
    begin 
        instruction_vect := opcode(5 downto 0) & std_logic_vector(to_unsigned(rs, 5)) 
		& std_logic_vector(to_unsigned(rt, 5)) & std_logic_vector(to_unsigned(immediate, 16));
        instruction := create_instruction(instruction_vect);
        return instruction;
    end create_instruction;

    function create_instruction(opcode : std_logic_vector(5 downto 0); address : integer)
        return INSTRUCTION is
        variable instruction : INSTRUCTION;
        variable instruction_vect : std_logic_vector(31 downto 0);
    begin
        instruction_vect := opcode(5 downto 0) & std_logic_vector(to_unsigned(address, 26));
        instruction := create_instruction(instruction_vect);
        return instruction;
    end create_instruction;
	
	constant NO_OP : INSTRUCTION := create_instruction(RTYPE_OP, 0,0,0,0, ADD_FN);
   
    function is_branch(instruction : INSTRUCTION) 
		return boolean is
    begin
        case instruction.name is
            when BEQ | BNE =>
                return true;
            when others => 
                return false;
        end case;
    end is_branch;
	
    function is_jump(instruction : INSTRUCTION) 
		return boolean is
    begin
        case instruction.name is
            when J | JR | JAL =>
                return true;
            when others => 
                return false;
        end case;
    end is_jump;
	
   	function sign_extend(immediate : std_logic_vector(15 downto 0))
		return std_logic_vector is
	begin
		if(immediate(15) = '1') then
			return x"FFFF" & immediate;
		else
			return x"0000" & immediate;
		end if;
	end sign_extend;
	
	-- extend 32 bit to 64 bit
	function conv_32_to_64(vect_32 : std_logic_vector(31 downto 0))
		return std_logic_vector is
	begin
		return x"00000000" & vect_32;
	end conv_32_to_64;
	
end definitions;