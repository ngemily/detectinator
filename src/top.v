`include "global.vh"

module top (
    input clk,
    input reset,
    input en,
    input [`PIXEL_SIZE - 1:0] data,
    output [`PIXEL_SIZE - 1:0] out
);
    wire [7:0] R = data[7:0];
    wire [7:0] G = data[15:8];
    wire [7:0] B = data[23:16];

    wire [7:0] I = 0.299 * R + 0.587 * G + 0.114 * B;

    assign out = {R, G, B};
endmodule
