// ============================================================
// TKEO (Teager-Kaiser Energy Operator), width-reduced:
// This mathematical operator applies a non-linear transformation for the improvement of the   
// signal-to-noise ratio.
//
// - internal output energy is non-negative and clipped
// - OUT_BITS reduced to 29 internally, then top-level can extend
// ============================================================
module tkeo #(
    parameter integer OUT_BITS  = 29,
    parameter integer SCALE_SH  = 1
)(
    input  wire                clk,
    input  wire                rst,
    input  wire signed [15:0]  data_in,
    output reg  [OUT_BITS-1:0] data_out
);

    reg signed [15:0] x_n0, x_n1, x_n2;

    // Products: Q30
    reg signed [31:0] sq_term_r;
    reg signed [31:0] cross_term_r;

    // Raw energy: keep a modest headroom; 33 bits is fine here,
    // but the output is reduced to OUT_BITS.
    reg signed [32:0] psi_raw_r;
    reg signed [32:0] psi_scaled_r;

    // Saturation max for OUT_BITS (unsigned clip)
    localparam [OUT_BITS-1:0] SAT_MAX_U = {OUT_BITS{1'b1}};

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            x_n0         <= 16'sd0;
            x_n1         <= 16'sd0;
            x_n2         <= 16'sd0;
            sq_term_r    <= 32'sd0;
            cross_term_r <= 32'sd0;
            psi_raw_r    <= 33'sd0;
            psi_scaled_r <= 33'sd0;
            data_out     <= {OUT_BITS{1'b0}};
        end else begin
            // Stage 1: delay + products
            x_n2 <= x_n1;
            x_n1 <= x_n0;
            x_n0 <= data_in;

            sq_term_r    <= x_n1 * x_n1;
            cross_term_r <= x_n0 * x_n2;

            // Stage 2: subtract + rectify/scale
            psi_raw_r <= $signed({1'b0, sq_term_r}) - $signed({1'b0, cross_term_r});

            if (psi_raw_r[32])
                psi_scaled_r <= 33'sd0;
            else
                psi_scaled_r <= psi_raw_r >>> SCALE_SH;

            // Clip to OUT_BITS (unsigned)
            if (psi_scaled_r[32:OUT_BITS] != { (33-OUT_BITS){1'b0} })
                data_out <= SAT_MAX_U;
            else
                data_out <= psi_scaled_r[OUT_BITS-1:0];
        end
    end

endmodule
