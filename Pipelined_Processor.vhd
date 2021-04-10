-- Entity: Pipelined_Processor
-- Authors: Anas Deis, Albert Assouad, Barry Chen
-- Date: 04/16/2021

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Pipelined_Processor is
port(
	clk : in std_logic;
	writeToRegisterFile : in std_logic := '0';
	writeToMemoryFile : in std_logic := '0'
);
end Pipelined_Processor;

architecture behavioral of Pipelined_Processor is

-- Stage 1 : IF
component Fetch is
port(
	clk : in std_logic;
	fetch_sel : in std_logic;
	structural_stall_in : in std_logic;
	pc_stall_in : in std_logic;	
	mux_in : in std_logic_vector(31 downto 0);    
	next_address_out : out std_logic_vector(31 downto 0); 
	instruction_out  : out std_logic_vector(31 downto 0)  
); end component;

-- Stage 2 : ID		
component Decode is
port(
	clk : in std_logic;
	instruction_in : in std_logic_vector (31 downto 0);  
	write_file_en : in std_logic;						 
	write_en_in : in std_logic; 						 
	rd_in : in std_logic_vector (4 downto 0);	 		  
	rd_reg_data_in : in std_logic_vector (31 downto 0);   
	rs_reg_data_out : out std_logic_vector (31 downto 0); 
	rt_reg_data_out : out std_logic_vector (31 downto 0); 
	R_Type_out : out std_logic; 
	J_Type_out : out std_logic; 
	shift_out : out std_logic;
	MemRead_out : out std_logic; 
	MemWrite_out : out std_logic; 
	MemToReg_out : out std_logic;	
	RegWrite_out : out std_logic;
	structural_hazard_out : out std_logic; 
	branch_in : in std_logic; 
	old_branch_in : in std_logic;
	ALUOp_out : out std_logic_vector(4 downto 0); 
	sel_ALU_mux0_out : out std_logic; 
	sel_ALU_mux1_out : out std_logic; 
	immediate_out : out std_logic_vector (31 downto 0)
); end component;

-- Stage 3 : EX
component Execute is
port(
    address_in : std_logic_vector(31 downto 0);
	sel_ALU_mux0_in : in std_logic;
	sel_ALU_mux1_in : in std_logic;
    ALUop_in : in std_logic_vector(4 downto 0);				
    immediate_in : in std_logic_vector(31 downto 0);		
    read_data0_in : in std_logic_vector(31 downto 0);		
    read_data1_in : in std_logic_vector(31 downto 0);		
    control_flow_out : out std_logic := '0'; 
    alu_result_out : out std_logic_vector(31 downto 0) 		
); end component;

-- Stage 4 : MEM
component Memory is
GENERIC(
	ramsize : INTEGER := 8192;
	memdelay : time := 10 ns;
	clockperiod : time := 1 ns
);
port (
	clk : in std_logic;
	jal_in: in std_logic;			
	write_mem_file : in std_logic;	
	RegWrite_in: in std_logic;		
	MemToReg_in: in std_logic;
	mem_store : in std_logic;
	mem_load: in std_logic;	
	alu_in : in std_logic_vector (31 downto 0);		
	mem_data_in: in std_logic_vector (31 downto 0); 
	rd_in: in std_logic_vector (4 downto 0);		
	RegWrite_out: out std_logic;
	MemToReg_out: out std_logic;
	alu_out : out std_logic_vector (31 downto 0);
	mem_data_out: out std_logic_vector (31 downto 0);
	rd_out: out std_logic_vector (4 downto 0)	
); end component;

-- Stage 5 : WB
component Write_Back is
port (
	mem_op_en_in: in std_logic;					 
	register_file_en_in: in std_logic;		     
	ex_in : in std_logic_vector (31 downto 0);	  
	mem_in: in std_logic_vector (31 downto 0);	
	ir_in: in std_logic_vector (4 downto 0);      
	register_file_en_out: out std_logic;		  
	mux_out : out std_logic_vector (31 downto 0);
	ir_out: out std_logic_vector (4 downto 0)	 
); end component;

-- STALL SIGNALS 
signal IDEXStructuralStall : std_logic;
signal EXMEMStructuralStall : std_logic;
signal structuralStall : std_logic;
signal pcStall : std_logic;

-- PIPELINE IFID
--address goes to both IFID and IDEX
signal address : std_logic_vector(31 downto 0);
signal instruction : std_logic_vector(31 downto 0);
signal IFIDaddress : std_logic_vector(31 downto 0);
signal IFIDinstruction : std_logic_vector(31 downto 0);

--PIPELINE IDEX
signal IDEXaddress : std_logic_vector(31 downto 0);
signal IDEXra : std_logic_vector(31 downto 0);
signal IDEXrb : std_logic_vector(31 downto 0);
signal IDEXimmediate : std_logic_vector(31 downto 0);
signal IDEXrd : std_logic_vector (4 downto 0);
signal IDEXALU1srcO, IDEXALU2srcO, IDEXMemReadO, IDEXMeMWriteO, IDEXRegWriteO, IDEXMemToRegO: std_logic;
signal IDEXAluOp : std_logic_vector (4 downto 0);

-- SIGNALS FOR CONTROLLER
signal opcodeInput,functInput : std_logic_vector(5 downto 0);
signal ALU1srcO,ALU2srcO,MemReadO,MemWriteO,RegWriteO,MemToRegO,RType,Jtype,Shift: std_logic;
signal ALUOp : std_logic_vector(4 downto 0);

-- SIGNALS FOR REGISTERS
signal rs,rt,rd,WBrd : std_logic_vector (4 downto 0);
signal rd_data: std_logic_vector(31 downto 0);
signal write_enable : std_logic;
signal ra,rb : std_logic_vector(31 downto 0);
signal shamnt : std_logic_vector(4 downto 0);

signal immediate : std_logic_vector(15 downto 0); 
signal immediate_out : std_logic_vector(31 downto 0);

-- SIGNALS FOR EXECUTE STAGE  
signal muxOutput1 : std_logic_vector(31 downto 0);
signal muxOutput2 : std_logic_vector(31 downto 0);
signal aluOutput : std_logic_vector(31 downto 0);
signal zeroOutput : std_logic;

-- SIGNALS FOR EXMEM
signal EXMEMBranch : std_logic; -- need the zero variable 
signal ctrl_jal : std_logic;
signal EXMEMaluOutput : std_logic_vector(31 downto 0);
signal EXMEMregisterOutput : std_logic_vector(31 downto 0);
signal EXMEMrd : std_logic_vector(4 downto 0);
signal EXMEMMemReadO, EXMEMMeMWriteO, EXMEMRegWriteO, EXMEMMemToRegO: std_logic;

-- MEM SIGNALS 
signal MEMWBmemOutput : std_logic_vector(31 downto 0);
signal MEMWBaluOutput : std_logic_vector(31 downto 0);
signal MEMWBrd : std_logic_vector(4 downto 0);
signal memtoReg : std_logic;
signal regWrite : std_logic;

begin

	IFS : Fetch
	port map(
		clk => clk,
		fetch_sel => EXMEMBranch,
		structural_stall_in => structuralStall,
		pc_stall_in => pcStall,	
		mux_in => EXMEMaluOutput, 
		next_address_out => address,
		instruction_out => instruction
	);

	ID : Decode
	port map(
		clk => clk,
		instruction_in => IFIDinstruction,
		write_file_en => writeToRegisterFile,					 
		write_en_in => write_enable,					 
		rd_in => WBrd,	 		  
		rd_reg_data_in => rd_data,   
		rs_reg_data_out => ra,
		rt_reg_data_out => rb, 
		R_Type_out => RType,
		J_Type_out => JType,
		shift_out => Shift,
		MemRead_out => MemReadO,
		MemWrite_out => MemWriteO, 
		MemToReg_out => MemToRegO,
		RegWrite_out => RegWriteO,
		structural_hazard_out => IDEXStructuralStall,
		branch_in => zeroOutput,
		old_branch_in => EXMEMBranch,
		ALUOp_out => ALUOp,
		sel_ALU_mux0_out => ALU1srcO,
		sel_ALU_mux1_out => ALU2srcO,
		immediate_out => immediate_out
	);

	EX : Execute
	port map(
		 address_in => IDEXaddress,
		sel_ALU_mux0_in => IDEXALU1srcO,
		sel_ALU_mux1_in => IDEXALU2srcO,
		 ALUop_in => IDEXAluOp,			
		 immediate_in => IDEXimmediate,		
		 read_data0_in => IDEXra,		
		 read_data1_in => IDEXrb,		
		 control_flow_out => zeroOutput,
		 alu_result_out => aluOutput
	); 

	MEM : Memory
	port map(
		clk => clk,
		jal_in => ctrl_jal,		
		write_mem_file => writeToMemoryFile,
		RegWrite_in => EXMEMRegWriteO,		
		MemToReg_in => EXMEMMemToRegO,
		mem_store => EXMEMMemWriteO,
		mem_load => EXMEMMemReadO,	
		alu_in => EXMEMaluOutput,		
		mem_data_in => EXMEMregisterOutput,
		rd_in => EXMEMrd,		
		RegWrite_out => regWrite,
		MemToReg_out => memtoReg,
		alu_out => MEMWBaluOutput,
		mem_data_out => MEMWBmemOutput, 
		rd_out => MEMWBrd
	); 

	WB: Write_Back
	port map(
		mem_op_en_in => memtoReg,				 
		register_file_en_in => regWrite,	     
		ex_in => MEMWBaluOutput,
		mem_in => MEMWBmemOutput,
		ir_in => MEMWBrd,
		register_file_en_out => write_enable,  
		mux_out => rd_data,
		ir_out => WBrd
	);

	process(EXMEMStructuralStall)
	begin
		if EXMEMStructuralStall = '1' then 
			pcStall <= '1';
		else 
			pcStall <= '0';
		end if;

	end process;

	process (clk)
	begin

		if (clk'event and clk = '1') then
		--PIPELINED VALUE 
		--IFID 
		IFIDaddress <= address;
		IFIDinstruction <= instruction;

		-- IDEX
		IDEXaddress <= IFIDaddress;
		IDEXrb <= rb;

		--FOR IMMEDIATE VALUES
		if RType = '1' then
			IDEXrd <= rd;
		-- FOR JAL
		elsif ALUOP = "11010" then
			IDEXrd <= "11111";
		else
			IDEXrd <= rt;
		end if;

		--FOR SHIFT INSTRUCTIONS
		if Shift = '1' then
			IDEXra <= rb;
		else
			IDEXra <= ra;
		end if;

		--FOR JUMP INSTRUCTIONS
		if JType = '1' then
			IDEXimmediate <= "000000" & IFIDinstruction(25 downto 0);
		else
			IDEXimmediate <= immediate_out;
		end if;

		IDEXALU1srcO <= ALU1srcO;
		IDEXALU2srcO <= ALU2srcO;
		IDEXMemReadO <= MemReadO;
		IDEXMeMWriteO <= MemWriteO;
		IDEXRegWriteO <= RegWriteO;
		IDEXMemToRegO <= MemToRegO;
		IDEXAluOp <= ALUOp;

			
		--EXMEM 
		EXMEMBranch <= zeroOutput; 
		EXMEMrd <= IDEXrd;
		EXMEMMemReadO <= IDEXMemReadO;
		EXMEMMeMWriteO <= IDEXMeMWriteO;
		EXMEMRegWriteO <= IDEXRegWriteO;
		EXMEMMemToRegO <= IDEXMemToRegO;
		EXMEMaluOutput <= aluOutput;
		EXMEMStructuralStall <= IDEXStructuralStall;
		structuralStall <= EXMEMStructuralStall;
		--FOR JAL
		if IDEXAluOp = "11010" then
			EXMEMregisterOutput <= IDEXaddress;
			ctrl_jal <= '1';
		else
			EXMEMregisterOutput <= IDEXrb;
			ctrl_jal <= '0';
		end if;
			
		end if ;
	end process;
end behavioral;