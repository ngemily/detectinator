file mkdir out

vlib work

vlog src/top.v
vlog src/tb.sv

vsim -gui work.tb
run -all

exit
