# Architecture Manual: The Theoretical Anchor

This document proves to anchor every design decision in the `riscv-5` core to the official RISC-V ISA Specification and the seminal microarchitecture text *Patterson & Hennessy (RISC-V Edition)*.

## Introduction

To understand why we build pipelined processors, we first have to look at the limitations of a **Single Cycle CPU**. In a single-cycle implementation, the entire execution of an instruction—fetching from memory, decoding, calculating in the ALU, accessing data memory, and finally writing back to registers must happen in exactly one clock tick. 

> **FPGA Tip: The "Long Wire" Problem**
> If you have used Xilinx Vivado to synthesize a core, you likely encountered **Total Negative Slack (TNS)**. In a Single Cycle CPU, the "Critical Path" (the longest path between two registers) is effectively the entire length of the CPU. Vivado will report timing violations because the signal physically cannot travel to the logic gates fast enough.

You can think of a Single Cycle CPU as one giant combinational circuit, and the critical path as "one long wire" spanning from the Fetch $\to$ Writeback. If the signal has to travel through 50 gates to get from the Instruction Memory to the Register Writeback, your clock cycle must be long enough for the electricity to traverse all 50 gates at once. While this design is simple to understand, it is practically inefficient.

### The Solution: Pipelining

Pipelining solves this by breaking that "one long wire" into smaller, independent segments separated by Pipeline Registers. Instead of one cycle needing to cover the Fetch $\to$ Writeback distance, the clock cycle only needs to be long enough for the longest individual stage (e.g., just the Execute stage).

This architecture shift dramatically increases **Throughput**. While the time to execute one individual instruction (Latency) stays roughly the same, the rate at which we finish instructions skyrockets.

| Metric | Single Cycle CPU | Pipelined CPU |
| :--- | :--- | :--- |
| **Clock Speed** | Low (~10 MHz) | High (**50-100 MHz+**) |
| **Instructions Per Cycle** | 1 | 1 (Ideal) |
| **Logic Depth** | 50+ Gates (Deep) | ~10 Gates (Shallow) |
| **Vivado Timing** | Negative Slack 🔴 | Positive Slack 🟢 |

## Building the Core

Motivations:
systemverilog and function programming

found the hennesey book, everybody said it was the best, started reading in conjuction with the isa spec, went from there.

## 1. Mapping the Textbook to the RTL

The 5-stage pipeline is a faithful instantiation of the classic microarchitecture defined in **Section 4.6** of Patterson & Hennessy.

![Simplified pipelined datapath](../images/pipeline_basic.svg "Figure 4.31 - Patterson & Hennesey")

### 1.1 The Pipelined Datapath (Section 4.6)

Pipeline stage registers are the backbone of the pipeline, they allow us to transfer data freely between stages with blocking the flow of instructions. In the RTL, these registers carry data and control signals forward, ensuring that signals are synchronized with the instruction they control. This allows us to effectively synchronized the data and control signals required for instruction.

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
<!-- ELABORATION POINT: Discuss why you chose to resolve branches in EX vs ID. Refer to the "2-cycle penalty" tradeoff mentioned in the textbook. -->

### 2.2 Instruction Decode (ID)
- **Primary Objective:** Translate the opcode into control signals and retrieve operands.
- **ISA Compliance (Vol I, Ch 2):** Supports Integer Computational, Control Transfer, and Load/Store instructions.
<!-- ELABORATION POINT: Mention the specific handling of JAL in this stage. Why resolve it here? What is the impact on the branch penalty? -->
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
<!-- ELABORATION POINT: Add a side-by-side comparison for the MEM-to-EX forwarding condition. This proves you translated the mathematical logic accurately into hardware. -->

### 2.4 Memory Access (MEM)
- **Primary Objective:** Data memory interaction.
- **RTL implementation:** `mem_stage.sv`.
<!-- ELABORATION POINT: Explain the byte-alignment and sign-extension logic for LB, LH, and LBU instructions as per RISC-V Spec Section 2.6. -->
- **MMIO Support:** Integrated UART transmitter and LED controller at specific memory-mapped addresses.

### 2.5 Writeback (WB)
- **Primary Objective:** Update architectural registers.
- **Logic:** Selects between ALU results, Memory data, or Link addresses (`PC+4`) for register file updates.

---

## 3. Legislative Compliance: The RISC-V ISA Spec

<!-- ELABORATION POINT: Insert a section here detailing your implementation of the Zicsr extension or the behavior of SLT (Set Less Than) for signed vs unsigned comparisons. Refer specifically to Chapter 2 of the Unprivileged ISA manual. -->

---
*Reference: Patterson, D. A., & Hennessy, J. L. (2017). Computer Organization and Design RISC-V Edition.*
