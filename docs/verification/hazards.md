# Hazard Handling & War Stories

This document explores the complex interactions of the 5-stage pipeline, focusing on how data and control hazards are resolved through logic and architectural ingenuity.

## 1. Temporal Proof: The Load-Use Stall

One of the most complex interactions in a 5-stage pipeline is the **Load-Use Hazard**. When an instruction depends on the result of a `LW` instruction, it must stall for one cycle because the memory data is only available at the end of the `MEM` stage.

### WaveDrom: Load-Use Stall Visualization
The following timing diagram illustrates a `LW` instruction followed by an `ADD` that uses the loaded value. Note the 1-cycle "bubble" inserted into the EX stage.

```json
{ "signal": [
  { "name": "CLK",    "wave": "p......." },
  { "name": "PC",     "wave": "2222.222", "data": ["0x10", "0x14", "0x14", "0x14", "0x18", "0x1C"] },
  { "name": "IF (LW)", "wave": "3.......", "data": ["LW x1, 0(x2)"] },
  { "name": "ID",     "wave": ".333....", "data": ["LW", "ADD", "ADD"] },
  { "name": "EX",     "wave": "..3.3...", "data": ["LW", "ADD"] },
  { "name": "Hazard", "wave": "0.1.0...", "node": ".a.b." }
],
  "edge": ["a<->b Stall Interval"]
}
```

---

## 2. War Story: The Frozen Pipeline

### 🌟 Situation
During early integration testing with the `fib_test.mem`, the processor would consistently deadlock on the first loop iteration. The PC would stop incrementing, and the `IF/ID` register would hold the same branch instruction indefinitely.

### 🎯 Task
Identify why the pipeline was freezing instead of progressing through the Fibonacci calculation.

### 🛠️ Action
Using GTKWave, I traced the `stall_if` signal from the `HazardUnit`. I discovered that the stall logic for Load-Use hazards was incorrectly triggering on **all** instructions where `rd == rs1`, regardless of whether the instruction in EX was actually a `Load`.

**The Buggy Logic:**
```systemverilog
// Triggered on ANY rd match, not just Loads
if ((id_ex_rd == id_rs1) || (id_ex_rd == id_rs2)) begin
    stall_if = 1;
end
```

### ✅ Result
I added the `id_ex_mem_read` check to ensure the stall only occurs when the previous instruction is a memory load.
```systemverilog
// Fixed Logic
if (id_ex_mem_read && ((id_ex_rd == id_rs1) || (id_ex_rd == id_rs2))) begin
    stall_if = 1;
end
```
The deadlock was resolved, and the core successfully calculated the 10th Fibonacci number.

---

## 3. War Story: The Bouncing Branch

### 🌟 Situation
The core passed all arithmetic compliance tests but failed on `BEQ` (Branch if Equal) when comparing negative numbers (e.g., `-1` vs `-1`). The branch would consistently evaluate as "Not Taken".

### 🎯 Task
Debug the signed comparison logic in the Branch comparator.

### 🛠️ Action
I isolated the comparison logic in the `EX_Stage`. I realized that while `XLEN` was 32 bits, the operands were being treated as `unsigned` by default in the SystemVerilog equality check, causing sign-extension issues.

### ✅ Result
I explicitly cast the operands to `signed` for the comparison logic, aligning the behavior with the RISC-V Spec Section 2.5.
```systemverilog
// Explicit signed casting for branch comparison
assign rs1_eq_rs2 = ($signed(alu_in_a_forwarded) == $signed(rs2_data_forwarded));
```
This fix allowed the core to pass the full `rv32i_m/I` compliance suite.

---
*War stories represent the real-world engineering resilience required for silicon success.*
