proc AddWaves {} {
	;#Add waves we're interested in to the Wave window
	add wave -position end sim:/fib_performance_tb/clk
    	add wave -position end sim:/fib_performance_tb/write_file
    	add wave -position end sim:/fib_performance_tb/initialize
	add wave -position end sim:/fib_performance_tb/register_file
}

vlib work

;# Compile the needed components
vcom definitions.vhd 
vcom Instruction_Memory.vhd
vcom Fetch.vhd 
vcom IF_ID.vhd 
vcom Decode.vhd 
vcom ID_EX.vhd
vcom Execute.vhd
vcom EX_MEM.vhd 
vcom Memory.vhd 
vcom MEM_WB.vhd 
vcom Write_Back.vhd 
vcom Pipelined_Processor.vhd 
vcom fib_performance_tb.vhd

;# Start simulation
vsim fib_performance_tb

;# Generate a clock with 1ns period
force -deposit clk 0 0 ns, 1 0.5 ns -repeat 1 ns

;# Add the waves
AddWaves

;# Run for 10000 ns
run 10000 ns