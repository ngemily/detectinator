file mkdir out

vlib work

vlog src/location_generator.v
vlog viv/top_synth.vo

# Sobel
vlog +define+OUT="`CC" +define+IFILE="imgs/portal2.bmp" \
    +define+OFILE="out/post_syn_cc.bmp" +define+SIM_TIME=80_000_000 src/tb.sv
vsim -gui -L secureip -L unisims_ver work.tb work.glbl
run -all

exit
