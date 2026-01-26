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
  overflow-x: auto;]==]
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
  { "name": "IF (Fetch)",     "wave": "345...", "data": ["ADDI", "SUB", "OR"] },
  { "name": "ID (Decode)",    "wave": ".345..", "data": ["ADDI", "SUB", "OR"] },
  { "name": "EX (Execute)",   "wave": "..345.", "data": ["ADDI", "SUB", "OR"] },
  { "name": "MEM (Memory)",   "wave": "...345", "data": ["ADDI", "SUB", "OR"] },
  { "name": "WB (Writeback)", "wave": "....34", "data": ["ADDI", "SUB"] },
  {},
  { "name": "Forward A Select", "wave": "...2..", "data": ["10 (EX/MEM)"] }
],
  "head": { "text": "EX-to-EX Forwarding (Bypassing at Cycle 4)", "tick": 0 },
  "config": { "hscale": 2.2 }
}
</script>

**Cycle-by-Cycle Breakdown:**
*   **Cycle 3:** `ADDI` is in **Execute** calculating its result. `SUB` is in **Decode**.
*   **Cycle 4 (Forwarding!):** `ADDI` moves to **Memory** (result is now in the `EX/MEM` register). `SUB` moves to **Execute**. The Forwarding Unit detects the hazard and tells the ALU to grab the result from the `EX/MEM` register instead of the Register File.

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

A Load-Use hazard is the only data hazard that **cannot** be solved by forwarding alone. The data is still in RAM while the next instruction is already trying to use it.

<script type="WaveDrom">
{ "signal": [
  { "name": "CLK", "wave": "p......" },
  { "name": "IF (Fetch)",     "wave": "34556..", "data": ["LW", "ADD", "OR", "SUB"] },
  { "name": "ID (Decode)",    "wave": ".34456.", "data": ["LW", "ADD", "OR", "SUB"] },
  { "name": "EX (Execute)",   "wave": "..3x456", "data": ["LW", "BUBBLE", "ADD", "OR", "SUB"] },
  { "name": "MEM (Memory)",   "wave": "...3x45", "data": ["LW", "NOP", "ADD", "OR"] },
  { "name": "WB (Writeback)", "wave": "....3x4", "data": ["LW", "NOP", "ADD"] },
  {},
  { "name": "PIPELINE STATE", "wave": "...34..", "data": ["STALL", "Resume"] }
],
  "head": { "text": "Load-Use Hazard (Detection at Cycle 3, Stall at Cycle 4)", "tick": 0 },
  "config": { "hscale": 2.2 }
}
</script>

**Cycle-by-Cycle Breakdown:**
*   **Cycle 3 (Detection):** `LW` is in **Execute** (calculating the RAM address). `ADD` is in **Decode**. The Hazard Unit realizes `ADD` depends on `LW` and triggers a stall.
*   **Cycle 4 (The Stall):** 
    *   **IF & ID are Frozen:** `ADD` stays in Decode, and `OR` stays in Fetch.
    *   **EX is Flushed:** A `BUBBLE` (NOP) is sent to Execute so that no "bad" math happens with the old register value.
    *   `LW` is in **Memory** actually reading the data from RAM.
*   **Cycle 5 (Resume):** `LW` is in **Writeback**. `ADD` finally moves to **Execute**, receiving its data via forwarding from the WB stage.

---

## 3.4 Control Hazards

Control hazards occur when the CPU fetches instructions from the wrong path (e.g., after a branch).

### Case 5: Branch Misprediction (2-Cycle Flush)

Our CPU assumes a branch is **Not Taken** by default. If the branch *is* taken, we must "kill" the instructions already behind it in the pipeline.

<script type="WaveDrom">
{ "signal": [
  { "name": "CLK", "wave": "p......" },
  { "name": "IF (Fetch)",     "wave": "34567..", "data": ["BEQ", "Wrong1", "Wrong2", "Target", "Target+4"] },
  { "name": "ID (Decode)",    "wave": ".34x67.", "data": ["BEQ", "Wrong1", "Bubble", "Target", "Target+4"] },
  { "name": "EX (Execute)",   "wave": "..3xx6.", "data": ["BEQ", "Flush1", "Flush2", "Target"] },
  {},
  { "name": "Branch Taken",   "wave": "..010.." },
  { "name": "PIPELINE ACTION","wave": "...2.3.", "data": ["FLUSHING", "Resume"] }
],
  "head": { "text": "Branch Taken (Resolves at Cycle 3, Flushes at Cycle 4)", "tick": 0 },
  "config": { "hscale": 2.2 }
}
</script>

**Cycle-by-Cycle Breakdown:**
*   **Cycle 3 (Resolution):** `BEQ` is in **Execute**. The ALU determines the branch is **TAKEN**. The PC is updated to the `Target` address, and the flush signal is asserted.
*   **Cycle 4 (The Flush):** 
    *   `Wrong1` (which was in Decode) and `Wrong2` (which was in Fetch) are both discarded (`Flush1` and `Flush2`).
    *   The `Target` instruction is fetched from memory.
*   **Cycle 5:** The pipeline contains bubbles where the wrong instructions were. The `Target` instruction moves to **Decode**.
*   **Cycle 6:** `Target` reaches **Execute**.



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
