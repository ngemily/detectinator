`include "global.vh"

module top (
    input clk,
    input reset_n,
    input en,
    input [`LOC_SIZE - 1:0]x,
    input [`LOC_SIZE - 1:0]y,
    input [`PIXEL_SIZE - 1:0] data,
    input [`WORD_SIZE - 1:0] mode,
    input [`WORD_SIZE - 1:0] sobel_threshold,
    input [`WORD_SIZE - 1:0] flood1_threshold,
    input [`WORD_SIZE - 1:0] flood2_threshold,
    input [`WORD_SIZE - 1:0] obj_id,
    output [`WORD_SIZE - 1:0] num_labels,
    output [`PIXEL_SIZE - 1:0] out,
    output [`LOC_SIZE - 1:0] obj_area,
    output [`LOC_SIZE - 1:0] obj_x,
    output [`LOC_SIZE - 1:0] obj_y
);
    /*  Internal registers */
    // Row buffers
    reg [`WORD_SIZE - 1:0] buf9 [2:0];

    reg buf8 [4:0];
    reg buf7 [4:0];
    reg buf6 [4:0];

    reg buf5 [4:0];
    reg buf4 [4:0];
    reg buf3 [4:0];

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
    wire flood1_window_out;
    wire flood2_window_out;
    wire cc_in = (mode[`FLOOD2_BIT]) ? flood2_window_out : flood1_window_out;
    wire [`WORD_SIZE - 1:0] threshold_out;
    wire [`WORD_SIZE - 1:0] cc_out;
    wire [`PIXEL_SIZE - 1:0] color_out;

    // Line buffer signals
    wire [9:1] empty;
    wire [9:1] full;

    // Sobel line buffers: 3x3
    wire [`WORD_SIZE - 1:0] sobel_queue_in [2:1];
    wire [`WORD_SIZE - 1:0] sobel_queue_out [2:1];

    assign sobel_queue_in[2] = buf1[2];
    assign sobel_queue_in[1] = buf0[2];

    genvar i;
    generate
        for (i = 1; i < 1 + 2; i = i + 1) begin
            queue #(
                .ADDR_WIDTH(11),
                .DATA_WIDTH(`WORD_SIZE),
                .MAX_DEPTH(`FRAME_WIDTH - 3)
            )
            Q4 (
                .clk(clk),
                .reset_n(reset_n),
                .enqueue(en),
                .dequeue(en & full[i]),
                .data_in(sobel_queue_in[i]),
                .data_out(sobel_queue_out[i]),
                .empty(empty[i]),
                .full(full[i])
            );

        end
    endgenerate

    // flood1 line buffers: 3x5
    wire [5:4] flood1_queue_out;
    wire [5:4] flood1_queue_in;

    assign flood1_queue_in[4] = buf3[4];
    assign flood1_queue_in[5] = buf4[4];

    generate
        for (i = 4; i < 4 + 2; i = i + 1) begin
            queue #(
                .ADDR_WIDTH(11),
                .DATA_WIDTH(1),
                .MAX_DEPTH(`FRAME_WIDTH - 5)
            )
            Q4 (
                .clk(clk),
                .reset_n(reset_n),
                .enqueue(en),
                .dequeue(en & full[i]),
                .data_in(flood1_queue_in[i]),
                .data_out(flood1_queue_out[i]),
                .empty(empty[i]),
                .full(full[i])
            );

        end
    endgenerate

    // Flood line buffers: 3x5
    wire [8:7] flood2_queue_out;
    wire [8:7] flood2_queue_in;

    assign flood2_queue_in[7] = buf6[4];
    assign flood2_queue_in[8] = buf7[4];

    generate
        for (i = 7; i < 7 + 2; i = i + 1) begin
            queue #(
                .ADDR_WIDTH(11),
                .DATA_WIDTH(1),
                .MAX_DEPTH(`FRAME_WIDTH - 5)
            )
            Q4 (
                .clk(clk),
                .reset_n(reset_n),
                .enqueue(en),
                .dequeue(en & full[i]),
                .data_in(flood2_queue_in[i]),
                .data_out(flood2_queue_out[i]),
                .empty(empty[i]),
                .full(full[i])
            );

        end
    endgenerate

    // Connected components buffer: 1x3
    wire [`WORD_SIZE - 1:0] queue9_out;

    queue #(
        .ADDR_WIDTH(11),
        .DATA_WIDTH(`WORD_SIZE),
        .MAX_DEPTH(`FRAME_WIDTH - 5)
    )
    Q9 (
        .clk(clk),
        .reset_n(reset_n),
        .enqueue(en),
        .dequeue(en & full[9]),
        .data_in(cc_out),
        .data_out(queue9_out),
        .empty(empty[9]),
        .full(full[9])
    );

    // Set up row buffers:
    //  <--- SRs --->  <-------- FIFO -------->
    //  +--+ +--+ +--+ +----------------------+
    //  |  |-|  |-|  |-|                      |
    //  +--+ +--+ +--+ +----------------------+
    integer j;
    always @(posedge clk) begin
        if (en) begin
            // Connected Components
            for (j = 2; j > 0; j = j - 1) begin
                buf9[j] <= buf9[j - 1];
            end
            buf9[0] <= queue9_out;

            // Flood
            for (j = 4; j > 0; j = j - 1) begin
                buf8[j] <= buf8[j - 1];
                buf7[j] <= buf7[j - 1];
                buf6[j] <= buf6[j - 1];
            end
            buf8[0] <= flood2_queue_out[8];
            buf7[0] <= flood2_queue_out[7];
            buf6[0] <= flood1_window_out;

            // Flood
            for (j = 4; j > 0; j = j - 1) begin
                buf5[j] <= buf5[j - 1];
                buf4[j] <= buf4[j - 1];
                buf3[j] <= buf3[j - 1];
            end
            buf5[0] <= flood1_queue_out[5];
            buf4[0] <= flood1_queue_out[4];
            buf3[0] <= threshold_out[0];

            // Sobel
            for (j = 2; j > 0; j = j - 1) begin
                buf2[j] <= buf2[j - 1];
                buf1[j] <= buf1[j - 1];
                buf0[j] <= buf0[j - 1];
            end
            buf2[0] <= sobel_queue_out[2];
            buf1[0] <= sobel_queue_out[1];
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
        .clk(clk),
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
        .clk(clk),
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
        .threshold(flood1_threshold),
        .q(flood1_window_out)
    );

    // *****---
    // *****---
    // *****---
    flood_window U5 (
        .clk(clk),
        .p11(buf8[4]),
        .p12(buf8[3]),
        .p13(buf8[2]),
        .p14(buf8[1]),
        .p15(buf8[0]),
        .p21(buf7[4]),
        .p22(buf7[3]),
        .p23(buf7[2]),
        .p24(buf7[1]),
        .p25(buf7[0]),
        .p31(buf6[4]),
        .p32(buf6[3]),
        .p33(buf6[2]),
        .p34(buf6[1]),
        .p35(buf6[0]),
        .threshold(flood2_threshold),
        .q(flood2_window_out)
    );

    // Threshold Sobel output to get a binary image.
    threshold #(
        .WIDTH(`WORD_SIZE),
        .HI(1),
        .LO(0)
    )
    U3 (
        .d(sobel_window_out),
        .threshold(sobel_threshold),
        .q(threshold_out)
    );

    // Run connected components on the output stream from Sobel.
    connected_components_labeling U2 (
        .clk(clk),
        .reset_n(reset_n),
        .en(en),
        .A(buf9[2]),
        .B(buf9[1]),
        .C(buf9[0]),
        .D(cc_out),
        .x(x),
        .y(y),
        .p(flood2_window_out),
        .obj_id(obj_id),
        .num_labels(num_labels),
        .q(cc_out),
        .obj_area(obj_area),
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
                (mode == `THRESH) ? (threshold_out ? {`PIXEL_SIZE{1'b1}} : {`PIXEL_SIZE{1'b0}}) :
                (mode == `FLOOD1) ? (flood1_window_out ? {`PIXEL_SIZE{1'b1}} : {`PIXEL_SIZE{1'b0}}) :
                (mode == `FLOOD2) ? (flood2_window_out ? {`PIXEL_SIZE{1'b1}} : {`PIXEL_SIZE{1'b0}}) :
                    (mode == `CC) ?           {3{cc_out}} :
                 (mode == `COLOR) ?           {color_out} :
                                    {3{sobel_window_out}} ;
endmodule
