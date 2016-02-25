`define MEM_SIZE 'h10_0000
`define WORD_SIZE 8

`include "utils.sv"
`include "tasks.sv"

module tb();
    integer ifh, ofh;

    // Inputs
    reg CLK;
    reg RESET;
    reg ENABLE;
    reg [31:0] DATA;

    // Outputs
    wire OUT;

    // Internal
    reg [`WORD_SIZE - 1:0] mem[0:`MEM_SIZE];

    // Instantiate the Unit Under Test (DUT)
    top dut (
        .CLK(CLK),
        .RESET(RESET),
        .ENABLE(ENABLE),
        .DATA(DATA),
        .OUT(OUT)
    );

    // Initialization sequence
    initial begin
        // Initialize inputs
        CLK = 0;
        RESET = 1;

        // Deassert reset
        #20
        RESET = 0;
        ENABLE = 1;
        DATA = 0;

        // Open files
        ifh = open_file(`IFILE, "rb");
        ofh = open_file(`OFILE, "wb");

        // Read bitmap
        read_bmp_head(ifh);
        init_mem(ifh, mem);

        // Write bitmap
        write_bmp_head(ifh, ofh);
        write_mem(ofh, mem);
    end

    // Generate clock
    always
        #10 CLK  = ~CLK ;

    // Terminate simulation
    initial begin
        // Close files
        $fclose(ifh);
        $fclose(ofh);

        // Exit
        #1000 $finish;
    end

    //--------------------------------------------------------------------------
    // Write test logic here!
    //--------------------------------------------------------------------------
    always @ (posedge CLK) begin
        #20 DATA = 0;
    end


endmodule
