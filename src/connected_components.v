`include "global.vh"

/**
* Connected components labeling
*
* Expected input:
*   +---+---+---+
*   | A | B | C |
*   +---+---+
*   | D | p |
*   +---+---+
*
* Output labelled image.
*/
module connected_components_labeling(
    input clk,
    input reset_n,
    input en,
    input [`LBL_WIDTH - 1:0] A,
    input [`LBL_WIDTH - 1:0] B,
    input [`LBL_WIDTH - 1:0] C,
    input [`LBL_WIDTH - 1:0] D,
    input p,
    input [`LOC_SIZE - 1:0] x,
    input [`LOC_SIZE - 1:0] y,
    input [`LBL_WIDTH - 1:0] obj_id,
`ifndef STANDALONE
    output [`LBL_WIDTH - 1:0] q,
    output reg [`LBL_WIDTH - 1:0] num_labels,
    output [`LOC_SIZE - 1:0] obj_area,
    output [`LOC_SIZE - 1:0] obj_x,
    output [`LOC_SIZE - 1:0] obj_y
`else
    output [`LBL_WIDTH - 1:0] q
`endif
);

`ifdef STANDALONE
    reg [`LBL_WIDTH - 1:0] num_labels;
`endif
    // Pipeline registers
    reg [`LBL_WIDTH - 1:0] label_delay  [1:0];
    reg [`LBL_WIDTH - 1:0] q_delay;
    reg [`D_WIDTH - 1:0]    p_delay      [2:0];
    reg                    data_valid   [2:0];

    // Label selection/Merge table
    reg [`LBL_WIDTH * 2 - 1:0] stack_entry_delay;

    // Merge stack/Merge table
    reg is_merge_delay;

    // Label selection signals
    wire is_background;
    wire is_new_label;
    wire is_merge;
    wire [`LBL_WIDTH - 1:0] min_label;
    wire [`LBL_WIDTH - 1:0] max_label;
    wire [`LBL_WIDTH - 1:0] label;

    label_selector U2(
        .A(A),
        .B(B),
        .C(C),
        .D(D),
        .p(p),
        .num_labels(num_labels),
        .is_background(is_background),
        .is_new_label(is_new_label),
        .is_merge(is_merge),
        .label(label),
        .min_label(min_label),
        .max_label(max_label)
    );

    wire valid = en & ~(is_new_label | is_background);    // no valid table entries

    // Stack manager
    wire popped;
    wire stack_sel;
    wire [`LBL_WIDTH * 2 - 1:0] stack_top;
    wire [`LBL_WIDTH * 2 - 1:0] stack_entry;    // Assume max one merge per neighbourhood.

    assign stack_entry = {max_label, min_label};
    assign stack_sel   = y[0];

    merge_ctrl U1 (
        .clk(clk),
        .reset_n(reset_n),
        .push(is_merge_delay),
        .stack_sel(stack_sel),
        .stack_entry(stack_entry_delay),
        .popped(popped),
        .stack_top(stack_top)
    );

    // Merge table
    wire write_merge          = popped | is_new_label;

    wire [`LBL_WIDTH - 1:0] index;
    wire [`LBL_WIDTH - 1:0] target;
    wire [`LBL_WIDTH - 1:0] resolved_label;

    assign index  = (is_new_label) ? num_labels : stack_top[2 * `LBL_WIDTH - 1 -: `LBL_WIDTH];
    assign target = (is_new_label) ? num_labels : stack_top[1 * `LBL_WIDTH - 1 -: `LBL_WIDTH];

    ram #(
        .ADDR_WIDTH(`LBL_WIDTH),
        .DATA_WIDTH(`LBL_WIDTH)
    )
    MERGE_TABLE (
        .clk(clk),
        .wen(write_merge),
        .w_addr(index),
        .r_addr(label_delay[0]),
        .data_in(target),
        .data_out(resolved_label)
    );


    // Data table
    wire [`D_WIDTH - 1:0] data_in;
    wire [`D_WIDTH - 1:0] data_out1;
    wire [`D_WIDTH - 1:0] data_out2;

    // Feed into SR
    wire [`OBJ_WIDTH - 1:0] p_in = p;
    wire [`OBJ_WIDTH - 1:0] xp   = x * p;
    wire [`OBJ_WIDTH - 1:0] yp   = y * p;

    // Coming out of SR
    wire [`OBJ_WIDTH - 1:0] p_acc = data_out1[1 * `OBJ_WIDTH - 1 -: `OBJ_WIDTH] + p_delay[2][1 * `OBJ_WIDTH - 1 -: `OBJ_WIDTH];
    wire [`OBJ_WIDTH - 1:0] x_acc = data_out1[2 * `OBJ_WIDTH - 1 -: `OBJ_WIDTH] + p_delay[2][2 * `OBJ_WIDTH - 1 -: `OBJ_WIDTH];
    wire [`OBJ_WIDTH - 1:0] y_acc = data_out1[3 * `OBJ_WIDTH - 1 -: `OBJ_WIDTH] + p_delay[2][3 * `OBJ_WIDTH - 1 -: `OBJ_WIDTH];

    // Data layout
    //  0 15:0  - 00
    //  1 31:16 - 01
    //  2 47:32 - 10

    assign data_in = (data_valid[2]) ? {y_acc, x_acc, p_acc} : p_delay[2] ;

    ram_dr_sw #(
        .ADDR_WIDTH(`LBL_WIDTH),
        .DATA_WIDTH(`D_WIDTH)
    )
    DATA_TABLE (
        .clk(clk),
        .wen(1'b1),
        .w_addr(q_delay),
        .r_addr1(q),
        .r_addr2(obj_id),
        .data_in(data_in),
        .data_out1(data_out1),
        .data_out2(data_out2)
    );

    always @(posedge clk) begin
        if (~reset_n) begin
            num_labels <= 1;        // 0 is reserved
        end else if (en) begin
            // Label count
            if (is_new_label && num_labels < `MAX_LABEL - 1) begin
                num_labels <= num_labels + 1;
            end
        end

        if (en) begin
            // Data valid
            //  Cheat (a little).  We know which values we have populated into
            //  the merge table, and we know what address we're reading this
            //  cycle, so we can predict data valid rather than set it properly.
            data_valid[2] <= data_valid[1];
            data_valid[1] <= data_valid[0];
            data_valid[0] <= valid;

            // Register current label, to match the delay from reading from the
            // merge table.
            label_delay[1] <= label_delay[0];
            label_delay[0] <= label;

            // Register input to merge stacks.
            stack_entry_delay  <= stack_entry;

            // Takes one cycle to read from merge stack, so delay writing to
            // merge table.
            is_merge_delay <= is_merge;

            // Register current output, for writing data next cycle.
            q_delay <= q;

            // Register current pixel, for writing into data tbale.
            p_delay[2] <= p_delay[1];
            p_delay[1] <= p_delay[0];
            p_delay[0] <= {xp, yp, p_in};
        end
    end

    // Output either merge table output
    assign q = (data_valid[1]) ? resolved_label : label_delay[1];

    // Output requested object location.
    wire [`OBJ_WIDTH - 1:0] obj_a     = data_out2[1 * `OBJ_WIDTH - 1 -: `OBJ_WIDTH];
    wire [`OBJ_WIDTH - 1:0] obj_x_acc = data_out2[2 * `OBJ_WIDTH - 1 -: `OBJ_WIDTH];
    wire [`OBJ_WIDTH - 1:0] obj_y_acc = data_out2[3 * `OBJ_WIDTH - 1 -: `OBJ_WIDTH];

    assign obj_area = obj_a[`LOC_SIZE - 1:0];
    assign obj_x = obj_x_acc[`LOC_SIZE - 1:0];
    assign obj_y = obj_y_acc[`LOC_SIZE - 1:0];
endmodule

/*
* Manage two alternating stacks.  Always pushing to one and popping from the
* other.
*/
module merge_ctrl(
    input clk,
    input reset_n,
    input push,
    input stack_sel,
    input [`LBL_WIDTH * 2 - 1:0] stack_entry,
    output reg popped,
    output [`LBL_WIDTH * 2 - 1:0] stack_top
);
    wire push_0;
    wire pop_0;
    wire full_0;
    wire empty_0;

    wire push_1;
    wire pop_1;
    wire full_1;
    wire empty_1;

    wire [`LBL_WIDTH * 2 - 1:0] stack0_top;
    wire [`LBL_WIDTH * 2 - 1:0] stack1_top;

    stack #(
        .ADDR_WIDTH(`WORD_SIZE),
        .DATA_WIDTH(`LBL_WIDTH * 2)
    )
    U0 (
        .clk(clk),
        .reset_n(reset_n),
        .data_in(stack_entry),
        .data_out(stack0_top),
        .push(push_0),
        .pop(pop_0),
        .empty(empty_0),
        .full(full_0)
    );

    stack #(
        .ADDR_WIDTH(`WORD_SIZE),
        .DATA_WIDTH(`LBL_WIDTH * 2)
    )
    U1 (
        .clk(clk),
        .reset_n(reset_n),
        .data_in(stack_entry),
        .data_out(stack1_top),
        .push(push_1),
        .pop(pop_1),
        .empty(empty_1),
        .full(full_1)
    );

    // Push on a merge.
    assign push_0 = push && ~stack_sel;
    assign push_1 = push &&  stack_sel;

    // Pop while not empty.
    assign pop_0 =  stack_sel && ~empty_0;
    assign pop_1 = ~stack_sel && ~empty_1;

    always @(posedge clk) begin
        popped <= pop_0 || pop_1;
    end

    assign stack_top = (stack_sel) ? stack0_top : stack1_top;
endmodule

module label_selector(
    input [`LBL_WIDTH - 1:0] A,
    input [`LBL_WIDTH - 1:0] B,
    input [`LBL_WIDTH - 1:0] C,
    input [`LBL_WIDTH - 1:0] D,
    input p,
    input [`LBL_WIDTH - 1:0] num_labels,
    output is_background,
    output is_new_label,
    output is_merge,
    output [`LBL_WIDTH - 1:0] label,
    output [`LBL_WIDTH - 1:0] min_label,
    output [`LBL_WIDTH - 1:0] max_label
);
    wire [`LBL_WIDTH - 1:0] _A;
    wire [`LBL_WIDTH - 1:0] _B;
    wire [`LBL_WIDTH - 1:0] _C;
    wire [`LBL_WIDTH - 1:0] _D;

    wire copy_a;
    wire copy_b;
    wire copy_c;
    wire copy_d;

    assign is_background = !p;
    assign is_new_label = ~(A || B || C || D) & ~is_background;
    assign copy_a = A
        && (A == B || !B)
        && (A == C || !C)
        && (A == D || !D);
    assign copy_b = B
        && (B == A || !A)
        && (B == C || !C)
        && (B == D || !D);
    assign copy_c = C
        && (C == B || !B)
        && (C == A || !A)
        && (C == D || !D);
    assign copy_d =  D
        && (D == B || !B)
        && (D == C || !C)
        && (D == A || !A);
    assign is_merge = ~(is_background | is_new_label | copy_a | copy_b | copy_c | copy_d);

    // Don't want to count 0 in min label.
    assign _A = (A == 0) ? `MAX_LABEL : A;
    assign _B = (B == 0) ? `MAX_LABEL : B;
    assign _C = (C == 0) ? `MAX_LABEL : C;
    assign _D = (D == 0) ? `MAX_LABEL : D;

    min4 M0(_A, _B, _C, _D, min_label);
    max4 M1(A, B, C, D, max_label);

    assign label = (is_background) ?          0 :
                    (is_new_label) ? num_labels :
                          (copy_a) ?          A :
                          (copy_b) ?          B :
                          (copy_c) ?          C :
                          (copy_d) ?          D :
                                      min_label ;
endmodule
