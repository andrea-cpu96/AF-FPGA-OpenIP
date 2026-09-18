# ModelSim batch flow for I2C_Master: write, public read-data,
# clock-stretching and multi-byte/repeated-START tests.
# Run from inside sim_i2c_master/: vsim -c -do sim_run.do
transcript file sim_transcript.log
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
vcom -quiet i2c_master_tb.vhd
vcom -quiet i2c_master_read_tb.vhd
vcom -quiet i2c_master_stretch_tb.vhd
vcom -quiet i2c_master_multibyte_tb.vhd
vcom -quiet i2c_master_stretch_multi_tb.vhd

vsim -voptargs=+acc work.i2c_master_tb
set BreakOnAssertion 2
run 250 us
quit -sim

vsim -voptargs=+acc work.i2c_master_read_tb
set BreakOnAssertion 2
run 1 ms
if {![examine /i2c_master_read_tb/finished]} {
    echo "RESULT: FAIL -- read test did not finish"
    quit -code 1 -f
}
quit -sim

vsim -voptargs=+acc work.i2c_master_stretch_tb
set BreakOnAssertion 2
run 1 ms
if {![examine /i2c_master_stretch_tb/finished]} {
    echo "RESULT: FAIL -- stretch test did not finish"
    quit -code 1 -f
}
quit -sim

vsim -voptargs=+acc work.i2c_master_multibyte_tb
set BreakOnAssertion 2
run 3 ms
if {![examine /i2c_master_multibyte_tb/finished]} {
    echo "RESULT: FAIL -- multibyte test did not finish"
    quit -code 1 -f
}
quit -sim

vsim -voptargs=+acc work.i2c_master_stretch_multi_tb
set BreakOnAssertion 2
run 3 ms
if {![examine /i2c_master_stretch_multi_tb/finished]} {
    echo "RESULT: FAIL -- Sr + multi-stretch test did not finish"
    quit -code 1 -f
}
quit -code 0 -f

