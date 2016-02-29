OUTDIR=out
OBJ=$(OUTDIR)/out
BMP=$(OBJ).bmp
XXD=$(OBJ).xxd

all: sim

sim_gui:
	vsim -do run_sim.do

sim:
	vsim -c -do run_sim.do

xxd:
	xxd -cols 12 -g 3 -s 0x0000008a $(BMP) $(XXD)

test:
	xdg-open $(BMP)
