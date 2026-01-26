<div class="site-nav">
  <a href="../index.html">Home</a>
  <a href="./manual.html">Architecture Overview</a>
  <a href="./stages.html">Pipeline Stages</a>
  <a href="./hazards.html">Hazard Resolution</a>
  <a href="../verification/report.html">Design Verification</a>
  <a href="../verification/fpga.html">FPGA Implementation</a>
  <a href="../developer/guide.html">Setup Guide</a>
</div>

<script src="https://cdnjs.cloudflare.com/ajax/libs/wavedrom/3.1.0/skins/default.js" type="text/javascript"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/wavedrom/3.1.0/wavedrom.min.js" type="text/javascript"></script>
<script>
window.onload = function() {
    WaveDrom.ProcessAll();
};
</script>

<style>
/* Adapt WaveDrom to Dark Theme (Midnight) */
div[id^="WaveDrom_Display_"] svg {
  filter: invert(1) hue-rotate(180deg) contrast(1.2);
  background-color: transparent !important;
}
div[id^="WaveDrom_Display_"] {
  margin: 20px 0;
  overflow-x: auto;
}
</style>

# 3.0 Hazard Resolution

In a pipelined processor, multiple instructions overlap in execution. Hazards occur when the hardware cannot support the next instruction in the next clock cycle without producing incorrect results. Our CPU handles three types of hazards through a combination of **Forwarding**, **Stalling**, and **Flushing**.

## 3.1 Hazard Summary Table

| Hazard Type | Scenario | Hardware Action | Penalty (Cycles) |
|-------------|----------|-----------------|------------------|
| **Data Hazard** | Register dependency (ALU to ALU) | Forwarding | 0 |
| **Data Hazard** | Store dependency (WB to MEM) | MEM Forwarding | 0 |
| **Data Hazard** | Load-Use dependency | Stall + Forwarding | 1 |
| **Control Hazard** | Conditional Branch (Taken) | Flush IF & ID | 2 |
| **Control Hazard** | JAL (Unconditional Jump) | Flush IF | 1 |
| **Control Hazard** | JALR (Indirect Jump) | Flush IF & ID | 2 |
| **Special Case** | ALU-to-Branch Dependency | Stall + Flush IF/ID | 3 (Total) |

---

## 3.2 Data Hazards: Forwarding & Bypassing

Data hazards occur when an instruction depends on the result of a previous instruction that hasn't yet been written back to the Register File.

### Case 1: EX-to-EX Forwarding
This occurs when an instruction needs a result computed by the *immediately* preceding instruction.

```asm
addi x1, x10, 5  # Result calculated in EX, moves to EX/MEM register
sub  x2, x1, x3   # Needs x1 NOW in its EX stage
```

<script type="WaveDrom">
{ "signal": [
  { "name": "CLK", "wave": "p....." },
  { "name": "IF",  "wave": "345...", "data": ["ADDI", "SUB", "OR"] },
  { "name": "ID",  "wave": ".345..", "data": ["ADDI", "SUB", "OR"] },
  { "name": "EX",  "wave": "..345.", "data": ["ADDI", "SUB", "OR"] },
  { "name": "MEM", "wave": "...345", "data": ["ADDI", "SUB", "OR"] },
  { "name": "WB",  "wave": "....34", "data": ["ADDI", "SUB"] },
  {},
  { "name": "Forward A", "wave": "...5..", "data": ["10 (EX/MEM)"] }
],
  "head": { "text": "EX-to-EX Forwarding", "tick": 0 },
  "config": { "hscale": 2 }
}
</script>

**Implementation (`src/forwarding_unit.sv`):**
The Forwarding Unit detects that the source register in the Execute stage (`id_ex_rs1`) matches the destination register of the instruction in the Memory stage (`ex_mem_rd`).

```verilog
if (ex_mem_reg_write && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs1))
    forward_a = 2'b10; // Select data from EX/MEM register
```

### Case 2: MEM-to-EX Forwarding
This occurs when the dependency is two instructions apart. The data is currently sitting in the `MEM/WB` pipeline register.

```asm
addi x1, x10, 5
or   x4, x5, x6   # Unrelated
sub  x2, x1, x3   # Needs x1
```

**Implementation:** The unit selects `2'b01` to bypass from the Writeback stage.

### Case 3: MEM Store Forwarding (WB-to-MEM)
A unique case where a `store` instruction needs data that is currently in the Writeback stage.

```asm
addi x1, x0, 10
sw   x1, 0(x2)    # sw needs x1, which is in WB stage
```

**Implementation (`src/mem_stage.sv`):**
The Memory stage contains its own mini-forwarding logic to ensure the `dmem_wdata` is updated if the `rs2` register is being written to by the instruction currently in the Writeback stage.

---

## 3.3 The Load-Use Hazard

When an instruction depends on a `load` instruction, forwarding alone is insufficient because the data isn't available until the end of the Memory stage.

### Case 4: Load-Use Stall (The "Hardware Pause")

A Load-Use hazard is the only data hazard that **cannot** be solved by forwarding alone. Because the data is being fetched from external RAM, it simply isn't inside the CPU yet. We have to pause the pipeline.

<script type="WaveDrom">
{ "signal": [
  { "name": "CLK", "wave": "p......" },
  { "name": "IF (Fetch)",     "wave": "34.56..", "data": ["LW", "ADD", "OR", "SUB"] },
  { "name": "ID (Decode)",    "wave": ".34.56.", "data": ["LW", "ADD", "OR", "SUB"] },
  { "name": "EX (Execute)",   "wave": "..3x456", "data": ["LW", "BUBBLE", "ADD", "OR", "SUB"] },
  { "name": "MEM (Memory)",   "wave": "...3x45", "data": ["LW", "NOP", "ADD", "OR"] },
  { "name": "WB (Writeback)", "wave": "....3x4", "data": ["LW", "NOP", "ADD"] },
  {},
  { "name": "HAZARD UNIT",    "wave": "..10...", "data": ["DETECTED"] },
  { "name": "PIPELINE STATE", "wave": "..345..", "data": ["Normal", "STALL", "Resume"] }
],
  "head": { "text": "Load-Use Hazard Walkthrough", "tick": 0 },
  "config": { "hscale": 2 }
}
</script>

**What is happening here?**
*   **Cycle 2:** The `LW` is in **Execute** (calculating the address). The `ADD` is in **Decode**. The Hazard Unit sees that `ADD` needs the register `LW` is about to load.
*   **Cycle 3 (The Stall):** 
    *   The `IF` and `ID` stages are **Frozen**. Notice `ADD` stays in `ID` and `OR` stays in `IF`.
    *   The `EX` stage is **Flushed**. The `ADD` instruction is prevented from moving forward, and a `BUBBLE` (NOP) is injected instead.
    *   The `LW` moves to **Memory** to actually get the data.
*   **Cycle 4:** The data is now available at the end of the Memory stage. The `ADD` finally moves into **Execute**, and the data is **Forwarded** to it.

---

## 3.4 Control Hazards

Control hazards occur when the CPU fetches instructions from the wrong path (e.g., after a branch).

### Case 5: Branch Misprediction (2-Cycle Flush)

Our CPU assumes a branch is **Not Taken** to keep moving fast. If the branch *is* taken, we've already fetched two wrong instructions.

<script type="WaveDrom">
{ "signal": [
  { "name": "CLK", "wave": "p......" },
  { "name": "IF (Fetch)",     "wave": "345.6..", "data": ["BEQ", "Wrong1", "Wrong2", "Target"] },
  { "name": "ID (Decode)",    "wave": ".345.6.", "data": ["BEQ", "Wrong1", "Wrong2", "Target"] },
  { "name": "EX (Execute)",   "wave": "..3xx6.", "data": ["BEQ", "FLUSH", "FLUSH", "Target"] },
  {},
  { "name": "Branch Taken",   "wave": "..010.." },
  { "name": "PIPELINE ACTION","wave": "..34.3.", "data": ["Normal", "FLUSHING", "Resume"] }
],
  "head": { "text": "Branch Taken (Discarding the Wrong Path)", "tick": 0 },
  "config": { "hscale": 2 }
}
</script>

**Why 2 cycles?**
1.  **Cycle 2:** The `BEQ` reaches the **Execute** stage. This is the first time the CPU actually knows the branch is taken.
2.  **The Penalty:** 
    *   The instruction in `ID` (**Wrong1**) is killed.
    *   The instruction in `IF` (**Wrong2**) is killed.
    *   The PC is updated to the **Target** address.
3.  **Cycle 3:** The pipeline is empty (bubbles) where the wrong instructions were, and the `Target` instruction is fetched.

---

### Case 6: ALU-to-Branch Stall (Specific Implementation)
In our architecture, if a branch in the Decode stage depends on an ALU result currently in the Execute stage, the `HazardUnit` triggers an additional stall. This is a design choice to simplify the branch comparison timing.

**Example Code:**
```asm
addi x1, x0, 10
beq  x1, x2, label  # Depends on x1 immediately
```

**Total Penalty:** 1 cycle (stall) + 2 cycles (flush if taken) = **3 cycles**.

---

## 3.5 Implementation Details

### The Hazard Unit (`src/hazard_unit.sv`)
The "Traffic Cop" of the CPU. It monitors the pipeline and decides when to freeze or flush.

```verilog
// Load-Use Detection
if (id_ex_mem_read && ((id_ex_rd == id_rs1) || (id_ex_rd == id_rs2))) begin
    stall_if = 1'b1;
    stall_id = 1'b1;
    flush_ex = 1'b1;
end

// Branch Flush Detection
if (branch_taken_ex) begin
    flush_id = 1'b1;
    flush_ex = 1'b1;
end
```

### The Forwarding Unit (`src/forwarding_unit.sv`)
Handles priority to ensure the *most recent* data is used.

```verilog
// Priority: EX/MEM (Most Recent) > MEM/WB (Older)
if (has_ex_hazard) begin
    forward_a = 2'b10;
end else if (has_mem_hazard) begin
    forward_a = 2'b01;
end
```

---
*riscv-cpu: a 5-Stage Pipelined RISC-V Processor (RV32I) by Charlie Shields, 2026*
