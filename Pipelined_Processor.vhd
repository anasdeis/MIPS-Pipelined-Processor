-- Group 7: Anas Deis, Albert Assouad, Barry Chen
-- Date: 16/4/2021

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.definitions.all;

-- Pipelined_Processor
entity Pipelined_Processor is
	generic(
		ram_size : integer := 8192;
		mem_delay : time := 10 ns;
		clk_period : time := 1 ns
	);
	port(
		clk : in std_logic;
		initialize : in std_logic := '0'; 
		write_file : in std_logic := '0';
		register_file : out REGISTER_BLOCK
	);
	constant bit_width : integer := 32;
end Pipelined_Processor ;

architecture behavioral of Pipelined_Processor is
	-- COMPONENTS DECLARATION
    -- IF
	component Fetch is
		generic(
			ram_size : integer := ram_size;
			bit_width : integer := bit_width
		);
		port (
			clk : in std_logic;
			reset : in std_logic;
			stall_in : in std_logic;  -- hazard stall
			branch_target_in : in integer;  -- combined with a condition test boolean to enable loading the branch target address into the PC
			branch_condition_in : in std_logic; -- condition test boolean
			instruction_out : out INSTRUCTION;
			PC_out : out integer;
			
			-- Memory
			m_addr : out integer range 0 to ram_size-1;
			m_read : out std_logic;
			m_readdata : in std_logic_vector (bit_width-1 downto 0)
		); 
	end component;

    -- IF/ID
	component IF_ID is
		port(
			clk: in std_logic;
			stall_in: in std_logic;
			PC_in: in integer;
			PC_out: out integer;
			instruction_in: in INSTRUCTION;
			instruction_out: out INSTRUCTION
		); 
	end component;

    -- ID
    component Decode is
		port(
			-- INPUTS
			clk : in std_logic;
			reset : in std_logic;       -- reset register file
			write_en_in : in std_logic;	-- enable writing to register	
			
			-- Hazard
			stall_in : in std_logic;  -- stall if instruction from IF uses a register that is currently busy
			
			-- From IF/ID 
			PC_in : in integer;
			instruction_in : in INSTRUCTION;
			
			-- From WB
			wb_instr_in : in INSTRUCTION;
			wb_data_in : in std_logic_vector(63 downto 0);
			
			-- OUTPUTS
			-- Hazard / Branching
			branch_target_out : out std_logic_vector(bit_width-1 downto 0);
			stall_out : out std_logic;
			
			-- To ID/EX
			PC_out : out integer;
			instruction_out : out INSTRUCTION;
			rs_data : out std_logic_vector(bit_width-1 downto 0);	   -- data associated with the register index of rs
			rt_data : out std_logic_vector(bit_width-1 downto 0);	   -- data associated with the register index of rt
			immediate_out : out std_logic_vector(bit_width-1 downto 0); -- sign extendeded immediate value
			
			-- To Pipeline
			register_file_out : out REGISTER_BLOCK
		); 
	end component;

    -- ID/EX
	component ID_EX is
		port(
			clk: in std_logic;
			PC_in: in integer;
			PC_out: out integer;
			instruction_in: in INSTRUCTION;
			instruction_out: out INSTRUCTION;
			ra_in: in std_logic_vector(bit_width-1 downto 0);
			ra_out: out std_logic_vector(bit_width-1 downto 0);
			rb_in: in std_logic_vector(bit_width-1 downto 0);
			rb_out: out std_logic_vector(bit_width-1 downto 0);
			immediate_in: in std_logic_vector(bit_width-1 downto 0);
			immediate_out: out std_logic_vector(bit_width-1 downto 0)
		); 
	end component;
    
    -- Execute
    component Execute is
		port (
			-- INPUTS
			PC_in : in integer; 
			instruction_in : in INSTRUCTION;
			ra_in : in std_logic_vector(bit_width-1 downto 0);
			rb_in : in std_logic_vector(bit_width-1 downto 0);
			immediate_in : in std_logic_vector(bit_width-1 downto 0);
			
			-- OUTPUTS
			PC_out : out integer;
			instruction_out : out INSTRUCTION;
			branch_out : out std_logic;
			branch_target_out : out std_logic_vector(bit_width-1 downto 0);
			rb_out : out std_logic_vector(bit_width-1 downto 0);
			alu_out : out std_logic_vector(63 downto 0)
		); 
	end component;
	
	-- EX/MEM
	component EX_MEM is
		port (
			clk: in std_logic;
			PC_in: in integer;
			PC_out: out integer;
			instruction_in: in INSTRUCTION;
			instruction_out: out INSTRUCTION;
			branch_in: in std_logic;
			branch_out: out std_logic;
			branch_target_in : in std_logic_vector(bit_width-1 downto 0);
			branch_target_out : out std_logic_vector(bit_width-1 downto 0);
			rb_in: in std_logic_vector(bit_width-1 downto 0);
			rb_out: out std_logic_vector(bit_width-1 downto 0);
			alu_in: in std_logic_vector(63 downto 0);
			alu_out: out std_logic_vector(63 downto 0)
		); 
	end component;

    -- Memory
    component Memory is
		generic(
			ram_size : integer := ram_size;
			bit_width : integer := bit_width
		);
		port(
			-- INPUTS
			instruction_in : in INSTRUCTION;
			alu_in : in std_logic_vector(63 downto 0);	
			rb_in : in std_logic_vector(bit_width-1 downto 0);
			
			-- OUTPUTS
			instruction_out : out INSTRUCTION;
			alu_out : out std_logic_vector(63 downto 0);        
			memory_data : out std_logic_vector(bit_width-1 downto 0);
			
			-- Memory
			m_write_data : out std_logic_vector (bit_width-1 downto 0);
			m_addr : out integer range 0 to ram_size-1;   
			m_write : out std_logic;
			m_read : out std_logic;
			m_readdata : in std_logic_vector (bit_width-1 downto 0)
    ); 
	end component;

    -- MEM/WB
    component MEM_WB is
		port(
			clk: in std_logic;
			instruction_in: in INSTRUCTION;
			instruction_out: out INSTRUCTION;
			alu_in: in std_logic_vector(63 downto 0);
			alu_out: out std_logic_vector(63 downto 0);
			mem_in: in std_logic_vector(bit_width-1 downto 0);
			mem_out: out std_logic_vector(bit_width-1 downto 0)
		);
    end component;

	-- Write_Back
    component Write_Back is
		port(
			-- INPUTS
			instruction_in : in instruction;
			memory_data_in : in std_logic_vector(bit_width-1 downto 0);
			alu_in : in std_logic_vector(63 downto 0);
					
			-- OUTPUTS
			instruction_out : out instruction;
			wb_data_out : out std_logic_vector(63 downto 0)
		); 
	end component;
    
	-- Instruction_Memory
    component Instruction_Memory is
		generic(
			ram_size : integer := ram_size;
			bit_width : integer := bit_width;
			mem_delay : time := mem_delay;
			clk_period : time := clk_period
		);
		port (
			clk: in std_logic;
			writedata: in std_logic_vector (bit_width-1 downto 0) := (others => '0');
			address: in integer RANGE 0 TO ram_size-1;
			memwrite: in std_logic := '0';
			memread: in std_logic;
			readdata: out std_logic_vector (bit_width-1 downto 0);
			write_to_mem: in std_logic := '0';
			load_program: in std_logic := '0'
		);
	end component;
    
    -- SIGNALS
    -- Fetch
    signal IF_reset : std_logic;
	signal IF_stall : std_logic;
    signal IF_branch_target : integer;
    signal IF_branch_condition : std_logic;
    signal IF_instruction : INSTRUCTION;
    signal IF_PC : integer;
    signal IF_m_addr : integer;
    signal IF_m_read : std_logic;
    signal IF_m_readdata : std_logic_vector (bit_width-1 downto 0);
    
    -- IF/ID
	signal IF_ID_register_stall: std_logic;
    signal IF_ID_PC_in: integer;
    signal IF_ID_PC_out: integer;
    signal IF_ID_instruction_in: INSTRUCTION;
    signal IF_ID_instruction_out: INSTRUCTION;

    -- Decode
	signal ID_reset : std_logic;
	signal ID_write_en : std_logic;
	signal ID_IR : INSTRUCTION_ARRAY := (others => NO_OP);
	signal ID_stall_in : std_logic;
    signal ID_PC_in : integer;
    signal ID_instruction_in : INSTRUCTION;
    signal ID_wb_instr : INSTRUCTION;
    signal ID_wb_data : std_logic_vector(63 downto 0);
	signal ID_branch_target : std_logic_vector(bit_width-1 downto 0);	
    signal ID_stall_out : std_logic;
	signal ID_PC_out : integer;
	signal ID_instruction_out : INSTRUCTION;
    signal ID_ra : std_logic_vector(bit_width-1 downto 0);
    signal ID_rb : std_logic_vector(bit_width-1 downto 0);
    signal ID_immediate : std_logic_vector(bit_width-1 downto 0);
	signal ID_register_file : REGISTER_BLOCK;

    -- ID/EX
    signal ID_EX_PC_in: integer;
    signal ID_EX_PC_out:  integer;
    signal ID_EX_instruction_in: INSTRUCTION;
    signal ID_EX_instruction_out:  INSTRUCTION;
    signal ID_EX_ra_in: std_logic_vector(bit_width-1 downto 0);
    signal ID_EX_ra_out:  std_logic_vector(bit_width-1 downto 0);
    signal ID_EX_rb_in: std_logic_vector(bit_width-1 downto 0);
    signal ID_EX_rb_out:  std_logic_vector(bit_width-1 downto 0);
	signal ID_EX_immediate_in: std_logic_vector(bit_width-1 downto 0);
    signal ID_EX_immediate_out:  std_logic_vector(bit_width-1 downto 0);

    -- Execute
    signal EX_PC_in : integer; 
    signal EX_instruction_in : INSTRUCTION;
    signal EX_ra : std_logic_vector(bit_width-1 downto 0);
    signal EX_rb : std_logic_vector(bit_width-1 downto 0);
    signal EX_immediate : std_logic_vector(bit_width-1 downto 0);
    signal EX_PC_out : integer;
    signal EX_instruction_out : INSTRUCTION;
    signal EX_branch : std_logic;
	signal EX_branch_target : std_logic_vector(bit_width-1 downto 0);
	signal EX_rb_out : std_logic_vector(bit_width-1 downto 0);
    signal EX_alu : std_logic_vector(63 downto 0);
    
    -- EX/MEM
    signal EX_MEM_PC_in: integer;
    signal EX_MEM_PC_out: integer;
    signal EX_MEM_instruction_in: INSTRUCTION;
    signal EX_MEM_instruction_out: INSTRUCTION;
    signal EX_MEM_branch_in: std_logic;
    signal EX_MEM_branch_out: std_logic;
    signal EX_MEM_alu_in: std_logic_vector(63 downto 0);
    signal EX_MEM_alu_out: std_logic_vector(63 downto 0);
    signal EX_MEM_branch_target_in : std_logic_vector(bit_width-1 downto 0);
    signal EX_MEM_branch_target_out : std_logic_vector(bit_width-1 downto 0);
    signal EX_MEM_rb_in: std_logic_vector(bit_width-1 downto 0);
    signal EX_MEM_rb_out: std_logic_vector(bit_width-1 downto 0);

    -- MEM
    signal MEM_instruction_in : INSTRUCTION;
	signal MEM_alu_in : std_logic_vector(63 downto 0);
	signal MEM_rb : std_logic_vector(bit_width-1 downto 0);
    signal MEM_instruction_out : INSTRUCTION;
    signal MEM_alu_out : std_logic_vector(63 downto 0);
    signal MEM_memory_data : std_logic_vector(bit_width-1 downto 0);
    signal MEM_m_write_data : std_logic_vector (bit_width-1 downto 0);
	signal MEM_m_addr : integer range 0 to ram_size-1;
	signal MEM_m_write : std_logic;
    signal MEM_m_read : std_logic;
    signal MEM_m_readdata : std_logic_vector (bit_width-1 downto 0);        

    -- MEM/WB
    signal MEM_WB_instruction_in: INSTRUCTION;
    signal MEM_WB_instruction_out: INSTRUCTION;
    signal MEM_WB_alu_in: std_logic_vector(63 downto 0);
    signal MEM_WB_alu_out: std_logic_vector(63 downto 0);
    signal MEM_WB_mem_in: std_logic_vector(bit_width-1 downto 0);
    signal MEM_WB_mem_out: std_logic_vector(bit_width-1 downto 0);

    -- WB
	signal WB_instruction_in : INSTRUCTION;
    signal WB_mem_data : std_logic_vector(bit_width-1 downto 0);
    signal WB_alu : std_logic_vector(63 downto 0);
    signal WB_instruction_out : INSTRUCTION;
	signal WB_data : std_logic_vector(63 downto 0);

    -- load/write memory
    signal load_memory : std_logic := '0';
    signal write_memory : std_logic := '0';

	-- control stall
    signal control_stall : std_logic := '0';
	
begin
	-- COMPONENTS MAPPING
    IFS : Fetch
    generic map(
        ram_size => ram_size,
        bit_width => bit_width
    ) 
    port map(
        clk => clk,
        reset => IF_reset,
        stall_in => IF_stall,
        branch_target_in => IF_branch_target,
        branch_condition_in => IF_branch_condition,
        instruction_out => IF_instruction,
        PC_out => IF_PC,
        m_addr => IF_m_addr,
        m_read => IF_m_read,
		m_readdata => IF_m_readdata
    );

    load_mem : Instruction_Memory 
	generic map(
        ram_size => ram_size,
        bit_width => bit_width
    )
    port map(
        clk => clk,
        address => IF_m_addr,
        memread => IF_m_read,
        readdata => IF_m_readdata,
        load_program => load_memory
    );

    IF_ID_REG : IF_ID
	port map(
        clk => clk,
		stall_in => IF_ID_register_stall,
        PC_in => IF_ID_PC_in,
        PC_out => IF_ID_PC_out,
        instruction_in => IF_ID_instruction_in,
        instruction_out => IF_ID_instruction_out
	);

    ID : Decode 
    port map(
        clk => clk,
		reset => ID_reset,
		write_en_in => ID_write_en,
        stall_in => ID_stall_in,
        PC_in => ID_PC_in,
        instruction_in => ID_instruction_in,
        wb_instr_in => ID_wb_instr,
        wb_data_in => ID_wb_data,
		stall_out => ID_stall_out,
        branch_target_out => ID_branch_target,
		PC_out => ID_PC_out,
        instruction_out => ID_instruction_out,
        rs_data => ID_ra,
        rt_data => ID_rb,
        immediate_out => ID_immediate,
		register_file_out => ID_register_file
    );

    ID_EX_REG : ID_EX 
	port map(
        clk => clk,
        PC_in => ID_EX_PC_in,
        PC_out => ID_EX_PC_out,
        instruction_in => ID_EX_instruction_in,
        instruction_out => ID_EX_instruction_out,
        ra_in => ID_EX_ra_in,
        ra_out => ID_EX_ra_out,
        rb_in => ID_EX_rb_in,
        rb_out => ID_EX_rb_out,
		immediate_in => ID_EX_immediate_in,
        immediate_out => ID_EX_immediate_out
    );

    EX : Execute  
	port map(
		PC_in => EX_PC_in,
		instruction_in => EX_instruction_in,
		ra_in => EX_ra,
		rb_in => EX_rb,
		immediate_in => EX_immediate,
		PC_out => EX_PC_out,
		instruction_out => EX_instruction_out,
		branch_out => EX_branch,
		branch_target_out => EX_branch_target,
		rb_out => EX_rb_out,
		alu_out => EX_alu	
    );

    EX_MEM_REG : EX_MEM 
	port map(
        clk => clk,
        PC_in => EX_MEM_PC_in,
        PC_out => EX_MEM_PC_out,
        instruction_in => EX_MEM_instruction_in,
        instruction_out => EX_MEM_instruction_out,
        branch_in => EX_MEM_branch_in,
        branch_out => EX_MEM_branch_out,
        branch_target_in => EX_MEM_branch_target_in,
        branch_target_out => EX_MEM_branch_target_out,
        rb_in => EX_MEM_rb_in,
        rb_out => EX_MEM_rb_out,
        alu_in => EX_MEM_alu_in,
        alu_out => EX_MEM_alu_out
    );

    MEM : Memory 
	port map(
        instruction_in => MEM_instruction_in,
        alu_in => MEM_alu_in,
        rb_in => MEM_rb,
        instruction_out => MEM_instruction_out,
        alu_out => MEM_alu_out,
        memory_data => MEM_memory_data,
        m_write_data => MEM_m_write_data,
        m_addr => MEM_m_addr,
        m_write => MEM_m_write,    
        m_read => MEM_m_read,
        m_readdata => MEM_m_readdata
    );
	
    write_mem : Instruction_Memory 
	generic map(
        ram_size => ram_size,
        bit_width => bit_width
    )
    port map(
        clk => clk,
        writedata => MEM_m_write_data,
        address => MEM_m_addr,
        memwrite => MEM_m_write, 
        memread => MEM_m_read,
        readdata => MEM_m_readdata,
		write_to_mem => write_memory
    );

    MEM_WB_REG : MEM_WB 
	port map (
        clk => clk,
        instruction_in => MEM_WB_instruction_in,
        instruction_out => MEM_WB_instruction_out,
        alu_in => MEM_WB_alu_in,
        alu_out => MEM_WB_alu_out,
        mem_in => MEM_WB_mem_in,
        mem_out => MEM_WB_mem_out
    );

    WB : Write_Back 
	port map(
        instruction_in => WB_instruction_in,
        memory_data_in => WB_mem_data,
        alu_in => WB_alu,
        instruction_out => WB_instruction_out,
        wb_data_out => WB_data
    );
	
	-- CONNECT SIGNALS
	-- IF
	IF_reset <= '1' when initialize = '1' else '0';
    IF_stall <= ID_stall_out or control_stall;
	
	IF_branch_process : process(clk,IF_ID_instruction_out,ID_EX_instruction_out,EX_MEM_instruction_out,
								EX_MEM_branch_target_out,EX_MEM_branch_out,MEM_WB_instruction_out) 							
    variable branch_target : std_logic_vector(bit_width-1 downto 0) := (others => '0');
    begin
		branch_target := EX_MEM_branch_target_out;
		IF_branch_condition <= EX_MEM_branch_out;
        IF_branch_target <= to_integer(signed(branch_target));
    end process;
	
	control_stall_process : process(clk, IF_ID_instruction_out,ID_EX_instruction_out,
									EX_MEM_instruction_out,EX_MEM_branch_out)
    begin
		if  is_branch(IF_ID_instruction_out) or is_jump(IF_ID_instruction_out) or 
			is_branch(ID_EX_instruction_out) or is_jump(ID_EX_instruction_out) or
			((is_branch(EX_MEM_instruction_out) or is_jump(EX_MEM_instruction_out)) and EX_MEM_branch_out = '1')
		then
			control_stall <= '1';
		else			
			control_stall <= '0';
		end if;
    end process;
	
	-- IF/ID
	IF_ID_register_stall <= ID_stall_out;
	IF_ID_PC_in <= IF_PC;
	IF_ID_instruction_in <= NO_OP when initialize = '1' or control_stall = '1' else IF_instruction;
							
	-- ID
	register_file <= ID_register_file;
	ID_reset <= '1' when initialize = '1' else '0';
    ID_PC_in <= IF_ID_PC_out;
    ID_instruction_in <= IF_ID_instruction_out;
	ID_wb_instr <= WB_instruction_out;
    ID_wb_data <= WB_data;
	
	write_file_process : process(write_file)
    begin
        if rising_edge(write_file) then
            write_memory <= '1';
            ID_write_en <= '1';
        else 
            write_memory <= '0';
            ID_write_en <= '0';        
        end if;
    end process ;
	
	-- ID/EX
	ID_EX_PC_in <= ID_PC_out;
    ID_EX_ra_in <= ID_ra;
    ID_EX_rb_in <= ID_rb;
    ID_EX_instruction_in <= ID_instruction_out;
    ID_EX_immediate_in <= ID_immediate;

	-- EX
    EX_PC_in <= ID_EX_PC_out;
    EX_instruction_in <= ID_EX_instruction_out;
    EX_ra <= ID_EX_ra_out;
    EX_rb <= ID_EX_rb_out;
    EX_immediate <= ID_EX_immediate_out;
    
	-- EX/MEM
	EX_MEM_PC_in <= EX_PC_out;
	EX_MEM_instruction_in <= EX_instruction_out;
	EX_MEM_branch_in <= EX_branch;
    EX_MEM_alu_in <= EX_alu;
	EX_MEM_branch_target_in <= EX_branch_target;
    EX_MEM_rb_in <= EX_rb; 
	
	-- MEM
    MEM_instruction_in <= EX_MEM_instruction_out;
	MEM_alu_in <= EX_MEM_alu_out;
    MEM_rb <= EX_MEM_rb_out;
	
	-- MEM/WB
	MEM_WB_instruction_in <= MEM_instruction_out;
    MEM_WB_alu_in <= MEM_alu_out;
    MEM_WB_mem_in <= MEM_memory_data;
    
	-- WB
    WB_instruction_in <= MEM_WB_instruction_out;
    WB_mem_data <= MEM_WB_mem_out;
	WB_alu <= MEM_WB_alu_out;
    
	-- INITIALIZE
    init_process : process(initialize)
    begin
        if rising_edge(initialize) then
            load_memory <= '1';
        else 
            load_memory <= '0';
        end if;
    end process ; 
end behavioral;