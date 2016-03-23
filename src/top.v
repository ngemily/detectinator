`include "global.vh"

module top (
    input clk,
    input reset_n,
    input en,
    input [31:0]x,
    input [31:0]y,
    input [`PIXEL_SIZE - 1:0] data,
    input [`WORD_SIZE - 1:0] mode,
    input [`WORD_SIZE - 1:0] threshold,
    output [`PIXEL_SIZE - 1:0] out
);
    /*  Internal registers */
    // Row buffers
    reg [`WORD_SIZE - 1:0] buf4 [2:0];
    reg [`WORD_SIZE - 1:0] threshold_out_delay;

    reg [`WORD_SIZE - 1:0] buf2 [2:0];
    reg [`WORD_SIZE - 1:0] buf1 [2:0];
    reg [`WORD_SIZE - 1:0] buf0 [2:0];

    /*  Internal signals */
    /*
    // Location of current pixel
    wire [31:0] x;
    wire [31:0] y;
    wire [31:0] frame;
    */

    wire [`WORD_SIZE - 1:0] R = data[7:0];
    wire [`WORD_SIZE - 1:0] G = data[15:8];
    wire [`WORD_SIZE - 1:0] B = data[23:16];

    // Intermediate stages of output
    wire [`WORD_SIZE - 1:0] I;
    wire [`WORD_SIZE - 1:0] sobel_window_out;
    wire [`WORD_SIZE - 1:0] threshold_out;
    wire [`WORD_SIZE - 1:0] cc_out;
    wire [`PIXEL_SIZE - 1:0] color_out;


    integer i;

    wire empty_1, full_1;
    wire empty_2, full_2;
    wire empty_4, full_4;

    wire enqueue_1 = en;
    wire dequeue_1 = en & full_1;
    wire enqueue_2 = en;
    wire dequeue_2 = en & full_2;
    wire enqueue_4 = en;
    wire dequeue_4 = en & full_4;

    wire [`WORD_SIZE - 1:0] queue1_out;
    wire [`WORD_SIZE - 1:0] queue2_out;
    wire [`WORD_SIZE - 1:0] queue4_out;

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
        .MAX_DEPTH(`FRAME_WIDTH - 4)
    )
    Q4 (
        .clk(clk),
        .reset_n(reset_n),
        .enqueue(enqueue_4),
        .dequeue(dequeue_4),
        .data_in(cc_out),
        .data_out(queue4_out),
        .empty(empty_4),
        .full(full_4)
    );

    // Set up row buffers:
    //  <--- SRs --->  <-------- FIFO -------->
    //  +--+ +--+ +--+ +----------------------+
    //  |  |-|  |-|  |-|                      |
    //  +--+ +--+ +--+ +----------------------+
    always @(posedge clk) begin
        if (en) begin
            // Connected Components
            buf4[2] <= buf4[1];
            buf4[1] <= buf4[0];
            buf4[0] <= queue4_out;

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

            // Pipeline register
            threshold_out_delay <= threshold_out;
        end
    end

    // Generate x, y co-ords
    /*
    location_generator U4(
        .clk(clk),
        .reset_n(reset_n),
        .en(en),
        .hsync(hsync),
        .vsync(vsync),
        .x(x),
        .y(y),
        .frame(frame)
    );
    */

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

    // Threshold Sobel output to get a binary image.
    threshold U3 (
        .d(sobel_window_out),
        .threshold(threshold),
        .q(threshold_out)
    );

    // Run connected components on the output stream from Sobel.
    connected_components_labeling U2 (
        .clk(clk),
        .reset_n(reset_n),
        .en(en),
        .A(buf4[2]),
        .B(buf4[1]),
        .C(buf4[0]),
        .D(cc_out),
        .x(x),
        .y(y),
        .p(threshold_out_delay),
        .q(cc_out)
    );

    rom #(
        .ADDR_WIDTH(8),
        .DATA_WIDTH(`PIXEL_SIZE),
        .INIT_FILE(`CFILE)
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
                    (mode == `CC) ?           {3{cc_out}} :
                 (mode == `COLOR) ?           {color_out} :
                                    {3{sobel_window_out}} ;
endmodule
