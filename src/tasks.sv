`define IFILE "init/balloon.bmp"
`define OFILE "dump/output.txt"

function integer open_file(
    input string fname,
    input string mode
);
    integer fh;

    fh = $fopen(fname, mode);
    if (fh == 0) begin
        $display("Error: Failed to open file.\n");
        $display("Exiting Simulation.\n");
        $finish;
    end

    return fh;
endfunction

/**
* Copy input bitmap header to output bitmap.
*/
task write_bmp_head(
    input integer ifh,
    input integer ofh
);
    integer i, r;
    integer offset_to_data;

    reg [7:0] value0;
    reg [7:0] value1;
    reg [7:0] value2;
    reg [7:0] value3;
    reg [31:0] value_32;


    r = $fseek(ifh, 10, 0);
    offset_to_data = Utils#($bits(value_32))::read(ifh, "offset to data");

    // Copy from header from input file.
    //
    // Read 4 bytes and write a word because endianness and different sized
    // data types, and may only write with the granularity of one word.
    r = $fseek(ifh, 0, 0);
    for (i = 0; i < offset_to_data / 8; i++) begin
        r = $fread(value0, ifh);
        r = $fread(value1, ifh);
        r = $fread(value2, ifh);
        r = $fread(value3, ifh);
        $fwrite(ofh, "%u", { value3, value2, value1, value0 });
    end

endtask

/**
* Read bitmap header.
*/
task read_bmp_head(
    input integer ifh
);
    integer j, r;

    reg [31:0] offset_to_data;
    reg [31:0] value_32;
    reg [23:0] value_24;
    reg [15:0] value_16;
    reg [7:0] value_8;

    // Read bitmap header
    value_16 = Utils#($bits(value_16))::read(ifh, "signature");
    value_32 = Utils#($bits(value_32))::read(ifh, "size of file");
    value_32 = Utils#($bits(value_32))::read(ifh, "reserved");
    offset_to_data = Utils#($bits(value_32))::read(ifh, "offset to data");
    value_32 = Utils#($bits(value_32))::read(ifh, "size of header");
    value_32 = Utils#($bits(value_32))::read(ifh, "width");
    value_32 = Utils#($bits(value_32))::read(ifh, "height");
    value_16 = Utils#($bits(value_16))::read(ifh, "planes");
    value_16 = Utils#($bits(value_16))::read(ifh, "bits per pixel");

    // Seek to data. read pixel data.
    r = $fseek(ifh, offset_to_data, 0);
    for (j = 0; j < 12; j++) begin
        #10
        r = $fread(value_24, ifh);
        $display("mem_Address = %x ; mem_Content = %x", j, value_24);
    end
endtask
