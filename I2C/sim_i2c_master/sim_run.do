# ModelSim batch flow for the I2C_Master write/TX testbench
# Run from inside sim_i2c_master/:  vsim -c -do sim_run.do
transcript file sim_transcript.log
onerror {quit -f}

if {[file exists work/_info]} { vdel -lib work -all }
vlib work

vcom -quiet ../clock_div.vhd
vcom -quiet ../parallel_to_serial.vhd
vcom -quiet ../I2C_TX.vhd
vcom -quiet ../I2C_Master.vhd
vcom -quiet i2c_master_tb.vhd

vsim -voptargs=+acc work.i2c_master_tb
run 250 us
quit -f
