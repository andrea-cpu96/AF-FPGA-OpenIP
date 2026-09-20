# ModelSim batch flow for the I2C_DUT command/confirm sequence test.
# Run from inside sim_build/: vsim -c -do sequence_run.do
transcript file sequence_transcript.log
onerror {quit -code 1 -f}
onbreak {quit -code 1 -f}

if {[file exists work/_info]} { vdel -lib work -all }
vlib work

vcom -quiet ../clock_div.vhd
vcom -quiet ../parallel_to_serial.vhd
vcom -quiet ../serial_to_parallel.vhd
vcom -quiet ../I2C_TX.vhd
vcom -quiet ../I2C_RX.vhd
vcom -quiet ../I2C_Master.vhd
vcom -quiet ../I2C_DUT.vhd
vcom -quiet dut_sequence_tb.vhd

vsim -voptargs=+acc work.dut_sequence_tb
run 3 ms
quit -code 0 -f