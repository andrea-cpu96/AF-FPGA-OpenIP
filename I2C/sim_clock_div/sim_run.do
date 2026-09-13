# ModelSim BATCH flow for the clock_div testbench
# Run from inside sim_clock_div/:  vsim -c -do sim_run.do
transcript file sim_transcript.log
onerror {quit -f}

# Always compile into a clean local library.
if {[file exists work/_info]} { vdel -lib work -all }
vlib work

vcom -quiet ../clock_div.vhd
vcom -quiet clock_div_tb.vhd

# Sweep the DUT generic: minimum (2), even (4) and odd (5) division.
foreach div {2 4 5} {
    vsim -gG_DIVIDER=$div -voptargs=+acc work.clock_div_tb
    run -all
}
quit -f