-- Group 7: Anas Deis, Albert Assouad, Barry Chen
-- Date: 16/4/2021

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.instruction_tools.all;

-- Stage 4 : Memory
entity Memory is
    generic(
		ram_size : integer := 8192;
		bit_width  : integer := 32
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
end Memory;

architecture behavioral of Memory is
begin
    -- propagate inputs
    instruction_out <= instruction_in;
    alu_out <= alu_in;

    mem_process : process(instruction_in, alu_in, rb_in, m_readdata)
    begin
        case instruction_in.INSTRUCTION_TYPE is
            when load_word =>
                m_read <= '1';
				memory_data <= m_readdata;
                m_addr <= to_integer(unsigned(alu_in(31 downto 0))) / 4;
            when store_word =>
                m_write <= '1';
				m_write_data <= rb_in;
                m_addr <= to_integer(unsigned(alu_in(31 downto 0))) / 4;
            when others =>
				null;
        end case;
    end process;
end behavioral;