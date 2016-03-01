`include "global.vh"

module top #(
    parameter width = 1,
    parameter height = 1
) (
    input clk,
    input reset,
    input en,
    input hsync,
    input vsync,
    input [`PIXEL_SIZE - 1:0] data,
    output [`PIXEL_SIZE - 1:0] out
);
    wire [7:0] R = data[7:0];
    wire [7:0] G = data[15:8];
    wire [7:0] B = data[23:16];

    reg [`PIXEL_SIZE - 1:0] buf2 [1024:0];
    reg [`PIXEL_SIZE - 1:0] buf1 [1024:0];
    reg [`PIXEL_SIZE - 1:0] buf0 [1024:0];

    integer i;

    always @(posedge clk) begin
        buf0[0] <= data;
        buf1[0] <= buf0[width - 1];
        buf2[0] <= buf1[width - 1];
        for(i = 1; i < width; i = i + 1) begin
            buf2[i] <= buf2[i - 1];
            buf1[i] <= buf1[i - 1];
            buf0[i] <= buf0[i - 1];
        end
    end

    window U0 (
        .p1(buf2[width - 1]),
        .p2(buf2[width - 2]),
        .p3(buf2[width - 3]),
        .p4(buf1[width - 1]),
        .p5(buf1[width - 2]),
        .p6(buf1[width - 3]),
        .p7(buf0[width - 1]),
        .p8(buf0[width - 2]),
        .p9(buf0[width - 3]),
        .q(out)
    );

endmodule

/**
* +---+---+---+
* | 1 | 2 | 3 |
* +---+---+---+
* | 4 | 5 | 6 |
* +---+---+---+
* | 7 | 8 | 9 |
* +---+---+---+
*/

module window(
    input [`PIXEL_SIZE - 1:0] p1,
    input [`PIXEL_SIZE - 1:0] p2,
    input [`PIXEL_SIZE - 1:0] p3,
    input [`PIXEL_SIZE - 1:0] p4,
    input [`PIXEL_SIZE - 1:0] p5,
    input [`PIXEL_SIZE - 1:0] p6,
    input [`PIXEL_SIZE - 1:0] p7,
    input [`PIXEL_SIZE - 1:0] p8,
    input [`PIXEL_SIZE - 1:0] p9,
    output [`PIXEL_SIZE - 1:0] q
);
    wire signed [`PIXEL_SIZE - 1:0] dx;
    wire signed [`PIXEL_SIZE - 1:0] dy;
    wire [`PIXEL_SIZE - 1:0] abs_dx;
    wire [`PIXEL_SIZE - 1:0] abs_dy;

    x_derivative U0 (
        .p1(p1),
        .p2(p2),
        .p3(p3),
        .p4(p4),
        .p5(p5),
        .p6(p6),
        .p7(p7),
        .p8(p8),
        .p9(p9),
        .q(dx)
    );

    y_derivative U1 (
        .p1(p1),
        .p2(p2),
        .p3(p3),
        .p4(p4),
        .p5(p5),
        .p6(p6),
        .p7(p7),
        .p8(p8),
        .p9(p9),
        .q(dy)
    );

    assign abs_dx = (dx < 0) ? -dx : dx;
    assign abs_dy = (dy < 0) ? -dy : dy;
    assign q = abs_dx + abs_dy;
endmodule

module x_derivative(
    input [`PIXEL_SIZE - 1:0] p1,
    input [`PIXEL_SIZE - 1:0] p2,
    input [`PIXEL_SIZE - 1:0] p3,
    input [`PIXEL_SIZE - 1:0] p4,
    input [`PIXEL_SIZE - 1:0] p5,
    input [`PIXEL_SIZE - 1:0] p6,
    input [`PIXEL_SIZE - 1:0] p7,
    input [`PIXEL_SIZE - 1:0] p8,
    input [`PIXEL_SIZE - 1:0] p9,
    output signed [`PIXEL_SIZE - 1:0] q
);
    assign q = (p1 + 2 * p4 + p7) - (p3 + 2 * p6 + p9);
endmodule

module y_derivative(
    input [`PIXEL_SIZE - 1:0] p1,
    input [`PIXEL_SIZE - 1:0] p2,
    input [`PIXEL_SIZE - 1:0] p3,
    input [`PIXEL_SIZE - 1:0] p4,
    input [`PIXEL_SIZE - 1:0] p5,
    input [`PIXEL_SIZE - 1:0] p6,
    input [`PIXEL_SIZE - 1:0] p7,
    input [`PIXEL_SIZE - 1:0] p8,
    input [`PIXEL_SIZE - 1:0] p9,
    output signed  [`PIXEL_SIZE - 1:0] q
);
    assign q = (p1 + 2 * p2 + p3) - (p7 + 2 * p8 + p9);
endmodule
