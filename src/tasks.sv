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
    input integer ifh,
    output integer width,
    output integer height,
    output integer size_of_data,
    output integer offset_to_data,
    output integer bytes_per_pixel,
    output integer padding
);
    integer bytes_per_row, bits_per_pixel;
    integer r;

    reg [31:0] value_32;
    reg [23:0] value_24;
    reg [`LOC_SIZE - 1:0] value_16;
    reg [7:0] value_8;

    // Read bitmap header
    value_16       = Utils#($bits(value_16))::read(ifh, "signature");
    value_32       = Utils#($bits(value_32))::read(ifh, "size of file");
    value_32       = Utils#($bits(value_32))::read(ifh, "reserved");
    offset_to_data = Utils#($bits(value_32))::read(ifh, "offset to data");
    value_32       = Utils#($bits(value_32))::read(ifh, "size of header");
    width          = Utils#($bits(value_32))::read(ifh, "width");
    height         = Utils#($bits(value_32))::read(ifh, "height");
    value_16       = Utils#($bits(value_16))::read(ifh, "planes");
    bits_per_pixel = Utils#($bits(value_16))::read(ifh, "bits per pixel");
    value_32       = Utils#($bits(value_32))::read(ifh, "compression method");
    size_of_data   = Utils#($bits(value_32))::read(ifh, "size of data");
    value_32       = Utils#($bits(value_32))::read(ifh, "horizontal res");
    value_32       = Utils#($bits(value_32))::read(ifh, "vertical res");
    value_32       = Utils#($bits(value_32))::read(ifh, "no. colors");
    value_32       = Utils#($bits(value_32))::read(ifh, "no. important colors");

    // Bitmaps pad end of row to 4 bytes
    bytes_per_pixel = bits_per_pixel / 8;
    bytes_per_row = width * bytes_per_pixel / 8;
    padding = 4 - (bytes_per_row % 4);

    $display("%20s %d", "bytes_per_pixel", bytes_per_pixel);
    $display("%20s %d", "bytes_per_row", bytes_per_row);
    $display("%20s %d", "padding", padding);

    // Seek to data. read pixel data.
    r = $fseek(ifh, offset_to_data, 0);
endtask

/**
* Read image data into memory.
*/
task init_mem(
    input integer ifh,
    input integer bytes_per_row,
    input integer rows,
    input integer padding,
    output reg [`WORD_SIZE - 1:0] mem[0:`MEM_SIZE]
);
    integer i, j, r;
    reg [7:0] pixel;

    for (i = 0; i < rows; i++) begin
        for (j = 0; j < bytes_per_row; j++) begin
            r = $fread(pixel, ifh);
            mem[i * bytes_per_row + j] = pixel;
        end
        for (j = 0; j < padding; j++) begin
            r = $fgetc(ifh);
        end
    end

`ifdef DEBUG
    $display("Reading...");
    for (i = 0; i < 12; i++) begin
        $display("\t%u: %u", i, mem[i]);
    end
`endif

endtask

/*
* Write image data to file.
*/
task write_mem(
    input integer ofh,
    input integer bytes_per_row,
    input integer rows,
    input integer padding,
    input reg [`WORD_SIZE - 1:0] mem[0:`MEM_SIZE]
);
    integer i, j, idx;
    reg [31:0] value;

`ifdef DEBUG
    $display("Writing...");
    for (i = 5; i < 12; i++) begin
        $display("\t%u: %u", i, mem[i]);
    end
`endif

    // WARNING alignment issues with size of header.
    //
    // $fwrite may only write a word (4 bytes) at a time, but start of image
    // data is not word aligned.  At this time, it is not clear whether or not
    // a static offset will work for all images.
    for (i = 0; i < rows; i++) begin
        for (j = 0; j < bytes_per_row + padding; j += 4) begin
            idx = i * bytes_per_row + j + 5;
            //value = {mem[idx+3], mem[idx+2], mem[idx+1], mem[idx+0]};
            value[31:24] = (j + 3 < bytes_per_row) ? mem[idx + 3] : 8'h0;
            value[23:16] = (j + 2 < bytes_per_row) ? mem[idx + 2] : 8'h0;
            value[15:8]  = (j + 1 < bytes_per_row) ? mem[idx + 1] : 8'h0;
            value[7:0]   = (j + 0 < bytes_per_row) ? mem[idx + 0] : 8'h0;
            $fwrite(ofh, "%u", value);
        end
    end

endtask

`ifdef RTL_SIM
/*
* Do a second pass to show final label in output.
*/
task color_labels(
    input integer bytes_per_row,
    input integer rows,
    inout reg [`WORD_SIZE - 1:0] mem[0:`MEM_SIZE]
);
    integer i, j, idx;
    integer label, resolved_label, color;
    integer p0, p1, p2;

    for (i = 0; i < rows; i++) begin
        for (j = 0; j < bytes_per_row; j += 3) begin
            idx            = i * bytes_per_row + j;
            label          = mem[idx];
`ifdef DISP_RESOLVED_LABEL
            resolved_label = tb.dut.U2.MERGE_TABLE.mem[label[7:0]];
`else
            resolved_label = label;
`endif
            color          = tb.color_table[resolved_label[7:0]];

            //$display("%h %h %h", label, resolved_label, color);

            mem[idx + 0] = color[23:16];
            mem[idx + 1] = color[15:8];
            mem[idx + 2] = color[7:0];
        end
    end

endtask
`endif

/**
* Annotate output image with dots indicating centre of mass of detected objects.
*/
task draw_dots(
    input integer bytes_per_row,
    input integer rows,
    inout reg [`WORD_SIZE - 1:0] mem[0:`MEM_SIZE],
    input reg [383:0] data_table[0:255]
);
    parameter WIDTH = 384;//`WORD_SIZE;
    parameter DEPTH = 255; //`MEM_SIZE;

    localparam NUM_OBJS  = 3;
    localparam OBJ_WIDTH = 128;
    localparam D_WIDTH   = NUM_OBJS * OBJ_WIDTH;

    integer i, idx;
    longint unsigned p_acc;
    longint unsigned x_acc;
    longint unsigned y_acc;
    longint unsigned x_bar;
    longint unsigned y_bar;
    longint unsigned x;
    longint unsigned y;

    $display("%16s %16s %16s %16s", "x_bar", "y_bar", "x", "y");
    for (i = 0; i < DEPTH; i++) begin
        p_acc = data_table[i][1 * OBJ_WIDTH - 1 -: OBJ_WIDTH];
        x_acc = data_table[i][2 * OBJ_WIDTH - 1 -: OBJ_WIDTH];
        y_acc = data_table[i][3 * OBJ_WIDTH - 1 -: OBJ_WIDTH];
        x_bar = x_acc / p_acc;
        y_bar = y_acc / p_acc;
        x = y_bar;
        y = x_bar;

        if (p_acc) begin
            $display("%d %d %d %d", x_bar, y_bar, x, y);
            draw_circle(
                .bytes_per_row(bytes_per_row),
                .x(x),
                .y(y),
                .mem(mem)
            );
        end
    end

endtask

task draw_circle(
    input integer bytes_per_row,
    input integer x,
    input integer y,
    inout reg [`WORD_SIZE - 1:0] mem[0:`MEM_SIZE]
);
    integer idx;

    idx = y * bytes_per_row + x * 3;
    mem[idx - 2] = 255;
    mem[idx - 1] = 255;
    mem[idx] = 255;
    mem[idx + 1] = 255;
    mem[idx + 2] = 255;

    idx = (y + 1) * bytes_per_row + x * 3;
    mem[idx - 1] = 255;
    mem[idx] = 255;
    mem[idx + 1] = 255;

    idx = (y - 1) * bytes_per_row + x * 3;
    mem[idx - 1] = 255;
    mem[idx] = 255;
    mem[idx + 1] = 255;

    idx = (y + 2) * bytes_per_row + x * 3;
    mem[idx] = 255;

    idx = (y - 2) * bytes_per_row + x * 3;
    mem[idx] = 255;
endtask

task dump_data (
    input integer ofh,
    input reg [383:0] mem[0:255]
);
    parameter WIDTH = 384;//`WORD_SIZE;
    parameter DEPTH = 20; //`MEM_SIZE;

    localparam NUM_OBJS  = 3;
    localparam OBJ_WIDTH = 128;
    localparam D_WIDTH   = NUM_OBJS * OBJ_WIDTH;

    integer i;
    longint unsigned p_acc;
    longint unsigned x_acc;
    longint unsigned y_acc;
    longint unsigned x_bar;
    longint unsigned y_bar;

    $fwrite(ofh, "%8s %16s %16s %16s %8s %8s\n",
        "label", "area", "xacc", "yacc", "xbar", "ybar");

    for (i = 0; i < DEPTH; i++) begin
        p_acc = mem[i][1 * OBJ_WIDTH - 1 -: OBJ_WIDTH];
        x_acc = mem[i][2 * OBJ_WIDTH - 1 -: OBJ_WIDTH];
        y_acc = mem[i][3 * OBJ_WIDTH - 1 -: OBJ_WIDTH];
        x_bar = x_acc / p_acc;
        y_bar = y_acc / p_acc;

        if (p_acc) begin
            $fwrite(ofh, "%8d %h %h %h %8d %8d\n", i, p_acc, x_acc, y_acc, x_bar, y_bar);
        end
    end

endtask
