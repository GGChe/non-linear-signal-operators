/*
 * Copyright (c) 2024 Gabriel Galeote-Checa
 * SPDX-License-Identifier: Apache-2.0
 */

module operators_top #(
    parameter integer OUT_BITS = 29
)(
    input  wire                 clk,
    input  wire                 rst,
    input  wire signed [15:0]   data_in,
    
    // Outputs from all four operators
    output wire [OUT_BITS-1:0]  tkeo_out,
    output wire [OUT_BITS-1:0]  ed_out,
    output wire [15:0]          aso_out,
    output wire [15:0]          ado_out
);

    // 1. Teager-Kaiser Energy Operator
    tkeo #(
        .OUT_BITS(OUT_BITS),
        .SCALE_SH(1)
    ) i_tkeo (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_out(tkeo_out)
    );

    // 2. Energy of Derivative
    ed #(
        .K_DELAY(2),
        .OUT_BITS(OUT_BITS),
        .SCALE_SH(1)
    ) i_ed (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_out(ed_out)
    );

    // 3. Amplitude Slope Operator
    aso #(
        .K_DELAY(3),
        .OUT_BITS(16),
        .SCALE_SH(0)
    ) i_aso (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_out(aso_out)
    );

    // 4. Amplitude Difference Operator
    ado #(
        .K_DELAY(3),
        .OUT_BITS(16),
        .SCALE_SH(0)
    ) i_ado (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_out(ado_out)
    );

endmodule