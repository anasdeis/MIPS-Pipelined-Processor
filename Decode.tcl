proc AddWaves {} {
	;#Add waves we're interested in to the Wave window
	 add wave -position end sim:/Decode_tb/clk
    add wave -position end sim:/Decode_tb/s_instruction
    add wave -position end sim:/Decode_tb/s_sel_ALU_mux0
    add wave -position end sim:/Decode_tb/s_sel_ALU_mux1
    add wave -position end sim:/Decode_tb/s_MemRead
	 add wave -position end sim:/Decode_tb/s_MemWrite
    add wave -position end sim:/Decode_tb/s_RegWrite
    add wave -position end sim:/Decode_tb/s_MemToReg
    add wave -position end sim:/Decode_tb/s_rd
    add wave -position end sim:/Decode_tb/s_rd_reg_data
	 add wave -position end sim:/Decode_tb/s_ALUOp
	 add wave -position end sim:/Decode_tb/s_write_file
	 add wave -position end sim:/Decode_tb/s_write_en
}

vlib work

;# Compile components if any
vcom Decode.vhd
vcom Decode_tb.vhd

;# Start simulation
vsim Decode_tb

;# Generate a clock with 1ns period
force -deposit clk 0 0 ns, 1 0.5 ns -repeat 1 ns

;# Add the waves
AddWaves

;# Run for 50 ns
run 50 ns