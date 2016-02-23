`include "utils.sv"
`include "tasks.sv"

module tb();

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

        // Read bitmap header
        #20 read_bmp_head;

    end

    // Generate clock
    always
        #10 CLK  = ~CLK ;

    // Terminate simulation
    initial
        #1000 $finish;

    //--------------------------------------------------------------------------
    // Write test logic here!
    //--------------------------------------------------------------------------
    always @ (posedge CLK) begin
        #20 DATA = 0;
    end


endmodule
