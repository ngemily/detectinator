`include "global.vh"
/**
* Generate a window for image kernel computations.
*
* Size of the window and data width are parameterizable.  FIFO width is
* calculated based on frame width (frame width - window size).  Bottom queue is
* optional, defaults to 'false'.  Usually not needed, supplied for the special
* case of connected components where the desired pixel window is not
* rectangular. NB: window size unaffected by existence of bottom queue.
*
* Return the result as a concatenation of each pixel because arrays in port
* declarations not allowed.
*
*   ^   <-SRs-> <--- FIFO ---->
*   h    x-x-x-[                ]<.
*   e  ,--------------------------'
*   i  `-x-x-x-[                ]<.
*   g  ,--------------------------'
*   h  `-x-x-x-[                ]<.
*   t  ,--------------------------'
*   v  `-x-x-x-[opt. queue]<-- din
*
*       <-width->
*/
module window_generator #(
    parameter WORD_SIZE = `WORD_SIZE,
    parameter WIDTH = 1,
    parameter HEIGHT = 1,
    parameter BOTTOM_QUEUE = 0
) (
    input clk,
    input en,
    input reset_n,
    input [WORD_SIZE - 1:0] din,
    output [WIDTH * HEIGHT * WORD_SIZE - 1:0] dout
);
    reg [WORD_SIZE - 1:0] p [HEIGHT - 1:0][WIDTH - 1:0];

    wire [WORD_SIZE - 1:0] queue_in [HEIGHT - 1:0];
    wire [WORD_SIZE - 1:0] queue_out [HEIGHT - 1:0];

    wire [HEIGHT - 1:0] full;
    wire [HEIGHT - 1:0] empty;

    genvar  i, j;
    integer k, l;

    // Setup queues
    generate
        if (BOTTOM_QUEUE) begin
            assign queue_in[0] = din;

            queue #(
                .ADDR_WIDTH(11),
                .DATA_WIDTH(WORD_SIZE),
                .MAX_DEPTH(`FRAME_WIDTH - WIDTH)
            )
            Q0 (
                .clk(clk),
                .reset_n(reset_n),
                .enqueue(en),
                .dequeue(en & full[0]),
                .data_in(queue_in[0]),
                .data_out(queue_out[0]),
                .empty(empty[0]),
                .full(full[0])
            );
        end
        for (i = 1; i < HEIGHT; i = i + 1) begin: line_queue
            assign queue_in[i] = p[i - 1][WIDTH - 1];

            queue #(
                .ADDR_WIDTH(11),
                .DATA_WIDTH(WORD_SIZE),
                .MAX_DEPTH(`FRAME_WIDTH - WIDTH)
            )
            Q0 (
                .clk(clk),
                .reset_n(reset_n),
                .enqueue(en),
                .dequeue(en & full[i]),
                .data_in(queue_in[i]),
                .data_out(queue_out[i]),
                .empty(empty[i]),
                .full(full[i])
            );

        end
    endgenerate

    // Shift
    //
    // The pixel array region is divided as follows:
    //  +---------+---+
    //  |         |   |  1 - shift in from previous pixel
    //  |         | 2 |  2 - shift in from queue out
    //  |    1    |   |  3 - shift in from data in
    //  |         +---+
    //  |         | 3 |
    //  +---------+---+
    //
    //  in the case of a bottom queue, only regions 1 and 2 exist.
    always @(posedge clk) begin
        for (k = 0; k < HEIGHT; k = k + 1) begin
            for (l = 1; l < WIDTH; l = l + 1) begin
                p[k][l] <= p[k][l - 1];
            end
        end
        for (k = 1; k < HEIGHT; k = k + 1) begin
            p[k][0] <= queue_out[k];
        end
        if (BOTTOM_QUEUE) begin
            p[0][0] <= queue_out[0];
        end else begin
            p[0][0] <= din;
        end
    end

    // Pack the output
    generate
        for(i = 0; i < HEIGHT; i = i + 1) begin : out0
            for (j = 0; j < WIDTH; j = j + 1) begin : out1
                assign dout[(i * WIDTH + j + 1) * WORD_SIZE - 1 -: WORD_SIZE] = p[i][j];
            end
        end
    endgenerate
endmodule
