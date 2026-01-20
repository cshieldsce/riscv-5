# Hazard Handling and Debugging Retrospectives

This document analyzes the resolution of data and control hazards within the 5-stage pipeline.

## 1. Load-Use Hazard Analysis

In a 5-stage pipeline, a load-use hazard occurs when an instruction depends on the result of a preceding `LW` instruction. Because memory data is only available at the end of the `MEM` stage, a 1-cycle stall is required.

### Temporal Visualization
The following timing diagram illustrates the insertion of a pipeline bubble.

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

## 2. Forwarding Logic

Forwarding bypasses the register file to provide results from the `MEM` or `WB` stages directly to the ALU inputs.

```json
{ "signal": [
  { "name": "CLK",    "wave": "p....." },
  { "name": "ADD (x1)", "wave": "34567.", "data": ["IF", "ID", "EX", "MEM", "WB"] },
  { "name": "SUB (x1)", "wave": ".34567", "data": ["IF", "ID", "EX", "MEM", "WB"] },
  { "name": "rs1_data", "wave": "..==..", "data": ["Old x1", "Fwd x1"] }
],
  "edge": ["ADD.EX -> SUB.EX Forwarding Path"]
}
```

---

## 3. Retrospective: The Frozen Pipeline

**Situation:** During initial integration, the processor deadlocked on loop iterations. The PC stopped incrementing, and the instruction registers stalled indefinitely.

**Task:** Debug the stall logic within the `HazardUnit`.

**Action:** Traced the `stall_if` signal in GTKWave. Analysis revealed that the load-use stall was triggering on all register matches, regardless of whether the instruction in EX was a load.

**Result:** Implemented an explicit `id_ex_mem_read` check.
```systemverilog
if (id_ex_mem_read && ((id_ex_rd == id_rs1) || (id_ex_rd == id_rs2))) begin
    stall_if = 1;
    stall_id = 1;
    flush_ex = 1;
end
```

---

## 4. Retrospective: Signed Branch Comparison

**Situation:** The core failed `BEQ` compliance tests for negative number comparisons.

**Task:** Audit the branch comparator logic in the `EX_Stage`.

**Action:** Isolated the comparison and identified that SystemVerilog was performing unsigned comparisons by default, leading to incorrect evaluations for sign-extended values.

**Result:** Applied explicit `$signed()` casting to the comparator inputs.
```systemverilog
assign rs1_eq_rs2 = ($signed(alu_in_a_forwarded) == $signed(rs2_data_forwarded));
```