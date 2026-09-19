# ModelSim batch flow for the I2C_TX transmit testbench
# Run from inside sim_i2c_tx/:  vsim -c -do sim_run.do
transcript file sim_transcript.log
onerror {quit -f}

if {[file exists work/_info]} { vdel -lib work -all }
vlib work

vcom -quiet ../parallel_to_serial.vhd
vcom -quiet ../I2C_TX.vhd
vcom -quiet i2c_tx_tb.vhd

vsim -voptargs=+acc work.i2c_tx_tb
run 200 us
quit -f
