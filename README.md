Detectinator
============

About
-----
Hardware implementation of [opencv-object-detection][1] object detecting
software.

[1]: https://github.com/ngemily/opencv-object-detection

Quick Start
-----------
Run simulation in Modelsim.  The testbench reads a bitmap from `imgs/` (defined
in `src/global.vh` and writes the processed image to a bitmap in `out/`.  The
output should be readable by any image viewer.

    vsim -c -do run_sim.do

To pull up gui:

    vsim -do run_sim.do


Vivado Flow
-----------
Run through synthesis, implementation in Vivado.  Writes post-synth and
post-impl netlists.  A vivado project is created in the directory `viv/`.

    vivado -mode batch -source vivado.tcl

To pull up gui, run above command and

    vivado $(find . -type f -name '*.xpr')

Debugging
---------
Output a bitmap as hex, grouped by pixel
	xxd -cols 12 -g 3 -s 0x0000008a out.bmp out.xxd
