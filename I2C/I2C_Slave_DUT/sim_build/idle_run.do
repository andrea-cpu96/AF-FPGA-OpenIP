# ModelSim batch flow for the I2C_Slave_DUT power-up / idle guard.
# Run from inside sim_build/: vsim -c -do idle_run.do
transcript file transcript_idle.log
onerror {quit -code 1 -f}
onbreak {quit -code 1 -f}

if {[file exists work/_info]} { vdel -lib work -all }
vlib work

vcom -quiet ../sync_2ff.vhd
vcom -quiet ../parallel_to_serial.vhd
vcom -quiet ../serial_to_parallel.vhd
vcom -quiet ../I2C_TX.vhd
vcom -quiet ../I2C_RX.vhd
vcom -quiet ../start_stop_detect.vhd
vcom -quiet ../scl_stretch.vhd
vcom -quiet ../I2C_Slave.vhd
vcom -quiet ../I2C_Slave_DUT.vhd
vcom -quiet slave_dut_idle_tb.vhd

vsim -voptargs=+acc work.slave_dut_idle_tb
run 300 us
quit -code 0 -f
