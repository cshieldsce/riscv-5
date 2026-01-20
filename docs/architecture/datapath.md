# Pipelined Datapath Analysis

This document provides a detailed mapping of the `riscv-5` SystemVerilog implementation to the theoretical concepts defined in *Computer Organization and Design (RISC-V Edition)* by Patterson & Hennessy (Chapter 4).

## 1. The 5-Stage Pipeline Strategy

The processor implements the classic "Store-and-Forward" pipeline architecture. This separates the execution of an instruction into five discrete stages, allowing up to five instructions to be in flight simultaneously.

### Mapping Stages to Textbook Concepts (Section 4.6)

| Stage | Textbook Section | SystemVerilog Module | Key Functionality |
| :--- | :--- | :--- | :--- |
| **IF** | 4.6.1 | `if_stage.sv` | Program Counter (PC) management and instruction fetch. |
| **ID** | 4.6.1 | `id_stage.sv` | Instruction decoding, register file read, and immediate generation. |
| **EX** | 4.6.1 | `ex_stage.sv` | Arithmetic/Logic operations and branch target calculation. |
| **MEM** | 4.6.1 | `mem_stage.sv` | Data memory access (Load/Store). |
| **WB** | 4.6.1 | `reg_file.sv` | Writing results back to the architectural state. |

---

## 2. Temporal Pipeline Flow (WaveDrom)

The following diagram illustrates how a sequence of independent instructions flows through the pipeline stages (`IF` -> `ID` -> `EX` -> `MEM` -> `WB`).

```json
{ "signal": [
  { "name": "CLK", "wave": "p......." },
  { "name": "Instr 1 (ADD)", "wave": "34567...", "data": ["IF", "ID", "EX", "MEM", "WB"] },
  { "name": "Instr 2 (SUB)", "wave": ".34567..", "data": ["IF", "ID", "EX", "MEM", "WB"] },
  { "name": "Instr 3 (OR)",  "wave": "..34567.", "data": ["IF", "ID", "EX", "MEM", "WB"] },
  { "name": "Instr 4 (AND)", "wave": "...34567", "data": ["IF", "ID", "EX", "MEM", "WB"] }
]}
```

---

## 3. Pipeline Registers (The State-Between-Stages)

As defined in **Section 4.6 (Figure 4.35)**, pipeline registers are mandatory to preserve the values produced in one clock cycle for use in the next. In `riscv-5`, these are implemented as a generic `pipeline_reg` module.

### IF/ID Pipeline Register
**Textbook Mapping:** Preserves the fetched instruction and the PC for subsequent decoding.

```systemverilog
// In pipelined_cpu.sv
pipeline_reg #(32 + 32) IF_ID_REG (
    .clk(clk), .rst(rst | flush_id), .en(en_id),
    .d({pc_if, instr_if}),
    .q({pc_id, instr_id})
);
```

### ID/EX Pipeline Register
**Textbook Mapping:** Carries control signals and operand values to the Execution stage.

```systemverilog
// In pipelined_cpu.sv
pipeline_reg #(ID_EX_WIDTH) ID_EX_REG (
    .clk(clk), .rst(rst | flush_ex), .en(1'b1),
    .d(id_ex_data_in),
    .q(id_ex_data_out)
);
```

---

## 3. Data Hazards and Forwarding (Section 4.7)

To minimize stalls, `riscv-5` implements **Forwarding** (also known as Bypassing). This satisfies the "Data Hazard" equations defined in **Section 4.7**.

### Forwarding Logic (EX Stage)
The textbook defines the condition for forwarding from the MEM stage to the EX stage as:
> `if (MEM/WB.RegWrite and (MEM/WB.RegisterRd != 0) and (MEM/WB.RegisterRd == ID/EX.RegisterRs1)) ForwardA = 01`

**SystemVerilog Implementation (`forwarding_unit.sv`):**
```systemverilog
// Forwarding from WB stage back to EX stage
if (wb_reg_write && (wb_rd != 0) && (wb_rd == ex_rs1)) begin
    forward_a = 2'b01; // Forward from WB
end
```

---

## 4. Control Hazards and Branching (Section 4.8)

Branching is resolved in the **Execute (EX)** stage in our implementation, following the optimized design discussed in **Section 4.8**.

### Flush Mechanism
When a branch is "Taken", the instructions currently in the `IF` and `ID` stages must be discarded (flushed). This corresponds to replacing instructions with `NOPs` or clearing the pipeline registers.

```systemverilog
// In pipelined_cpu.sv
assign flush_id = branch_taken;
assign flush_ex = branch_taken;
```

---
**[Explore Detailed Hazard Handling & War Stories](../verification/hazards.md)**

---
*Reference: Patterson, D. A., & Hennessy, J. L. (2017). Computer Organization and Design RISC-V Edition: The Hardware/Software Interface.*
