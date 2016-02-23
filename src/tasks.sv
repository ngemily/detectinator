`define IFILE "init/balloon.bmp"
`define OFILE "dump/output.txt"

/**
* Copy input bitmap header to output bitmap.
*/
task write_bmp_head(
    input integer ifh,
    input integer offset
);
    integer i, r, ofh;
    reg [7:0] value0;
    reg [7:0] value1;
    reg [7:0] value2;
    reg [7:0] value3;

    $display("offset %x\n", offset);

    // Open file for writing.
    ofh = $fopen(`OFILE, "w");
    if (ofh == 0) begin
        $display("Error: Failed to open output...\n Exiting Simulation.");
        $finish;
    end

    // Copy from header from input file.
    //
    // Read 4 bytes and write a word because endianness and different sized
    // data types, and may only write with the granularity of one word.
    r = $fseek(ifh, 0, 0);
    for (i = 0; i < offset / 8; i++) begin
        r = $fread(value0, ifh);
        r = $fread(value1, ifh);
        r = $fread(value2, ifh);
        r = $fread(value3, ifh);
        $fwrite(ofh, "%u", { value3, value2, value1, value0 });
    end

    // close output file
    $fclose(ofh);

endtask

/**
* Read bitmap header.
*/
task read_bmp_head;
    integer j, r, fh;

    reg [31:0] offset_to_data;
    reg [31:0] value_32;
    reg [23:0] value_24;
    reg [15:0] value_16;
    reg [7:0] value_8;

    // Open file in read mode
    fh = $fopen(`IFILE, "r");
    if (fh == 0) begin
        $display("Error: Failed to open file...\n Exiting Simulation.");
        $finish;
    end

    // Read bitmap header
    value_16 = Utils#($bits(value_16))::read(fh, "signature");
    value_32 = Utils#($bits(value_32))::read(fh, "size of file");
    value_32 = Utils#($bits(value_32))::read(fh, "reserved");
    offset_to_data = Utils#($bits(value_32))::read(fh, "offset to data");
    value_32 = Utils#($bits(value_32))::read(fh, "size of header");
    value_32 = Utils#($bits(value_32))::read(fh, "width");
    value_32 = Utils#($bits(value_32))::read(fh, "height");
    value_16 = Utils#($bits(value_16))::read(fh, "planes");
    value_16 = Utils#($bits(value_16))::read(fh, "bits per pixel");

    // Seek to data. read pixel data.
    r = $fseek(fh, offset_to_data, 0);
    for (j = 0; j < 12; j++) begin
        #10
        r = $fread(value_24, fh);
        $display("mem_Address = %x ; mem_Content = %x", j, value_24);
    end

    // Copy header to output file
    write_bmp_head(fh, offset_to_data);

    // Close file.
    $fclose(fh);

endtask
