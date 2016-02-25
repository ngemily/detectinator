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
    //reg [`MEM_SIZE:0] count;
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
        read_bmp_head(ifh);
        init_mem(ifh, mem);

    end

    // ====================
    // Termination sequence
    // ====================
    initial begin
        #1000

        // Write bitmap
        write_bmp_head(ifh, ofh);
        write_mem(ofh, mem);

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
        data = mem[count];
        $display("0x%x", out);
        count++;
    end

endmodule
