-- Group 7: Anas Deis, Albert Assouad, Barry Chen
-- Date: 16/4/2021

library ieee;
use ieee.std_logic_1164.all ;
use ieee.numeric_std.all ;
use ieee.std_logic_textio.all;
use std.textio.all;
use work.definitions.all;

entity Pipelined_Processor_tb is
end Pipelined_Processor_tb ; 

architecture behavioral of Pipelined_Processor_tb is
    component Pipelined_Processor is
        generic(
			ram_size : integer := 8192;
			bit_width : integer := 32;
			mem_delay : time := 10 ns;
			clk_period : time := 1 ns
        );
        port(
            clk : in std_logic;
            initialize : in std_logic; 
            write_file : in std_logic;
					
			-- Testing
			register_file : out REGISTER_BLOCK;
			IF_branch_condition_out : out std_logic;
			IF_branch_target_out : out integer;
			IF_instruction_out : out INSTRUCTION;
			IF_PC_out : out integer;
			IF_stall_out : out std_logic;
			control_stall_out : out std_logic;
			ID_instruction_in_out : out INSTRUCTION;
			ID_instruction_out_out : out INSTRUCTION;
			ID_PC_in_out : out integer;
			ID_ra_out : out std_logic_vector(bit_width-1 downto 0);
			ID_rb_out : out std_logic_vector(bit_width-1 downto 0);
			ID_stall_in_out : out std_logic;
			ID_stall_out_out : out std_logic;
			ID_wb_data_out : out std_logic_vector(63 downto 0);
			ID_wb_instr_out : out INSTRUCTION;
			EX_alu_out : out std_logic_vector(63 downto 0);
			EX_branch_out : out std_logic;
			MEM_m_addr_out : out integer range 0 to ram_size-1;
			MEM_m_write_data_out : out std_logic_vector(bit_width-1 downto 0);
			MEM_memory_data_out : out std_logic_vector(bit_width-1 downto 0)
        );
    end component;
	
	constant bit_width : integer := 32;
	constant ram_size : integer := 8192;
	constant clock_period : time := 1 ns;
	
	signal clk : std_logic := '0';
	signal initialize : std_logic := '0';
    signal write_file : std_logic := '0';
	signal register_file : REGISTER_BLOCK;
	signal IF_branch_condition : std_logic;
	signal IF_branch_target : integer;
	signal IF_instruction : INSTRUCTION;
	signal IF_PC : integer;
	signal IF_stall :  std_logic;
	signal control_stall : std_logic;
	signal ID_instruction_in : INSTRUCTION;
	signal ID_instruction_out : INSTRUCTION;
	signal ID_PC_in : integer;
	signal ID_ra : std_logic_vector(bit_width-1 downto 0);
	signal ID_rb : std_logic_vector(bit_width-1 downto 0);
	signal ID_stall_in : std_logic;
	signal ID_stall_out : std_logic;
	signal ID_wb_data : std_logic_vector(63 downto 0);
	signal ID_wb_instr : INSTRUCTION;
	signal EX_alu : std_logic_vector(63 downto 0);
	signal EX_branch : std_logic;
	signal MEM_m_addr : integer range 0 to ram_size-1;
	signal MEM_m_write_data : std_logic_vector(bit_width-1 downto 0);
	signal MEM_memory_data : std_logic_vector(bit_width-1 downto 0);
begin
	dut : Pipelined_Processor 
	port map(
		clk => clk,
		initialize => initialize,
		write_file => write_file,
		register_file => register_file,
		IF_branch_condition_out => IF_branch_condition,
		IF_branch_target_out => IF_branch_target,
		IF_instruction_out => IF_instruction,
		IF_PC_out => IF_PC,
		IF_stall_out => IF_stall,
		control_stall_out => control_stall,
		ID_instruction_in_out => ID_instruction_in,
		ID_instruction_out_out => ID_instruction_out,
		ID_PC_in_out => ID_PC_in,
		ID_ra_out => ID_ra,
		ID_rb_out => ID_rb,
		ID_stall_in_out => ID_stall_in,
		ID_stall_out_out => ID_stall_out,
		ID_wb_data_out => ID_wb_data,
		ID_wb_instr_out => ID_wb_instr,
		EX_alu_out => EX_alu,
		EX_branch_out => EX_branch,
		MEM_m_addr_out => MEM_m_addr,
		MEM_m_write_data_out => MEM_m_write_data,
		MEM_memory_data_out => MEM_memory_data
	);

	clk_process : process
	begin
		clk <= '0';
		wait for clock_period/2;
		clk <= '1';
		wait for clock_period/2;
	end process ;

	test_process : process
	begin

		initialize <= '1';
		wait for clock_period;
		initialize <= '0';
		wait for clock_period;
		
		wait for 9900 ns;
		
		write_file <= '1';
		wait for clock_period;
		write_file <= '0';
		wait for clock_period;
		
		report "Stored output in 'register_file.txt' and 'memory.txt'";
		
		wait;

	end process;
end behavioral;