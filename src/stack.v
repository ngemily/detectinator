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

    parameter WIDTH = 11;
    parameter DEPTH = 7;

    input                    clk;
    input                    reset;
    input      [WIDTH - 1:0] d;
    output reg [WIDTH - 1:0] q;
    input                    push;
    input                    pop;
    output                   empty;
    output                   full;

    reg [DEPTH - 1:0] ptr;
    reg [WIDTH - 1:0] mem [0:(1 << DEPTH) - 1];

    always @(posedge clk) begin
        if (reset)
            ptr <= 0;
        else if (push)
            ptr <= ptr + 1;
        else if (pop)
            ptr <= ptr - 1;
    end

    always @(posedge clk) begin
        if (push || pop) begin
            if(push)
                mem[ptr] <= q;

            q <= mem[ptr - 1];
        end
    end

    assign full  = (ptr == (1 << WIDTH) - 1);
    assign empty = (ptr == 0);

endmodule
