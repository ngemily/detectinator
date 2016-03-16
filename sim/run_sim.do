do base.do

vsim work.tb
run 2 ms

mem save -o out/merge_table.mem -f mti -data unsigned -addr hex \
    -startaddress 0 -endaddress 25 -wordsperline 1 /tb/dut/U2/MERGE_TABLE/mem

run -all

exit
