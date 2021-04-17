-- Group 7: Anas Deis, Albert Assouad, Barry Chen
-- Date: 16/4/2021

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;
use work.definitions.all;

-- Stage 2 : Decode
entity Decode is
	port(
		-- INPUTS
		clk : in std_logic;
		reset : in std_logic;  -- reset register file
		write_en_in : in std_logic;	 -- enable writing to register
		
		-- From IF/ID 
		PC_in : in integer;
		instruction_in : in INSTRUCTION;
		
		-- From WB
		wb_instr_in : in INSTRUCTION;
		wb_data_in : in std_logic_vector(63 downto 0);
		
		-- OUTPUTS
		-- Hazard / Branching
		branch_target_out : out std_logic_vector(31 downto 0);
		stall_out : out std_logic;
		
		-- To ID/EX
		PC_out : out integer;
		instruction_out : out INSTRUCTION;
		rs_data : out std_logic_vector(31 downto 0);	   -- data associated with the register index of rs
		rt_data : out std_logic_vector(31 downto 0);	   -- data associated with the register index of rt
		immediate_out : out std_logic_vector(31 downto 0); -- sign extendeded immediate value
		
		-- To Pipeline
		register_file_out : out REGISTER_BLOCK
	);
	end Decode;

architecture behavioral of Decode is
	-- CONSTANTS
	constant void_register : REGISTER_ENTRY := (busy => '0', data => (others => '0'));
	constant void_register_file : REGISTER_BLOCK := (others => void_register);

	-- SIGNALS
	signal lo, hi : REGISTER_ENTRY := void_register; -- hi and lo for multiply and divide
	signal register_file : REGISTER_BLOCK := void_register_file;  -- register file data structure
	signal stall_op, stall_decode : std_logic := '0';
begin
	register_file_out <= register_file;
	PC_out <= PC_in;
	stall_out <= stall_op;
	stall_decode <= '1' when stall_op = '1' else '0';
	instruction_out <=  NO_OP when stall_decode = '1' else 
						instruction_in;

	decode_process : process(clk, reset, instruction_in, wb_instr_in, wb_data_in, register_file, stall_decode)
		variable rs, wb_rs, rt, wb_rt, rd, wb_rd : integer range 0 to NUM_REGISTERS-1;
		variable immediate : std_logic_vector(15 downto 0);
	begin
		-- IF instruction
		rs := instruction_in.rs;
		rt := instruction_in.rt;
		rd := instruction_in.rd;
		immediate := instruction_in.immediate_vect; 
		
		-- WB instruction
		wb_rs := wb_instr_in.rs;
		wb_rt := wb_instr_in.rt;
		wb_rd := wb_instr_in.rd;	

		-- reset register file to 0's
		if reset = '1' then
			for i in register_file' range loop
				register_file(i).busy <= '0';
				register_file(i).data <= (others => '0');
			end loop;

		elsif clk = '0' then
			if stall_decode = '1' then
				rs_data <= (others => '0');
				rt_data <= (others => '0'); 
			else
				case instruction_in.name is 
					when ADD | SUB | BITWISE_AND | BITWISE_OR | BITWISE_NOR | BITWISE_XOR | SLT =>
						rs_data <= register_file(rs).data;
						rt_data <= register_file(rt).data;
						if (rd /= 0) then -- only write to register if not $0
							register_file(rd).busy <= '1';
						end if;

					when ADDI | SLTI =>
						rs_data <= register_file(rs).data;
						immediate_out <= sign_extend(instruction_in.immediate_vect);
						register_file(rt).busy <= '1';
						
					when MULT | DIV =>
						rs_data <= register_file(rs).data;
						rt_data <= register_file(rt).data;
						lo.busy <= '1';
						hi.busy <= '1';

					when ANDI | ORI | XORI =>
						rs_data <= register_file(rs).data;
						immediate_out <= (x"0000" & immediate);
						register_file(rt).busy <= '1';

					when MFHI =>
						rs_data <= hi.data;
						rt_data <= (others => '0');
						register_file(rd).busy <= '1';
						hi.busy <= '1';

					when MFLO =>
						rs_data <= lo.data;
						rt_data <= (others => '0');
						register_file(rd).busy <= '1';
						lo.busy <= '1';

					when LUI =>
						rs_data <=  immediate & (15 downto 0 => '0');
						rt_data <= (others => '0');
						register_file(rt).busy <= '1';

					when SHIFT_LL | SHIFT_RL | SHIFT_RA =>
						rs_data <= (31 downto 5 => '0') & instruction_in.shamt_vect; 
						rt_data <= register_file(rt).data; 
						register_file(rd).busy <= '1';

				    when LW =>
						rs_data <= register_file(rs).data;      
						immediate_out <= sign_extend(immediate);  
						register_file(rt).busy <= '1';

				    when SW =>
						rs_data <= register_file(rs).data; 
						rt_data <= register_file(rt).data; 
						immediate_out <= sign_extend(immediate);

				    when BEQ | BNE =>
						rs_data <= register_file(rs).data;
						rt_data <= register_file(rt).data;
						immediate_out <= sign_extend(immediate);

				    when J | UNKNOWN =>
						null;
				
					when JR =>
						rs_data <= register_file(rs).data;
						
				    when JAL =>
					  register_file(31).data <= std_logic_vector(to_unsigned(PC_in + 4, 32));
				end case;
			end if;

		else 
			-- reset busy bit of instruction from WB
			case wb_instr_in.name is
				-- R format: write into rd (destination register) for R formats we get from WB stage unless it's $0
				when ADD | SUB | BITWISE_AND | BITWISE_OR | BITWISE_NOR | BITWISE_XOR | SLT | SHIFT_LL | SHIFT_RL | SHIFT_RA =>
					if (wb_rd /= 0) then	-- if rd is not $0
						register_file(wb_rd).data <= wb_data_in(31 downto 0);
					end if;
					register_file(wb_rd).busy <= '0';
				
				-- I format: write into rt as destination register
				when ADDI | ANDI | ORI | XORI | SLTI | LW =>
					register_file(wb_rt).data <= wb_data_in(31 downto 0);
					register_file(wb_rt).busy <= '0';
				
				when MULT | DIV =>
					lo.data <= wb_data_in(31 downto 0);
					lo.busy <= '0';
					hi.data <= wb_data_in(63 downto 32);
					hi.busy <= '0';

				when LUI =>
					register_file(wb_rt).data <= wb_data_in(31 downto 0);
					register_file(wb_rt).busy <= '0';
				
				when MFHI =>
					register_file(wb_rd).data <= wb_data_in(31 downto 0);
					register_file(wb_rd).busy <= '0';
					hi.busy <= '0';
				
				when MFLO =>
					register_file(wb_rd).data <= wb_data_in(31 downto 0);
					register_file(wb_rd).busy <= '0';
					lo.busy <= '0';

				when SW | BEQ | BNE | J | JR | JAL | UNKNOWN =>
					null;

			end case;
		end if;
	end process;

	-- set stall depending on whether there is a data hazard
	data_hazard_process : process(instruction_in, wb_instr_in)
		variable rs, rt, rd : REGISTER_ENTRY;
	begin
		-- get values for rs,rt,rd from regsiter file
		rs := register_file(instruction_in.rs);
		rt := register_file(instruction_in.rt);
		rd := register_file(instruction_in.rd);

		case instruction_in.name is
			when ADD | SUB | SLT | BITWISE_AND | BITWISE_OR | BITWISE_NOR | BITWISE_XOR =>
				if rs.busy = '1' or rt.busy = '1' or rd.busy = '1' then
					stall_op <= '1';
				else
					stall_op <= '0';
				end if;

			when ADDI | SLTI | ANDI | ORI | XORI | LW | SW =>
				if rs.busy = '1' or rt.busy = '1' then
					stall_op <= '1';
				else
					stall_op <= '0';
				end if;

			when MULT | DIV =>
				if rs.busy = '1' or rt.busy = '1' or hi.busy = '1' or lo.busy = '1' then
					stall_op <= '1';
				else 
					stall_op <= '0';
				end if;

		    when MFHI =>
				if rd.busy = '1' or hi.busy = '1' then
					stall_op <= '1';
				else
					stall_op <= '0';
				end if;

			when MFLO =>
				if rd.busy = '1' or lo.busy = '1' then
					stall_op <= '1';
				else
					stall_op <= '0';
				end if;

			when LUI =>
				if rt.busy = '1' then
					stall_op <= '1';
				else 
					stall_op <= '0';
				end if;

			when SHIFT_LL | SHIFT_RL | SHIFT_RA =>
				if rd.busy = '1' or rt.busy = '1' then
					stall_op <= '1';
				else
					stall_op <= '0';
				end if;
				
			when BEQ | BNE =>
				if rs.busy = '1' or rt.busy = '1' then
					stall_op <= '1';
				else
					stall_op <= '0';
				end if;
				
			when J | JAL =>
				stall_op <= '0';
				
			when JR =>
				if rs.busy = '1' then
					stall_op <= '1';
				else
					stall_op <= '0';
				end if;
				
			when UNKNOWN  =>
				null;
		end case;
	end process;

	-- compute branch target 
	branch_target_process : process(PC_in, instruction_in, register_file) 
		variable rs, rt : integer range 0 to NUM_REGISTERS-1;
		variable target_int : integer;
		variable immediate : std_logic_vector(15 downto 0);
		variable address : std_logic_vector(25 downto 0);
		variable PC_vect, target : std_logic_vector(31 downto 0);
		
	begin
		rs := instruction_in.rs;
		rt := instruction_in.rt;
		target_int := PC_in + 4;
		immediate := instruction_in.immediate_vect;
		address := instruction_in.address_vect;
		PC_vect := std_logic_vector(to_unsigned(PC_in, 32));

		case instruction_in.name is 
			when J| JAL =>
				target := PC_vect(31 downto 28) & address & "00";
			when JR =>
				target := register_file(rs).data;
			when BEQ | BNE =>
				target_int := PC_in + 4 + to_integer(shift_left(signed(sign_extend(immediate)), 2));  -- target + address offset
			    target := std_logic_vector(to_unsigned(target_int, 32));
			when others =>
			    null;
		end case;
		branch_target_out <= target;
	end process;
	
	-- write to register file
	write_file_process : process(write_en_in)
		file      fptr  : text;
		variable  line  : line;
	begin
		if rising_edge(write_en_in) then
			file_open(fptr, "register_file.txt", WRITE_MODE);
			for i in 0 to NUM_REGISTERS-1 loop
				write(line, register_file(i).data);
				writeline(fptr, line);
			end loop;
			file_close(fptr);
		end if;    
	end process;
end behavioral;