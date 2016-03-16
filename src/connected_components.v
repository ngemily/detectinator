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
    input [`WORD_SIZE - 1:0] data,
    input [31:0] x,
    input [31:0] y,
    output [`WORD_SIZE - 1:0] q
);
    reg [`WORD_SIZE - 1:0] num_labels;
    reg [`WORD_SIZE - 1:0] merge_table [0 : `MAX];

    // Label selection signals
    wire is_new_label;
    wire is_merge;
    wire [`WORD_SIZE - 1:0] min_label;
    wire [`WORD_SIZE - 1:0] max_label;
    wire [`WORD_SIZE - 1:0] label;

    // Merge stack signals
    wire push_0;
    wire pop_0;
    wire full_0;
    wire empty_0;

    wire push_1;
    wire pop_1;
    wire full_1;
    wire empty_1;

    wire [`WORD_SIZE * 2 - 1:0] stack_entry;
    wire [`WORD_SIZE * 2 - 1:0] stack0_top;
    wire [`WORD_SIZE * 2 - 1:0] stack1_top;

    label_selector U2(
        .A(A),
        .B(B),
        .C(C),
        .D(D),
        .data(data),
        .num_labels(num_labels),
        .is_new_label(is_new_label),
        .is_merge(is_merge),
        .label(label),
        .min_label(min_label),
        .max_label(max_label)
    );

    stack #(
        .WIDTH(`WORD_SIZE * 2),
        .DEPTH(`WORD_SIZE)
    )
    U0 (
        .clk(clk),
        .reset(~reset_n),
        .d(stack_entry),
        .q(stack0_top),
        .push(push_0),
        .pop(pop_0),
        .empty(empty_0),
        .full(full_0)
    );

    stack #(
        .WIDTH(`WORD_SIZE * 2),
        .DEPTH(`WORD_SIZE)
    )
    U1 (
        .clk(clk),
        .reset(~reset_n),
        .d(stack_entry),
        .q(stack1_top),
        .push(push_1),
        .pop(pop_1),
        .empty(empty_1),
        .full(full_1)
    );

    always @(posedge clk) begin
        if (~reset_n) begin
            num_labels <= 1;        // 0 is reserved
            merge_table[0] <= 255;  // merge_table[0] should NEVER be looked up
        end else if (en) begin
            // Label count
            if (is_new_label) begin
                num_labels <= num_labels + 1;
            end else begin
                num_labels <= num_labels;
            end

            // Merge table
            if (is_new_label) begin
                merge_table[num_labels] <= num_labels;
            end else if (pop_0) begin
                merge_table[stack0_top[15:8]] = merge_table[stack0_top[7:0]];
            end else if (pop_1) begin
                merge_table[stack1_top[15:8]] = merge_table[stack1_top[7:1]];
            end

        end
    end

    // Assumption: Only two distinct non-zero labels.
    assign stack_entry = {max_label, min_label};

    // Push on a merge.
    assign push_0 = is_merge && ~y[0];
    assign push_1 = is_merge &&  y[0];

    // Pop while not empty.
    assign pop_0 =  y[0] && ~empty_0;
    assign pop_1 = ~y[0] && ~empty_1;

    assign q = label;

endmodule

module label_selector(
    input [`WORD_SIZE - 1:0] A,
    input [`WORD_SIZE - 1:0] B,
    input [`WORD_SIZE - 1:0] C,
    input [`WORD_SIZE - 1:0] D,
    input [`WORD_SIZE - 1:0] data,
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

    assign is_background = !data;
    assign is_new_label = !(A | B | C | D) && !is_background;
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
    assign is_merge = !(is_background | is_new_label | copy_a | copy_b | copy_c | copy_d);

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
