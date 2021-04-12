library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Pipelined_Processor_tb is
end Pipelined_Processor_tb;

architecture behavioral of Pipelined_Processor_tb is

component Pipelined_Processor is
port(
	clk : in std_logic;
	writeToRegisterFile : in std_logic;
	writeToMemoryFile : in std_logic;
	out_IDEXStructuralStall : out std_logic;
	out_EXMEMStructuralStall :  out std_logic;
	out_structuralStall :  out std_logic;
	out_pcStall :  out std_logic;

	-- PIPELINE IFID
	--address goes to both IFID and IDEX
	out_address : out std_logic_vector(31 downto 0);
	out_instruction : out std_logic_vector(31 downto 0);
	out_IFIDaddress : out  std_logic_vector(31 downto 0);
	out_IFIDinstruction : out  std_logic_vector(31 downto 0);

	--PIPELINE IDEX
	out_IDEXaddress : out  std_logic_vector(31 downto 0);
	out_IDEXra : out  std_logic_vector(31 downto 0);
	out_IDEXrb : out  std_logic_vector(31 downto 0);
	out_IDEXimmediate : out  std_logic_vector(31 downto 0);
	out_IDEXrd : out  std_logic_vector (4 downto 0);
	out_IDEXALU1srcO, out_IDEXALU2srcO, out_IDEXMemReadO, out_IDEXMeMWriteO, out_IDEXRegWriteO, out_IDEXMemToRegO: out  std_logic;
	out_IDEXAluOp : out  std_logic_vector (4 downto 0);

	-- S FOR CONTROLLER
	out_opcodeInput,out_functInput : out  std_logic_vector(5 downto 0);
	out_ALU1srcO,out_ALU2srcO,out_MemReadO,out_MemWriteO,out_RegWriteO,out_MemToRegO,out_RType,out_Jtype,out_Shift: out  std_logic;
	out_ALUOp : out  std_logic_vector(4 downto 0);

	-- S FOR REGISTERS
	out_rs,out_rt,out_rd,out_WBrd : out  std_logic_vector (4 downto 0);
	out_rd_data: out  std_logic_vector(31 downto 0);
	out_write_enable : out  std_logic;
	out_ra,out_rb : out  std_logic_vector(31 downto 0);
	out_shamnt : out  std_logic_vector(4 downto 0);

	out_immediate : out  std_logic_vector(15 downto 0); 
	out_immediate_out : out  std_logic_vector(31 downto 0);

	-- S FOR EXECUTE STAGE  
	out_muxOutput1 : out  std_logic_vector(31 downto 0);
	out_muxOutput2 : out  std_logic_vector(31 downto 0);
	out_aluOutput : out  std_logic_vector(31 downto 0);
	out_zeroOutput : out  std_logic;

	-- S FOR EXMEM
	out_EXMEMBranch : out  std_logic; -- need the zero variable 
	out_ctrl_jal : out  std_logic;
	out_EXMEMaluOutput : out  std_logic_vector(31 downto 0);
	out_EXMEMregisterOutput : out  std_logic_vector(31 downto 0);
	out_EXMEMrd : out  std_logic_vector(4 downto 0);
	out_EXMEMMemReadO, out_EXMEMMeMWriteO, out_EXMEMRegWriteO, out_EXMEMMemToRegO: out  std_logic;

	-- MEM S 
	out_MEMWBmemOutput : out  std_logic_vector(31 downto 0);
	out_MEMWBaluOutput : out  std_logic_vector(31 downto 0);
	out_MEMWBrd : out  std_logic_vector(4 downto 0);
	out_memtoReg : out  std_logic;
	out_regWrite : out  std_logic
); end component;

constant clk_period : time := 1 ns;
signal clk : std_logic := '0';
signal s_writeToRegisterFile : std_logic := '0';
signal s_writeToMemoryFile : std_logic := '0';
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

pipeline : Pipelined_Processor
port map(
	clk => clk,
	writeToMemoryFile => s_writeToRegisterFile,
	writeToRegisterFile => s_writeToMemoryFile,
		-- STALL SIGNALS 
	out_IDEXStructuralStall => IDEXStructuralStall,
	out_EXMEMStructuralStall => EXMEMStructuralStall,
	out_structuralStall => structuralStall,
	out_pcStall => pcStall,

	-- PIPELINE IFID
	--address goes to both IFID and IDEX
	out_address => address,
	out_instruction => instruction,
	out_IFIDaddress => IFIDaddress,
	out_IFIDinstruction => IFIDinstruction,

	--PIPELINE IDEX
	out_IDEXaddress => IDEXaddress,
	out_IDEXra => IDEXra,
	out_IDEXrb => IDEXrb,
	out_IDEXimmediate => IDEXimmediate,
	out_IDEXrd => IDEXrd,
	out_IDEXALU1srcO => IDEXALU1srcO,
	out_IDEXALU2srcO => IDEXALU2srcO,
	out_IDEXMemReadO => IDEXMemReadO,
	out_IDEXMeMWriteO => IDEXMeMWriteO,
	out_IDEXRegWriteO => IDEXRegWriteO,
	out_IDEXMemToRegO => IDEXMemToRegO,
	out_IDEXAluOp => IDEXAluOp,

	-- S FOR CONTROLLER
	out_opcodeInput => opcodeInput,
	out_functInput => functInput,
	out_ALU1srcO => ALU1srcO,
	out_ALU2srcO => ALU2srcO,
	out_MemReadO => MemReadO,
	out_MemWriteO => MemWriteO,
	out_RegWriteO => RegWriteO,
	out_MemToRegO => MemToRegO,
	out_RType => RType,
	out_Jtype => Jtype,
	out_Shift => Shift, 
	out_ALUOp => ALUOp,

	-- S FOR REGISTERS
	out_rs => rs,
	out_rt => rt,
	out_rd => rd,
	out_WBrd => WBrd,
	out_rd_data => rd_data,
	out_write_enable => write_enable,
	out_ra => ra,
	out_rb => rb,
	out_shamnt => shamnt,

	out_immediate => immediate,
	out_immediate_out => immediate_out,

	-- S FOR EXECUTE STAGE  
	out_muxOutput1 => muxOutput1,
	out_muxOutput2 => muxOutput2,
	out_aluOutput => aluOutput,
	out_zeroOutput => zeroOutput,

	-- S FOR EXMEM
	out_EXMEMBranch => EXMEMBranch,
	out_ctrl_jal => ctrl_jal,
	out_EXMEMaluOutput => EXMEMaluOutput,
	out_EXMEMregisterOutput => EXMEMregisterOutput,
	out_EXMEMrd => EXMEMrd,
	out_EXMEMMemReadO => EXMEMMemReadO,
	out_EXMEMMeMWriteO => EXMEMMeMWriteO, 
	out_EXMEMRegWriteO => EXMEMRegWriteO, 
	out_EXMEMMemToRegO => EXMEMMemToRegO,

	-- MEM S 
	out_MEMWBmemOutput => MEMWBmemOutput,
	out_MEMWBaluOutput => MEMWBaluOutput,
	out_MEMWBrd => MEMWBrd,
	out_memtoReg => memtoReg,
	out_regWrite => regWrite

);

	clk_process : process
	begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
	end process;

	test_process : process
	begin
		wait for clk_period;
		report "STARTING SIMULATION \n";
		wait for  9800 * clk_period;
		s_writeToRegisterFile <= '1';
		s_writeToMemoryFile <= '1';
		
		wait;		
	end process;
end behavioral;