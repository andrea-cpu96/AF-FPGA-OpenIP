# ModelSim BATCH flow for the debouncer testbench
# Run from inside sim_debouncer/:  vsim -c -do sim_run.do
transcript file sim_transcript.log
onerror {quit -f}

# Always compile into a clean local library.
if {[file exists work/_info]} { vdel -lib work -all }
vlib work

vcom -quiet ../debouncer.vhd
vcom -quiet debouncer_tb.vhd

# Sweep the DUT generics: minimum window, small window, wide + long window.
foreach {w n} {1 2  1 5  4 64} {
    vsim -gG_WIDTH=$w -gG_DEBOUNCE_CYCLES=$n -voptargs=+acc work.debouncer_tb
    run -all
}
quit -f
