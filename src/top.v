`include "global.vh"

module top (
    input clk,
    input reset,
    input en,
    input [`PIXEL_SIZE:0] data,
    output [`PIXEL_SIZE:0] out
);
    assign out = data;
endmodule
