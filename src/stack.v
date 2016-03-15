module stack (
    clk,
    reset,
    q,
    d,
    push,
    pop,
    empty,
    full
);

    parameter WIDTH = 32;
    parameter DEPTH = 8;

    input                    clk;
    input                    reset;
    input      [WIDTH - 1:0] d;
    output reg [WIDTH - 1:0] q;
    input                    push;
    input                    pop;
    output                   empty;
    output                   full;

    reg [DEPTH - 1:0] ptr;
    reg [WIDTH - 1:0] mem [0:DEPTH - 1];

    always @(posedge clk) begin
        if (reset) begin
            ptr <= 0;
        end else begin
            if (push) begin
                mem[ptr] <= d;
                ptr <= ptr + 1;
                q <= 0;
            end else if (pop) begin
                q <= mem[ptr - 1];
                ptr <= ptr - 1;
            end else begin
                q <= 0;
                ptr <= ptr;
            end
        end
    end

    assign full  = (ptr == (1 << WIDTH) - 1);
    assign empty = (ptr == 0);

endmodule

module ram #(
    parameter WIDTH = 32,
    parameter DEPTH = 1024
) (
    input clk,
    input wen,
    input [WIDTH - 1:0] w_addr,
    input [WIDTH - 1:0] r_addr,
    input [WIDTH - 1:0] data_in,
    output reg [WIDTH - 1:0] data_out
);
    reg [WIDTH - 1:0] mem [0: DEPTH - 1];

    always @(posedge clk) begin
        if (wen) begin
            mem[w_addr] <= data_in;
        end
        data_out <= mem[r_addr];
    end
endmodule
