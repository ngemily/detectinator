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
    input clk,
    input [`WORD_SIZE - 1:0] p1,
    input [`WORD_SIZE - 1:0] p2,
    input [`WORD_SIZE - 1:0] p3,
    input [`WORD_SIZE - 1:0] p4,
    input [`WORD_SIZE - 1:0] p5,
    input [`WORD_SIZE - 1:0] p6,
    input [`WORD_SIZE - 1:0] p7,
    input [`WORD_SIZE - 1:0] p8,
    input [`WORD_SIZE - 1:0] p9,
    output reg [`WORD_SIZE - 1:0] q
);
    wire signed [`WORD_SIZE - 1:0] dx;
    wire signed [`WORD_SIZE - 1:0] dy;
    wire [`WORD_SIZE - 1:0] abs_dx;
    wire [`WORD_SIZE - 1:0] abs_dy;

    assign dx = (3 * p1 + 10 * p4 + 3 * p7) - (3 * p3 + 10 * p6 + 3 * p9);
    assign dy = (3 * p1 + 10 * p2 + 3 * p3) - (3 * p7 + 10 * p8 + 3 * p9);
    assign abs_dx = (dx < 0) ? -dx : dx;
    assign abs_dy = (dy < 0) ? -dy : dy;

    always @(posedge clk) begin
        q <= abs_dx + abs_dy;
    end
endmodule

module flood_window(
    input clk,
    input p11,
    input p12,
    input p13,
    input p14,
    input p15,
    input p21,
    input p22,
    input p23,
    input p24,
    input p25,
    input p31,
    input p32,
    input p33,
    input p34,
    input p35,
    input [`WORD_SIZE - 1:0] threshold,
    output reg q
);
    wire [`WORD_SIZE - 1:0] sum;

    assign sum = p11 + p12 + p13 + p14 + p15 + p21 + p22 + p23 + p24 + p25 + p31
                + p32 + p33 + p34 + p35;


    always @(posedge clk) begin
        if (sum > threshold) begin
            q <= 1'b1;
        end else begin
            q <= 1'b0;
        end
    end

endmodule
