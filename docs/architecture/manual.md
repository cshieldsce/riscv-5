# Architecture Manual: The Theoretical Anchor

This document proves to anchor every design decision in the `riscv-5` core to the official RISC-V ISA Specification and the seminal microarchitecture text *Patterson & Hennessy (RISC-V Edition)*.

## Introduction

To understand why we build pipelined processors, we first have to look at the limitations of a **Single Cycle CPU**. In a single-cycle implementation, the entire execution of an instruction—fetching from memory, decoding, calculating in the ALU, accessing data memory, and finally writing back to registers must happen in exactly one clock tick. 

You can think of a Single Cycle CPU as one giant combinational circuit, and the critical path as "one long wire" spanning from the Fetch $\to$ Writeback. If the signal has to travel through 50 gates to get from the Instruction Memory to the Register Writeback, your clock cycle must be long enough for the electricity to traverse all 50 gates at once. While this design is simple to understand, it is practically inefficient.

> **FPGA Tip: The "Long Wire" Problem**
> If you have used Xilinx Vivado to synthesize a core, you likely encountered **Total Negative Slack (TNS)**. In a Single Cycle CPU, the "Critical Path" (the longest path between two registers) is effectively the entire length of the CPU. Vivado will report timing violations because the signal physically cannot travel to the logic gates fast enough.

### The Solution: Pipelining

Pipelining solves this by breaking that "one long wire" into smaller, independent segments separated by Pipeline Registers. Instead of one cycle needing to cover the Fetch $\to$ Writeback distance, the clock cycle only needs to be long enough for the longest individual stage (e.g., just the Execute stage).

This architecture shift dramatically increases **Throughput**. While the time to execute one individual instruction (Latency) stays roughly the same, the rate at which we finish instructions skyrockets.

| Metric | Single Cycle CPU | Pipelined CPU |
| :--- | :--- | :--- |
| **Clock Speed** | Low (~10 MHz) | High (**50-100 MHz+**) |
| **Instructions Per Cycle** | 1 | 1 (Ideal) |
| **Logic Depth** | 50+ Gates (Deep) | ~10 Gates (Shallow) |
| **Vivado Timing** | Negative Slack (-) | Positive Slack (+) |

> **Latency vs. Throughput**: It is a common misconception that pipelining reduces the execution time of a single instruction; in fact, individual latency often increases slightly due to register overhead. The true performance gain comes from throughput, as the processor completes one instruction every clock cycle rather than waiting for the entire datapath to finish. We accept this minor latency cost to achieve a massive increase in overall system frequency and processing rate.

## Building the Core

Motivations:
systemverilog and function programming

found the hennesey book, everybody said it was the best, started reading in conjuction with the isa spec, went from there.

## 1. Mapping the Textbook to the RTL
The 5-stage pipeline is a faithful instantiation of the classic microarchitecture defined in **Section 4.6** of *Patterson & Hennessy*.

![Simplified pipelined datapath](../images/pipeline_basic.svg "Figure 4.31 - Patterson & Hennessy")

**Figure 1** illustrates the theoretical 5-stage RISC-V datapath as described in *Patterson & Hennessy*. Ideally, one instruction completes every cycle.


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

## 3.0 Hazard Resolution:

### The Problem: The Pipeline Illusion
In a standard Single-Cycle processor, the concept of a "Data Hazard" does not exist. The entire instruction completes fetching, calculating, and writing back to the register file before the next instruction even begins. The software written for a single cycle processor assumes: "Instruction A finishes completely before Instruction B starts."

However, in our Pipelined design we violate this assumption. We now have up to five instructions executing simultaneously.

> **The Dependency Paradox**:<br> If Instruction B relies on a value calculated by Instruction A, Instruction B might try to read that value from the Register File *before* Instruction A has actually written the value to the register.

Without intervention, the CPU would process stale data leading to calculation errors. To maintain the illusion of sequential execution while enjoying the speed of parallel processing, we implemented a sophisticated Hazard Resolution system using **Forwarding** (bypassing storage) and **Stalling** (injecting wait states).

> **Implementation:** When a Data Hazard occurs, the hardware must choose between an aggressive optimization (Forwarding) or a defensive pause (Stalling).<br><br>**Forwarding** relies on the fact that the calculated data already exists inside the pipeline registers somewhere even though it hasn't been written back to the Register File. The Forwarding Unit detects routes the data directly to the ALU inputs via multiplexers. This allows the pipeline to maintain full speed, executing dependent instructions with zero latency penalty.<br><br>**Stalling** is the fallback used when forwarding is physically impossible (case study link), the Hazard Unit must freeze the Program Counter and flush the `ID/EX` register. This injects a "bubble" (or NOP) into the pipeline, forcing the instruction to wait exactly one clock cycle so that the memory access can complete.

---

### 2.1 The Solution Architecture

We handle hazards using two dedicated hardware units. You can see their interactions in the datapath diagram below.

![Insert your Draw.io Diagram Here](path/to/your/pipeline_diagram.png)
*(Figure 2.1: The Pipelined Datapath featuring Hazard and Forwarding Units)*

1.  **The Forwarding Unit (`src/forwarding_unit.sv`):** A combinational logic block that controls MUXes at the ALU inputs. It "short-circuits" data from later pipeline stages directly to the Execute stage, skipping the Register File entirely. 
2.  **The Hazard Unit (`src/hazard_unit.sv`):** The "traffic cop" of the CPU. If forwarding is impossible (e.g., waiting for RAM), it freezes the PC and inserts "bubbles" (NOPs) to pause execution.

---

### 2.2 Detailed Case Analysis

Below is an analysis of every hazard scenario our architecture handles, including the specific assembly code that triggers it and the hardware's response.

#### Case 1: EX-to-EX Forwarding (Immediate Dependency)
This is the most common hazard. An instruction needs the result of the *immediately preceding* operation.

**The Code:**
```assembly
add x1, x2, x3   # In EX/MEM stage (Result calculated, not written)
sub x5, x1, x4   # In ID/EX stage  (Needs x1 NOW)
```

| The Problem | The Fix | Penalty (Cycles) |
| :--- | :--- | :--- |
| The result of the add is in the `EX/MEM` pipeline register.<br> The `sub` instruction is about to enter the ALU. | The Forwarding Unit detects `rs1_ex == rd_mem`.<br> It switches the ALU MUX to grab data directly from the `EX/MEM` register. | 0 |

### Case 2: MEM-to-EX Forwarding (Delayed Dependency)
The dependency is one instruction removed.

Code snippet
```assembly
add x1, x2, x3   # In MEM/WB stage (Waiting to be written)
nop              # (Or any unrelated instruction)
sub x5, x1, x4   # In ID/EX stage (Needs x1)
```

| The Problem | The Fix | Penalty (Cycles) |
| :--- | :--- | :--- |
| The result is in the `MEM/WB` register, we don't have access to it. | The Forwarding Unit detects `rs1_ex == rd_wb`. <br>It switches the ALU MUX to grab data from the `MEM/WB register.` | 0 |


### Case 3: The "Double Hazard" (Priority Logic)
This is an edge case that tests the robustness of the forwarding logic. What if both previous instructions write to the same register?

The Code:
Code snippet
```assembly
addi x1, x0, 10    # Instruction A (In MEM/WB) - Writes 10 to x1
addi x1, x0, 20    # Instruction B (In EX/MEM) - Writes 20 to x1
add  x5, x1, x6    # Instruction C (In ID/EX)  - Needs x1
```

| The Problem | The Fix | Penalty (Cycles) |
| :--- | :--- | :--- |
| Both the `EX/MEM` and `MEM/WB` stages contain a value for `x1`.<br> Which one do we use? | The Forwarding Unit checks the `EX/MEM` hazard first.<br>Since *Instruction B* is more recent, its value overrides *Instruction A*. | 0 |

Snippet (forwarding_unit.sv):
```sv
if (forward_ex_condition) begin
    // Forward from EX/MEM (Most Recent)
end else if (forward_mem_condition) begin
    // Forward from MEM/WB (Older)
end
```

#### Case 4: The Load-Use Hazard (The Physical Limit)
This is the only case where forwarding is physically impossible.

Code snippet
```assembly
lw  x1, 0(x2)    # In EX stage (Calculating address, data is still in RAM)
add x3, x1, x4   # In ID stage (Needs x1 immediately)
```

| The Problem | The Fix | Penalty (Cycles) |
| :--- | :--- | :--- |
| The `lw` instruction is currently calculating the address.<br> The data is still inside the memory chip.<br>We cannot forward data we haven't fetched yet. | The Hazard Unit : <br>**1. Stall:** PC_Write and IF/ID_Write are disabled. <br>The `lw` and `add` stay put for 1 cycle.<br> **2. Bubble:** The `ID/EX` register is flushed (control signals set to 0),<br> sending a `NOP` down the pipeline. | 1 |



explain stalls and bubbles

### Case 5: Control Hazards (Branch Misprediction)
Because we resolve branches in the **Execute (EX)** stage, we don't know if we need to jump until the instruction is halfway through the pipeline.

The Code:

Code snippet
```asm
beq x1, x2, LABEL  # Taken! (In EX Stage)
addi x5, x0, 1     # (In ID Stage - Wrong path!)
sub  x6, x0, 2     # (In IF Stage - Wrong path!)
```

Penalty: 2 Cycles.

| The Problem | The Fix | Penalty (Cycles) |
| :--- | :--- | :--- |
| By the time `beq` decides to take the branch,<br> we have already fetched two instructions we shouldn't have. | The Hazard Unit detects `PCSrc` (Branch Taken) is high. It asserts `Flush_ID` and `Flush_EX`, wiping those two instructions from existence. | 2 |


> You might notice that our **2-Cycle Branch Penalty** (flushing IF and ID) seems high. A common optimization in RISC-V architectures is to move the branch comparison logic earlier, from the **Execute (EX)** stage to the **Decode (ID)** stage. If we resolved branches in the ID stage, we would only need to flush the IF stage, reducing the misprediction penalty to just **1 Cycle**.<br><br>**So, why did we keep it in the EX stage?**<br>If we wanted to move the branch logic we would have to introduce significant hardware costs (e.g., comparator, adder) into the **Decode (ID)** stage which is already congested. This would cause our *Critical Path* to grow, forcing us to slow down the entire CPU clock.

---
*Reference: Patterson, D. A., & Hennessy, J. L. (2017). Computer Organization and Design RISC-V Edition.*


