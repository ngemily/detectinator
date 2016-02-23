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
        ifh = open_file(`IFILE, "r");
        ofh = open_file(`OFILE, "w");

        // Read bitmap header
        #20 read_bmp_head(ifh);

        // Copy header to output file
        write_bmp_head(ifh, ofh);
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
