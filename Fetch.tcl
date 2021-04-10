proc AddWaves {} {
	;#Add waves we're interested in to the Wave window
	 add wave -position end sim:/Fetch_tb/clk
    add wave -position end sim:/Fetch_tb/s_mux
    add wave -position end sim:/Fetch_tb/s_SEL
    add wave -position end sim:/Fetch_tb/s_address_output
    add wave -position end sim:/Fetch_tb/s_instruction
}

vlib work

;# Compile components if any
vcom Fetch.vhd
vcom Fetch_tb.vhd

;# Start simulation
vsim Fetch_tb

;# Generate a clock with 1ns period
force -deposit clk 0 0 ns, 1 0.5 ns -repeat 1 ns

;# Add the waves
AddWaves

;# Run for 20 ns
run 20 ns