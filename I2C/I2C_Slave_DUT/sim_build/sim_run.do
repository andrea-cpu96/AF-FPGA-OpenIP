# ModelSim BATCH flow for the whole I2C_Slave_DUT TB suite:
#   * slave_dut_idle_tb     -- power-up / idle guard (no controller on the bus)
#   * slave_dut_sequence_tb -- the 0xAA command / 0xEE reply dialogue against the
#                              real I2C_Master acting as the external controller
# Run from inside sim_build/:  vsim -c -do sim_run.do
transcript file sim_transcript.log
onerror {quit -code 1 -f}
onbreak {quit -code 1 -f}

# Always compile into a clean local library. The DUT RTL lives one folder up
# (copies, so the project is self-contained); the external controller the
# sequence testbench uses is the I2C_Master from the sibling project.
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
vcom -quiet ../../I2C_Master/clock_div.vhd
vcom -quiet ../../I2C_Master/I2C_Master.vhd
vcom -quiet slave_dut_idle_tb.vhd
vcom -quiet slave_dut_sequence_tb.vhd

# 1) Idle guard: with nobody addressing it, the target must not touch the bus.
vsim -voptargs=+acc work.slave_dut_idle_tb
run 300 us
if {![examine /slave_dut_idle_tb/finished]} {
    echo "RESULT: FAIL -- idle test did not finish"
    quit -code 1 -f
}
quit -sim

# 2) The command/reply dialogue on the bus.
vsim -voptargs=+acc work.slave_dut_sequence_tb
run 4 ms
if {![examine /slave_dut_sequence_tb/finished]} {
    echo "RESULT: FAIL -- sequence test did not finish"
    quit -code 1 -f
}
quit -code 0 -f
