// ============================================================
// ED (Energy of Derivative) Operator:
// This operator highlights rapid transitions by computing the 
// squared difference between the current sample and a delayed sample.
//
// - Pipelined architecture for high-frequency operation
// - Parametric bit-widths and scaling
// - Non-negative output with saturation logic
// ============================================================
module ed #(
    parameter integer K_DELAY    = 2,   // Delay distance (k)
    parameter integer OUT_BITS   = 29, 
    parameter integer SCALE_SH   = 1
)(
    input  wire                 clk,
    input  wire                 rst,
    input  wire signed [15:0]   data_in,
    output reg  [OUT_BITS-1:0]  data_out
);

    // Delay buffer for input samples
    reg signed [15:0] input_buffer [0:K_DELAY];
    
    // Intermediate signals
    reg signed [16:0] diff_r;
    reg signed [33:0] squared_diff_r;
    reg signed [33:0] psi_scaled_r;

    // Saturation constant
    localparam [OUT_BITS-1:0] SAT_MAX_U = {OUT_BITS{1'b1}};

    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i <= K_DELAY; i = i + 1)
                input_buffer[i] <= 16'sd0;

            diff_r         <= 17'sd0;
            squared_diff_r <= 34'sd0;
            psi_scaled_r   <= 34'sd0;
            data_out       <= {OUT_BITS{1'b0}};
        end else begin
            // Stage 1: Shift Register
            for (i = K_DELAY; i > 0; i = i - 1)
                input_buffer[i] <= input_buffer[i - 1];
            
            input_buffer[0] <= data_in;

            // Stage 2: Difference
            // (x[n] - x[n-k])
            diff_r <= $signed(input_buffer[0]) - $signed(input_buffer[K_DELAY]);

            // Stage 3: Square (Always positive result, but stored as signed for math consistency)
            // 17-bit * 17-bit = 34-bit
            squared_diff_r <= diff_r * diff_r;

            // Stage 4: Scaling/Rectification
            // Energy of derivative is naturally non-negative, but we use a safety check
            if (squared_diff_r[33]) 
                psi_scaled_r <= 34'sd0;
            else
                psi_scaled_r <= squared_diff_r >>> SCALE_SH;

            // Stage 5: Clipping to OUT_BITS (Unsigned)
            if (psi_scaled_r[33:OUT_BITS] != {(34-OUT_BITS){1'b0}})
                data_out <= SAT_MAX_U;
            else
                data_out <= psi_scaled_r[OUT_BITS-1:0];
        end
    end

endmodule