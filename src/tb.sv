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

    // Internal
    wire [`PIXEL_SIZE - 1:0] label;

    // Outputs
    reg [`PIXEL_SIZE - 1:0] out;

    // Metadata
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
    reg [`PIXEL_SIZE - 1:0] color_table[0:`C_TABLE_SIZE];

    // Instantiate the Unit Under Test (DUT)
    top dut (
        .clk(clk),
        .reset_n(reset_n),
        .en(en),
        .hsync(hsync),
        .vsync(vsync),
        .data(data),
        .out(label)
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

        // Read externally generated color table.
        $readmemh(`CFILE, color_table);

        #30_000
        // Error checking
        $monitor("ERROR: %d ns min and max label match on a merge %b",
            $time, dut.U2.merge && (dut.U2.min_label == dut.U2.max_label));
        $monitor("ERROR: %d ns A neither min nor max on a merge %b",
            $time, dut.U2.merge && (dut.U2.A && dut.U2.A != dut.U2.min_label && dut.U2.A != dut.U2.max_label));
        $monitor("ERROR: %d ns B neither min nor max on a merge %b",
            $time, dut.U2.merge && (dut.U2.B && dut.U2.B != dut.U2.min_label && dut.U2.B != dut.U2.max_label));
        $monitor("ERROR: %d ns C neither min nor max on a merge %b",
            $time, dut.U2.merge && (dut.U2.C && dut.U2.C != dut.U2.min_label && dut.U2.C != dut.U2.max_label));
        $monitor("ERROR: %d ns D neither min nor max on a merge %b",
            $time, dut.U2.merge && (dut.U2.D && dut.U2.D != dut.U2.min_label && dut.U2.D != dut.U2.max_label));

    end

    // ====================
    // Termination sequence
    // ====================
    initial begin
        #3_000_000

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
        /***** Input stimulus *****/
        data = {mem[count + 2], mem[count + 1], mem[count + 0]};

        if (count % (width * bytes_per_pixel) == 0) begin
            hsync = 1;
        end else begin
            hsync = 0;
        end

        /***** Output verification *****/
        out = color_table[label[7:0]];      // cc output
        //out = { 3{label[15:8]} };         // threshold output
        //out = { 3{label[23:16]} };        // sobel output

        mem[count + 0] = out[7:0];
        mem[count + 1] = out[15:8];
        mem[count + 2] = out[23:16];

        /***** Test bench logic *****/
        count += 3;
    end

endmodule
