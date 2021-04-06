library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
 
entity alu is
 Port ( 
 clk : in std_logic;
 in_a : in STD_LOGIC_VECTOR (31 downto 0);
 in_b : in STD_LOGIC_VECTOR (31 downto 0);
 instruction : in STD_LOGIC_VECTOR (4 downto 0); --there are 27 possible instructions therefore need 5 bits
 output : out STD_LOGIC_VECTOR(31 downto 0));
end alu;
 
architecture Behavioral of alu is

signal shift, hi, lo, product, quotient, remainder  : std_logic_vector (31 downto 0);

begin
process(in_a, in_b, instruction) 	
begin
case instruction is
 --CASE 1 ADD
 when "00000" =>
 output<= std_logic_vector(to_unsigned(to_integer (unsigned(in_a)) +   to_integer (unsigned(in_b)), output'length)) ; 
 
 --CASE 2 SUB
 when "00001" => 
 output<= std_logic_vector(to_unsigned(to_integer (unsigned(in_a)) -   to_integer (unsigned(in_b)), output'length)); 
 
 --CASE 3 ADDI
 when "00010" => 
  output<= std_logic_vector(to_unsigned(to_integer (unsigned(in_a)) +   to_integer (unsigned(in_b)), output'length)) ;
 
 --CASE 4 MULT
 when "00011" => 
 hi<= std_logic_vector(to_unsigned(to_integer (unsigned(in_a)) *   to_integer (unsigned(in_b)), 64))(63 downto 32);
 lo<= std_logic_vector(to_unsigned(to_integer (unsigned(in_a)) *   to_integer (unsigned(in_b)), 64))(31 downto 0);
 product <= std_logic_vector(to_unsigned(to_integer (unsigned(in_a)) *   to_integer (unsigned(in_b)), 32));
 output<= product;
 
 --CASE 5 DIV
 when "00100" =>  
 quotient <= std_logic_vector(to_unsigned(to_integer (unsigned(in_a)) /   to_integer (unsigned(in_b)), quotient'length));
 remainder <= std_logic_vector(to_unsigned(to_integer (unsigned(in_a)) mod to_integer (unsigned(in_b)), remainder'length));
 lo <= quotient;
 hi <= remainder;
 output <= quotient;

 --CASE 6 SLT
 when "00101" =>  
 if (unsigned(in_a) < unsigned(in_b)) then
	output <= x"00000001";
	else
	output <= x"00000000";
 end if;
 
 --CASE 7 SLT1
 when "00110" => 
  if (unsigned(in_a) < unsigned(in_b)) then
	output <= x"00000001";
	else
	output <= x"00000000";
 end if;
 
 --CASE 8 AND
 when "00111" => 
 output<= in_a and in_b;

 --CASE 9 OR
 when "01000" =>
 output<= in_a or in_b;

 --CASE 10 NOR
 when "01001" => 
 output<= in_a nor in_b;
 
 --CASE 11 XOR
 when "01010" =>
 output<= in_a xor in_b;

 --CASE 12 ANDI
 when "01011" =>
 output<= in_a and in_b;
 
 --CASE 13 ORI
 when "01100" =>
 output<= in_a or in_b;

 --CASE 14 XORI
 when "01101" => 
 output<= in_a xor in_b; 
 
 --CASE 15 MFHI
 when "01110" =>
 output<= hi;

 --CASE 16 MFLO
 when "01111" =>
 output<= lo;
 
 --CASE 17 LUI
 when "10000" =>
	output <= in_b (15 downto 0)  & std_logic_vector(to_unsigned(0, 16));
 
 --CASE 18 SLL
 when "10001" =>
	output <= in_a ((31 - to_integer(unsigned(in_b(10 downto 6)))) downto 0)  & std_logic_vector(to_unsigned(0, to_integer(unsigned(in_b(10 downto 6)))));

 --CASE 19 SRL
 when "10010" => 
	output <= std_logic_vector(to_unsigned(0, to_integer(unsigned(in_b(10 downto 6))))) & in_a (31 downto (0 + to_integer(unsigned(in_b(10 downto 6)))));

 --CASE 20 SRA
 when "10011" =>
	if in_a(31) = '0' then
		output <= std_logic_vector(to_unsigned(0, to_integer(unsigned(in_b(10 downto 6))))) & in_a (31 downto (0 + to_integer(unsigned(in_b(10 downto 6)))));
	else
		output <= std_logic_vector(to_unsigned(1, to_integer(unsigned(in_b(10 downto 6))))) & in_a (31 downto (0 + to_integer(unsigned(in_b(10 downto 6)))));
	end if;	
 
 --CASE 21 LW
 when "10100" =>
 output<= std_logic_vector(to_unsigned(to_integer (unsigned(in_a)) +   to_integer (unsigned(in_b)), output'length)) ; 
 
 --CASE 22 SW
 when "10101" =>
	output<= std_logic_vector(to_unsigned(to_integer (unsigned(in_a)) +   to_integer (unsigned(in_b)), output'length)) ; 
 
 --CASE 23 BEQ
 when "10110" =>
 output<= std_logic_vector(to_unsigned((to_integer (unsigned(in_a)) +   to_integer (unsigned(in_b)) * 4), output'length));
 
 --CASE 24 BNE
 when "10111" =>
 output<= std_logic_vector(to_unsigned((to_integer (unsigned(in_a)) +   to_integer (unsigned(in_b)) * 4), output'length));
 
 --CASE 25 J
 --when "11000" =>
 
 --CASE 26 JR
 --when "11001" =>
	
 --CASE 27 JAL
 --when "11010" =>
 
 when others =>
  NULL;
end case; 
  
end process; 
 
end Behavioral;
