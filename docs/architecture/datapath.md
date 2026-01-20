# Pipelined Datapath Analysis

This document maps the `riscv-5` SystemVerilog implementation to the architectural principles defined in *Computer Organization and Design (RISC-V Edition)* by Patterson & Hennessy.

## 1. Pipeline Stages

The processor implements a 5-stage pipeline, decoupling instruction execution into discrete clock cycles.

| Stage | Textbook Section | Module | Primary Responsibility |
| :--- | :--- | :--- | :--- |
| **IF** | 4.6.1 | `if_stage.sv` | PC management and instruction memory access. |
| **ID** | 4.6.1 | `id_stage.sv` | Decoding, register file access, and immediate generation. |
| **EX** | 4.6.1 | `ex_stage.sv` | ALU operations and branch target calculation. |
| **MEM** | 4.6.1 | `mem_stage.sv` | Synchronous data memory access. |
| **WB** | 4.6.1 | `reg_file.sv` | Register file writeback. |

---

## 2. Temporal Pipeline Flow

The following WaveDrom diagram illustrates the standard instruction flow through the pipeline stages.

```json
{ "signal": [
  { "name": "CLK", "wave": "p......." },
  { "name": "Instr 1", "wave": "34567...", "data": ["IF", "ID", "EX", "MEM", "WB"] },
  { "name": "Instr 2", "wave": ".34567..", "data": ["IF", "ID", "EX", "MEM", "WB"] },
  { "name": "Instr 3", "wave": "..34567.", "data": ["IF", "ID", "EX", "MEM", "WB"] },
  { "name": "Instr 4", "wave": "...34567", "data": ["IF", "ID", "EX", "MEM", "WB"] }
]}
```

---

## 3. Pipeline Registers

Inter-stage registers are utilized to preserve state across clock boundaries, as described in Section 4.6.

### IF/ID Register
Captures the instruction and PC for the decode stage.
```systemverilog
pipeline_reg #(32 + 32) IF_ID_REG (
    .clk(clk), .rst(rst | flush_id), .en(en_id),
    .d({pc_if, instr_if}),
    .q({pc_id, instr_id})
);
```

### ID/EX Register
Passes control signals and operands to the execution stage.
```systemverilog
pipeline_reg #(ID_EX_WIDTH) ID_EX_REG (
    .clk(clk), .rst(rst | flush_ex), .en(1'b1),
    .d(id_ex_data_in),
    .q(id_ex_data_out)
);
```

---

## 4. Hazard Mitigation

To resolve data hazards, the design implements a forwarding unit in the EX stage, minimizing stalls by bypassing the register file.

```systemverilog
// Forwarding from WB stage back to EX stage
if (wb_reg_write && (wb_rd != 0) && (wb_rd == ex_rs1)) begin
    forward_a = 2'b01; // Forward from WB
end
```

**[Detailed Hazard Analysis and War Stories](../verification/hazards.md)**

---
*Reference: Patterson & Hennessy, Computer Organization and Design (RISC-V Edition).*