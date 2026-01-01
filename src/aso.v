// ============================================================
// ASO (Amplitude Slope Operator):
// This operator captures the slope/velocity of the signal by 
// calculating the absolute difference between samples over a 
// specific window.
//
// - Pipelined absolute value and slope calculation
// - Parametric bit-widths and scaling
// - Continuous output for downstream feature extraction
// ============================================================
module aso #(
    parameter integer K_DELAY    = 3,   // Slope window (x4-x1 = 3)
    parameter integer OUT_BITS   = 16,
    parameter integer SCALE_SH   = 0
)(
    input  wire                 clk,
    input  wire                 rst,
    input  wire signed [15:0]   data_in,
    output reg  [OUT_BITS-1:0]  data_out
);

    // Delay line
    reg signed [15:0] input_buffer [0:K_DELAY];

    // Internal pipeline stages
    reg signed [16:0] slope_r;
    reg        [15:0] abs_slope_r;
    reg        [15:0] psi_scaled_r;

    // Saturation limit
    localparam [OUT_BITS-1:0] SAT_MAX_U = {OUT_BITS{1'b1}};

    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i <= K_DELAY; i = i + 1)
                input_buffer[i] <= 16'sd0;

            slope_r      <= 17'sd0;
            abs_slope_r  <= 16'd0;
            psi_scaled_r <= 16'd0;
            data_out     <= {OUT_BITS{1'b0}};
        end else begin
            // Stage 1: Buffer update
            for (i = K_DELAY; i > 0; i = i - 1)
                input_buffer[i] <= input_buffer[i - 1];
            
            input_buffer[0] <= data_in;

            // Stage 2: Slope calculation (x[n] - x[n-k])
            slope_r <= $signed(input_buffer[0]) - $signed(input_buffer[K_DELAY]);

            // Stage 3: Absolute Value (Rectification)
            if (slope_r[16])
                abs_slope_r <= -slope_r[15:0];
            else
                abs_slope_r <= slope_r[15:0];

            // Stage 4: Scaling
            psi_scaled_r <= abs_slope_r >> SCALE_SH;

            // Stage 5: Output clipping
            if (psi_scaled_r > SAT_MAX_U)
                data_out <= SAT_MAX_U;
            else
                data_out <= psi_scaled_r[OUT_BITS-1:0];
        end
    end

endmodule