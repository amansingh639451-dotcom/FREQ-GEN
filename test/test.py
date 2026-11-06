# SPDX-FileCopyrightText: © 2026 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer

@cocotb.test()
async def test_tt_repellant(dut):
    dut._log.info("Start test_tt_repellant")

    # 125 MHz clock (8 ns period)
    clock = Clock(dut.clk, 8, unit="ns")
    cocotb.start_soon(clock.start())

    # Initialize signals
    dut.ena.value = 1
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    dut.ui_in.value = 0b1111_1111  # All buttons released (active low)

    # Wait 50 ns and release reset
    await Timer(50, unit="ns")
    dut.rst_n.value = 1
    dut._log.info("Reset released")

    # Wait 100 ns post-reset
    await Timer(100, unit="ns")

    # Helper function to press and release the mode button (ui_in[1])
    async def press_mode_button():
        await Timer(5000, unit="ns")
        # Extract current integer value and clear bit 1 (active low press)
        current_val = int(dut.ui_in.value)
        dut.ui_in.value = current_val & ~(1 << 1)
        
        await Timer(5000, unit="ns")
        # Set bit 1 back to 1 to release
        current_val = int(dut.ui_in.value)
        dut.ui_in.value = current_val | (1 << 1)

    # Mode 1 -> Mode 2 (100Hz)
    await Timer(2000, unit="ns")
    await press_mode_button()

    # Mode 2 -> Mode 3 (1kHz)
    await press_mode_button()

    # Mode 3 -> Mode 4 (10kHz)
    await press_mode_button()

    # Final wait before finishing
    await Timer(10000, unit="ns")
    dut._log.info("Test completed successfully")
