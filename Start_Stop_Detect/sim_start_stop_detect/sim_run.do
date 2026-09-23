# ModelSim BATCH flow for the start_stop_detect testbench
# Run from inside sim_start_stop_detect/:  vsim -c -do sim_run.do
transcript file sim_transcript.log
onerror {quit -code 1 -f}
onbreak {quit -code 1 -f}

# Always compile into a clean local library.
if {[file exists work/_info]} { vdel -lib work -all }
vlib work

vcom -quiet ../start_stop_detect.vhd
vcom -quiet start_stop_detect_tb.vhd

vsim -voptargs=+acc work.start_stop_detect_tb
set BreakOnAssertion 2
run 100 us
if {![examine /start_stop_detect_tb/finished]} {
    echo "RESULT: FAIL -- start/stop detector test did not finish"
    quit -code 1 -f
}
quit -code 0 -f
