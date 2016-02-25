`include "global.vh"

`include "utils.sv"
`include "tasks.sv"

module tb();
    integer ifh, ofh;

    // Inputs
    reg clk;
    reg reset;
    reg en;
    reg [`PIXEL_SIZE:0] data;

    // Outputs
    wire [`PIXEL_SIZE:0] out;

    // Internal
    integer width;
    integer height;
    integer size_of_data;
    integer offset_to_data;
    integer count;
    reg [`WORD_SIZE - 1:0] mem[0:`MEM_SIZE];

    // Instantiate the Unit Under Test (DUT)
    top dut (
        .clk(clk),
        .reset(reset),
        .en(en),
        .data(data),
        .out(out)
    );

    // =======================
    // Initialization sequence
    // =======================
    initial begin
        // Initialize inputs
        clk = 0;
        reset = 1;
        count = 0;

        // Deassert reset
        #20
        reset = 0;
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
            .offset_to_data(offset_to_data)
        );

        init_mem(
            .ifh(ifh),
            .bytes(size_of_data),
            .mem(mem)
        );

    end

    // ====================
    // Termination sequence
    // ====================
    initial begin
        #500_000

        // Write bitmap
        write_bmp_head(ifh, ofh);
        write_mem(
            .ofh(ofh),
            .bytes(size_of_data),
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
        mem[count + 1] = out[15:8];
        mem[count + 2] = out[23:16];
        count += 3;
    end

endmodule
