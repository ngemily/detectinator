`include "global.vh"

`define THRESHOLD 150
`define MAX 255
`define MIN 0

module top #(
    parameter width = 1,
    parameter height = 1
) (
    input clk,
    input reset,
    input en,
    input hsync,
    input vsync,
    input [`PIXEL_SIZE - 1:0] data,
    output [`PIXEL_SIZE - 1:0] out
);
    wire [7:0] R = data[7:0];
    wire [7:0] G = data[15:8];
    wire [7:0] B = data[23:16];

    // Calculate grayscale intensity
    // I = 0.299 * R + 0.587 * G + 0.114 * B;
    wire [7:0] I = (R >> 2) + (R >> 5)
                    + (G >> 1) + (G >> 4)
                    + (B >> 4) + (B >> 5);

    // Keep three buffers, for the last three rows.
    reg [`WORD_SIZE - 1:0] buf2 [1024:0];
    reg [`WORD_SIZE - 1:0] buf1 [1024:0];
    reg [`WORD_SIZE - 1:0] buf0 [1024:0];

    // Intermediate stages of output
    wire [`WORD_SIZE - 1:0] window_out;
    wire [`WORD_SIZE - 1:0] threshold_out;

    integer i;

    // Shift in one pixel every clock cycle.
    always @(posedge clk) begin
        buf0[0] <= I;
        buf1[0] <= buf0[width - 1];
        buf2[0] <= buf1[width - 1];
        for(i = 1; i < width; i = i + 1) begin
            buf2[i] <= buf2[i - 1];
            buf1[i] <= buf1[i - 1];
            buf0[i] <= buf0[i - 1];
        end
    end

    // Perform Sobel on a sliding window
    //
    // ***----------        <buf2>
    // ***----------        <buf1>
    // ***                  <buf0>
    sobel_window U0 (
        .p1(buf2[width - 1]),
        .p2(buf2[width - 2]),
        .p3(buf2[width - 3]),
        .p4(buf1[width - 1]),
        .p5(buf1[width - 2]),
        .p6(buf1[width - 3]),
        .p7(buf0[width - 1]),
        .p8(buf0[width - 2]),
        .p9(buf0[width - 3]),
        .q(window_out)
    );

    assign threshold_out = (window_out > `THRESHOLD) ? `MAX : `MIN;
    assign out = {3{threshold_out}};

endmodule

/**
* Perform Sobel operator on this 3x3 window.
*
* Use the approximation grad f = |dx| + |dy| instead of sqrt(dx ^ 2 + dy ^ 2) to
* avoid square root calculation.
*
* Expected pixel (p1-p9) layout:
*   +---+---+---+
*   | 1 | 2 | 3 |
*   +---+---+---+
*   | 4 | 5 | 6 |
*   +---+---+---+
*   | 7 | 8 | 9 |
*   +---+---+---+
*/
module sobel_window(
    input [`WORD_SIZE - 1:0] p1,
    input [`WORD_SIZE - 1:0] p2,
    input [`WORD_SIZE - 1:0] p3,
    input [`WORD_SIZE - 1:0] p4,
    input [`WORD_SIZE - 1:0] p5,
    input [`WORD_SIZE - 1:0] p6,
    input [`WORD_SIZE - 1:0] p7,
    input [`WORD_SIZE - 1:0] p8,
    input [`WORD_SIZE - 1:0] p9,
    output [`WORD_SIZE - 1:0] q
);
    wire signed [`WORD_SIZE - 1:0] dx;
    wire signed [`WORD_SIZE - 1:0] dy;
    wire [`WORD_SIZE - 1:0] abs_dx;
    wire [`WORD_SIZE - 1:0] abs_dy;

    assign dx = (p1 + 2 * p4 + p7) - (p3 + 2 * p6 + p9);
    assign dy = (p1 + 2 * p2 + p3) - (p7 + 2 * p8 + p9);
    assign abs_dx = (dx < 0) ? -dx : dx;
    assign abs_dy = (dy < 0) ? -dy : dy;

    assign q = abs_dx + abs_dy;
endmodule
