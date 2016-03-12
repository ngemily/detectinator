`include "global.vh"

`include "utils.sv"
`include "tasks.sv"

`timescale 1ns/100ps

module tb();
    integer ifh, ofh;

    // Inputs
    reg clk;
    reg reset_n;
    reg en;
    reg [`PIXEL_SIZE - 1:0] data;

    // Outputs
    wire [`PIXEL_SIZE - 1:0] out;

    // Internal
    integer width;
    integer height;
    integer size_of_data;
    integer offset_to_data;
    integer count;
    integer padding;
    integer bytes_per_pixel;

    reg hsync;
    reg vsync;

    reg [`WORD_SIZE - 1:0] mem[0:`MEM_SIZE];

    // Instantiate the Unit Under Test (DUT)
    top dut (
        .clk(clk),
        .reset_n(reset_n),
        .en(en),
        .hsync(hsync),
        .vsync(vsync),
        .data(data),
        .out(out)
    );

    // =======================
    // Initialization sequence
    // =======================
    initial begin
        // Initialize inputs
        clk = 0;
        reset_n = 0;
        count = 0;
        en = 0;
        hsync = 0;
        vsync = 0;

        // Take out of reset
        #20
        reset_n = 1;
        en = 1;
        data = 0;

        // Open files
        ifh = open_file(`IFILE, "rb");
        ofh = open_file(`OFILE, "wb");

        // Read bitmap
        read_bmp_head(
            .ifh(ifh),
            .width(width),
            .height(height),
            .size_of_data(size_of_data),
            .offset_to_data(offset_to_data),
            .padding(padding),
            .bytes_per_pixel(bytes_per_pixel)
        );

        init_mem(
            .ifh(ifh),
            .bytes_per_row(width * bytes_per_pixel),
            .rows(height),
            .padding(padding),
            .mem(mem)
        );

    end

    // ====================
    // Termination sequence
    // ====================
    initial begin
        #2_000_000

        // Write bitmap
        write_bmp_head(ifh, ofh);
        write_mem(
            .ofh(ofh),
            .bytes_per_row(width * bytes_per_pixel),
            .rows(height),
            .padding(padding),
            .mem(mem)
        );

        // Close files
        $fclose(ifh);
        $fclose(ofh);

        // Exit
        $finish;
    end

    // ----------------
    // Clock generation
    // ----------------
    always
        #10 clk  = ~clk ;

    //-----------
    // Test logic
    //-----------
    always @ (posedge clk) begin
        data = {mem[count + 2], mem[count + 1], mem[count + 0]};
        //$display("0x%x", out);
        mem[count + 0] = out[7:0];
        mem[count + 1] = out[7:0];
        mem[count + 2] = out[7:0];

        if (count % (width * bytes_per_pixel) == 0) begin
            hsync = 1;
        end else begin
            hsync = 0;
        end
`ifdef DEBUG
        if (count < 24) begin
            $display("tb: %u: %u", count + 0, mem[count + 0]);
            $display("tb: %u: %u", count + 1, mem[count + 1]);
            $display("tb: %u: %u", count + 2, mem[count + 2]);
        end
`endif
        count += 3;
    end

endmodule
