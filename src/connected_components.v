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
    input [`WORD_SIZE - 1:0] A,
    input [`WORD_SIZE - 1:0] B,
    input [`WORD_SIZE - 1:0] C,
    input [`WORD_SIZE - 1:0] D,
    input [`WORD_SIZE - 1:0] p,
    input [31:0] x,
    input [31:0] y,
    output [`WORD_SIZE - 1:0] q
);

    // Internal registers
    reg [`WORD_SIZE - 1:0] num_labels;

    // Label selection signals
    wire is_new_label;
    wire is_merge;
    wire [`WORD_SIZE - 1:0] min_label;
    wire [`WORD_SIZE - 1:0] max_label;
    wire [`WORD_SIZE - 1:0] label;
    reg [`WORD_SIZE - 1:0] reg_label;

    label_selector U2(
        .A(A),
        .B(B),
        .C(C),
        .D(D),
        .p(p),
        .num_labels(num_labels),
        .is_new_label(is_new_label),
        .is_merge(is_merge),
        .label(label),
        .min_label(min_label),
        .max_label(max_label)
    );

    // Stack manager
    wire pop;
    wire stack_sel;
    wire [`WORD_SIZE * 2 - 1:0] stack_top;
    wire [`WORD_SIZE * 2 - 1:0] stack_entry;    // Assume max one merge per neighbourhood.

    assign stack_entry = {max_label, min_label};
    assign stack_sel   = y[0];

    merge_ctrl U1 (
        .clk(clk),
        .reset_n(reset_n),
        .push(is_merge),
        .stack_sel(stack_sel),
        .stack_entry(stack_entry),
        .pop(pop),
        .stack_top(stack_top)
    );

    // Merge table
    reg write_merge;
    reg data_valid;

    wire [`WORD_SIZE - 1:0] index;
    wire [`WORD_SIZE - 1:0] target;
    wire [`WORD_SIZE - 1:0] resolved_label;

    assign index  = (is_new_label) ? num_labels : stack_top[15:8];
    assign target = (is_new_label) ? num_labels :  stack_top[7:0];

    ram #(
        .ADDR_WIDTH(`WORD_SIZE),
        .DATA_WIDTH(`WORD_SIZE)
    )
    MERGE_TABLE (
        .clk(clk),
        .wen(write_merge || is_new_label),
        .w_addr(index),
        .r_addr(label),
        .data_in(target),
        .data_out(resolved_label)
    );


    // Data table
    wire [`WORD_SIZE - 1:0] r_addr;
    reg  [`WORD_SIZE - 1:0] w_addr;
    reg  valid [2:0];
    reg  [23:0] buf0 [2:0];
    wire [23:0] data_in;
    wire [23:0] data_out;

    assign r_addr = q;
    assign data_in = (valid[2]) ? data_out + buf0[2] : buf0[2];

    ram #(
        .ADDR_WIDTH(`WORD_SIZE),
        .DATA_WIDTH(24)
    )
    DATA_TABLE (
        .clk(clk),
        .wen(1'b1),
        .w_addr(w_addr),
        .r_addr(r_addr),
        .data_in(data_in),
        .data_out(data_out)
    );

    always @(posedge clk) begin
        w_addr <= r_addr;

        buf0[2] <= buf0[1];
        buf0[1] <= buf0[0];
        buf0[0] <= p;

        valid[2] <= valid[1];
        valid[1] <= valid[0];
        valid[0] <= r_addr < num_labels - 1;
    end

    always @(posedge clk) begin
        if (~reset_n) begin
            num_labels <= 1;        // 0 is reserved
        end else if (en) begin
            // Data valid
            //  Cheat (a little).  We know which values we have populated into
            //  the merge table, and we know what address we're reading this
            //  cycle, so we can predict data valid rather than set it properly.
            if (is_new_label || !label) begin
                data_valid <= 0;
            end else begin
                data_valid <= 1;
            end

            // Label count
            if (is_new_label) begin
                num_labels <= num_labels + 1;
            end else begin
                num_labels <= num_labels;
            end

            // Register write enable on pop, since pop takes one cycle.
            write_merge <= pop;

            // Register current label, to match the delay from reading from the
            // merge table.
            reg_label <= label;
        end
    end

    // Output either merge table output
    assign q = (data_valid) ? resolved_label : reg_label;

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
    input [`WORD_SIZE * 2 - 1:0] stack_entry,
    output pop,
    output [`WORD_SIZE * 2 - 1:0] stack_top
);
    wire push_0;
    wire pop_0;
    wire full_0;
    wire empty_0;

    wire push_1;
    wire pop_1;
    wire full_1;
    wire empty_1;

    wire [`WORD_SIZE * 2 - 1:0] stack0_top;
    wire [`WORD_SIZE * 2 - 1:0] stack1_top;

    stack #(
        .ADDR_WIDTH(`WORD_SIZE),
        .DATA_WIDTH(`WORD_SIZE * 2)
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
        .DATA_WIDTH(`WORD_SIZE * 2)
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
    assign pop   =  pop_0 || pop_1;

    assign stack_top = (stack_sel) ? stack0_top : stack1_top;
endmodule

module label_selector(
    input [`WORD_SIZE - 1:0] A,
    input [`WORD_SIZE - 1:0] B,
    input [`WORD_SIZE - 1:0] C,
    input [`WORD_SIZE - 1:0] D,
    input [`WORD_SIZE - 1:0] p,
    input [`WORD_SIZE - 1:0] num_labels,
    output is_new_label,
    output is_merge,
    output [`WORD_SIZE - 1:0] label,
    output [`WORD_SIZE - 1:0] min_label,
    output [`WORD_SIZE - 1:0] max_label
);
    wire [`WORD_SIZE - 1:0] _A;
    wire [`WORD_SIZE - 1:0] _B;
    wire [`WORD_SIZE - 1:0] _C;
    wire [`WORD_SIZE - 1:0] _D;

    wire is_background;
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
    assign _A = (A == 0) ? `MAX : A;
    assign _B = (B == 0) ? `MAX : B;
    assign _C = (C == 0) ? `MAX : C;
    assign _D = (D == 0) ? `MAX : D;

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
