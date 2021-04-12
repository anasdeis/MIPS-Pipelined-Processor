  
library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Decode_tb is
end Decode_tb;

architecture behavioral of Decode_tb is

component Decode is
port(	 
	clk : in std_logic;
	instruction_in : in std_logic_vector (31 downto 0); 
	write_file_en : in std_logic;						
	write_en_in : in std_logic := '1'; 					
	rd_in : in std_logic_vector (4 downto 0);	 		 
	rd_reg_data_in : in std_logic_vector (31 downto 0);  
	rs_reg_data_out : out std_logic_vector (31 downto 0);
	rt_reg_data_out : out std_logic_vector (31 downto 0); 
	R_Type_out : out std_logic; 
	J_Type_out : out std_logic; 
	shift_out  : out std_logic; 
	MemRead_out  : out std_logic; 
	MemWrite_out : out std_logic; 
	MemToReg_out   : out std_logic;	
	RegWrite_out : out std_logic; 
	structural_hazard_out : out std_logic; 
	branch_in             : in std_logic := '0'; 
	old_branch_in      : in std_logic := '0';
	ALUOp_out : out std_logic_vector(4 downto 0);
	sel_ALU_mux0_out : out std_logic; 
	sel_ALU_mux1_out : out std_logic; 
	immediate_out: out std_logic_vector (31 downto 0) 
);
end component;

constant clk_period : time := 1 ns;

signal clk : std_logic := '0';
signal s_sel_ALU_mux0, s_sel_ALU_mux1, s_MemRead, s_MemWrite, s_RegWrite, s_MemToReg, s_write_file, s_write_en : std_logic;
signal s_ALUOp, s_rd : std_logic_vector(4 downto 0);
signal s_instruction, s_rd_reg_data : std_logic_vector(31 downto 0);

begin

	dut : Decode 
	port map(
		clk => clk,
		write_file_en => s_write_file,
		write_en_in => s_write_en,
		instruction_in => s_instruction,
		sel_ALU_mux0_out => s_sel_ALU_mux0,
		sel_ALU_mux1_out => s_sel_ALU_mux1,
		MemRead_out => s_MemRead,
		MemWrite_out => s_MemWrite,
		RegWrite_out => s_RegWrite,
		MemToReg_out => s_MemToReg,
		rd_in => s_rd,
		rd_reg_data_in => s_rd_reg_data,
		ALUOp_out => s_ALUOp 
	);

	stim_process : process
   begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

	test_process : process	
	begin
	   s_write_file <= '0';
		s_write_en <= '1';
      wait for clk_period;
		s_rd <= "00100";
		s_rd_reg_data <= x"00000001";
		s_instruction <= "00100000001000010000000000000001";
		wait for 15*clk_period;
		s_rd <= "00010";
		s_rd_reg_data <= x"00000111";
		s_instruction <= "00010001011010111111111111111111";
		wait for 15*clk_period;
		s_write_file <= '1';
		
		wait;
		
	end process;
end behavioral;