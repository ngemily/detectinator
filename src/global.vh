`ifndef _global_vh_
`define _global_vh_

/**** Memory setup ****/
`define MEM_SIZE     'h10_0000

`define WORD_SIZE  8
`define MAX        255
`define MIN        0
`define PIXEL_SIZE 24
`define LOC_SIZE   32

// Maximum number of labels
`define LBL_WIDTH   14
`define MAX_LABEL   16383

// Data table parameters
`define NUM_FEATURES 10
`define OBJ_WIDTH    40
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
`define SIM_TIME 4_000_000

/**** IP logic ****/
`define SOBEL_THRESHOLD 8'd50
`define FLOOD_THRESHOLD 8'd5

/**** Output mode ****/
`define FLOOD2_BIT 7
`define PASS     0
`define GRAY     1
`define SOBEL    2
`define THRESH   3
`define FLOOD1   7
`define FLOOD2   8
`define CC       4
`define COLOR    5

// set output mode to one of the above modes 
`define OUT `COLOR

`endif
