# ModelSim BATCH flow for the S2P testbench
# Run from inside serial_to_parallel/:  vsim -c -do sim_run.do
transcript file sim_transcript.log
onerror {quit -f}

# Always compile into a clean local library.
if {[file exists work/_info]} { vdel -lib work -all }
vlib work

vcom -quiet serial_to_parallel.vhd
vcom -quiet serial_to_parallel_tb.vhd
vsim -voptargs=+acc work.tb_serial_to_parallel
run 10 us
quit -f