-- Group 7: Anas Deis, Albert Assouad, Barry Chen
-- Date: 16/4/2021

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;
use work.instruction_tools.all;

entity Branch_Predictor is
    generic(
        bit_width : integer := 2;
		counter : integer := 8
    );
    port(
		-- INPUTS
        clk : in std_logic;
        instruction_in : in INSTRUCTION;
		branch_taken_in : in std_logic;  -- update to branch taken
        branch_target_in : in std_logic_vector(31 downto 0); -- update branch target
        branch_target_next_in : in std_logic_vector(31 downto 0); -- evaluate next branch target
		
		-- OUTPUTS
        branch_prediction_out : out std_logic
    );
end Branch_Predictor;

architecture behavioral of Branch_Predictor is
	
	-- CONSTANTS
    constant min : integer := -(2**(bit_width - 1)); 
    constant max : integer :=   2**(bit_width - 1) - 1;
    
	-- SIGNALS
	signal present_value, next_value : integer range min to max;
    signal present_index, next_index : integer range 0 to counter-1;
	
	type branch_predictor_array is array (counter-1 downto 0) of integer range min to max;
    signal predictors : branch_predictor_array := (others => 0);

begin

    present_index <= to_integer(unsigned(branch_target_next_in(2 + bit_width-1 downto 2)));
	
	 -- branch taken if counter >= 0 or J,JR,JAL
	branch_prediction_out <= '1' when is_jump_type(instruction_in) else
							 'U' when not is_branch_type(instruction_in) else	
							 '1' when predictors(present_index) >= 0 else						 
							 '0';

    -- update next index set counter value in predictor 
    next_index <= to_integer(unsigned(branch_target_in(bit_width-1 downto 0)));
	predictors(next_index) <= next_value;
	
	-- update present value
	present_value <= predictors(next_index);
    
    update_process : process(clk, instruction_in, branch_target_in, branch_taken_in)
    begin
        next_value <= present_value; -- update next value
        if rising_edge(clk) then
            if is_branch_type(instruction_in) then
                if branch_taken_in = '1' then
                    next_value <= increment_predictor(present_value, max);
                else
                    next_value <= decrement_predictor(present_value, min);
                end if;
            end if;
        end if;
    end process;
end behavioral;

