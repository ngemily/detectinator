file mkdir out

vlib work

vlog src/top.v
vlog src/tb.sv

vsim -gui work.tb
run 2 ms

mem save -o merge_table.mem -f mti -data unsigned -addr hex -startaddress 0 \
    -endaddress 25 -wordsperline 1 /tb/dut/U2/merge_table

run -all

exit
