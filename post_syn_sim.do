file mkdir out

vlib work

vlog viv/top_synth.vo
vlog src/tb.sv

vsim -gui -L secureip -L unisims_ver work.tb work.glbl
run -all

exit
