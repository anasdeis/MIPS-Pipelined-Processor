-- Entity: Execute
-- Authors: Anas Deis, Albert Assouad, Barry Chen
-- Date: 04/16/2021

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Stage 3 : Execute

entity Execute is
port (
    -- INPUTS
	
    -- From IF
    address_in : std_logic_vector(31 downto 0);
    
	 -- From ID
	sel_ALU_mux0_in : in std_logic;
	sel_ALU_mux1_in : in std_logic;
    ALUop_in : in std_logic_vector(4 downto 0);				-- ALU operation
    immediate_in : in std_logic_vector(31 downto 0);		-- immediate 
    read_data0_in : in std_logic_vector(31 downto 0);		-- rs data if shift is '0', otherwise same as read_data_2
    read_data1_in : in std_logic_vector(31 downto 0);		-- rt data

    -- OUTPUTS

    -- To ID
    control_flow_out : out std_logic := '0'; 	-- control flow operation

    -- To MEM
    alu_result_out : out std_logic_vector(31 downto 0) 		-- ALU output
);
end Execute;

architecture behavioral of Execute is

-- mux 
component mux is
port(
	input_0 : in std_logic_vector(31 downto 0);
	input_1 : in std_logic_vector(31 downto 0);
	selector : in std_logic;
	output : out std_logic_vector(31 downto 0)
); end component;
  
component alu is 
port (
    input_0 : in std_logic_vector(31 downto 0);
    input_1 : in std_logic_vector(31 downto 0);
    ALUop_in : in std_logic_vector(4 downto 0);
    output : out std_logic_vector(31 downto 0)
); end component;

signal mux_result_0 : std_logic_vector(31 downto 0);
signal mux_result_1 : std_logic_vector(31 downto 0);

begin 

	ex_mux_0 : mux 
	port map(
		selector => sel_ALU_mux0_in,
		input_0 => read_data0_in,
		input_1 => address_in,
		output => mux_result_0
	);	
		
	ex_mux_1 : mux 
	port map(
		selector => sel_ALU_mux1_in,
		input_0 => immediate_in,
		input_1 => read_data1_in,
		output => mux_result_1
	);	

	ex_alu : alu 
	port map(
		input_0 => mux_result_0,
		input_1 => mux_result_1,
		ALUop_in => ALUop_in,
		output => alu_result_out
	);
		
	control_flow: process (read_data0_in, read_data1_in, ALUop_in)
	begin
		case ALUop_in is
			-- BEQ
			when "10111" => 
				if unsigned(read_data0_in) = unsigned(read_data1_in) then
					control_flow_out <= '1';
				else
					control_flow_out <= '0';
				end if;
			-- BNE	
			when "11000" => 
				if unsigned(read_data0_in) = unsigned(read_data1_in) then
					control_flow_out <= '0';
				else
					control_flow_out <= '1';
				end if;
			-- J	
			when "11001" => 
				control_flow_out <= '1';
			-- JR
			when "11010" => 
				control_flow_out <= '1';
			-- JAL
			when "11011" => 
				control_flow_out <= '1';
				
			when others =>
				control_flow_out <= '0';
		end case;
	end process;
end behavioral;