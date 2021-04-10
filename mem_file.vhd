--Taken from the Memory.vhd file from assignment 2 and modified
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.std_logic_textio.all;
USE std.textio.all;

ENTITY mem_file IS
	GENERIC(
		ram_size : INTEGER := 8192;
		mem_delay : time := 10 ns;
		clock_period : time := 1 ns
	);
	PORT (
		clk: IN STD_LOGIC;
		writedata: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		address: IN INTEGER RANGE 0 TO ram_size-1;
		memwrite: IN STD_LOGIC;
		memread: IN STD_LOGIC;
		waitrequest: OUT STD_LOGIC;
		readdata: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
    	write_text_flag : IN STD_LOGIC
	);
END mem_file;

ARCHITECTURE rtl OF mem_file IS
	TYPE MEM IS ARRAY(ram_size-1 downto 0) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL ram_block: MEM;
	SIGNAL read_address_reg: INTEGER RANGE 0 to ram_size-1;
	SIGNAL write_waitreq_reg: STD_LOGIC := '1';
	SIGNAL read_waitreq_reg: STD_LOGIC := '1';
BEGIN

	write_file: process(write_text_flag)
	FILE fptr : text;
	variable file_line : line;	
	variable idx : integer := 0;
	
	begin
	
		if write_text_flag = '1' then
			file_open(fptr,"memory.txt.", write_mode);
			idx := 0;
			while (idx < 8192) loop 
				write(file_line, ram_block(idx));
				writeline(fptr, file_line);
				idx := idx + 1;
			end loop;
		end if;
		
		file_close(fptr);
		
	end process;
	
	--SRAM model
	mem_process: PROCESS (clk)
	BEGIN
		--This is a cheap trick to initialize the SRAM in simulation
    		IF(now < 1 ps)THEN
			For i in 0 to ram_size-1 LOOP
				ram_block(i) <= std_logic_vector(to_unsigned(0,32));
			END LOOP;
		end if;

		--Actual synthesizable SRAM block
		IF (clk'event AND clk = '1') THEN
			IF (memwrite = '1') THEN
				ram_block(address) <= writedata;
			END IF;
		read_address_reg <= address;
		END IF;	
	END PROCESS;
	readdata <= ram_block(read_address_reg);


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
