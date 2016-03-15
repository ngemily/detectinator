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
    output [`WORD_SIZE - 1:0] q
);
    reg [`WORD_SIZE - 1:0] num_labels;
    reg [`WORD_SIZE - 1:0] merge_table [0 : `MAX];

    wire is_background;
    wire is_new_label;
    wire copy_a;
    wire copy_b;
    wire copy_c;
    wire copy_d;
    wire merge;

    wire push;
    wire pop;
    wire full;
    wire empty;

    wire [`WORD_SIZE - 1:0] _A;
    wire [`WORD_SIZE - 1:0] _B;
    wire [`WORD_SIZE - 1:0] _C;
    wire [`WORD_SIZE - 1:0] _D;
    wire [`WORD_SIZE - 1:0] max_label;
    wire [`WORD_SIZE - 1:0] min_label;

    wire [`WORD_SIZE * 2 - 1:0] stack_entry;
    wire [`WORD_SIZE * 2 - 1:0] stack_top;

    stack #(
        .WIDTH(`WORD_SIZE * 2),
        .DEPTH(`MAX)
    )
    U0 (
        .clk(clk),
        .reset(~reset_n),
        .d(stack_entry),
        .q(stack_top),
        .push(push),
        .pop(pop),
        .empty(empty),
        .full(full)
    );

    always @(posedge clk) begin
        if (~reset_n) begin
            num_labels <= 1;        // 0 is reserved
            merge_table[0] <= 255;  // merge_table[0] should NEVER be looked up
        end else if (en) begin
            if (is_new_label) begin
                num_labels <= num_labels + 1;
                merge_table[num_labels] <= num_labels;
            end else if (merge) begin
                // TODO push entries onto merge stack.  For now, chain merge entries.
                num_labels <= num_labels;
                merge_table[max_label] <= merge_table[min_label];
            end
        end
    end

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
    assign merge = !(is_background | is_new_label | copy_a | copy_b | copy_c | copy_d);

    // Don't want to count 0 in min label.
    assign _A = (A == 0) ? `MAX : A;
    assign _B = (B == 0) ? `MAX : B;
    assign _C = (C == 0) ? `MAX : C;
    assign _D = (D == 0) ? `MAX : D;

    min4 M0(_A, _B, _C, _D, min_label);
    max4 M1(A, B, C, D, max_label);

    // Assumption: Only two distinct non-zero labels.
    assign stack_entry = {max_label, min_label};
    assign push = merge;

    // always @(posedge clk) begin
    // end

    // assign label
    assign q = (is_background) ? 0 :
        (is_new_label) ? num_labels :
        (copy_a)                      ? merge_table[A] :
        (copy_b)                      ? merge_table[B] :
        (copy_c)                      ? merge_table[C] :
        (copy_d)                      ? merge_table[D] :
                                 merge_table[min_label] ;
endmodule
