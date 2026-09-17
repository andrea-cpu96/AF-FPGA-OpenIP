# ModelSim BATCH flow for the UART S2P testbench (sweeps LSB-first and MSB-first)
# Run from inside UART/sim_serial_to_parallel/:  vsim -c -do sim_run.do
transcript file sim_transcript.log
onerror {quit -f}

# Always compile into a clean local library.
if {[file exists work/_info]} { vdel -lib work -all }
vlib work

vcom -quiet ../serial_to_parallel.vhd
vcom -quiet serial_to_parallel_tb.vhd

# LSB-first (UART behaviour, default)
vsim -voptargs=+acc work.tb_serial_to_parallel -gG_MSB_FIRST=false
run 10 us

# MSB-first (I2C behaviour)
vsim -voptargs=+acc work.tb_serial_to_parallel -gG_MSB_FIRST=true
run 10 us

quit -f