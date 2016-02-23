`include "utils.sv"
`include "tasks.sv"
module tb;

    integer out_ptr  ;
    integer r;

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

    initial begin

        // Initialize Inputs
        CLK = 0;
        RESET = 1;

        #20
        RESET = 0;
        ENABLE = 1;
        DATA = 0;

        #20 read_bmp_head;

        #1000 $finish;
    end
    //--------------------------------------------------------------------------
    // Generate the periodic clock signal
    always
        #10 CLK  = ~CLK ;
    //--------------------------------------------------------------------------
    // Write Computed output to file after every clock cycle
    //--------------------------------------------------------------------------

    always @ (posedge CLK)
    begin   : output_text_file
            #20
            //$fwrite(out_ptr,"%d\n",OUT);    // Here OUT is the signal you want to write in file
            //$display("Time=%t ; OUT=%d ", $time,OUT);
            DATA = 0;
    end


endmodule
