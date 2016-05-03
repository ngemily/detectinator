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
    input [`LBL_WIDTH - 1:0] obj_id,
`ifndef STANDALONE
    output reg [`PIXEL_SIZE - 1:0] out,
    output [`LBL_WIDTH - 1:0] num_labels,
    output [`LOC_SIZE - 1:0] obj_area,
    output [`LOC_SIZE - 1:0] obj_x,
    output [`LOC_SIZE - 1:0] obj_y,
    output [`LOC_SIZE - 1:0] obj_m02,
    output [`LOC_SIZE - 1:0] obj_m11,
    output [`LOC_SIZE - 1:0] obj_m20,
    output [`LOC_SIZE - 1:0] obj_m30,
    output [`LOC_SIZE - 1:0] obj_m21,
    output [`LOC_SIZE - 1:0] obj_m12,
    output [`LOC_SIZE - 1:0] obj_m03
`else
    output reg [`PIXEL_SIZE - 1:0] out
`endif
);
    /*  Internal registers */
    // Row buffers
    reg [`LBL_WIDTH - 1:0] buf9 [2:0];

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
    wire [`LBL_WIDTH - 1:0] cc_out;
    reg  [`LBL_WIDTH - 1:0] cc_out_delay;
    wire [`PIXEL_SIZE - 1:0] color_out;

    // Sobel line buffers: 3x3, data width `WORD_SIZE
    wire [3 * 3 * `WORD_SIZE - 1:0] sobel_window_in;

    window_generator #(
        .WORD_SIZE(`WORD_SIZE),
        .WIDTH(3),
        .HEIGHT(3)
    ) W0 (
        .clk(clk),
        .en(en),
        .reset_n(reset_n),
        .din(I),
        .dout(sobel_window_in)
    );

    // flood1 line buffers: 3x5, data width 1
    wire [3 * 5 * 1 - 1:0] flood1_window_in;

    window_generator #(
        .WORD_SIZE(1),
        .WIDTH(5),
        .HEIGHT(3)
    ) W1 (
        .clk(clk),
        .en(en),
        .reset_n(reset_n),
        .din(threshold_out[0]),
        .dout(flood1_window_in)
    );

    // flood2 line buffers: 3x5, data width 1
    wire [3 * 5 * 1 - 1:0] flood2_window_in;

    window_generator #(
        .WORD_SIZE(1),
        .WIDTH(5),
        .HEIGHT(3)
    ) W2 (
        .clk(clk),
        .en(en),
        .reset_n(reset_n),
        .din(flood1_window_out),
        .dout(flood2_window_in)
    );

    // Connected components buffer: 1x3
    wire empty;
    wire full;

    wire [`LBL_WIDTH - 1:0] queue9_out;

    queue #(
        .ADDR_WIDTH(11),
        .DATA_WIDTH(`LBL_WIDTH),
        .MAX_DEPTH(`FRAME_WIDTH - 4)
    )
    Q9 (
        .clk(clk),
        .reset_n(reset_n),
        .enqueue(en),
        .dequeue(en & full),
        .data_in(cc_out),
        .data_out(queue9_out),
        .empty(empty),
        .full(full)
    );

    // Set up row buffers:
    integer j;
    always @(posedge clk) begin
        if (en) begin
            // Connected Components
            for (j = 2; j > 0; j = j - 1) begin
                buf9[j] <= buf9[j - 1];
            end
            buf9[0] <= queue9_out;

            cc_out_delay <= cc_out;
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
        .en(en),
        .p1(sobel_window_in[9 * `WORD_SIZE - 1 -: `WORD_SIZE]),
        .p2(sobel_window_in[8 * `WORD_SIZE - 1 -: `WORD_SIZE]),
        .p3(sobel_window_in[7 * `WORD_SIZE - 1 -: `WORD_SIZE]),
        .p4(sobel_window_in[6 * `WORD_SIZE - 1 -: `WORD_SIZE]),
        .p5(sobel_window_in[5 * `WORD_SIZE - 1 -: `WORD_SIZE]),
        .p6(sobel_window_in[4 * `WORD_SIZE - 1 -: `WORD_SIZE]),
        .p7(sobel_window_in[3 * `WORD_SIZE - 1 -: `WORD_SIZE]),
        .p8(sobel_window_in[2 * `WORD_SIZE - 1 -: `WORD_SIZE]),
        .p9(sobel_window_in[1 * `WORD_SIZE - 1 -: `WORD_SIZE]),
        .q(sobel_window_out)
    );

    // *****---
    // *****---
    // *****---
    flood_window U4 (
        .clk(clk),
        .en(en),
        .p11(flood1_window_in[14]),
        .p12(flood1_window_in[13]),
        .p13(flood1_window_in[12]),
        .p14(flood1_window_in[11]),
        .p15(flood1_window_in[10]),
        .p21(flood1_window_in[9]),
        .p22(flood1_window_in[8]),
        .p23(flood1_window_in[7]),
        .p24(flood1_window_in[6]),
        .p25(flood1_window_in[5]),
        .p31(flood1_window_in[4]),
        .p32(flood1_window_in[3]),
        .p33(flood1_window_in[2]),
        .p34(flood1_window_in[1]),
        .p35(flood1_window_in[0]),
        .threshold(flood1_threshold),
        .q(flood1_window_out)
    );

    // *****---
    // *****---
    // *****---
    flood_window U5 (
        .clk(clk),
        .en(en),
        .p11(flood2_window_in[14]),
        .p12(flood2_window_in[13]),
        .p13(flood2_window_in[12]),
        .p14(flood2_window_in[11]),
        .p15(flood2_window_in[10]),
        .p21(flood2_window_in[9]),
        .p22(flood2_window_in[8]),
        .p23(flood2_window_in[7]),
        .p24(flood2_window_in[6]),
        .p25(flood2_window_in[5]),
        .p31(flood2_window_in[4]),
        .p32(flood2_window_in[3]),
        .p33(flood2_window_in[2]),
        .p34(flood2_window_in[1]),
        .p35(flood2_window_in[0]),
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
        .D(cc_out_delay),
        .x(x),
        .y(y),
        .p(flood2_window_out),
        .obj_id(obj_id),
`ifndef STANDALONE
        .q(cc_out),
        .num_labels(num_labels),
        .obj_area(obj_area),
        .obj_x(obj_x),
        .obj_y(obj_y),
        .obj_m02(obj_m02),
        .obj_m11(obj_m11),
        .obj_m20(obj_m20),
        .obj_m30(obj_m30),
        .obj_m21(obj_m21),
        .obj_m12(obj_m12),
        .obj_m03(obj_m03)
`else
        .q(cc_out)
`endif
    );

    rom #(
        .ADDR_WIDTH(`LBL_WIDTH),
        .DATA_WIDTH(`PIXEL_SIZE),
`ifdef RTL_SIM
        .INIT_FILE(`SIM_CFILE)
`else
        .INIT_FILE(`SYNTH_CFILE)
`endif
    )
    COLOR_TABLE (
        .clk(clk),
        .r_addr(cc_out),
        .data_out(color_out)
    );

    always @(posedge clk) begin
        case (mode)
            `PASS:   out = data;
            `GRAY:   out = {3{I}};
            `SOBEL:  out = {3{sobel_window_out}};
            `THRESH: out = {`PIXEL_SIZE{threshold_out[0]}};
            `FLOOD1: out = {`PIXEL_SIZE{flood1_window_out}};
            `FLOOD2: out = {`PIXEL_SIZE{flood2_window_out}};
            `CC:     out = cc_out;
            `COLOR:  out = color_out;
            default: out = {3{sobel_window_out}} ;
        endcase
    end
endmodule
