proc AddWaves {} {
	;#Add waves we're interested in to the Wave window
	add wave -position end sim:/Pipelined_Processor_tb/clk
    add wave -position end sim:/Pipelined_Processor_tb/write_file
    add wave -position end sim:/Pipelined_Processor_tb/initialize
}

vlib work

;# Compile the needed components
vcom instruction/instruction.vhd 
vcom Instruction_Memory.vhd
vcom Fetch.vhd 
vcom Decode.vhd 
vcom Execute.vhd
vcom Memory.vhd 
vcom Write_Back.vhd 
vcom pipeline_registers/EX_MEM.vhd 
vcom pipeline_registers/ID_EX.vhd
vcom pipeline_registers/IF_ID.vhd 
vcom pipeline_registers/MEM_WB.vhd 
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