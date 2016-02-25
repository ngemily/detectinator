`include "global.vh"

module top (
    input clk,
    input reset,
    input en,
    input [`PIXEL_SIZE:0] data,
    output [`PIXEL_SIZE:0] out
);
    assign out = {data[7:0], data[15:8], data[23:16]};
endmodule
