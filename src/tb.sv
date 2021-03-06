`include "global.vh"

`include "utils.sv"
`include "tasks.sv"

`timescale 1ns/100ps

module tb();
    integer i, ifh, ofh, dfh;

    // Inputs
    reg clk;
    reg reset_n;
    reg en;
    reg [`PIXEL_SIZE - 1:0] data;
    reg [`LBL_WIDTH - 1:0] obj_id = 1;
    wire [`WORD_SIZE - 1:0] mode = `OUT;
    wire [`LBL_WIDTH - 1:0] num_labels;
    wire [`LOC_SIZE - 1:0] obj_area;
    wire [`LOC_SIZE - 1:0] obj_x;
    wire [`LOC_SIZE - 1:0] obj_y;
    wire [`LOC_SIZE - 1:0] obj_m02;
    wire [`LOC_SIZE - 1:0] obj_m11;
    wire [`LOC_SIZE - 1:0] obj_m20;
    wire [`LOC_SIZE - 1:0] obj_m30;
    wire [`LOC_SIZE - 1:0] obj_m21;
    wire [`LOC_SIZE - 1:0] obj_m12;
    wire [`LOC_SIZE - 1:0] obj_m03;

    // Outputs
    reg [`PIXEL_SIZE - 1:0] out;

    // Metadata
    integer width;
    integer height;
    integer size_of_data;
    integer offset_to_data;
    integer count;
    integer padding;
    integer bytes_per_pixel;

    reg hsync;
    reg vsync;
    wire [`LOC_SIZE - 1:0] x;
    wire [`LOC_SIZE - 1:0] y;
    wire [`LOC_SIZE - 1:0] frame;

    reg [`WORD_SIZE - 1:0] mem[0:`MEM_SIZE];
    reg [`PIXEL_SIZE - 1:0] color_table[0:`MAX_LABEL];

    // Instantiate the Unit Under Test (DUT)
    top dut (
        .clk(clk),
        .reset_n(reset_n),
        .en(en),
        .x(x),
        .y(y),
        .mode(mode),
        .data(data),
        .sobel_threshold(`SOBEL_THRESHOLD),
        .flood1_threshold(`FLOOD_THRESHOLD),
        .flood2_threshold(`FLOOD_THRESHOLD),
        .obj_id(obj_id),
        .out(out),
        .obj_area(obj_area),
        .obj_x(obj_x),
        .obj_y(obj_y),
        .num_labels(num_labels),
        .obj_m02(obj_m02),
        .obj_m11(obj_m11),
        .obj_m20(obj_m20),
        .obj_m30(obj_m30),
        .obj_m21(obj_m21),
        .obj_m12(obj_m12),
        .obj_m03(obj_m03)
    );

    // Generate x, y co-ords
    location_generator U4(
        .clk(clk),
        .reset_n(reset_n),
        .en(en),
        .hsync(hsync),
        .vsync(vsync),
        .x(x),
        .y(y),
        .frame(frame)
    );

    // =======================
    // Initialization sequence
    // =======================
    initial begin
        // Initialize inputs
        clk = 0;
        reset_n = 0;
        count = 0;
        en = 0;
        hsync = 0;
        vsync = 0;

        // Take out of reset
        #20
        reset_n = 1;
        en = 1;
        data = 0;

        // Open files
        ifh = open_file(`IFILE, "rb");
        ofh = open_file(`OFILE, "wb");

        // Read bitmap
        read_bmp_head(
            .ifh(ifh),
            .width(width),
            .height(height),
            .size_of_data(size_of_data),
            .offset_to_data(offset_to_data),
            .padding(padding),
            .bytes_per_pixel(bytes_per_pixel)
        );

        init_mem(
            .ifh(ifh),
            .bytes_per_row(width * bytes_per_pixel),
            .rows(height),
            .padding(padding),
            .mem(mem)
        );

        // Read externally generated color table.
        $readmemh(`SIM_CFILE, color_table);

        #30_000
        /*** Error checking ***/
`ifdef RTL_SIM
        // Merge with itself.
        $monitor("ERROR: %d ns min and max label match on a merge %b",
            $time, dut.U2.is_merge && (dut.U2.min_label == dut.U2.max_label));

        // 3-way merge
        $monitor("ERROR: %d ns A neither min nor max on a merge %b",
            $time, dut.U2.is_merge && (dut.U2.A && dut.U2.A != dut.U2.min_label && dut.U2.A != dut.U2.max_label));
        $monitor("ERROR: %d ns B neither min nor max on a merge %b",
            $time, dut.U2.is_merge && (dut.U2.B && dut.U2.B != dut.U2.min_label && dut.U2.B != dut.U2.max_label));
        $monitor("ERROR: %d ns C neither min nor max on a merge %b",
            $time, dut.U2.is_merge && (dut.U2.C && dut.U2.C != dut.U2.min_label && dut.U2.C != dut.U2.max_label));
        $monitor("ERROR: %d ns D neither min nor max on a merge %b",
            $time, dut.U2.is_merge && (dut.U2.D && dut.U2.D != dut.U2.min_label && dut.U2.D != dut.U2.max_label));

        // Merge stack
        $monitor("ERROR: %d ns stack0 pushing and popping at the same time! %b",
            $time, dut.U2.U1.U0.push && dut.U2.U1.U0.pop);
        $monitor("ERROR: %d ns stack1 pushing and popping at the same time! %b",
            $time, dut.U2.U1.U1.push && dut.U2.U1.U1.pop);
        $monitor("ERROR: %d ns popping from stack0 and stack1 at the same time! %b",
            $time, dut.U2.U1.U0.pop && dut.U2.U1.U1.pop);
        $monitor("ERROR: %d ns pushing to stack0 and stack1 at the same time! %b",
            $time, dut.U2.U1.U0.push && dut.U2.U1.U1.push);
`endif

        // Test abrupt enable/disable
        #500_000 en = 0;
        #500_000 en = 1;
        #500_000 en = 0;
        #500_000 en = 1;

    end

    // ====================
    // Termination sequence
    // ====================
    initial begin
        #`SIM_TIME

        // Write bitmap
        write_bmp_head(ifh, ofh);

`ifdef RTL_SIM
        if (mode == `CC || mode == `COLOR) begin
            if (mode == `CC) begin
                color_labels(
                    .bytes_per_row(width * bytes_per_pixel),
                    .rows(height),
                    .mem(mem)
                );
            end

            draw_dots(
                .bytes_per_row(width * bytes_per_pixel),
                .rows(height),
                .mem(mem),
                .merge_table(dut.U2.MERGE_TABLE.mem),
                .data_table(dut.U2.DATA_TABLE.mem)
            );

            dfh = open_file("out/data_table.txt", "w");
            dump_data (
                .ofh(dfh),
                .mem(dut.U2.DATA_TABLE.mem)
            );
            $fclose(dfh);
        end
`endif

        write_mem(
            .ofh(ofh),
            .bytes_per_row(width * bytes_per_pixel),
            .rows(height),
            .padding(padding),
            .mem(mem)
        );

        $display("Found %d labels.", num_labels);
        dfh = open_file("out/roi.txt", "w");
        for (i = 0; i < num_labels; i++) begin
            #50
            obj_id <= obj_id + 1;
            $fwrite(dfh, "%h: %h %d %d\n", obj_id, obj_area, obj_x / obj_area, obj_y / obj_area);
        end
        $fclose(dfh);

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
        /***** Input stimulus *****/
        data = {mem[count + 2], mem[count + 1], mem[count + 0]};

        if (count % (width * bytes_per_pixel) == 0) begin
            hsync = 1;
        end else begin
            hsync = 0;
        end

        if (en) begin
            /***** Output verification *****/
            mem[count + 0] = out[7:0];
            mem[count + 1] = out[15:8];
            mem[count + 2] = out[23:16];

            /***** Test bench logic *****/
            count += 3;
        end
    end

endmodule
