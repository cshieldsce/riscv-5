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
  /* Centering is now handled by a wrapper div */
  overflow-x: auto;
}
</style>

# 3.0 Hazard Resolution

In a pipelined processor, multiple instructions overlap in execution. Hazards occur when the hardware cannot support the next instruction in the next clock cycle without producing incorrect results. Our CPU handles three types of hazards through a combination of **Forwarding**, **Stalling**, and **Flushing**.

## 3.1 Hazard Summary Table

<div class="hazard-table">

| Hazard Type | Scenario | Hardware Action | Penalty (Cycles) |
|-------------|----------|-----------------|------------------|
| **Data Hazard** | Register dependency (ALU to ALU) | Forwarding | 0 |
| **Data Hazard** | Store dependency (WB to MEM) | MEM Forwarding | 0 |
| **Data Hazard** | Load-Use dependency | Stall + Forwarding | 1 |
| **Control Hazard** | Conditional Branch (Taken) | Flush IF & ID | 2 |
| **Control Hazard** | JAL (Unconditional Jump) | Flush IF | 1 |
| **Control Hazard** | JALR (Indirect Jump) | Flush IF & ID | 2 |
| **Special Case** | ALU-to-Branch Dependency | Stall + Flush IF/ID | 3 (Total) |

</div>

---

## 3.2 Data Hazards: Forwarding & Bypassing

Data hazards occur when an instruction depends on the result of a a previous instruction that hasn't yet been written back to the Register File.

### Case 1: EX-to-EX Forwarding
This occurs when an instruction needs a result computed by the *immediately* preceding instruction.

```asm
addi x1, x10, 5 # Result calculated in EX, moves to EX/MEM register
sub  x2, x1, x3 # Needs x1 NOW in its EX stage
```
<div style="text-align: center;">
<script type="WaveDrom">
{ "signal": [
  { "name": "CLK", "wave": "p...." },
  { "name": "IF (Fetch)",     "wave": "345xx", "data": ["ADDI", "SUB", "OR"] },
  { "name": "ID (Decode)",    "wave": "x345x", "data": ["ADDI", "SUB", "OR"] },
  { "name": "EX (Execute)",   "wave": "xx375", "data": ["ADDI", "SUB", "OR"] },
  { "name": "MEM (Memory)",   "wave": "xxx34", "data": ["ADDI", "SUB", "OR"] },
  { "name": "WB (Writeback)", "wave": "xxxx3", "data": ["ADDI", "SUB"] },
  {},
  { "name": "Forward A Select", "wave": "xxx4x", "data": ["FORWARD"] }
],
  "head": { "text": "EX-to-EX Forwarding (Bypassing at Cycle 3)", "tick": 0 },
  "config": { "hscale": 2.2 },
  "style": {
    "4": "fill:#f0f; stroke:#f0f; stroke-width:2;"
  }
}
</script>
</div>
<br>
**Implementation (`src/forwarding_unit.sv`):**
```verilog
if (ex_mem_reg_write && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs1))
    forward_a = 2'b10; // Select data from EX/MEM register
```
The Forwarding Unit detects that the source register in the Execute stage (`id_ex_rs1`) matches the destination register of the instruction in the Memory stage (`ex_mem_rd`).


### Case 2: MEM-to-EX Forwarding
This occurs when the dependency is two instructions apart. The data is currently sitting in the `MEM/WB` pipeline register.

```asm
addi x1, x10, 5
or   x4, x5, x6   # Unrelated
sub  x2, x1, x3   # Needs x1
```

**Implementation (`src/forwarding_unit.sv`):**
```verilog
logic mem_match, ex_match;

mem_match = mem_reg_write && (mem_rd != 5'b0) && (mem_rd == rs);
ex_match = reg_write && (mem_rd != 5'b0) && (mem_rd == rs);;

if (mem_match && !ex_match) begin : MEMHazard
  return 1'b1;
end else begin : NoMEMHazard
  return 1'b0;
end
```
The forwarding unit selects forward control `1'b01` to bypass data from the MEM/WB pipeline register directly to the execute stage.

### Case 3: MEM Store Forwarding (WB-to-MEM)
A unique case where a `store` instruction needs data that is currently in the Writeback stage.

```asm
addi x1, x0, 10
sw   x1, 0(x2)    # sw needs x1, which is in WB stage
```

**Implementation (`src/mem_stage.sv`):**
```verilog
if (wb_reg_write && (wb_rd != 5'b0) && (wb_rd == mem_rs2)) begin
  return wb_data;
end else begin
  return mem_data;
end
```
The Memory stage contains its own mini-forwarding logic to ensure the <code>mem_data</code> is updated if the <code>rs2</code> register is being written to by the instruction currently in the Writeback stage.

---

## 3.3 The Load-Use Hazard

When an instruction depends on a `load` instruction, forwarding alone is insufficient because the data isn't available until the end of the Memory stage.

### Case 4: Load-Use Stall (The "Hardware Pause")

A Load-Use hazard is the only data hazard that **cannot** be solved by forwarding alone. The data is still in RAM while the next instruction is already trying to use it.

```asm
lw   x1, 0(x10)   # Load into x1
add  x2, x1, x3   # Uses x1 immediately (Stall needed)
or   x4, x5, x6   # Unrelated instruction
sub  x7, x1, x8   # Uses x1 (No stall, forwarding)
```

<div style="text-align: center;">
<script type="WaveDrom">
{ "signal": [
  { "name": "CLK", "wave": "p....." },
  { "name": "IF (Fetch)",     "wave": "34697x", "data": ["LW", "ADD", "OR", "OR", "SUB"] },
  { "name": "ID (Decode)",    "wave": "x34967", "data": ["LW", "ADD", "ADD", "OR", "SUB"] },
  { "name": "EX (Execute)",   "wave": "xx3546", "data": ["LW", "NOP", "AND", "OR" ] },
  { "name": "MEM (Memory)",   "wave": "xxx354", "data": ["LW", "NOP", "AND"] },
  { "name": "WB (Writeback)", "wave": "xxxx35", "data": ["LW", "NOP"] },
  {},
  { "name": "PIPELINE STATE", "wave": "xx345x", "data": ["DETECT", "STALL", "RESUME"] }
],
  "node": "b....",
  "edge": [ "a~>b Stall Active" ],
  "head": { "text": "Load-Use Hazard (1-Cycle Stall)", "tick": 0 },
  "config": { "hscale": 2.2 },
  "style": {
    "4": "fill:#0dd; stroke:#0dd; stroke-width:2;",
    "7": "fill:#f90; stroke:#f90; stroke-width:2;"
  }
}
</script>
</div>
<br>

---

## 3.4 Control Hazards

Control hazards occur when the CPU fetches instructions from the wrong path (e.g., after a branch).

### Case 5: Branch Misprediction (2-Cycle Flush)

Our CPU assumes a branch is **Not Taken** by default. If the branch *is* taken, we must "kill" the instructions already behind it in the pipeline.

```asm
beq  x1, x2, target  # Taken
addi x3, x0, 1       # Wrong1 (Flushed)
addi x4, x0, 2       # Wrong2 (Flushed)
...
target:
sub  x5, x5, x6      # Target
```

<div style="text-align: center;">
<script type="WaveDrom">
{ "signal": [
  { "name": "CLK", "wave": "p....." },
  { "name": "IF (Fetch)",     "wave": "34867x", "data": ["BEQ", "Wrong1", "Wrong2", "Target", "Next"] },
  { "name": "ID (Decode)",    "wave": "x34567", "data": ["BEQ", "Wrong1", "NOP", "Target", "Next"] },
  { "name": "EX (Execute)",   "wave": "xx3556", "data": ["BEQ", "NOP", "NOP", "Target"] },
  { "name": "MEM (Memory)",   "wave": "xxx355", "data": ["BEQ", "NOP", "NOP"] },
  {},
  { "name": "Branch Taken",   "wave": "xx10xx" },
  { "name": "Pipeline Action","wave": "xx35xx", "data": ["RESOLVE", "FLUSH", "Resume"] }
],
  "node": "b..",
  "edge": [ "a~>b Flush Active" ],
  "head": { "text": "Branch Taken (2-Cycle Flush)", "tick": 0 },
  "config": { "hscale": 2.2 },
  "style": {
    "4": "fill:#0dd; stroke:#0dd; stroke-width:2;",
    "5": "fill:#0dd; stroke:#0dd; stroke-width:2;",
    "8": "fill:#f90; stroke:#f90; stroke-width:2;"
  }
}
</script>
</div>
<br>

### Case 6: ALU-to-Branch Stall (Specific Implementation)
<div class="callout warn"><span class="title">Design Choice</span>
In our architecture, if a branch in the Decode stage depends on an ALU result currently in the Execute stage, the <code>HazardUnit</code> triggers an additional stall. This simplifies branch comparison timing at the cost of one extra cycle penalty.
</div>

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

<div class="callout note"><span class="title">A Note on Cycle Timing</span>
The following diagrams use a <strong>0-indexed</strong> cycle count, which is standard in hardware design. <strong>Cycle 0</strong> is the first clock cycle where the first instruction is fetched. An instruction fetched in Cycle <code>N</code> will be in the Decode stage in Cycle <code>N+1</code> and the Execute stage in Cycle <code>N+2</code>.
</div>

---

*riscv-5: a 5-Stage Pipelined RISC-V Processor (RV32I) by [Charlie Shields](https://github.com/cshieldsce), 2026*

<script src="{{ '/assets/js/lightbox.js' | relative_url }}"></script>
