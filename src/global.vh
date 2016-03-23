`ifndef _global_vh_
`define _global_vh_

/**** Memory setup ****/
`define MEM_SIZE 'h10_0000
`define C_TABLE_SIZE 255

`define WORD_SIZE 8
`define MAX 255
`define MIN 0
`define PIXEL_SIZE 24

/**** Input/output files ****/
`define IFILE "imgs/alien.bmp"
`define OFILE "out/out.bmp"
`define CFILE "src/colors.txt"

// input image size
`define FRAME_WIDTH 1280     //0x226
`define FRAME_HEIGHT 1

/**** IP logic ****/
// Sobel output threshold
`define THRESHOLD 50

/**** Output mode ****/
// one-hot encoded mode
`define SOBEL    0
`define THRESH   1
`define CC       2
`define COLOR    3

// set output mode to one of the above modes 
`define OUT `COLOR

`endif
