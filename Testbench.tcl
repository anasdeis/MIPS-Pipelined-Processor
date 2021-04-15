proc AddWaves {} {
	;#Add waves we're interested in to the Wave window
	add wave -position end sim:/Pipelined_Processor_tb/clk
	add wave -position end sim:/Pipelined_Processor_tb/initialize
    	add wave -position end sim:/Pipelined_Processor_tb/write_file
	add wave -position end sim:/Pipelined_Processor_tb/register_file
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
vcom Pipelined_Processor_tb.vhd 

;# Start simulation
vsim Pipelined_Processor_tb

;# Generate a clock with 1ns period
force -deposit clk 0 0 ns, 1 0.5 ns -repeat 1 ns

;# Add the waves
AddWaves

;# Run for 10000 ns
run 10000 ns