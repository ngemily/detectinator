/**
* Generate (x, y) co-ordinates from sync signals.
*/
module location_generator(
    input clk,
    input reset_n,
    input en,
    input hsync,
    input vsync,
    output reg [15:0] x,
    output reg [15:0] y,
    output reg [15:0] frame
);
    // Update location using HSYNC and VSYNC
    always @(posedge clk) begin
        if (~reset_n) begin
            x <= 0;
            y <= 0;
            frame <= 0;
        end else if (en) begin
            if (hsync) begin
                // new row
                x <= 0;
                y <= y + 1;
            end else if (vsync) begin
                // new frame
                x <= 0;
                y <= 0;
                frame <= frame + 1;
            end else begin
                // new column
                x <= x + 1;
            end
        end
    end

endmodule
