file mkdir out

vlib work

vlog viv/top_synth.vo

# Sobel
vlog +define+OUT="`SOBEL" +define+IFILE="imgs/alien.bmp" +define+OFILE="out/post_syn_sobel.bmp" src/tb.sv
vsim -gui -L secureip -L unisims_ver work.tb work.glbl
run -all

# FLOOD
restart
vlog +define+OUT="`FLOOD" +define+IFILE="imgs/alien.bmp" +define+OFILE="out/post_syn_flood.bmp" src/tb.sv
vsim -gui -L secureip -L unisims_ver work.tb work.glbl
run -all

# CC
restart
vlog +define+OUT="`CC" +define+IFILE="imgs/alien.bmp" +define+OFILE="out/post_syn_cc.bmp" src/tb.sv
vsim -gui -L secureip -L unisims_ver work.tb work.glbl
run -all

exit
