`include "global.vh"

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
    reg [`WORD_SIZE - 1:0] buf4 [`FRAME_WIDTH - 1:0];
    reg [`WORD_SIZE - 1:0] buf3 [`FRAME_WIDTH - 1:`FRAME_WIDTH - 1];

    reg [`WORD_SIZE - 1:0] buf2 [`FRAME_WIDTH - 1:0];
    reg [`WORD_SIZE - 1:0] buf1 [`FRAME_WIDTH - 1:0];
    reg [`WORD_SIZE - 1:0] buf0 [`FRAME_WIDTH - 1: `FRAME_WIDTH - 3];

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
        end else if (en) begin
            if (hsync) begin
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
    end

    // Shift in one pixel every clock cycle into cascading buffers.
    always @(posedge clk) begin
        if (en) begin
            // Input to Sobel
            buf0[`FRAME_WIDTH - 3] <= I;
            buf0[`FRAME_WIDTH - 2] <= buf0[`FRAME_WIDTH - 3];
            buf0[`FRAME_WIDTH - 1] <= buf0[`FRAME_WIDTH - 2];

            // Input to connected components
            buf3[`FRAME_WIDTH - 1] <= cc_out;

            // Cascade
            buf1[0] <= buf0[`FRAME_WIDTH - 1];
            buf2[0] <= buf1[`FRAME_WIDTH - 1];

            buf4[0] <= buf3[`FRAME_WIDTH - 1];

            // Shift
            for(i = 1; i < `FRAME_WIDTH; i = i + 1) begin
                buf4[i] <= buf4[i - 1];
                buf2[i] <= buf2[i - 1];
                buf1[i] <= buf1[i - 1];
            end
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
    threshold U3 (
        .d(sobel_window_out),
        .q(threshold_out)
    );

    // Run connected components on the output stream from Sobel.
    connected_components_labeling U2 (
        .clk(clk),
        .reset_n(reset_n),
        .en(en),
        .A(buf4[`FRAME_WIDTH - 1]),
        .B(buf4[`FRAME_WIDTH - 2]),
        .C(buf4[`FRAME_WIDTH - 3]),
        .D(buf3[`FRAME_WIDTH - 1]),
        .data(threshold_out),
        .q(cc_out)
    );

    assign out = {sobel_window_out, threshold_out, cc_out};
endmodule
