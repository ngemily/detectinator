`include "global.vh"

module queue #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter MAX_DEPTH = (1 << ADDR_WIDTH)
) (
    input clk,
    input reset_n,
    input enqueue,
    input dequeue,
    input  [DATA_WIDTH - 1:0] data_in,
    output [DATA_WIDTH - 1:0] data_out,
    output empty,
    output full
);
    localparam DEPTH = (1 << ADDR_WIDTH);

    reg [ADDR_WIDTH - 1:0] head_ptr;
    reg [ADDR_WIDTH - 1:0] tail_ptr;
    reg [ADDR_WIDTH:0] size;

    ram #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    )
    U0 (
        .clk(clk),
        .wen(enqueue),
        .w_addr(head_ptr),
        .r_addr(tail_ptr),
        .data_in(data_in),
        .data_out(data_out)
    );

    always @(posedge clk) begin
        if (~reset_n) begin
            head_ptr <= 0;
            tail_ptr <= 0;
            size <= 0;
        end else begin
            if (enqueue) begin
                head_ptr <= (head_ptr + 1) % DEPTH;
            end
            if (dequeue) begin
                tail_ptr <= (tail_ptr + 1) % DEPTH;
            end

            if (enqueue ^ dequeue) begin
                size <= (enqueue) ? size + 1 : size - 1;
            end
        end
    end

    assign full  = (size == MAX_DEPTH);
    assign empty = (head_ptr == tail_ptr);

endmodule

module stack #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32
) (
    input clk,
    input reset_n,
    input push,
    input pop,
    input      [DATA_WIDTH - 1:0] data_in,
    output     [DATA_WIDTH - 1:0] data_out,
    output full,
    output empty
);
    localparam DEPTH = (1 << ADDR_WIDTH);

    reg [ADDR_WIDTH - 1:0] ptr;
    wire [ADDR_WIDTH - 1:0] r_addr = ptr - 1;
    wire [ADDR_WIDTH - 1:0] w_addr = ptr;

    ram #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    )
    U0 (
        .clk(clk),
        .wen(push),
        .w_addr(w_addr),
        .r_addr(r_addr),
        .data_in(data_in),
        .data_out(data_out)
    );

    always @(posedge clk) begin
        if (~reset_n) begin
            ptr <= 0;
        end else begin
            if (push) begin
                ptr <= ptr + 1;
            end else if (pop) begin
                ptr <= ptr - 1;
            end
        end
    end

    assign full  = (ptr == DEPTH - 1);
    assign empty = (ptr == 0);

endmodule

module ram #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32
) (
    input clk,
    input wen,
    input      [ADDR_WIDTH - 1:0] w_addr,
    input      [ADDR_WIDTH - 1:0] r_addr,
    input      [DATA_WIDTH - 1:0] data_in,
    output reg [DATA_WIDTH - 1:0] data_out
);
    localparam DEPTH = (1 << ADDR_WIDTH);

    reg [DATA_WIDTH - 1:0] mem [0:DEPTH-1];

    always @(posedge clk) begin
        if (wen) begin
            mem[w_addr] <= data_in;
        end
        data_out <= mem[r_addr];
    end
endmodule

module rom #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter INIT_FILE = `SYNTH_CFILE
) (
    input clk,
    input      [ADDR_WIDTH - 1:0] r_addr,
    output reg [DATA_WIDTH - 1:0] data_out
);
    localparam DEPTH = (1 << ADDR_WIDTH);

    reg [DATA_WIDTH - 1:0] mem [0:DEPTH-1];

    initial begin
        $readmemh(INIT_FILE, mem);
    end

    always @(posedge clk) begin
        data_out <= mem[r_addr];
    end
endmodule
