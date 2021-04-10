proc AddWaves {} {
	;#Add waves we're interested in to the Wave window
	add wave -position end sim:/Pipelined_Processor_tb/clk
    add wave -position end sim:/Pipelined_Processor_tb/s_writeToRegisterFile
    add wave -position end sim:/Pipelined_Processor_tb/s_writeToMemoryFile
}

vlib work

;# Compile components if any
vcom adder.vhd
vcom alu.vhd
vcom Decode.vhd
vcom Execute.vhd
vcom Fetch.vhd
vcom Instruction_Memory.vhd
vcom mem_file.vhd
vcom Memory.vhd
vcom mux.vhd
vcom Pipelined_Processor.vhd
vcom Pipelined_Processor_tb.vhd
vcom Write_Back.vhd

;# Start simulation
vsim Pipelined_Processor_tb

;# Generate a clock with 1ns period
force -deposit clk 0 0 ns, 1 0.5 ns -repeat 1 ns

;# Add the waves
AddWaves

;# Run for 10000 ns
run 10000 ns