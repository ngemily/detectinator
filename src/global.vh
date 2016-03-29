`ifndef _global_vh_
`define _global_vh_

/**** Memory setup ****/
`define MEM_SIZE     'h10_0000
`define C_TABLE_SIZE 255

`define WORD_SIZE  8
`define MAX        255
`define MIN        0
`define PIXEL_SIZE 24
`define LOC_SIZE   24

// Data table parameters
`define NUM_FEATURES 3
`define OBJ_WIDTH    24
`define D_WIDTH      (`NUM_FEATURES * `OBJ_WIDTH)

/**** Input/output files ****/
`define IFILE       "imgs/alien.bmp"
`define OFILE       "out/out.bmp"
`define SYNTH_CFILE "colors.dat"
`define SIM_CFILE   "src/colors.dat"

// input image size
`define FRAME_WIDTH  1280
`define FRAME_HEIGHT 1

/**** Testbench setup ****/
`define DISP_RESOLVED_LABEL

/**** IP logic ****/
`define SOBEL_THRESHOLD 8'd50
`define FLOOD_THRESHOLD 8'd3

/**** Output mode ****/
`define PASS     0
`define GRAY     1
`define SOBEL    2
`define FLOOD    7
`define THRESH   3
`define CC       4
`define COLOR    5

// set output mode to one of the above modes 
`define OUT `COLOR

`endif
