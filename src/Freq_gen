`default_nettype none
`timescale 1ns / 1ps

// ============================================================================
// TINY TAPEOUT: 4-BUTTON DDS FREQUENCY GENERATOR
// ============================================================================
//
// Inputs (ui_in):
//   ui_in[0] : ON / OFF button (Active low or high depending on testbench, 
//              configured here to match standard push button logic)
//   ui_in[1] : MODE button
//   ui_in[2] : INCREASE (+100 Hz) button
//   ui_in[3] : DECREASE (-100 Hz) button
//
// Outputs (uo_out):
//   uo_out[0] : signal_out (DDS Waveform output)
//   uo_out[7:1]: Unused (tied to 0)
//
// Bidirectional Pins (uio_*):
//   Set to high-impedance / unused outputs for safety.
// ============================================================================

module tt_um_repellant_gen (
    input  wire [7:0] ui_in,    // Dedicated inputs[cite: 1]
    output wire [7:0] uo_out,   // Dedicated outputs[cite: 2]
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (1=output, 0=input)
    input  wire       ena,      // optional signal, goes high when powered
    input  wire       clk,      // clock
    input  wire       rst_n     // active-low reset
);

    // ========================================================================
    // INTERNAL SIGNALS & MAPPING
    // ========================================================================
    wire btn_onoff = ui_in[0];
    wire btn_mode  = ui_in[1];
    wire btn_inc   = ui_in[2];
    wire btn_dec   = ui_in[3];

    reg signal_out;
    
    // Map signal_out to uo_out[0], keep rest 0
    assign uo_out  = {7'b0, signal_out};

    // Unused bidirectional pins configuration
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;   // Set all as inputs/disabled to avoid contention[cite: 2]

    // ========================================================================
    // CONSTANTS & TUNING WORDS (125 MHz Clock Reference)
    // ========================================================================
    localparam [31:0] STEP_SIZE   = 32'd100;
    localparam [31:0] MIN_FREQ    = 32'd0;
    localparam [31:0] MAX_FREQ    = 32'd40000;

    // Tuning Word = Frequency * 2^32 / 125,000,000
    localparam [31:0] TW_STEP     = 32'd3436;
    localparam [31:0] TW_0HZ      = 32'd0;
    localparam [31:0] TW_100HZ    = 32'd3436;
    localparam [31:0] TW_1KHZ     = 32'd34360;
    localparam [31:0] TW_10KHZ    = 32'd343597;

    // Shortened debounce/delay for fast EDA Playground simulation
    localparam [31:0] ONOFF_DELAY_CYCLES = 32'd1000; 

    // ========================================================================
    // DEBOUNCE LOGIC (Shortened for simulation)
    // ========================================================================
    reg [19:0] debounce_counter;
    wire debounce_done = (debounce_counter == 20'd999);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            debounce_counter <= 20'd0;
        else if (debounce_done)
            debounce_counter <= 20'd0;
        else
            debounce_counter <= debounce_counter + 1'b1;
    end

    // ========================================================================
    // BUTTON EDGE DETECTION & LOCKS
    // ========================================================================
    reg onoff_flag, mode_flag, inc_flag, dec_flag;
    reg onoff_lock, mode_lock, inc_lock, dec_lock;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            onoff_flag <= 1'b0; mode_flag <= 1'b0;
            inc_flag   <= 1'b0; dec_flag  <= 1'b0;
            onoff_lock <= 1'b0; mode_lock <= 1'b0;
            inc_lock   <= 1'b0; dec_lock  <= 1'b0;
        end else begin
            onoff_flag <= 1'b0;
            mode_flag  <= 1'b0;
            inc_flag   <= 1'b0;
            dec_flag   <= 1'b0;

            if (debounce_done) begin
                // ON/OFF Button
                if (!btn_onoff) begin
                    if (!onoff_lock) begin
                        onoff_flag <= 1'b1;
                        onoff_lock <= 1'b1;
                    end
                end else begin
                    onoff_lock <= 1'b0;
                end

                // MODE Button
                if (!btn_mode) begin
                    if (!mode_lock) begin
                        mode_flag <= 1'b1;
                        mode_lock <= 1'b1;
                    end
                end else begin
                    mode_lock <= 1'b0;
                end

                // INC Button
                if (!btn_inc) begin
                    if (!inc_lock) begin
                        inc_flag <= 1'b1;
                        inc_lock <= 1'b1;
                    end
                end else begin
                    inc_lock <= 1'b0;
                end

                // DEC Button
                if (!btn_dec) begin
                    if (!dec_lock) begin
                        dec_flag <= 1'b1;
                        dec_lock <= 1'b1;
                    end
                end else begin
                    dec_lock <= 1'b0;
                end
            end
        end
    end

    // ========================================================================
    // ON / OFF STATE MACHINE
    // ========================================================================
    reg generator_on;
    reg onoff_pending;
    reg [31:0] onoff_counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            generator_on  <= 1'b1; // Default ON for easier testing
            onoff_pending <= 1'b0;
            onoff_counter <= 32'd0;
        end else begin
            if (onoff_flag && !onoff_pending) begin
                onoff_pending <= 1'b1;
                onoff_counter <= 32'd0;
            end else if (onoff_pending) begin
                if (onoff_counter >= ONOFF_DELAY_CYCLES - 1'b1) begin
                    onoff_counter <= 32'd0;
                    onoff_pending <= 1'b0;
                    generator_on  <= ~generator_on;
                end else begin
                    onoff_counter <= onoff_counter + 1'b1;
                end
            end
        end
    end

    // ========================================================================
    // MODE CONTROL (Mode 1: 0Hz, Mode 2: 100Hz, Mode 3: 1kHz, Mode 4: 10kHz)
    // ========================================================================
    reg [1:0] mode;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            mode <= 2'd0; // Mode 1 on reset
        else if (mode_flag) begin
            if (mode == 2'd3)
                mode <= 2'd0;
            else
                mode <= mode + 1'b1;
        end
    end

    // ========================================================================
    // FREQUENCY & TUNING WORD LOGIC
    // ========================================================================
    reg [31:0] selected_freq;
    reg [31:0] tuning_word;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            selected_freq <= MIN_FREQ;
            tuning_word   <= TW_0HZ;
        end else begin
            if (mode_flag) begin
                case (mode)
                    2'd0: begin // Mode 1 -> 0 Hz
                        selected_freq <= 32'd0;
                        tuning_word   <= TW_0HZ;
                    end
                    2'd1: begin // Mode 2 -> 100 Hz
                        selected_freq <= 32'd100;
                        tuning_word   <= TW_100HZ;
                    end
                    2'd2: begin // Mode 3 -> 1 kHz
                        selected_freq <= 32'd1000;
                        tuning_word   <= TW_1KHZ;
                    end
                    2'd3: begin // Mode 4 -> 10 kHz
                        selected_freq <= 32'd10000;
                        tuning_word   <= TW_10KHZ;
                    end
                    default: begin
                        selected_freq <= 32'd0;
                        tuning_word   <= TW_0HZ;
                    end
                endcase
            end else if (inc_flag) begin
                if (selected_freq < MAX_FREQ) begin
                    selected_freq <= selected_freq + STEP_SIZE;
                    tuning_word   <= tuning_word + TW_STEP;
                end
            end else if (dec_flag) begin
                if (selected_freq > MIN_FREQ) begin
                    selected_freq <= selected_freq - STEP_SIZE;
                    if (tuning_word >= TW_STEP)
                        tuning_word <= tuning_word - TW_STEP;
                    else
                        tuning_word <= 32'd0;
                end
            end
        end
    end

    // ========================================================================
    // DDS PHASE ACCUMULATOR
    // ========================================================================
    reg [31:0] phase_accumulator;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_accumulator <= 32'd0;
            signal_out        <= 1'b0;
        end else begin
            phase_accumulator <= phase_accumulator + tuning_word;

            if (!generator_on || (selected_freq == 32'd0))
                signal_out <= 1'b0;
            else
                signal_out <= phase_accumulator[31];
        end
    end

endmodule
