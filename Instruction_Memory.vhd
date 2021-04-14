--Adapted from Example 12-15 of Quartus Design and Synthesis handbook
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.std_logic_textio.all;
USE std.textio.all;

ENTITY Instruction_Memory IS
	GENERIC(
		ram_size : INTEGER := 8192;
		bit_width : INTEGER := 32;
		mem_delay : time := 0.1 ns;
		clock_period : time := 1 ns
	);
	PORT (
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
END Instruction_Memory;

ARCHITECTURE rtl OF Instruction_Memory IS
	TYPE MEM IS ARRAY(ram_size-1 downto 0) OF STD_LOGIC_VECTOR(bit_width-1 DOWNTO 0);
	constant empty_ram_block : MEM := (others => (others => '0'));
	SIGNAL ram_block: MEM := empty_ram_block; 
	SIGNAL write_waitreq_reg: STD_LOGIC := '1';
	SIGNAL read_waitreq_reg: STD_LOGIC := '1';

BEGIN
	-- write to memory.txt
	write_mem_process: process(write_to_mem)
		file     fptr  : text;
		variable file_line : line;
	BEGIN
		if(rising_edge(write_to_mem)) then
			file_open(fptr, "memory.txt", WRITE_MODE);
			for i in 0 to ram_size-1 loop
				write(file_line, ram_block(i));
				writeline(fptr, file_line);
			end loop;
			file_close(fptr);
		end if;
	end process;

	-- load program.txt
	read_program_process: process(load_program, memwrite, address, writedata)
		file 	 fptr: text;
		variable file_line: line;
		variable line_data: std_logic_vector(bit_width-1 DOWNTO 0);
		variable i : integer := 0;
	begin
		if(rising_edge(load_program)) then
			file_open(fptr, "program.txt", READ_MODE);
			while ((not endfile(fptr)) and (i < ram_size)) loop
				readline(fptr, file_line);
				read(file_line, line_data);
				ram_block(i) <= line_data;
				i := i + 1;	
			end loop;
			file_close(fptr);
		elsif memwrite = '1' then
			ram_block(address) <= writedata;
		end if;	
	end process;
	readdata <= ram_block(address);

	--The waitrequest signal is used to vary response time in simulation
	--Read and write should never happen at the same time.
	waitreq_w_proc: PROCESS (memwrite)
	BEGIN
		IF(memwrite'event AND memwrite = '1')THEN
			write_waitreq_reg <= '0' after mem_delay, '1' after mem_delay + clock_period;

		END IF;
	END PROCESS;

	waitreq_r_proc: PROCESS (memread)
	BEGIN
		IF(memread'event AND memread = '1')THEN
			read_waitreq_reg <= '0' after mem_delay, '1' after mem_delay + clock_period;
		END IF;
	END PROCESS;
	waitrequest <= write_waitreq_reg and read_waitreq_reg;

END rtl;
