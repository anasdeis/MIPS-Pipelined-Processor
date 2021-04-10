proc AddWaves {} {
	;#Add waves we're interested in to the Wave window
	 add wave -position end sim:/alu_tb/clock
    add wave -position end sim:/alu_tb/s_input_0
    add wave -position end sim:/alu_tb/s_input_1
    add wave -position end sim:/alu_tb/s_ALUop_in
    add wave -position end sim:/alu_tb/s_output
}

vlib work

;# Compile components if any
vcom alu.vhd
vcom alu_tb.vhd

;# Start simulation
vsim alu_tb

;# Generate a clock with 1ns period
force -deposit clock 0 0 ns, 1 0.5 ns -repeat 1 ns

;# Add the waves
AddWaves

;# Run for 10000 ns
run 50 ns