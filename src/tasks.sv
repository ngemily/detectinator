`define IFILE "imgs/balloon.bmp"
`define OFILE "dump/out.bmp"

/**
* Open file.  Return file handle.
*/
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
    for (i = 0; i < offset_to_data; i += 4) begin
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
    value_32 = Utils#($bits(value_32))::read(ifh, "compression method");
    value_32 = Utils#($bits(value_32))::read(ifh, "size of data");
    value_32 = Utils#($bits(value_32))::read(ifh, "horizontal res");
    value_32 = Utils#($bits(value_32))::read(ifh, "vertical res");
    value_32 = Utils#($bits(value_32))::read(ifh, "no. colors");
    value_32 = Utils#($bits(value_32))::read(ifh, "no. important colors");

    // Seek to data. read pixel data.
    r = $fseek(ifh, offset_to_data, 0);
endtask

/**
* Read image data into memory.
*/
task init_mem(
    input integer fh,
    output reg [`WORD_SIZE - 1:0] mem[0:`MEM_SIZE]
);
    integer i, r;
    reg [7:0] pixel;

    for (i = 0; i < 'h3020c; i++) begin
        r = $fread(pixel, fh);
        mem[i] = pixel;
    end

endtask

/*
* Write image data to file.
*/
task write_mem(
    input integer fh,
    input reg [`WORD_SIZE - 1:0] mem[0:`MEM_SIZE]
);
    integer i;
    reg [31:0] value;

    // WARNING alignment issues with size of header.
    //
    // $fwrite may only write a word (4 bytes) at a time, but start of image
    // data is not word aligned.  At this time, it is not clear whether or not
    // a static offset will work for all images.
    for (i = 2; i < 'h3020c; i += 4) begin
        value = {mem[i+3], mem[i+2], mem[i+1], mem[i+0]};
        $fwrite(fh, "%u", value);
    end

endtask
