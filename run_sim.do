file mkdir out

vlib work

vlog src/top.v
vlog src/tb.sv

vsim -gui -L secureip -L unisims_ver work.tb work.glbl
run -all

exit
