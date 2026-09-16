# ModelSim batch flow for the I2C_RX receive testbench
# Run from inside sim_i2c_rx/:  vsim -c -do sim_run.do
transcript file sim_transcript.log
onerror {quit -f}

if {[file exists work/_info]} { vdel -lib work -all }
vlib work

vcom -quiet ../serial_to_parallel.vhd
vcom -quiet ../I2C_RX.vhd
vcom -quiet i2c_rx_tb.vhd

vsim -voptargs=+acc work.i2c_rx_tb
run 20 us
quit -f
