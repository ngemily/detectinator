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
    reg [`WORD_SIZE - 1:0] buf4 [`FRAME_WIDTH - 1:`FRAME_WIDTH - 3];
    reg [`WORD_SIZE - 1:0] buf3 [`FRAME_WIDTH - 1:`FRAME_WIDTH - 1];

    reg [`WORD_SIZE - 1:0] buf2 [`FRAME_WIDTH - 1:`FRAME_WIDTH - 3];
    reg [`WORD_SIZE - 1:0] buf1 [`FRAME_WIDTH - 1:`FRAME_WIDTH - 3];
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

    wire empty_1, full_1;
    wire empty_2, full_2;
    wire empty_4, full_4;

    wire enqueue_1 = 1'b1;
    wire dequeue_1 = full_1;
    wire enqueue_2 = 1'b1;
    wire dequeue_2 = full_2;
    wire enqueue_4 = 1'b1;
    wire dequeue_4 = full_4;

    wire [`WORD_SIZE - 1:0] queue1_out;
    wire [`WORD_SIZE - 1:0] queue2_out;
    wire [`WORD_SIZE - 1:0] queue4_out;

    queue #(
        .ADDR_WIDTH(10),
        .DATA_WIDTH(`WORD_SIZE),
        .MAX_DEPTH(`FRAME_WIDTH - 3)
    )
    Q1 (
        .clk(clk),
        .reset_n(reset_n),
        .enqueue(enqueue_1),
        .dequeue(dequeue_1),
        .data_in(buf0[`FRAME_WIDTH - 1]),
        .data_out(queue1_out),
        .empty(empty_1),
        .full(full_1)
    );

    queue #(
        .ADDR_WIDTH(10),
        .DATA_WIDTH(`WORD_SIZE),
        .MAX_DEPTH(`FRAME_WIDTH - 3)
    )
    Q2 (
        .clk(clk),
        .reset_n(reset_n),
        .enqueue(enqueue_2),
        .dequeue(dequeue_2),
        .data_in(buf1[`FRAME_WIDTH - 1]),
        .data_out(queue2_out),
        .empty(empty_2),
        .full(full_2)
    );

    queue #(
        .ADDR_WIDTH(10),
        .DATA_WIDTH(`WORD_SIZE),
        .MAX_DEPTH(`FRAME_WIDTH - 3)
    )
    Q4 (
        .clk(clk),
        .reset_n(reset_n),
        .enqueue(enqueue_4),
        .dequeue(dequeue_4),
        .data_in(buf3[`FRAME_WIDTH - 1]),
        .data_out(queue4_out),
        .empty(empty_4),
        .full(full_4)
    );

    always @(posedge clk) begin
        if (en) begin
            // Connected Components

            buf4[`FRAME_WIDTH - 1] <= buf4[`FRAME_WIDTH - 2];
            buf4[`FRAME_WIDTH - 2] <= buf4[`FRAME_WIDTH - 3];
            buf4[`FRAME_WIDTH - 3] <= queue4_out;

            buf3[`FRAME_WIDTH - 1] <= cc_out;


            // Sobel

            buf2[`FRAME_WIDTH - 1] <= buf2[`FRAME_WIDTH - 2];
            buf2[`FRAME_WIDTH - 2] <= buf2[`FRAME_WIDTH - 3];
            buf2[`FRAME_WIDTH - 3] <= queue2_out;

            buf1[`FRAME_WIDTH - 1] <= buf1[`FRAME_WIDTH - 2];
            buf1[`FRAME_WIDTH - 2] <= buf1[`FRAME_WIDTH - 3];
            buf1[`FRAME_WIDTH - 3] <= queue1_out;

            buf0[`FRAME_WIDTH - 1] <= buf0[`FRAME_WIDTH - 2];
            buf0[`FRAME_WIDTH - 2] <= buf0[`FRAME_WIDTH - 3];
            buf0[`FRAME_WIDTH - 3] <= I;

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
        .x(x),
        .y(y),
        .data(threshold_out),
        .q(cc_out)
    );

    assign out = {sobel_window_out, threshold_out, cc_out};
endmodule
