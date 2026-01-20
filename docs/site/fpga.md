# FPGA Deployment (PYNQ-Z2)

## Overview
The core is deployed on the PYNQ-Z2 FPGA board (Xilinx Zynq-7000). The implementation uses:
- **Clock:** Clocking Wizard IP to generate a stable system clock.
- **Memory:** Block RAM (BRAM) for Instruction and Data memory.
- **IO:** LEDs for debug output and UART for serial communication.

## Troubleshooting Case Study: Branch Misalignment

During initial deployment, the CPU failed to take branches correctly.

### Problem: Synchronous Instruction Fetch Mismatch
**Symptom:** The CPU executed the fall-through instruction even when the branch condition was met (LEDs showed 5 instead of 2).
**Root Cause:** The `InstructionMemory` was implemented using a synchronous block (`always_ff`). This introduced a 1-cycle delay between the Address phase and the Data phase. The pipeline's `IF/ID` register latched the instruction data *before* the memory updated, capturing the previous instruction (or NOP).

![Problem Waveform](images/fpga_problem1.png)

### Solution: Asynchronous Read
**Fix:** The `InstructionMemory` was refactored to use combinational logic (`assign`) for reading. This ensures the instruction is available in the same cycle the PC is presented, matching the pipeline's timing expectations.

```systemverilog
    // --- CHANGED: Read is now COMBINATIONAL (Async) ---
    assign Instruction = (word_addr < 4096) ? rom_memory[word_addr] : 32'h00000013;
```

**Result:** The ILA capture confirms that `pcsrc` goes high, and the branch target is loaded correctly.

![Solved Waveform](images/fpga_problem1_solved.png)
