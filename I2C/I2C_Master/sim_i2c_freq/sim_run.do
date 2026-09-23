# ModelSim batch flow for the I2C_Master SCL-frequency (ceiling) check
# Run from inside sim_i2c_freq/:  vsim -c -do sim_run.do
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
vcom -quiet i2c_master_freq_tb.vhd

# Non-integer ratio: 50 MHz / 90 kHz must round the divider UP (556, not 555)
vsim -voptargs=+acc -gG_CLK_FREQ=50000000 -gG_I2C_FREQ=90000 work.i2c_master_freq_tb
run 500 us
if {![examine /i2c_master_freq_tb/finished]} {
    echo "RESULT: FAIL -- 90 kHz (non-integer ratio) config did not finish"
    quit -code 1 -f
}
quit -sim

# Exact ratio: 50 MHz / 100 kHz must give divider 500 (SCL exactly 100 kHz)
vsim -voptargs=+acc -gG_CLK_FREQ=50000000 -gG_I2C_FREQ=100000 work.i2c_master_freq_tb
run 500 us
if {![examine /i2c_master_freq_tb/finished]} {
    echo "RESULT: FAIL -- 100 kHz (exact ratio) config did not finish"
    quit -code 1 -f
}
quit -code 0 -f
