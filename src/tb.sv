module tb;

    integer out_ptr  ;
    integer fh ;
    integer j, value ;
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

        // Output data file (Output data will be written into the file mentioend
        // below)
        out_ptr     = $fopen("dump/output.txt","w");
        if (out_ptr == 0)
        begin
         $display("Error: Failed to open output...\n Exiting Simulation.");
         $finish;
        end


        // Initialize Inputs
        CLK = 0;
        RESET = 1;

        #20
        RESET = 0 ;
        ENABLE = 1;
        DATA = 0;

        #20
        init_mem ;      // To read data from file and intialize the memory

        ///////////// Put you stimulus here ///////////////

        #1000
        $fclose(out_ptr);
        $finish;
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

    virtual class Utils #(
        parameter WIDTH=32
    );
        static function [WIDTH-1:0] reverseEndianness (
            input [WIDTH-1:0] data
        );

            case(WIDTH)
                32: begin
                    reverseEndianness[31:24] = data[7:0];
                    reverseEndianness[23:16] = data[15:8];
                    reverseEndianness[15:8] = data[23:16];
                    reverseEndianness[7:0] = data[31:24];
                end
                24: begin
                    reverseEndianness[23:16] = data[7:0];
                    reverseEndianness[15:8] = data[15:8];
                    reverseEndianness[7:0] = data[23:16];
                end
                16: begin
                    reverseEndianness[15:8] = data[7:0];
                    reverseEndianness[7:0] = data[15:8];
                end
                default: begin
                    reverseEndianness = data;
                end
            endcase

        endfunction

        static function [WIDTH-1:0] read (
            input string s
        );
            integer r;
            r = $fread(read, fh);
            read = Utils#($bits(read))::reverseEndianness(read);
            $display("%20s 0x%h", s, read);
        endfunction
    endclass

    //--------------------------------------------------------------------------
    // This task is to initialize memory from file
    //--------------------------------------------------------------------------
    task init_mem;
    integer j;

    reg [31:0] offset_to_data;
    reg [31:0] value_32;
    reg [23:0] value_24;
    reg [15:0] value_16;
    reg [7:0] value_8;

    begin
        // Open file in read mode
        fh = $fopen("init/balloon.bmp","r");
        if (fh == 0) begin
            $display("Error: Failed to open file...\n Exiting Simulation.");
            $finish;
        end

        // Read bitmap header
        value_16 = Utils#($bits(value_16))::read("signature");
        value_32 = Utils#($bits(value_32))::read("size of file");
        value_32 = Utils#($bits(value_32))::read("reserved");
        offset_to_data = Utils#($bits(value_32))::read("offset to data");
        value_32 = Utils#($bits(value_32))::read("size of header");
        value_32 = Utils#($bits(value_32))::read("width");
        value_32 = Utils#($bits(value_32))::read("height");
        value_16 = Utils#($bits(value_16))::read("planes");
        value_16 = Utils#($bits(value_16))::read("bits per pixel");

        // Seek to data. read pixel data.
        $display("offset %x\n", offset_to_data);
        r = $fseek(fh, offset_to_data, 0);
        for (j = 0; j < 12; j++) begin
            #10
            r = $fread(value_24, fh);
            $display("mem_Address = %x ; mem_Content = %x", j, value_24);
            $fwrite(out_ptr,"%u",value_24);
        end

        // Close file.
        $fclose(fh);
    end
    endtask
    //--------------------------------------------------------------------------
endmodule
