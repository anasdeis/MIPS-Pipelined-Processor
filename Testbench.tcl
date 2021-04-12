proc AddWaves {} {
	;#Add waves we're interested in to the Wave window
	add wave -position end sim:/Pipelined_Processor_tb/clk
   add wave -position end sim:/Pipelined_Processor_tb/s_writeToRegisterFile
   add wave -position end sim:/Pipelined_Processor_tb/s_writeToMemoryFile
	add wave -position end sim:/Pipelined_Processor_tb/IDEXStructuralStall
	add wave -position end sim:/Pipelined_Processor_tb/EXMEMStructuralStall
	add wave -position end sim:/Pipelined_Processor_tb/structuralStall
	add wave -position end sim:/Pipelined_Processor_tb/pcStall
	add wave -position end sim:/Pipelined_Processor_tb/address
	add wave -position end sim:/Pipelined_Processor_tb/instruction
	add wave -position end sim:/Pipelined_Processor_tb/IFIDaddress
	add wave -position end sim:/Pipelined_Processor_tb/IFIDinstruction
	add wave -position end sim:/Pipelined_Processor_tb/IDEXaddress
	add wave -position end sim:/Pipelined_Processor_tb/IDEXra
	add wave -position end sim:/Pipelined_Processor_tb/IDEXrb
	add wave -position end sim:/Pipelined_Processor_tb/IDEXimmediate
	add wave -position end sim:/Pipelined_Processor_tb/IDEXrd
	add wave -position end sim:/Pipelined_Processor_tb/IDEXALU1srcO
	add wave -position end sim:/Pipelined_Processor_tb/IDEXALU2srcO
	add wave -position end sim:/Pipelined_Processor_tb/IDEXMemReadO
	add wave -position end sim:/Pipelined_Processor_tb/IDEXMeMWriteO
	add wave -position end sim:/Pipelined_Processor_tb/IDEXRegWriteO
	add wave -position end sim:/Pipelined_Processor_tb/IDEXMemToRegO
	add wave -position end sim:/Pipelined_Processor_tb/IDEXAluOp
	add wave -position end sim:/Pipelined_Processor_tb/opcodeInput
	add wave -position end sim:/Pipelined_Processor_tb/functInput
	add wave -position end sim:/Pipelined_Processor_tb/ALU1srcO
	add wave -position end sim:/Pipelined_Processor_tb/ALU2srcO
	add wave -position end sim:/Pipelined_Processor_tb/MemReadO
	add wave -position end sim:/Pipelined_Processor_tb/MemWriteO
	add wave -position end sim:/Pipelined_Processor_tb/RegWriteO
	add wave -position end sim:/Pipelined_Processor_tb/MemToRegO
	add wave -position end sim:/Pipelined_Processor_tb/RType
	add wave -position end sim:/Pipelined_Processor_tb/Jtype
	add wave -position end sim:/Pipelined_Processor_tb/Shift
	add wave -position end sim:/Pipelined_Processor_tb/ALUOp
	add wave -position end sim:/Pipelined_Processor_tb/rs
	add wave -position end sim:/Pipelined_Processor_tb/rt
	add wave -position end sim:/Pipelined_Processor_tb/rd
	add wave -position end sim:/Pipelined_Processor_tb/WBrd
	add wave -position end sim:/Pipelined_Processor_tb/rd_data
	add wave -position end sim:/Pipelined_Processor_tb/write_enable
	add wave -position end sim:/Pipelined_Processor_tb/ra
	add wave -position end sim:/Pipelined_Processor_tb/rb
	add wave -position end sim:/Pipelined_Processor_tb/shamnt
	add wave -position end sim:/Pipelined_Processor_tb/immediate
	add wave -position end sim:/Pipelined_Processor_tb/immediate_out
	add wave -position end sim:/Pipelined_Processor_tb/muxOutput1
	add wave -position end sim:/Pipelined_Processor_tb/muxOutput2
	add wave -position end sim:/Pipelined_Processor_tb/aluOutput
	add wave -position end sim:/Pipelined_Processor_tb/zeroOutput
	add wave -position end sim:/Pipelined_Processor_tb/EXMEMBranch
	add wave -position end sim:/Pipelined_Processor_tb/ctrl_jal
	add wave -position end sim:/Pipelined_Processor_tb/EXMEMaluOutput
	add wave -position end sim:/Pipelined_Processor_tb/EXMEMregisterOutput
	add wave -position end sim:/Pipelined_Processor_tb/EXMEMrd
	add wave -position end sim:/Pipelined_Processor_tb/EXMEMMemReadO
	add wave -position end sim:/Pipelined_Processor_tb/EXMEMMeMWriteO
	add wave -position end sim:/Pipelined_Processor_tb/EXMEMRegWriteO
	add wave -position end sim:/Pipelined_Processor_tb/EXMEMMemToRegO
	add wave -position end sim:/Pipelined_Processor_tb/MEMWBmemOutput
	add wave -position end sim:/Pipelined_Processor_tb/MEMWBaluOutput
	add wave -position end sim:/Pipelined_Processor_tb/MEMWBrd
	add wave -position end sim:/Pipelined_Processor_tb/memtoReg
	add wave -position end sim:/Pipelined_Processor_tb/regWrite
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