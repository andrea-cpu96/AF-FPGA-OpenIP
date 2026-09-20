# ModelSim BATCH flow for the sync_2ff testbench
# Run from inside sim_sync_2ff/:  vsim -c -do sim_run.do
transcript file sim_transcript.log
onerror {quit -f}

# Always compile into a clean local library.
if {[file exists work/_info]} { vdel -lib work -all }
vlib work

vcom -quiet ../sync_2ff.vhd
vcom -quiet sync_2ff_tb.vhd

vsim -voptargs=+acc work.sync_2ff_tb
run -all
quit -f
