module top (
    input CLK,
    input RESET,
    input ENABLE,
    input [31:0] DATA,
    output OUT
);
    assign OUT = DATA;
endmodule
