do base.do

vsim work.tb
run 2 ms

mem save -o out/merge_table.mem -f mti -data hex -addr hex \
    -startaddress 0 -endaddress 255 -wordsperline 1 /tb/dut/U2/MERGE_TABLE/mem

mem save -o out/data_table.mem -f mti -data hex -addr hex \
    -startaddress 0 -endaddress 255 -wordsperline 1 /tb/dut/U2/DATA_TABLE/mem

run -all

exit
