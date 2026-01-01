`timescale 1ns / 1ps

module tb_operators;

    // Parameters
    parameter integer MAX_SAMPLES = 200000;
    parameter integer OUT_BITS    = 29;
    parameter integer SIM_LATENCY = 20; // Extra cycles to clear all pipelines

    // Global signals
    reg clk;
    reg rst;

    // Input data
    reg signed [15:0] data_in;

    // Output wires from each operator
    wire [OUT_BITS-1:0] tkeo_out;
    wire [OUT_BITS-1:0] ed_out;
    wire [15:0]         aso_out;
    wire [15:0]         ado_out;

    // --- DUT Instantiations ---
    // 1. Teager-Kaiser Energy Operator
    tkeo #(
        .OUT_BITS(OUT_BITS),
        .SCALE_SH(1)
    ) dut_tkeo (
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
    ) dut_ed (
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
    ) dut_aso (
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
    ) dut_ado (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_out(ado_out)
    );

    // Clock generation (100 MHz)
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Input sample storage
    integer sample_mem [0:MAX_SAMPLES-1];
    integer num_samples;
    integer i;
    integer fd;
    integer r;

    // Load samples from file
    initial begin
        // Update this path to your specific file location
        fd = $fopen("test_files/lfp/test_signal_20170224_16.txt", "r");

        if (fd == 0) begin
            $display("ERROR: Could not open input signal file.");
            $finish;
        end

        num_samples = 0;
        while (!$feof(fd) && num_samples < MAX_SAMPLES) begin
            r = $fscanf(fd, "%d\n", sample_mem[num_samples]);
            if (r == 1)
                num_samples = num_samples + 1;
        end

        $fclose(fd);
        $display("Loaded %0d samples.", num_samples);
    end

    // Main stimulus
    initial begin
        $dumpfile("operators_wave.vcd");
        $dumpvars(0, tb_operators);

        // Reset sequence
        rst     = 1'b1;
        data_in = 16'sd0;
        repeat (20) @(posedge clk);
        rst     = 1'b0;
        @(posedge clk);

        $display("Starting signal processing...");

        for (i = 0; i < num_samples; i = i + 1) begin
            @(posedge clk);
            data_in = sample_mem[i][15:0];
            
            if (i % 10000 == 0) 
                $display("Processed %0d samples...", i);
        end

        // Stop sending data
        @(posedge clk);
        data_in = 16'sd0;

        // Wait for pipelines to flush
        repeat (SIM_LATENCY) @(posedge clk);

        $display("All operators simulation completed.");
        $finish;
    end

endmodule