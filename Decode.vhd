-- Entity: Decode
-- Authors: Anas Deis, Albert Assouad, Barry Chen
-- Date: 04/16/2021

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

-- Stage 2: Decode
-- Takes output from IF/ID and send it to EX for calculations.
entity Decode is
port (
	clk: in std_logic;
	write_file_en: in std_logic;							    -- enable writing to file
	write_reg_en_in: in std_logic; 							 -- enable writing to registry file from WB stage
	rd_in: in std_logic_vector (4 downto 0);	 			 -- register destination from WB stage
	rd_reg_data_in : in std_logic_vector (31 downto 0); -- data to write back from WB stage
	instruction_in: in std_logic_vector (31 downto 0);  -- instruction from IF stage

	
	rs_reg_data_out: out std_logic_vector (31 downto 0);	-- data associated with the register index of rs (register source)
	rt_reg_data_out: out std_logic_vector (31 downto 0)	-- data associated with the register index of rt (register target)
  );
end Decode;

architecture behavioral of Decode is

type registers is array (0 to 31) of std_logic_vector(31 downto 0);	-- MIPS 32 32-bit registers
signal register_file: registers := (others => x"00000000"); 		   -- initialize all registers to 0, including R0

begin
	process (clk)
	
	variable rs : std_logic_vector(4 downto 0);	-- register source (rs)
	variable rt : std_logic_vector(4 downto 0);	-- register target (rt)

	begin
	
	rs := instruction_in(25 downto 21);	
	rt := instruction_in(20 downto 16);	
	
		if (clk'event and clk = '1') then
			rs_reg_data_out <= register_file(to_integer(unsigned(rs))); 
			rt_reg_data_out <= register_file(to_integer(unsigned(rt)));
			if (write_reg_en_in = '1') then 	-- update rd data if writing is enabled by WB stage
				if (to_integer(unsigned(rd_in)) /= 0) then 	-- only write to other than R0
					register_file(to_integer(unsigned(rd_in))) <= rd_reg_data_in; -- write rd data into the register index of rd				
				end if;
			end if;
		end if;
	end process;

	write_file: process(write_file_en)
	FILE fptr : text;
	variable file_line : line;	
	variable idx : integer := 0;
	
	begin
		if write_file_en = '1' then
			file_open(fptr,"register_file.txt.", write_mode);
			idx := 0;
			while (idx < 32) loop 
				write(file_line, register_file(idx));
				writeline(fptr, file_line);
				idx := idx + 1;
			end loop;
		end if;
		
		file_close(fptr);
		
	end process;
end behavioral;