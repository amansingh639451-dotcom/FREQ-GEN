`timescale 1ns / 1ps

// ============================================================================
// 4-BUTTON DDS FREQUENCY GENERATOR
// ============================================================================
//
// Clock      : 100 MHz
//
// BUTTONS:
//   btn_onoff : ON / OFF with 10-second delay
//   btn_mode  : Mode selection
//   btn_inc   : Increase by 100 Hz
//   btn_dec   : Decrease by 100 Hz
//
// MODE:
//   1st press -> 100 Hz
//   2nd press -> 1 kHz
//   3rd press -> 10 kHz
//   4th press -> 0 Hz
//   Then repeats.
//
// ON/OFF:
//   Press ON/OFF -> wait 10 seconds -> change state
//   Press again   -> wait 10 seconds -> change state
//
// Buttons are ACTIVE LOW.
//   1 = released
//   0 = pressed
//
// ============================================================================

module repellant_generator #(
    parameter [31:0] ONOFF_DELAY_CYCLES = 32'd1_000_000_000
)(
    input  wire clk,
    input  wire rst_n,

    input  wire btn_onoff,
    input  wire btn_mode,
    input  wire btn_inc,
    input  wire btn_dec,

    output reg signal_out
);


// ============================================================================
// 1. CONSTANTS
// ============================================================================

localparam [31:0] STEP_SIZE = 32'd100;

localparam [31:0] MODE1_FREQ = 32'd100;
localparam [31:0] MODE2_FREQ = 32'd1000;
localparam [31:0] MODE3_FREQ = 32'd10000;

localparam [31:0] MIN_FREQ = 32'd0;
localparam [31:0] MAX_FREQ = 32'd40000;


// ============================================================================
// 2. 20 ms BUTTON CHECK
// ============================================================================

reg [20:0] debounce_counter;

wire debounce_done;

assign debounce_done =
    (debounce_counter == 21'd1_999_999);


always @(posedge clk or negedge rst_n) begin

    if (!rst_n)

        debounce_counter <= 21'd0;

    else if (debounce_done)

        debounce_counter <= 21'd0;

    else

        debounce_counter <= debounce_counter + 1'b1;

end


// ============================================================================
// 3. BUTTON FLAGS AND LOCKS
// ============================================================================

reg onoff_flag;
reg mode_flag;
reg inc_flag;
reg dec_flag;

reg onoff_lock;
reg mode_lock;
reg inc_lock;
reg dec_lock;


always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        onoff_flag <= 1'b0;
        mode_flag  <= 1'b0;
        inc_flag   <= 1'b0;
        dec_flag   <= 1'b0;

        onoff_lock <= 1'b0;
        mode_lock  <= 1'b0;
        inc_lock   <= 1'b0;
        dec_lock   <= 1'b0;

    end

    else begin

        onoff_flag <= 1'b0;
        mode_flag  <= 1'b0;
        inc_flag   <= 1'b0;
        dec_flag   <= 1'b0;


        if (debounce_done) begin

            // ------------------------------------------------------------
            // ON / OFF BUTTON
            // ------------------------------------------------------------

            if (!btn_onoff) begin

                if (!onoff_lock) begin

                    onoff_flag <= 1'b1;
                    onoff_lock <= 1'b1;

                end

            end
            else begin

                onoff_lock <= 1'b0;

            end


            // ------------------------------------------------------------
            // MODE BUTTON
            // ------------------------------------------------------------

            if (!btn_mode) begin

                if (!mode_lock) begin

                    mode_flag <= 1'b1;
                    mode_lock <= 1'b1;

                end

            end
            else begin

                mode_lock <= 1'b0;

            end


            // ------------------------------------------------------------
            // INCREASE BUTTON
            // ------------------------------------------------------------

            if (!btn_inc) begin

                if (!inc_lock) begin

                    inc_flag <= 1'b1;
                    inc_lock <= 1'b1;

                end

            end
            else begin

                inc_lock <= 1'b0;

            end


            // ------------------------------------------------------------
            // DECREASE BUTTON
            // ------------------------------------------------------------

            if (!btn_dec) begin

                if (!dec_lock) begin

                    dec_flag <= 1'b1;
                    dec_lock <= 1'b1;

                end

            end
            else begin

                dec_lock <= 1'b0;

            end

        end

    end

end


// ============================================================================
// 4. 10-SECOND ON/OFF DELAY
// ============================================================================
//
// 100 MHz clock:
//
// 1 second  = 100,000,000 clocks
// 10 seconds = 1,000,000,000 clocks
//
// When ON/OFF button is pressed:
//     start delay
//     wait 10 seconds
//     change generator state
//
// ============================================================================

reg generator_on;

reg onoff_pending;

reg [31:0] onoff_counter;


always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        generator_on <= 1'b0;
        onoff_pending <= 1'b0;
        onoff_counter <= 32'd0;

    end

    else begin

        // ------------------------------------------------------------
        // Start 10-second delay
        // ------------------------------------------------------------

        if (onoff_flag && !onoff_pending) begin

            onoff_pending <= 1'b1;
            onoff_counter <= 32'd0;

        end


        // ------------------------------------------------------------
        // Count 10 seconds
        // ------------------------------------------------------------

        else if (onoff_pending) begin

            if (onoff_counter >= ONOFF_DELAY_CYCLES - 1) begin

                onoff_counter <= 32'd0;

                onoff_pending <= 1'b0;

                // Toggle ON/OFF after 10 seconds
                generator_on <= ~generator_on;

            end

            else begin

                onoff_counter <= onoff_counter + 1'b1;

            end

        end

    end

end


// ============================================================================
// 5. MODE CONTROL
// ============================================================================
//
// mode = 0 -> 0 Hz
// mode = 1 -> 100 Hz
// mode = 2 -> 1 kHz
// mode = 3 -> 10 kHz
//
// ============================================================================

reg [1:0] mode;


always @(posedge clk or negedge rst_n) begin

    if (!rst_n)

        mode <= 2'd0;

    else if (mode_flag) begin

        if (mode == 2'd3)

            mode <= 2'd0;

        else

            mode <= mode + 1'b1;

    end

end


// ============================================================================
// 6. SELECTED FREQUENCY
// ============================================================================

reg [31:0] selected_freq;


always @(posedge clk or negedge rst_n) begin

    if (!rst_n)

        selected_freq <= 32'd0;

    else begin

        // ------------------------------------------------------------
        // MODE BUTTON
        // ------------------------------------------------------------

        if (mode_flag) begin

            case (mode)

                2'd0:
                    selected_freq <= MODE1_FREQ;

                2'd1:
                    selected_freq <= MODE2_FREQ;

                2'd2:
                    selected_freq <= MODE3_FREQ;

                2'd3:
                    selected_freq <= MIN_FREQ;

                default:
                    selected_freq <= MIN_FREQ;

            endcase

        end

        // ------------------------------------------------------------
        // INCREASE
        // ------------------------------------------------------------

        else if (inc_flag) begin

            if (selected_freq + STEP_SIZE >= MAX_FREQ)

                selected_freq <= MAX_FREQ;

            else

                selected_freq <= selected_freq + STEP_SIZE;

        end

        // ------------------------------------------------------------
        // DECREASE
        // ------------------------------------------------------------

        else if (dec_flag) begin

            if (selected_freq <= STEP_SIZE)

                selected_freq <= MIN_FREQ;

            else

                selected_freq <= selected_freq - STEP_SIZE;

        end

    end

end


// ============================================================================
// 7. DDS TUNING WORD
// ============================================================================

wire [63:0] tuning_calculation;

wire [31:0] tuning_word;


assign tuning_calculation =
    ({32'd0, selected_freq} * 64'd4294967296)
    / 64'd100000000;

assign tuning_word = tuning_calculation[31:0];


// ============================================================================
// 8. DDS PHASE ACCUMULATOR
// ============================================================================

reg [31:0] phase_accumulator;


always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        phase_accumulator <= 32'd0;
        signal_out <= 1'b0;

    end

    else begin

        phase_accumulator <=
            phase_accumulator + tuning_word;


        // Generator OFF
        if (!generator_on)

            signal_out <= 1'b0;


        // 0 Hz
        else if (selected_freq == 32'd0)

            signal_out <= 1'b0;


        // Generator ON
        else

            signal_out <= phase_accumulator[31];

    end

end

endmodule
