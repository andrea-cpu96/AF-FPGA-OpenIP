# ModelSim BATCH flow for the two I2C_Slave testbenches
#   * i2c_slave_tb        -- standalone slave, scripted open-drain master BFM
#   * i2c_slave_master_tb -- the real I2C_Master driving the slave on one bus
# Run from inside sim_i2c_slave/:  vsim -c -do sim_run.do
transcript file sim_transcript.log
onerror {quit -code 1 -f}
onbreak {quit -code 1 -f}

# Always compile into a clean local library. The slave RTL lives one folder up;
# the controller the integration testbench uses is in the I2C_Master/ subfolder,
# two folders up (../../I2C_Master/I2C_Master.vhd).
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
vcom -quiet ../../clock_div.vhd
vcom -quiet ../../I2C_Master/I2C_Master.vhd
vcom -quiet i2c_slave_tb.vhd
vcom -quiet i2c_slave_master_tb.vhd

# Standalone slave tests: clock stretching enabled (500 clk = 10 us) and
# compiled out (0). Both sweep the DUT generic.
foreach n {500 0} {
    vsim -gG_STRETCH_CYCLES=$n -voptargs=+acc work.i2c_slave_tb
    set BreakOnAssertion 2
    run 3 ms
    if {![examine /i2c_slave_tb/finished]} {
        echo "RESULT: FAIL -- slave test did not finish (G_STRETCH_CYCLES=$n)"
        quit -code 1 -f
    }
    quit -sim
}

# Integration: the real controller drives the slave, stretching enabled.
vsim -voptargs=+acc work.i2c_slave_master_tb
set BreakOnAssertion 2
run 4 ms
if {![examine /i2c_slave_master_tb/finished]} {
    echo "RESULT: FAIL -- master/slave integration test did not finish"
    quit -code 1 -f
}
quit -code 0 -f
