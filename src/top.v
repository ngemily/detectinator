`include "global.vh"

module top (
    input clk,
    input reset_n,
    input en,
    input [15:0]x,
    input [15:0]y,
    input [`PIXEL_SIZE - 1:0] data,
    input [`WORD_SIZE - 1:0] mode,
    input [`WORD_SIZE - 1:0] sobel_threshold,
    input [`WORD_SIZE - 1:0] flood_threshold,
    input [`WORD_SIZE - 1:0] obj_id,
    output [`PIXEL_SIZE - 1:0] out,
    output [15:0] obj_x,
    output [15:0] obj_y
);
    /*  Internal registers */
    // Row buffers
    reg [`WORD_SIZE - 1:0] buf7 [2:0];

    reg [`WORD_SIZE - 1:0] buf5 [4:0];
    reg [`WORD_SIZE - 1:0] buf4 [4:0];
    reg [`WORD_SIZE - 1:0] buf3 [4:0];

    reg [`WORD_SIZE - 1:0] buf2 [2:0];
    reg [`WORD_SIZE - 1:0] buf1 [2:0];
    reg [`WORD_SIZE - 1:0] buf0 [2:0];

    /*  Internal signals */
    // Section data into RGB channels
    wire [`WORD_SIZE - 1:0] R = data[7:0];
    wire [`WORD_SIZE - 1:0] G = data[15:8];
    wire [`WORD_SIZE - 1:0] B = data[23:16];

    // Intermediate stages of output
    wire [`WORD_SIZE - 1:0] I;
    wire [`WORD_SIZE - 1:0] sobel_window_out;
    wire [`WORD_SIZE - 1:0] flood_window_out;
    wire [`WORD_SIZE - 1:0] threshold_out;
    wire [`WORD_SIZE - 1:0] cc_out;
    wire [`PIXEL_SIZE - 1:0] color_out;


    integer i;

    wire empty_1, full_1;
    wire empty_2, full_2;
    wire empty_4, full_4;
    wire empty_5, full_5;
    wire empty_7, full_7;

    wire enqueue_1 = en;
    wire dequeue_1 = en & full_1;
    wire enqueue_2 = en;
    wire dequeue_2 = en & full_2;
    wire enqueue_4 = en;
    wire dequeue_4 = en & full_4;
    wire enqueue_5 = en;
    wire dequeue_5 = en & full_5;
    wire enqueue_7 = en;
    wire dequeue_7 = en & full_7;

    wire [`WORD_SIZE - 1:0] queue1_out;
    wire [`WORD_SIZE - 1:0] queue2_out;
    wire [`WORD_SIZE - 1:0] queue4_out;
    wire [`WORD_SIZE - 1:0] queue5_out;
    wire [`WORD_SIZE - 1:0] queue7_out;

    queue #(
        .ADDR_WIDTH(11),
        .DATA_WIDTH(`WORD_SIZE),
        .MAX_DEPTH(`FRAME_WIDTH - 3)
    )
    Q1 (
        .clk(clk),
        .reset_n(reset_n),
        .enqueue(enqueue_1),
        .dequeue(dequeue_1),
        .data_in(buf0[2]),
        .data_out(queue1_out),
        .empty(empty_1),
        .full(full_1)
    );

    queue #(
        .ADDR_WIDTH(11),
        .DATA_WIDTH(`WORD_SIZE),
        .MAX_DEPTH(`FRAME_WIDTH - 3)
    )
    Q2 (
        .clk(clk),
        .reset_n(reset_n),
        .enqueue(enqueue_2),
        .dequeue(dequeue_2),
        .data_in(buf1[2]),
        .data_out(queue2_out),
        .empty(empty_2),
        .full(full_2)
    );

    queue #(
        .ADDR_WIDTH(11),
        .DATA_WIDTH(`WORD_SIZE),
        .MAX_DEPTH(`FRAME_WIDTH - 5)
    )
    Q4 (
        .clk(clk),
        .reset_n(reset_n),
        .enqueue(enqueue_4),
        .dequeue(dequeue_4),
        .data_in(buf3[4]),
        .data_out(queue4_out),
        .empty(empty_4),
        .full(full_4)
    );

    queue #(
        .ADDR_WIDTH(11),
        .DATA_WIDTH(`WORD_SIZE),
        .MAX_DEPTH(`FRAME_WIDTH - 5)
    )
    Q5 (
        .clk(clk),
        .reset_n(reset_n),
        .enqueue(enqueue_5),
        .dequeue(dequeue_5),
        .data_in(buf4[4]),
        .data_out(queue5_out),
        .empty(empty_5),
        .full(full_5)
    );

    queue #(
        .ADDR_WIDTH(11),
        .DATA_WIDTH(`WORD_SIZE),
        .MAX_DEPTH(`FRAME_WIDTH - 5)
    )
    Q7 (
        .clk(clk),
        .reset_n(reset_n),
        .enqueue(enqueue_7),
        .dequeue(dequeue_7),
        .data_in(cc_out),
        .data_out(queue7_out),
        .empty(empty_7),
        .full(full_7)
    );

    // Set up row buffers:
    //  <--- SRs --->  <-------- FIFO -------->
    //  +--+ +--+ +--+ +----------------------+
    //  |  |-|  |-|  |-|                      |
    //  +--+ +--+ +--+ +----------------------+
    always @(posedge clk) begin
        if (en) begin
            // Connected Components
            buf7[2] <= buf7[1];
            buf7[1] <= buf7[0];
            buf7[0] <= queue7_out;

            // Flood
            buf5[4] <= buf5[3];
            buf5[3] <= buf5[2];
            buf5[2] <= buf5[1];
            buf5[1] <= buf5[0];
            buf5[0] <= queue5_out;

            buf4[4] <= buf4[3];
            buf4[3] <= buf4[2];
            buf4[2] <= buf4[1];
            buf4[1] <= buf4[0];
            buf4[0] <= queue4_out;

            buf3[4] <= buf3[3];
            buf3[3] <= buf3[2];
            buf3[2] <= buf3[1];
            buf3[1] <= buf3[0];
            buf3[0] <= threshold_out;

            // Sobel
            buf2[2] <= buf2[1];
            buf2[1] <= buf2[0];
            buf2[0] <= queue2_out;

            buf1[2] <= buf1[1];
            buf1[1] <= buf1[0];
            buf1[0] <= queue1_out;

            buf0[2] <= buf0[1];
            buf0[1] <= buf0[0];
            buf0[0] <= I;
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
        .p1(buf2[2]),
        .p2(buf2[1]),
        .p3(buf2[0]),
        .p4(buf1[2]),
        .p5(buf1[1]),
        .p6(buf1[0]),
        .p7(buf0[2]),
        .p8(buf0[1]),
        .p9(buf0[0]),
        .q(sobel_window_out)
    );

    // *****---
    // *****---
    // *****---
    flood_window U4 (
        .p11(buf5[4]),
        .p12(buf5[3]),
        .p13(buf5[2]),
        .p14(buf5[1]),
        .p15(buf5[0]),
        .p21(buf4[4]),
        .p22(buf4[3]),
        .p23(buf4[2]),
        .p24(buf4[1]),
        .p25(buf4[0]),
        .p31(buf3[4]),
        .p32(buf3[3]),
        .p33(buf3[2]),
        .p34(buf3[1]),
        .p35(buf3[0]),
        .threshold(flood_threshold),
        .q(flood_window_out)
    );

    // Threshold Sobel output to get a binary image.
    threshold U3 (
        .d(sobel_window_out),
        .threshold(sobel_threshold),
        .q(threshold_out)
    );

    // Run connected components on the output stream from Sobel.
    connected_components_labeling U2 (
        .clk(clk),
        .reset_n(reset_n),
        .en(en),
        .A(buf7[2]),
        .B(buf7[1]),
        .C(buf7[0]),
        .D(cc_out),
        .x(x),
        .y(y),
        .p(flood_window_out),
        .obj_id(obj_id),
        .q(cc_out),
        .obj_x(obj_x),
        .obj_y(obj_y)
    );

    rom #(
        .ADDR_WIDTH(8),
        .DATA_WIDTH(`PIXEL_SIZE),
        .INIT_FILE(`SYNTH_CFILE)
    )
    COLOR_TABLE (
        .clk(clk),
        .r_addr(cc_out),
        .data_out(color_out)
    );

    assign out =  (mode == `PASS) ?                {data} :
                  (mode == `GRAY) ?                {3{I}} :
                 (mode == `SOBEL) ? {3{sobel_window_out}} :
                (mode == `THRESH) ?    {3{threshold_out}} :
                 (mode == `FLOOD) ? {3{flood_window_out}} :
                    (mode == `CC) ?           {3{cc_out}} :
                 (mode == `COLOR) ?           {color_out} :
                                    {3{sobel_window_out}} ;
endmodule
