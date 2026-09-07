# ModelSim BATCH flow for the P2S testbench
# Run from inside parallel_to_serial/:  vsim -c -do sim_run.do
transcript file sim_transcript.log
onerror {quit -f}

# Always compile into a clean local library.
if {[file exists work/_info]} { vdel -lib work -all }
vlib work

vcom -quiet parallel_to_serial.vhd
vcom -quiet parallel_to_serial_tb.vhd
vsim -voptargs=+acc work.tb_parallel_to_serial
run 10 us
quit -f