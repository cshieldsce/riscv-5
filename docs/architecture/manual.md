# Architecture Manual: The Theoretical Anchor

To prove engineering competence, this document anchors every design decision in the `riscv-5` core to the official RISC-V ISA Specification and the seminal microarchitecture text *Patterson & Hennessy (RISC-V Edition)*.

## 🏛️ Rationale: Why Mapping Matters

A common pitfall in digital design is "hacking" an architecture until it passes a testbench without understanding the underlying principles. By explicitly mapping RTL modules to established textbook equations, we demonstrate that this design is not ad-hoc, but a faithful instantiation of proven architectural principles. This mapping provides the "Theoretical Audit" required by academic evaluators and senior design engineers.

## 1. Mapping the Textbook to the RTL

The 5-stage pipeline is a faithful instantiation of the classic microarchitecture defined in **Section 4.6** of Patterson & Hennessy.

[INSERT DRAW.IO DIAGRAM: The 5-Stage Datapath Topology (LR Flow, Subgraph Boundaries, Signal Labels for rs1_data, imm_val, etc.)]

### 1.1 The Pipelined Datapath (Section 4.6)

Inter-stage registers are the structural necessity of the pipeline. In the RTL, these registers carry data and control signals forward, ensuring that signals are synchronized with the instruction they control.

| Textbook Reference | SystemVerilog Module | Architectural State Preserved |
| :--- | :--- | :--- |
| **Section 4.6.1** | `if_stage.sv` | Program Counter (PC) and instruction fetch logic. |
| **Section 4.6.2** | `id_stage.sv` | Decoding logic, Register File read, and Immediate generation. |
| **Section 4.6.2** | `pipeline_reg.sv` | IF/ID, ID/EX, EX/MEM, and MEM/WB stage registers. |

---

## 2. Pipeline Stages & Microarchitectural Logic

### 2.1 Instruction Fetch (IF)
- **Primary Objective:** Anchor the PC to the next instruction address.
- **RTL implementation:** `if_stage.sv`.
- **Key Logic:** The PC logic resolves `PC+4` by default, or the `branch_target` if `PCSrc` is asserted in the EX stage.

### 2.2 Instruction Decode (ID)
- **Primary Objective:** Translate the opcode into control signals and retrieve operands.
- **ISA Compliance (Vol I, Ch 2):** Supports Integer Computational, Control Transfer, and Load/Store instructions.
- **ImmGen Logic:** Maps directly to the signed immediate layouts for I, S, B, U, and J formats.

### 2.3 Execute (EX)
- **Primary Objective:** ALU execution and branch target resolution.
- **Forwarding Unit:** Implements the "Real-Time" bypass logic defined in **Section 4.7**.
- **Theoretical Equation Mapping:**
  ```verilog
  // Patterson & Hennessy Equation (Section 4.7)
  // if (EX/MEM.RegWrite and (EX/MEM.RegisterRd != 0) and (EX/MEM.RegisterRd == ID/EX.RegisterRs1)) ForwardA = 10
  if (ex_mem_reg_write && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs1)) begin
      forward_a = 2'b10;
  end
  ```

### 2.4 Memory Access (MEM)
- **Primary Objective:** Data memory interaction.
- **RTL implementation:** `mem_stage.sv`.
- **MMIO Support:** Integrated UART transmitter and LED controller at specific memory-mapped addresses.

### 2.5 Writeback (WB)
- **Primary Objective:** Update architectural registers.
- **Logic:** Selects between ALU results, Memory data, or Link addresses (`PC+4`) for register file updates.

---

## 3. Control Hazard Management (Section 4.8)

Branch instructions resolution is performed in the **EX stage**. Mispredicted branches result in a 2-cycle flush of the `IF` and `ID` stages, turning fetched instructions into bubbles (NOPs).

---
*Reference: Patterson, D. A., & Hennessy, J. L. (2017). Computer Organization and Design RISC-V Edition.*