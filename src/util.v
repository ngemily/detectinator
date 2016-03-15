`include "global.vh"

/**
* Perform binary threshold, like a step function u(t).
*/
module threshold #(
    parameter WIDTH = `WORD_SIZE,
    parameter THRESHOLD = `THRESHOLD,
    parameter HI = `MAX,
    parameter LO = `MIN
) (
    input [WIDTH - 1:0] d,
    output [WIDTH - 1:0] q
);
    assign q = (d > THRESHOLD) ? HI : LO;
endmodule

/**
* Calculate grayscale (intensity) from RGB
*/
module rgb2i(
    input [`WORD_SIZE - 1:0] R,
    input [`WORD_SIZE - 1:0] G,
    input [`WORD_SIZE - 1:0] B,
    output [`WORD_SIZE - 1:0] I
);
    // I = 0.299 * R + 0.587 * G + 0.114 * B;
    assign I = (R >> 2) + (R >> 5)
                + (G >> 1) + (G >> 4)
                + (B >> 4) + (B >> 5);
endmodule

/**
* Max function on 4 inputs.
*/
module max4 #(
    parameter WIDTH = `WORD_SIZE
) (
    input [WIDTH - 1:0] A,
    input [WIDTH - 1:0] B,
    input [WIDTH - 1:0] C,
    input [WIDTH - 1:0] D,
    output [WIDTH - 1:0] max
);
    wire [WIDTH - 1:0] max_a;
    wire [WIDTH - 1:0] max_b;

    assign max_a = (A > B) ? A : B;
    assign max_b = (C > D) ? C : D;
    assign max = (max_a > max_b) ? max_a : max_b;
endmodule

/**
* Min function of 4 inputs.
*/
module min4 #(
    parameter WIDTH = `WORD_SIZE
) (
    input [WIDTH - 1:0] A,
    input [WIDTH - 1:0] B,
    input [WIDTH - 1:0] C,
    input [WIDTH - 1:0] D,
    output [WIDTH - 1:0] min
);
    wire [WIDTH - 1:0] min_a;
    wire [WIDTH - 1:0] min_b;

    assign min_a = (A < B) ? A : B;
    assign min_b = (C < D) ? C : D;
    assign min = (min_a < min_b) ? min_a : min_b;
endmodule
