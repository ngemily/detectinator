file mkdir out

vlib work

vlog src/top.v
vlog src/tb.sv

vsim -gui tb
run -all

exit
