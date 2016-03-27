`include "global.vh"

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

    assign dx = (3 * p1 + 10 * p4 + 3 * p7) - (3 * p3 + 10 * p6 + 3 * p9);
    assign dy = (3 * p1 + 10 * p2 + 3 * p3) - (3 * p7 + 10 * p8 + 3 * p9);
    assign abs_dx = (dx < 0) ? -dx : dx;
    assign abs_dy = (dy < 0) ? -dy : dy;

    assign q = abs_dx + abs_dy;
endmodule

module flood_window(
    input [`WORD_SIZE - 1:0] p11,
    input [`WORD_SIZE - 1:0] p12,
    input [`WORD_SIZE - 1:0] p13,
    input [`WORD_SIZE - 1:0] p14,
    input [`WORD_SIZE - 1:0] p15,
    input [`WORD_SIZE - 1:0] p21,
    input [`WORD_SIZE - 1:0] p22,
    input [`WORD_SIZE - 1:0] p23,
    input [`WORD_SIZE - 1:0] p24,
    input [`WORD_SIZE - 1:0] p25,
    input [`WORD_SIZE - 1:0] p31,
    input [`WORD_SIZE - 1:0] p32,
    input [`WORD_SIZE - 1:0] p33,
    input [`WORD_SIZE - 1:0] p34,
    input [`WORD_SIZE - 1:0] p35,
    input [`WORD_SIZE - 1:0] threshold,
    output [`WORD_SIZE - 1:0] q
);
    wire [`WORD_SIZE - 1:0] sum;

    wire b11, b12, b13, b14, b15;
    wire b21, b22, b23, b24, b25;
    wire b31, b32, b33, b34, b35;

    assign b11 = p11 ? 1 : 0;
    assign b12 = p12 ? 1 : 0;
    assign b13 = p13 ? 1 : 0;
    assign b14 = p14 ? 1 : 0;
    assign b15 = p15 ? 1 : 0;
    assign b21 = p21 ? 1 : 0;
    assign b22 = p22 ? 1 : 0;
    assign b23 = p23 ? 1 : 0;
    assign b24 = p24 ? 1 : 0;
    assign b25 = p25 ? 1 : 0;
    assign b31 = p31 ? 1 : 0;
    assign b32 = p32 ? 1 : 0;
    assign b33 = p33 ? 1 : 0;
    assign b34 = p34 ? 1 : 0;
    assign b35 = p35 ? 1 : 0;

    assign sum = b11 + b12 + b13 + b14 + b15 + b21 + b22 + b23 + b24 + b25 + b31
                + b32 + b33 + b34 + b35;

    assign q = sum > threshold ? `MAX : 0;

endmodule
