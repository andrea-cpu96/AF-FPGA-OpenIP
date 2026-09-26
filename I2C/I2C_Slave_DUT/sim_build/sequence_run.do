# ModelSim batch flow for the I2C_Slave_DUT command/reply sequence test.
# Run from inside sim_build/: vsim -c -do sequence_run.do
transcript file transcript_sequence.log
onerror {quit -code 1 -f}
onbreak {quit -code 1 -f}

if {[file exists work/_info]} { vdel -lib work -all }
vlib work

# The DUT RTL lives one folder up (copies, so the project is self-contained);
# the EXTERNAL controller this testbench drives the DUT with is the real
# I2C_Master from the sibling project, exactly like its own integration TB does.
vcom -quiet ../sync_2ff.vhd
vcom -quiet ../parallel_to_serial.vhd
vcom -quiet ../serial_to_parallel.vhd
vcom -quiet ../I2C_TX.vhd
vcom -quiet ../I2C_RX.vhd
vcom -quiet ../start_stop_detect.vhd
vcom -quiet ../scl_stretch.vhd
vcom -quiet ../I2C_Slave.vhd
vcom -quiet ../I2C_Slave_DUT.vhd
vcom -quiet ../../I2C_Master/clock_div.vhd
vcom -quiet ../../I2C_Master/I2C_Master.vhd
vcom -quiet slave_dut_sequence_tb.vhd

vsim -voptargs=+acc work.slave_dut_sequence_tb
run 4 ms
quit -code 0 -f
