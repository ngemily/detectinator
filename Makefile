sim_gui:
	vsim -do run_sim.do

sim:
	vsim -c -do run_sim.do

xxd:
	xxd -cols 12 -g 3 -s 0x0000008a out/out.bmp out/out.xxd
