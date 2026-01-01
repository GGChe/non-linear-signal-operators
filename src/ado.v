// ============================================================
// ADO (Amplitude Difference Operator):
// This operator calculates the absolute difference between the 
// current sample and a delayed sample to emphasize amplitude 
// shifts.
//
// - Pipelined absolute value calculation
// - Parametric delay and output scaling
// - Consistent with TKEO/ED repository structure
// ============================================================
module ado #(
    parameter integer K_DELAY    = 3,
    parameter integer OUT_BITS   = 16,
    parameter integer SCALE_SH   = 0
)(
    input  wire                 clk,
    input  wire                 rst,
    input  wire signed [15:0]   data_in,
    output reg  [OUT_BITS-1:0]  data_out
);

    // Delay buffer
    reg signed [15:0] input_buffer [0:K_DELAY];

    // Intermediate signals
    reg signed [16:0] diff_r;
    reg        [15:0] abs_diff_r;
    reg        [15:0] psi_scaled_r;

    // Saturation constant
    localparam [OUT_BITS-1:0] SAT_MAX_U = {OUT_BITS{1'b1}};

    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i <= K_DELAY; i = i + 1)
                input_buffer[i] <= 16'sd0;

            diff_r       <= 17'sd0;
            abs_diff_r   <= 16'd0;
            psi_scaled_r <= 16'd0;
            data_out     <= {OUT_BITS{1'b0}};
        end else begin
            // Stage 1: Shift Register
            for (i = K_DELAY; i > 0; i = i - 1)
                input_buffer[i] <= input_buffer[i - 1];
            
            input_buffer[0] <= data_in;

            // Stage 2: Difference Calculation
            // Using 17 bits ensures we don't lose the sign bit during (min - max)
            diff_r <= $signed(input_buffer[0]) - $signed(input_buffer[K_DELAY]);

            // Stage 3: Absolute Value (Pipelined)
            // If negative, invert and add 1; else keep original
            if (diff_r[16])
                abs_diff_r <= -diff_r[15:0];
            else
                abs_diff_r <= diff_r[15:0];

            // Stage 4: Scaling
            psi_scaled_r <= abs_diff_r >> SCALE_SH;

            // Stage 5: Clipping to OUT_BITS
            if (psi_scaled_r > SAT_MAX_U)
                data_out <= SAT_MAX_U;
            else
                data_out <= psi_scaled_r[OUT_BITS-1:0];
        end
    end

endmodule