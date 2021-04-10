-- Entity: Memory
-- Authors: Anas Deis, Albert Assouad, Barry Chen
-- Date: 04/16/2021

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Stage 4 : Memory

entity Memory is
GENERIC(
	ramsize : INTEGER := 8192;
	memdelay : time := 10 ns;
	clockperiod : time := 1 ns
);
port (

	-- INPUTS
	clk : in std_logic;
	
	jal_in: in std_logic;			-- is operation jal
	write_mem_file : in std_logic;	-- enable writing to memory.txt
	
	-- From ID/EX
	RegWrite_in: in std_logic;		
	MemToReg_in: in std_logic;
	mem_store : in std_logic;
	mem_load: in std_logic;	
	
	alu_in : in std_logic_vector (31 downto 0);		-- ALU output from EX
	mem_data_in: in std_logic_vector (31 downto 0); 
	rd_in: in std_logic_vector (4 downto 0);		-- rd
	
	-- OUTPUTS
	RegWrite_out: out std_logic;
	MemToReg_out: out std_logic;
	alu_out : out std_logic_vector (31 downto 0);
	mem_data_out: out std_logic_vector (31 downto 0);
	rd_out: out std_logic_vector (4 downto 0)	
);
end Memory;

architecture behavioral of Memory is

component mem_file is
GENERIC(
	ram_size : INTEGER := 8192;
	mem_delay : time := 10 ns;
	clock_period : time := 1 ns
);
port (
	clk: in std_logic;
	writedata: in std_logic_vector (31 downto 0);
	address: in INTEGER range 0 to ram_size-1;
	memwrite: in std_logic;
	memread: in std_logic;
	waitrequest: out std_logic;
	readdata: out std_logic_vector (31 downto 0);
	write_text_flag : in std_logic
); end component;

--signal declaration
signal alu, mem_data, m_writedata, m_readdata : std_logic_vector (31 downto 0);
signal m_address: INTEGER range 0 to 32767;
signal m_memread, m_memwrite, m_waitrequest : std_logic;

begin
	propagate_signals: process (clk)
	begin
		if (clk'event and clk = '1') then
			rd_out <= rd_in;
			RegWrite_out <= RegWrite_in;
			MemToReg_out <= MemToReg_in;
			mem_data_out <= mem_data;
			alu_out <= alu;				
		end if;
		
	end process;

	mem_op : process (rd_in, MemToReg_in, RegWrite_in, alu_in)
	begin

		if jal_in = '1' then
			alu <= mem_data_in;
		else
			alu <= alu_in;
		end if;
		
		m_memwrite <= '0';
		m_memread <= '0';
		if mem_store = '1' then
			m_memwrite <= '1'; 	
			m_address <= to_integer(unsigned(alu_in));				
			m_writedata <= mem_data_in;
		elsif mem_load = '1' then
			m_memread <= '1';
			m_address <= to_integer(unsigned(alu_in));
			mem_data <= m_readdata;
		end if;
	end process;

	memory_file : mem_file
	GENERIC map(
		ram_size => ramsize,
		mem_delay => memdelay,
		clock_period => clockperiod
	)
	port map(
		clk => clk,
		writedata => m_writedata,
		address => m_address,
		memwrite => m_memwrite,
		memread => m_memread,
		readdata => m_readdata,
		waitrequest => m_waitrequest,
		write_text_flag => write_mem_file
	);		
end behavioral;
