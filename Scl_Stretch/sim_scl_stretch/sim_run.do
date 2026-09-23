# ModelSim BATCH flow for the scl_stretch testbench
# Run from inside sim_scl_stretch/:  vsim -c -do sim_run.do
transcript file sim_transcript.log
onerror {quit -code 1 -f}
onbreak {quit -code 1 -f}

# Always compile into a clean local library.
if {[file exists work/_info]} { vdel -lib work -all }
vlib work

vcom -quiet ../scl_stretch.vhd
vcom -quiet scl_stretch_tb.vhd

# Sweep the DUT generic: feature off (0), minimum hold (1), a short hold (4)
# and the default hold the I2C slave uses (500).
foreach n {0 1 4 500} {
    vsim -gG_STRETCH_CYCLES=$n -voptargs=+acc work.scl_stretch_tb
    set BreakOnAssertion 2
    run 200 us
    if {![examine /scl_stretch_tb/finished]} {
        echo "RESULT: FAIL -- stretch test did not finish (G_STRETCH_CYCLES=$n)"
        quit -code 1 -f
    }
    quit -sim
}
quit -code 0 -f
