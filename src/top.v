`include "global.vh"

`define THRESHOLD 50
`define MAX 255
`define MIN 0

`define FRAME_WIDTH 550     //0x226
`define FRAME_HEIGHT 1

module top (
    input clk,
    input reset_n,
    input en,
    input hsync,
    input vsync,
    input [`PIXEL_SIZE - 1:0] data,
    output [`PIXEL_SIZE - 1:0] out
);
    /*  Internal registers */
    // Location of current pixel
    reg [31:0] x;
    reg [31:0] y;
    reg [31:0] frame;

    // Row buffers
    reg [`WORD_SIZE - 1:0] buf4 [1024:0];
    reg [`WORD_SIZE - 1:0] buf3 [1024:0];
    reg [`WORD_SIZE - 1:0] buf2 [1024:0];
    reg [`WORD_SIZE - 1:0] buf1 [1024:0];
    reg [`WORD_SIZE - 1:0] buf0 [1024:0];

    /*  Internal signals */
    wire [`WORD_SIZE - 1:0] R = data[7:0];
    wire [`WORD_SIZE - 1:0] G = data[15:8];
    wire [`WORD_SIZE - 1:0] B = data[23:16];

    // Intermediate stages of output
    wire [`WORD_SIZE - 1:0] I;
    wire [`WORD_SIZE - 1:0] sobel_window_out;
    wire [`WORD_SIZE - 1:0] threshold_out;
    wire [`WORD_SIZE - 1:0] cc_out;

    integer i;

    // Update location using HSYNC and VSYNC
    always @(posedge clk) begin
        if (~reset_n) begin
            x <= 0;
            y <= 0;
            frame <= 0;
        end else if (hsync) begin
            // new row
            x <= 0;
            y <= y + 1;
        end else if (vsync) begin
            // new frame
            x <= 0;
            y <= 0;
            frame <= frame + 1;
        end else begin
            x <= x + 1;
        end
    end

    // Shift in one pixel every clock cycle into three cascading buffers.
    always @(posedge clk) begin
        buf0[0] <= I;
        buf1[0] <= buf0[`FRAME_WIDTH - 1];
        buf2[0] <= buf1[`FRAME_WIDTH - 1];

        buf3[`FRAME_WIDTH - 1] <= cc_out;
        buf4[0] <= buf3[`FRAME_WIDTH - 1];

        for(i = 1; i < `FRAME_WIDTH; i = i + 1) begin
            buf4[i] <= buf4[i - 1];
            buf2[i] <= buf2[i - 1];
            buf1[i] <= buf1[i - 1];
            buf0[i] <= buf0[i - 1];
        end
    end

    // 24-bit RGB intput to 8-bit Intensity (grayscale)
    rgb2i U1(
        .R(R),
        .G(G),
        .B(B),
        .I(I)
    );

    // Perform Sobel on a sliding window
    //
    // ***----------        <buf2>
    // ***----------        <buf1>
    // ***                  <buf0>
    sobel_window U0 (
        .p1(buf2[`FRAME_WIDTH - 1]),
        .p2(buf2[`FRAME_WIDTH - 2]),
        .p3(buf2[`FRAME_WIDTH - 3]),
        .p4(buf1[`FRAME_WIDTH - 1]),
        .p5(buf1[`FRAME_WIDTH - 2]),
        .p6(buf1[`FRAME_WIDTH - 3]),
        .p7(buf0[`FRAME_WIDTH - 1]),
        .p8(buf0[`FRAME_WIDTH - 2]),
        .p9(buf0[`FRAME_WIDTH - 3]),
        .q(sobel_window_out)
    );

    // Threshold Sobel output to get a binary image.
    threshold #(
        .WIDTH(`WORD_SIZE)
    )
    U3 (
        .d(sobel_window_out),
        .q(threshold_out)
    );

    // Run connected components on the output stream from Sobel.
    connected_components_labeling U2 (
        .clk(clk),
        .reset_n(reset_n),
        .A(buf4[`FRAME_WIDTH - 1]),
        .B(buf4[`FRAME_WIDTH - 2]),
        .C(buf4[`FRAME_WIDTH - 3]),
        .D(buf3[`FRAME_WIDTH - 1]),
        .data(threshold_out),
        .q(cc_out)
    );

    assign out = {sobel_window_out, threshold_out, cc_out};
endmodule

/**
* Perform binary threshold, like a step function u(t).
*/
module threshold #(
    parameter WIDTH = 1,
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

/**
* Connected components labeling
*
* Expected input:
*   +---+---+---+
*   | A | B | C |
*   +---+---+
*   | D | p |
*   +---+---+
*
* Output labelled image.
*/
module connected_components_labeling(
    input clk,
    input reset_n,
    input [`WORD_SIZE - 1:0] A,
    input [`WORD_SIZE - 1:0] B,
    input [`WORD_SIZE - 1:0] C,
    input [`WORD_SIZE - 1:0] D,
    input [`WORD_SIZE - 1:0] data,
    output [`WORD_SIZE - 1:0] q
);
    reg [`WORD_SIZE - 1:0] num_labels;

    wire is_background;
    wire is_new_label;
    wire copy_a;
    wire copy_b;
    wire copy_c;
    wire copy_d;

    wire [`WORD_SIZE - 1:0] _A;
    wire [`WORD_SIZE - 1:0] _B;
    wire [`WORD_SIZE - 1:0] _C;
    wire [`WORD_SIZE - 1:0] _D;
    wire [`WORD_SIZE - 1:0] min_label_a;
    wire [`WORD_SIZE - 1:0] min_label_b;
    wire [`WORD_SIZE - 1:0] min_label;

    always @(posedge clk) begin
        if (~reset_n) begin
            num_labels <= 1;        // 0 is reserved
        end else if (is_new_label) begin
            num_labels <= num_labels + 1;
        end
    end

    assign is_background = !data;
    assign is_new_label = !(A | B | C | D) && !is_background;
    assign copy_a = (A == B || !B)
        && (A == C || !C)
        && (A == D || !D);
    assign copy_b = (B == A || !A)
        && (B == C || !C)
        && (B == D || !D);
    assign copy_c = (C == B || !B)
        && (C == A || !A)
        && (C == D || !D);
    assign copy_d = (D == B || !B)
        && (D == C || !C)
        && (D == A || !A);

    assign _A = (A == 0) ? `MAX : A;
    assign _B = (B == 0) ? `MAX : B;
    assign _C = (C == 0) ? `MAX : C;
    assign _D = (D == 0) ? `MAX : D;
    assign min_label_a = (_A < _B) ? _A : _B;
    assign min_label_b = (_C < _D) ? _C : _D;
    assign min_label = (min_label_a < min_label_b) ? min_label_a : min_label_b;

    assign q = (is_background) ? 0 :
        (is_new_label) ? num_labels :
        (copy_a)                      ? A :
        (copy_b)                      ? B :
        (copy_c)                      ? C :
        (copy_d)                      ? D :
                                 min_label ;
endmodule
