-- Group 7: Anas Deis, Albert Assouad, Barry Chen
-- Date: 16/4/2021

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.INSTRUCTION_TOOLS.all;

-- Pipelined_Processor
entity Pipelined_Processor is
	generic(
		ram_size : integer := 8192;
		mem_delay : time := 0.1 ns;
		clock_period : time := 1 ns;
		predictor_bit_width : integer := 2;
		use_branch_prediction : boolean := false;
		use_static_taken : boolean := false;
		use_static_not_taken : boolean := false
	);
	port (
		clock : in std_logic;
		initialize : in std_logic; -- signals to load Instruciton and Data Memories. Should be held at '1' for at least a few clock cycles.
		dump : in std_logic; -- similar to above but for dump instead of load.
		IF_ID_instruction : out INSTRUCTION; 
		ID_EX_instruction : out INSTRUCTION; 
		EX_MEM_instruction : out INSTRUCTION;
		MEM_WB_instruction : out INSTRUCTION;
		WB_instruction : out INSTRUCTION;
		WB_data : out std_logic_vector(63 downto 0);
		fetch_PC : out integer;
		decode_register_file : out REGISTER_BLOCK;
		ALU_out : out std_logic_vector(63 downto 0);
		input_instruction : in INSTRUCTION;
		override_input_instruction : in std_logic
	);
	constant bit_width : integer := 32;
end Pipelined_Processor ;


architecture behavioral of Pipelined_Processor is
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
			m_readdata : in std_logic_vector (bit_width-1 downto 0);
			m_waitrequest : in std_logic
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
			reset : in std_logic;  -- reset register file
			
			-- Hazard / Branching
			IR_in : in INSTRUCTION_ARRAY;  -- Instruction Register holds the instruction currently being decoded.
			stall_in : in std_logic;  -- stall if instruction from IF uses a register that is currently busy
			
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
			
			-- Write registry_file 	
			write_en_in : in std_logic;				 -- enable writing to register
			register_file_out : out REGISTER_BLOCK   -- output register data structure for pipeline to observe changes while testing	
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
			ra_in: in std_logic_vector(31 downto 0);
			ra_out: out std_logic_vector(31 downto 0);
			rb_in: in std_logic_vector(31 downto 0);
			rb_out: out std_logic_vector(31 downto 0);
			immediate_in: in std_logic_vector(31 downto 0);
			immediate_out: out std_logic_vector(31 downto 0)
		); 
	end component;
    
    -- Execute
    component Execute is
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
	end component;
	
	-- EX/MEM
	component EX_MEM is
		port (
			clk: in std_logic;
			PC_in: in INTEGER;
			PC_out: out integer;
			instruction_in: in INSTRUCTION;
			instruction_out: out INSTRUCTION;
			branch_in: in std_logic;
			branch_out: out std_logic;
			branch_target_in : in std_logic_vector(31 downto 0);
			branch_target_out : out std_logic_vector(31 downto 0);
			rb_in: in std_logic_vector(31 downto 0);
			rb_out: out std_logic_vector(31 downto 0);
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
			m_readdata : in std_logic_vector (bit_width-1 downto 0);
			m_waitrequest : in std_logic
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
			mem_in: in std_logic_vector(31 downto 0);
			mem_out: out std_logic_vector(31 downto 0)
		);
    end component;

	-- Write_Back
    component Write_Back is
		port(
			-- INPUTS
			instruction_in : in instruction;
			memory_data_in : in std_logic_vector(31 downto 0);
			alu_in : in std_logic_vector(63 downto 0);
					
			-- OUTPUTS
			instruction_out : out instruction;
			wb_data_out : out std_logic_vector(63 downto 0)
		); end component;
    
	-- Instruction_Memory
    component Instruction_Memory IS
		generic(
			ram_size : INTEGER := ram_size;
			bit_width : INTEGER := bit_width;
			mem_delay : time := mem_delay;
			clock_period : time := clock_period
		);
		port (
			clock: IN STD_LOGIC;
			writedata: IN STD_LOGIC_VECTOR (bit_width-1 DOWNTO 0);
			address: IN INTEGER RANGE 0 TO ram_size-1;
			memwrite: IN STD_LOGIC;
			memread: IN STD_LOGIC;
			readdata: OUT STD_LOGIC_VECTOR (bit_width-1 DOWNTO 0);
			waitrequest: OUT STD_LOGIC;
			write_to_mem: IN STD_LOGIC;
			load_program: IN STD_LOGIC
		);
	end component;
	
	-- Branch_Predictor
    component Branch_Predictor IS
		generic(
			bit_width : integer := 2;
			counter : integer := 8
		);
		port(
			-- INPUTS
			clk : in std_logic;
			instruction_in : in INSTRUCTION;
			branch_taken_in : in std_logic;  -- update to branch taken
			branch_target_in : in std_logic_vector(31 downto 0); -- update branch target
			branch_target_next_in : in std_logic_vector(31 downto 0); -- evaluate next branch target
			
			-- OUTPUTS
			branch_prediction_out : out std_logic
		);
    end component;
    
    -- SIGNALS
    --Fetch
    signal fetch_stage_reset : std_logic;
    signal fetch_stage_branch_target : integer;
    signal fetch_stage_branch_condition : std_logic;
    signal fetch_stage_stall : std_logic;
    signal fetch_stage_instruction_out : Instruction;
    signal fetch_stage_PC : integer;
    signal fetch_stage_m_addr : integer;
    signal fetch_stage_m_read : std_logic;
    signal fetch_stage_m_readdata : std_logic_vector (bit_width-1 downto 0);
    signal fetch_stage_m_waitrequest : std_logic; -- unused until the Avalon Interface is added.
    signal fetch_stage_m_write_data : std_logic_vector(bit_width-1 downto 0); -- unused;
    signal fetch_stage_m_write : std_logic; -- unused;
    
    --Fetch Decode Register
    signal IF_ID_register_pc_in: INTEGER;
    signal IF_ID_register_pc_out:  INTEGER;
    signal IF_ID_register_instruction_in: INSTRUCTION;
    signal IF_ID_register_instruction_out:  INSTRUCTION;
    signal IF_ID_register_stall: STD_LOGIC;

    --Decode
    signal decode_stage_PC : integer;
    signal decode_stage_instruction_in : INSTRUCTION;
    signal decode_stage_write_back_instruction : INSTRUCTION;
    signal decode_stage_write_back_data : std_logic_vector(63 downto 0);
    signal decode_stage_val_a :  std_logic_vector(31 downto 0);
    signal decode_stage_val_b :  std_logic_vector(31 downto 0);
    signal decode_stage_i_sign_extended :  std_logic_vector(31 downto 0);
    signal decode_stage_PC_out :  integer;
    signal decode_stage_instruction_out :  INSTRUCTION;
    signal decode_stage_register_file_out :  REGISTER_BLOCK;
    signal decode_stage_write_register_file : std_logic;
    signal decode_stage_reset_register_file : std_logic;
    signal decode_stage_stall_in : std_logic;
    signal decode_stage_stall_out :  std_logic;
    signal decode_stage_branch_target_out : std_logic_vector(31 downto 0); 
    signal decode_stage_release_instructions : INSTRUCTION_ARRAY := (others => NO_OP_INSTRUCTION);

    --Decode Execute Register 
    signal ID_EX_register_pc_in: INTEGER;
    signal ID_EX_register_pc_out:  INTEGER;
    signal ID_EX_register_instruction_in: INSTRUCTION;
    signal ID_EX_register_instruction_out:  INSTRUCTION;
    signal ID_EX_register_sign_extend_imm_in: STD_LOGIC_VECTOR(31 DOWNTO 0);
    signal ID_EX_register_sign_extend_imm_out:  STD_LOGIC_VECTOR(31 DOWNTO 0);
    signal ID_EX_register_a_in: STD_LOGIC_VECTOR(31 DOWNTO 0);
    signal ID_EX_register_a_out:  STD_LOGIC_VECTOR(31 DOWNTO 0);
    signal ID_EX_register_b_in: STD_LOGIC_VECTOR(31 DOWNTO 0);
    signal ID_EX_register_b_out:  STD_LOGIC_VECTOR(31 DOWNTO 0);


    --Execute
    signal execute_stage_instruction_in : Instruction;
    signal execute_stage_val_a : std_logic_vector(31 downto 0);
    signal execute_stage_val_b : std_logic_vector(31 downto 0);
    signal execute_stage_imm_sign_extended : std_logic_vector(31 downto 0);
    signal execute_stage_PC : integer; 
    signal execute_stage_instruction_out : Instruction;
    signal execute_stage_branch : std_logic;
    signal execute_stage_ALU_result : std_logic_vector(63 downto 0);
    signal execute_stage_branch_target_out : std_logic_vector(31 downto 0);
    signal execute_stage_val_b_out : std_logic_vector(31 downto 0);
    signal execute_stage_PC_out : integer;

    --Execute Memory register
    signal EX_MEM_register_pc_in: INTEGER;
    signal EX_MEM_register_pc_out: INTEGER;
    signal EX_MEM_register_instruction_in: INSTRUCTION;
    signal EX_MEM_register_instruction_out: INSTRUCTION;
    signal EX_MEM_register_does_branch_in: STD_LOGIC;
    signal EX_MEM_register_does_branch_out: STD_LOGIC;
    signal EX_MEM_register_ALU_result_in: STD_LOGIC_VECTOR(63 DOWNTO 0);
    signal EX_MEM_register_ALU_result_out: STD_LOGIC_VECTOR(63 DOWNTO 0);
    signal EX_MEM_register_branch_target_in : STD_LOGIC_VECTOR(31 DOWNTO 0);
    signal EX_MEM_register_branch_target_out : STD_LOGIC_VECTOR(31 DOWNTO 0);
    signal EX_MEM_register_b_value_in: STD_LOGIC_VECTOR(31 DOWNTO 0);
    signal EX_MEM_register_b_value_out: STD_LOGIC_VECTOR(31 DOWNTO 0);

    --Memory Stage
    signal memory_stage_ALU_result_in : std_logic_vector(63 downto 0);
    signal memory_stage_ALU_result_out : std_logic_vector(63 downto 0);
    signal memory_stage_instruction_in : INSTRUCTION;
    signal memory_stage_instruction_out : INSTRUCTION;
    signal memory_stage_val_b : std_logic_vector(31 downto 0);
    signal memory_stage_mem_data : std_logic_vector(31 downto 0);
    signal memory_stage_m_addr : integer range 0 to ram_size-1;
    signal memory_stage_m_read : std_logic;
    signal memory_stage_m_readdata : std_logic_vector (bit_width-1 downto 0);        
    signal memory_stage_m_write_data : std_logic_vector (bit_width-1 downto 0);
    signal memory_stage_m_write : std_logic;
    signal memory_stage_m_waitrequest : std_logic; -- Unused until the Avalon Interface is added.


    --Memory Writeback register
    signal MEM_WB_register_instruction_in: INSTRUCTION;
    signal MEM_WB_register_instruction_out: INSTRUCTION;
    signal MEM_WB_register_ALU_result_in: STD_LOGIC_VECTOR(63 DOWNTO 0);
    signal MEM_WB_register_ALU_result_out: STD_LOGIC_VECTOR(63 DOWNTO 0);
    signal MEM_WB_register_data_mem_in: STD_LOGIC_VECTOR(31 DOWNTO 0);
    signal MEM_WB_register_data_mem_out: STD_LOGIC_VECTOR(31 DOWNTO 0);

    --Write back
    signal write_back_stage_mem_data_in : std_logic_vector(31 downto 0);
    signal write_back_stage_ALU_result_in : std_logic_vector(63 downto 0);
    signal write_back_stage_instruction_in : instruction;
    signal write_back_stage_write_data : std_logic_vector(63 downto 0);
    signal write_back_stage_instruction_out : instruction;

    --memory
    signal instruction_memory_dump : std_logic := '0';
    signal instruction_memory_load : std_logic := '0';
    signal data_memory_dump : std_logic := '0';
    signal data_memory_load : std_logic := '0';

   
    signal branch_predictor_instruction_in : INSTRUCTION;
    signal branch_predictor_target : std_logic_vector(31 downto 0);
    signal branch_predictor_branch_taken : std_logic;
    signal branch_predictor_target_to_evaluate : std_logic_vector(31 downto 0);
    signal branch_predictor_prediction  : std_logic;

    --branch prediction
    signal branch_buff : branch_buffer;

    --misc
    signal initialized : std_logic := '0';
    signal dumped : std_logic := '0';

    signal manual_IF_ID_stall : std_logic := '0';
    signal manual_fetch_stall : std_logic := '0';

    signal feed_no_op_to_IF_ID : boolean := false;

    type branch_prediction_type is (PREDICT_NOT_TAKEN, PREDICT_TAKEN);
    signal current_prediction : branch_prediction_type := PREDICT_NOT_TAKEN;

    signal bad_prediction_occured : boolean := false;



begin

    ALU_out <= execute_stage_ALU_result;
    decode_register_file <= decode_stage_register_file_out;

    IFS : Fetch
    generic map(
        ram_size => ram_size,
        bit_width => bit_width
    ) 
    port map(
        clk => clock,
        reset => fetch_stage_reset,
        stall_in => fetch_stage_stall,
        branch_target_in => fetch_stage_branch_target,
        branch_condition_in => fetch_stage_branch_condition,
        instruction_out => fetch_stage_instruction_out,
        PC_out => fetch_stage_PC,
        m_addr => fetch_stage_m_addr,
        m_read => fetch_stage_m_read,
		m_readdata => fetch_stage_m_readdata,
		m_waitrequest => fetch_stage_m_waitrequest
    );

    load_program : Instruction_Memory 
	generic map(
        ram_size => ram_size,
        bit_width => bit_width
    )
    port map(
        clock => clock,
        writedata => fetch_stage_m_write_data,
        address => fetch_stage_m_addr,
        memwrite => fetch_stage_m_write, 
        memread => fetch_stage_m_read,
        readdata => fetch_stage_m_readdata,
        waitrequest => fetch_stage_m_waitrequest,
        write_to_mem => instruction_memory_dump,
        load_program => instruction_memory_load
    );

    IF_ID_REG : IF_ID
	port map(
        clk => clock,
		stall_in => IF_ID_register_stall,
        PC_in => IF_ID_register_pc_in,
        PC_out => IF_ID_register_pc_out,
        instruction_in => IF_ID_register_instruction_in,
        instruction_out => IF_ID_register_instruction_out
	);

    ID : Decode 
    port map(
        clk => clock,
		reset => decode_stage_reset_register_file,
		IR_in => decode_stage_release_instructions,
        stall_in => decode_stage_stall_in,
        PC_in => decode_stage_PC,
        instruction_in => decode_stage_instruction_in,
        wb_instr_in => decode_stage_write_back_instruction,
        wb_data_in => decode_stage_write_back_data,
		stall_out => decode_stage_stall_out,
        branch_target_out => decode_stage_branch_target_out,
		PC_out => decode_stage_PC_out,
        instruction_out => decode_stage_instruction_out,
        rs_data => decode_stage_val_a,
        rt_data => decode_stage_val_b,
        immediate_out => decode_stage_i_sign_extended,
		write_en_in => decode_stage_write_register_file,
		register_file_out => decode_stage_register_file_out
    );

    ID_EX_REG : ID_EX 
	port map(
        clk => clock,
        PC_in => ID_EX_register_pc_in,
        PC_out => ID_EX_register_pc_out,
        instruction_in => ID_EX_register_instruction_in,
        instruction_out => ID_EX_register_instruction_out,
        ra_in => ID_EX_register_a_in,
        ra_out => ID_EX_register_a_out,
        rb_in => ID_EX_register_b_in,
        rb_out => ID_EX_register_b_out,
		immediate_in => ID_EX_register_sign_extend_imm_in,
        immediate_out => ID_EX_register_sign_extend_imm_out
    );

    EX : Execute  
	port map(
		PC_in => execute_stage_PC,
		instruction_in => execute_stage_instruction_in,
		ra_in => execute_stage_val_a,
		rb_in => execute_stage_val_b,
		immediate_in => execute_stage_imm_sign_extended,
		PC_out => execute_stage_PC_out,
		instruction_out => execute_stage_instruction_out,
		branch_out => execute_stage_branch,
		branch_target_out => execute_stage_branch_target_out,
		rb_out => execute_stage_val_b_out,
		alu_out => execute_stage_ALU_result	
    );

    EX_MEM_REG : EX_MEM 
	port map(
        clk => clock,
        PC_in => EX_MEM_register_pc_in,
        PC_out => EX_MEM_register_pc_out,
        instruction_in => EX_MEM_register_instruction_in,
        instruction_out => EX_MEM_register_instruction_out,
        branch_in => EX_MEM_register_does_branch_in,
        branch_out => EX_MEM_register_does_branch_out,
        branch_target_in => EX_MEM_register_branch_target_in,
        branch_target_out => EX_MEM_register_branch_target_out,
        rb_in => EX_MEM_register_b_value_in,
        rb_out => EX_MEM_register_b_value_out,
        alu_in => EX_MEM_register_ALU_result_in,
        alu_out => EX_MEM_register_ALU_result_out
    );

    MEM : Memory 
	port map(
        instruction_in => memory_stage_instruction_in,
        alu_in => memory_stage_ALU_result_in,
        rb_in => memory_stage_val_b,
        instruction_out => memory_stage_instruction_out,
        alu_out => memory_stage_ALU_result_out,
        memory_data => memory_stage_mem_data,
        m_write_data => memory_stage_m_write_data,
        m_addr => memory_stage_m_addr,
        m_write => memory_stage_m_write,    
        m_read => memory_stage_m_read,
        m_readdata => memory_stage_m_readdata,
		m_waitrequest => memory_stage_m_waitrequest
    );
	
    write_mem : Instruction_Memory 
	generic map(
        ram_size => ram_size,
        bit_width => bit_width
    )
    port map(
        clock => clock,
        writedata => memory_stage_m_write_data,
        address => memory_stage_m_addr,
        memwrite => memory_stage_m_write, 
        memread => memory_stage_m_read,
        readdata => memory_stage_m_readdata,
        waitrequest => memory_stage_m_waitrequest,
        write_to_mem => data_memory_dump,
        load_program => data_memory_load
    );

    MEM_WB_REG : MEM_WB 
	port map (
        clk => clock,
        instruction_in => MEM_WB_register_instruction_in,
        instruction_out => MEM_WB_register_instruction_out,
        alu_in => MEM_WB_register_ALU_result_in,
        alu_out => MEM_WB_register_ALU_result_out,
        mem_in => MEM_WB_register_data_mem_in,
        mem_out => MEM_WB_register_data_mem_out
    );

    WB : Write_Back 
	port map(
        instruction_in => write_back_stage_instruction_in,
        memory_data_in => write_back_stage_mem_data_in,
        alu_in => write_back_stage_ALU_result_in,
        instruction_out => write_back_stage_instruction_out,
        wb_data_out => write_back_stage_write_data
    );

    optimize_predictor : Branch_Predictor 
	generic map(
        bit_width => predictor_bit_width
    )
    port map(
        clk => clock,
        instruction_in => branch_predictor_instruction_in,
        branch_taken_in => branch_predictor_branch_taken,
        branch_target_in => branch_predictor_target,
        branch_target_next_in => branch_predictor_target_to_evaluate,
        branch_prediction_out => branch_predictor_prediction
    );

    manage_fetch_branching : process(
        clock,
        current_prediction,
        IF_ID_register_instruction_out,
        ID_EX_register_instruction_out,
        EX_MEM_register_instruction_out,
        EX_MEM_register_branch_target_out,
        EX_MEM_register_does_branch_out,
        MEM_WB_register_instruction_out
    ) is 
    variable branch_target : std_logic_vector(31 downto 0) := (others => '0');
    begin
        -- if(rising_edge(clock)) then
        case use_branch_prediction is
            when false =>
                branch_target := EX_MEM_register_branch_target_out;
                fetch_stage_branch_condition <= EX_MEM_register_does_branch_out;
            when true =>
                if (bad_prediction_occured) then
                    branch_target := EX_MEM_register_branch_target_out;
                    fetch_stage_branch_condition <= EX_MEM_register_does_branch_out;
                else
                    case current_prediction is
                        when PREDICT_TAKEN =>
                            if(is_branch_type(IF_ID_register_instruction_out) 
                                AND NOT is_branch_type(ID_EX_register_instruction_out) 
                                AND NOT is_branch_type(EX_MEM_register_instruction_out) 
                                AND NOT is_branch_type(MEM_WB_register_instruction_out))
                                then
                                -- report "we're telling fetch to branch, since ID has a branch instruction and we're doing PREDICT TAKEN";
                                branch_target := decode_stage_branch_target_out;
                                fetch_stage_branch_condition <= '1';

                            elsif(NOT is_branch_type(IF_ID_register_instruction_out) 
                                AND NOT is_branch_type(ID_EX_register_instruction_out)
                                AND is_branch_type(EX_MEM_register_instruction_out) 
                                AND EX_MEM_register_does_branch_out = '1'
                                AND NOT is_branch_type(MEM_WB_register_instruction_out))
                                then
                                -- we don't branch, since we already correctly predicted we would.
                                -- report "we correctly predicted that we would branch!";
                                branch_target := (others => '0');
                                fetch_stage_branch_condition <= '0';

                            else
                                -- report "Default case";
                                branch_target := EX_MEM_register_branch_target_out;
                                fetch_stage_branch_condition <= EX_mem_register_does_branch_out;
                            end if;
                        when PREDICT_NOT_TAKEN =>
                            if(is_branch_type(decode_stage_instruction_out) 
                                AND NOT is_branch_type(ID_EX_register_instruction_out)
                                AND NOT is_branch_type(EX_MEM_register_instruction_out)
                                AND NOT is_branch_type(MEM_WB_register_instruction_out)) then
                                branch_target := (others => '0'); -- DOESNT MATTER, let the PC increment normally. 
                                fetch_stage_branch_condition <= '0';
                            else
                                branch_target := EX_MEM_register_branch_target_out;
                                fetch_stage_branch_condition <= EX_MEM_register_does_branch_out;
                            end if;
                    end case;
                end if;
        end case;
        fetch_stage_branch_target <= to_integer(signed(branch_target));
        -- end if;
    end process;

    fetch_stage_stall <= decode_stage_stall_out OR manual_fetch_stall;

    IF_ID_register_instruction_in <= 
        NO_OP_INSTRUCTION when use_branch_prediction AND bad_prediction_occured else
        NO_OP_INSTRUCTION when initialize = '1' else 
        input_instruction when override_input_instruction = '1' else
        NO_OP_INSTRUCTION when feed_no_op_to_IF_ID else
        fetch_stage_instruction_out;
    IF_ID_register_pc_in <= fetch_stage_PC;
    IF_ID_register_stall <= decode_stage_stall_out OR manual_IF_ID_stall;

    decode_stage_PC <= IF_ID_register_pc_out;
    decode_stage_instruction_in <= 
        NO_OP_INSTRUCTION when use_branch_prediction AND bad_prediction_occured else IF_ID_register_instruction_out;
    decode_stage_write_back_data <= write_back_stage_write_data;
    decode_stage_write_back_instruction <= write_back_stage_instruction_out;

    ID_EX_register_a_in <= decode_stage_val_a;
    ID_EX_register_b_in <= decode_stage_val_b;
    ID_EX_register_instruction_in <= 
        NO_OP_INSTRUCTION when use_branch_prediction AND bad_prediction_occured else decode_stage_instruction_out;
    ID_EX_register_pc_in <= decode_stage_PC_out;
    ID_EX_register_sign_extend_imm_in <= decode_stage_i_sign_extended;

    execute_stage_PC <= ID_EX_register_pc_out;
    execute_stage_instruction_in <= ID_EX_register_instruction_out;
    execute_stage_val_a <= ID_EX_register_a_out;
    execute_stage_val_b <= ID_EX_register_b_out;
    execute_stage_imm_sign_extended <= ID_EX_register_sign_extend_imm_out;
    
    EX_MEM_register_ALU_result_in <= execute_stage_ALU_result;
    EX_MEM_register_b_value_in <= execute_stage_val_b; 
    EX_MEM_register_does_branch_in <= execute_stage_branch;
    EX_MEM_register_branch_target_in <= execute_stage_branch_target_out;
    EX_MEM_register_pc_in <= execute_stage_PC_out;
    EX_MEM_register_instruction_in <= 
         NO_OP_INSTRUCTION when use_branch_prediction AND bad_prediction_occured else execute_stage_instruction_out;

    memory_stage_ALU_result_in <= EX_MEM_register_ALU_result_out;
    memory_stage_instruction_in <= EX_MEM_register_instruction_out;
    memory_stage_val_b <= EX_MEM_register_b_value_out;

    MEM_WB_register_ALU_result_in <= memory_stage_ALU_result_out;
    MEM_WB_register_data_mem_in <= memory_stage_mem_data;
    MEM_WB_register_instruction_in <= 
        NO_OP_INSTRUCTION when use_branch_prediction AND bad_prediction_occured else memory_stage_instruction_out;
    
    write_back_stage_ALU_result_in <= MEM_WB_register_ALU_result_out;
    write_back_stage_instruction_in <= MEM_WB_register_instruction_out;
    write_back_stage_mem_data_in <= MEM_WB_register_data_mem_out;

    -- TODO: Later, Take a look at page 684 (C-40) of the textbook "Computer Architecture : a quantitative approach"
    -- for some neat pseudo-code about forwarding.


    IF_ID_instruction <= IF_ID_register_instruction_out;
    ID_EX_instruction <= ID_EX_register_instruction_out;
    EX_MEM_instruction <= EX_MEM_register_instruction_out;
    MEM_WB_instruction <= MEM_WB_register_instruction_out;
    WB_instruction <= write_back_stage_instruction_out;
    WB_data <= write_back_stage_write_data;


    branch_predictor_instruction_in <= EX_MEM_register_instruction_out;
    branch_predictor_target <= EX_MEM_register_branch_target_out;
    branch_predictor_branch_taken <= EX_MEM_register_does_branch_out;
    -- TODO: change the target to be the PC, if that makes more sense.
    branch_predictor_target_to_evaluate <= decode_stage_branch_target_out;
    -- branch_predictor_target_to_evaluate <= std_logic_vector(to_unsigned(decode_stage_PC_out);

    fetch_PC <= IF_ID_register_pc_out;
    fetch_stage_reset <= '1' when initialize = '1' else '0';

    decode_stage_release_instructions(0) <= ID_EX_register_instruction_out when use_branch_prediction AND bad_prediction_occured else NO_OP_INSTRUCTION;
    decode_stage_release_instructions(1) <= EX_MEM_register_instruction_out when use_branch_prediction AND bad_prediction_occured else NO_OP_INSTRUCTION;
    
    init : process( clock, initialize )
    begin
        if initialize = '1' AND initialized = '0' then
            -- report "Initializing...";
            -- fetch_stage_reset <= '1';
            instruction_memory_load <= '1';
            initialized <= '1';  
        else 
            instruction_memory_load <= '0';
            -- fetch_stage_reset <= '0';     
        end if;
    end process ; -- init

    dump_process : process( clock, dump )
    begin
        if dump = '1' AND dumped = '0' then
            -- report "Dumping...";
            data_memory_dump <= '1';
            -- instruction_memory_dump <= '1';
            decode_stage_write_register_file <= '1';
            dumped <= '1';  
        else 
            data_memory_dump <= '0';
            decode_stage_write_register_file <= '0';
            -- instruction_memory_dump <= '0';         
        end if;
    end process ; -- dump


    -- HERE is the code that actually uses the predictor:
    current_prediction <= 
        PREDICT_NOT_TAKEN when use_static_not_taken else
        PREDICT_TAKEN when use_static_taken else
        PREDICT_TAKEN when branch_predictor_prediction = '1' else
        PREDICT_NOT_TAKEN when branch_predictor_prediction = '0'
        else current_prediction;

    report_prediction : process(current_prediction)
    begin
        case current_prediction is 
            when PREDICT_TAKEN =>
                report "current prediction is TAKEN";
            when PREDICT_NOT_TAKEN =>
                report "current prediction is NOT_TAKEN";
        end case;
    end process;


    detect_wrong_prediction : process(
        current_prediction,
        EX_MEM_register_instruction_out,
        EX_MEM_register_does_branch_out
        )
        variable instruction : INSTRUCTION;
        variable actual_branch : std_logic;
    begin
        if (use_branch_prediction) then
        instruction := EX_MEM_register_instruction_out;
        actual_branch := EX_MEM_register_does_branch_out;
        bad_prediction_occured <= false;
        case instruction.instruction_type is
            when BRANCH_IF_EQUAL | BRANCH_IF_NOT_EQUAL =>
                if (current_prediction = PREDICT_TAKEN AND actual_branch = '0') OR (current_prediction = PREDICT_NOT_TAKEN AND actual_branch = '1') then
                    bad_prediction_occured <= true;

                    -- report "bad branch prediction occured! Feeding no-ops to the IF_ID, ID_EX, EX_MEM, and MEM_WB registers.";
                end if;
            when others =>   
                -- do nothing.      
        end case;
        end if;
    end process;


    branch_stall_management : process(
        clock, 
        IF_ID_register_instruction_out,
        ID_EX_register_instruction_out,
        EX_MEM_register_instruction_out,
        EX_MEM_register_does_branch_out
        )
    begin
        if (NOT use_branch_prediction) then
            if  is_branch_type(IF_ID_register_instruction_out) OR is_jump_type(IF_ID_register_instruction_out) OR 
                is_branch_type(ID_EX_register_instruction_out) OR is_jump_type(ID_EX_register_instruction_out) OR
                ((is_branch_type(EX_MEM_register_instruction_out) OR is_jump_type(EX_MEM_register_instruction_out)) AND EX_MEM_register_does_branch_out = '1')
            then
                feed_no_op_to_IF_ID <= true;
                manual_fetch_stall <= '1';
            else
                feed_no_op_to_IF_ID <= false;
                manual_fetch_stall <= '0';
            end if;
        end if;
    end process;
end behavioral;