library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

ENTITY alu_tb IS
END alu_tb;

ARCHITECTURE behav of alu_tb IS
	COMPONENT alu IS
		PORT(
			input_0 : in STD_LOGIC_VECTOR (31 downto 0);
			input_1 : in STD_LOGIC_VECTOR (31 downto 0);
			ALUop_in : in STD_LOGIC_VECTOR (4 downto 0);
			output : out STD_LOGIC_VECTOR(31 downto 0)
		);
	END COMPONENT;

	SIGNAL clock: STD_LOGIC := '0';
	CONSTANT clock_period : time := 1 ns;
	SIGNAL s_input_0, s_input_1, s_output : STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL s_ALUop_in : STD_LOGIC_VECTOR(4 downto 0);

BEGIN
	dut : alu
	PORT MAP(
		input_0 => s_input_0,
		input_1 => s_input_1,
		ALUop_in => s_ALUop_in,
		output => s_output
	);

	stim_process : PROCESS
	BEGIN
		clock <= '1';
		wait for clock_period/2;
		clock <= '0';
		wait for clock_period/2;
	END PROCESS;

	test_process : PROCESS
	BEGIN
		wait for clock_period;

		-- ADD
		s_input_0 <= "00000000000000000000000000000000";
		s_input_1 <= "00000000000000000000000000000001";
		s_ALUop_in <= "00001";
		wait for clock_period;

		--SUBTRACT
		s_input_0 <= "00000000000000000000000000000001";
		s_input_1 <= "00000000000000000000000000000001";
		s_ALUop_in <= "00010";
		wait for clock_period;

		--SLL
		s_input_0 <= "00000000000000000000000000001000";
		s_input_1 <= "00000000000000000000000010000000";
		s_ALUop_in <= "10010";
		wait for clock_period;
		
		--SRL
		s_input_0 <= "00000000000000000000000000100000";
		s_input_1 <= "00000000000000000000000010000000";
		s_ALUop_in <= "10011";
		wait for clock_period;
		
		--SLT
		s_input_0 <= "00000000000000000000000000100000";
		s_input_1 <= "00000000000000000000000000000010";
		s_ALUop_in <= "00110";
		wait for clock_period;
		
		--SLT
		s_input_0 <= "00000000000000000000000000000010";
		s_input_1 <= "00000000000000000000000001000000";
		s_ALUop_in <= "00110";
		wait for clock_period;
		
		--MUL1
		s_input_0 <= "00000000000000000000000000001000";
		s_input_1 <= "00000000000000000000000000100000";
		s_ALUop_in <= "00100";
		wait for clock_period;

		--MFHI
		s_ALUop_in <= "01111";
		wait for clock_period;

		--MFLO
		s_ALUop_in <= "10000";
		wait for clock_period;

		--MUL2
		s_input_0 <= "10000000000000000000000000000000";
		s_input_1 <= "00000000010000000000000000000000";
		s_ALUop_in <= "00100";
		wait for clock_period;

		--MFHI
		s_ALUop_in <= "01111";
		wait for clock_period;

		--MFLO
		s_ALUop_in <= "10000";
		wait for clock_period;

		--DIV1
		s_input_0 <= "00000000000000000000000000001000";
		s_input_1 <= "00000000000000000000000000000010";
		s_ALUop_in <= "00101";
		wait for clock_period;

		--MFHI
		s_ALUop_in <= "01111";
		wait for clock_period;

		--MFLO
		s_ALUop_in <= "10000";
		wait for clock_period;

		--DIV2
		s_input_0 <= "00000000000000000000000000001000";
		s_input_0 <= "00000000000000000000000000000011";
		s_ALUop_in <= "00101";
		wait for clock_period;

		--MFHI
		s_ALUop_in <= "01111";
		wait for clock_period;

		--MFLO
		s_ALUop_in <= "10000";
		wait for clock_period;

		WAIT;
	END PROCESS;
END behav;