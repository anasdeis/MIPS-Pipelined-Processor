-- Entity: alu
-- Authors: Anas Deis, Albert Assouad, Barry Chen
-- Date: 04/16/2021

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
 
entity alu is
port (
	clk : in std_logic;
	input_0 : in std_logic_vector(31 downto 0); -- rs
	input_1 : in std_logic_vector(31 downto 0); -- rt
	ALUop_in : in std_logic_vector(4 downto 0); -- there are 27 possible ALU operations, therefore need 5 bits
	output : out std_logic_vector(31 downto 0)  -- rd
);
end alu;
 
architecture behavioral of alu is
begin

	compute: process(input_0, input_1, ALUop_in)
	
	variable product, quotient, remainder, hi, lo : std_logic_vector(31 downto 0);
	variable shamnt : INTEGER := 0;
	
	begin
	
		shamnt := to_integer(unsigned(input_1(10 downto 6))); -- shift amount

		case ALUop_in is
		
		-- Arithmetic
		
		--CASE 1 ADD
		when "00001" =>
			output <= input_0 + input_1; 
		 
		--CASE 2 SUB
		when "00010" => 
			output <= input_0 - input_1; 
		 
		--CASE 3 ADDI
		when "00011" => 
			output <= input_0 + input_1;
		 
		--CASE 4 MULT
		when "00100" => 
			 hi := std_logic_vector(to_unsigned(to_integer(unsigned(input_0)) * to_integer(unsigned(input_1)), 64))(63 downto 32);
			 lo := std_logic_vector(to_unsigned(to_integer(unsigned(input_0)) * to_integer(unsigned(input_1)), 64))(31 downto 0);
			 product := std_logic_vector(to_unsigned(to_integer(unsigned(input_0)) * to_integer(unsigned(input_1)), product'length));
			 output <= product;
		 
		--CASE 5 DIV
		when "00101" =>  
			 quotient := std_logic_vector(to_unsigned(to_integer(unsigned(input_0)) / to_integer(unsigned(input_1)), quotient'length));
			 remainder := std_logic_vector(to_unsigned(to_integer(unsigned(input_0)) mod to_integer(unsigned(input_1)), remainder'length));
			 lo := quotient;
			 hi := remainder;
			 output <= quotient;

		--CASE 6 SLT
		when "00110" =>  
			 if (input_0 < input_1) then
				output <= x"00000001";
				else
				output <= x"00000000";
			 end if;
		 
		--CASE 7 SLTI
		when "00111" => 
			if (input_0 < input_1) then
				output <= x"00000001";
			else
				output <= x"00000000";
			end if;
		 
		 -- Logical
		 
		--CASE 8 AND
		when "01000" => 
			output <= input_0 and input_1;

		--CASE 9 OR
		when "01001" =>
			output <= input_0 or input_1;

		--CASE 10 NOR
		when "01010" => 
			output <= input_0 nor input_1;

		--CASE 11 XOR
		when "01011" =>
			output <= input_0 xor input_1;

		--CASE 12 ANDI
		when "01100" =>
			output <= input_0 and input_1;

		--CASE 13 ORI
		when "01101" =>
			output <= input_0 or input_1;

		--CASE 14 XORI
		when "01110" => 
			output <= input_0 xor input_1; 

		-- Transfer

		--CASE 15 MFHI
		when "01111" =>
			output <= hi;

		--CASE 16 MFLO
		when "10000" =>
			output <= lo;

		--CASE 17 LUI
		when "10001" =>
			output <= input_1(15 downto 0) & std_logic_vector(to_unsigned(0, 16));

		-- Shift
		
		-- SLL
		when "10010" => 
			output <= std_logic_vector(shift_left(unsigned(input_0), shamnt));
			
		-- SRL
		when "10011" => 
			output <= std_logic_vector(shift_right(unsigned(input_0), shamnt));
		
		-- SRA
		when "10100" => 
			output <= std_logic_vector(shift_right(signed(input_0), shamnt));

		-- Memory

		--CASE 21 LW
		when "10101" =>
			output <= input_0 + input_1; 

		--CASE 22 SW
		when "10110" =>
			output <= input_0 + input_1;

		-- Control-flow

		--CASE 23 BEQ
		when "10111" =>
			output <= std_logic_vector(to_unsigned((to_integer(unsigned(input_0)) + to_integer(unsigned(input_1)) * 4), output'length));

		--CASE 24 BNE
		when "11000" =>
			output <= std_logic_vector(to_unsigned((to_integer(unsigned(input_0)) + to_integer(unsigned(input_1)) * 4), output'length));

		--CASE 25 J
		when "11001" =>
			output <= input_0(31 downto 28) & input_1(25 downto 0) & "00";
			
		--CASE 26 JR
		when "11010" =>
			output <= input_0;

		--CASE 27 JAL
		when "11011" =>
			output<= input_0(31 downto 28) & input_1(25 downto 0) & "00";

		when others =>
			NULL;
		  
		end case; 
	end process;
end behavioral;