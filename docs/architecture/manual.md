# Architecture Manual: The Theoretical Anchor

This document proves to anchor every design decision in the `riscv-5` core to the official RISC-V ISA Specification and the seminal microarchitecture text *Patterson & Hennessy (RISC-V Edition)*.

---

## Introduction

### The Single-Cycle Problem

To understand why we build pipelined processors, we first have to look at the limitations of a **Single Cycle CPU**. In a single-cycle implementation, the entire execution of an instruction—fetching from memory, decoding, calculating in the ALU, accessing data memory, and finally writing back to registers must happen in exactly one clock tick.

You can think of a Single Cycle CPU as one giant combinational circuit, and the critical path as "one long wire" spanning from the Fetch to Writeback. If the signal has to travel through 50 gates to get from the Instruction Memory to the Register Writeback, your clock cycle must be long enough for the electricity to traverse all 50 gates at once. While this design is simple to understand, it is practically inefficient.

> 💡 **FPGA Tip:**  
> If you have used Xilinx Vivado to synthesize a core, you likely encountered **Total Negative Slack (TNS)**. In a Single Cycle CPU, the "Critical Path" (the longest path between two registers) is effectively the entire length of the CPU. Vivado will report timing violations because the signal physically cannot travel to the logic gates fast enough.

### The Solution: Pipelining

Pipelining solves this by breaking that "one long wire" into smaller, independent segments separated by Pipeline Registers. Instead of one cycle needing to cover the Fetch to Writeback distance, the clock cycle only needs to be long enough for the longest individual stage (e.g., just the Execute stage).

This architecture shift dramatically increases **Throughput**. While the time to execute one individual instruction (Latency) stays roughly the same, the rate at which we finish instructions skyrockets.

| Metric | Single Cycle CPU | Pipelined CPU |
|--------|------------------|---------------|
| **Clock Speed** | Low (~10 MHz) | High (**50-100 MHz+**) |
| **Instructions Per Cycle** | 1 | 1 (Ideal) |
| **Logic Depth** | 50+ Gates (Deep) | ~10 Gates (Shallow) |
| **Vivado Timing** | Negative Slack (-) | Positive Slack (+) |

> ⚠️ **Latency vs. Throughput:**  
> It is a common misconception that pipelining reduces the execution time of a single instruction; in fact, individual latency often increases slightly due to register overhead. The true performance gain comes from throughput, as the processor completes one instruction every clock cycle rather than waiting for the entire datapath to finish. We accept this minor latency cost to achieve a massive increase in overall system frequency and processing rate.

---

## Building the Core

### Motivations

Motivations: SystemVerilog and functional programming

Found the Hennessy book, everybody said it was the best, started reading in conjunction with the ISA spec, went from there.

---

## 1. Mapping the Textbook to the RTL

The 5-stage pipeline is a faithful instantiation of the classic microarchitecture defined in **Section 4.6** of *Patterson & Hennessy*.

![Simplified pipelined datapath](../images/pipeline_basic.svg "Figure 4.31 - Patterson & Hennessy")

**Figure 1** illustrates the theoretical 5-stage RISC-V datapath as described in *Patterson & Hennessy*. Ideally, one instruction completes every cycle.

### 1.1 The Pipelined Datapath (Section 4.6)

Pipeline stage registers are the backbone of the pipeline, they allow us to transfer data freely between stages with blocking the flow of instructions. In the RTL, these registers carry data and control signals forward, ensuring that signals are synchronized with the instruction they control. This allows us to effectively synchronized the data and control signals required for instruction.

---

## 2. Pipeline Stages & Microarchitectural Logic

This section maps the theoretical pipeline stages from *Patterson & Hennessy* to our SystemVerilog implementation, proving that each stage faithfully implements the RISC-V ISA specification.

### 2.1 Instruction Fetch (IF)

**Implementation:** `if_stage.sv`  
**Objective:** Fetch the next instruction from memory and calculate `PC+4`.

The IF stage is responsible for maintaining program flow. It receives a `next_pc` value (either sequential or redirected due to branches/jumps) and outputs the current PC, the fetched instruction, and the default next address (`PC+4`).

#### RTL Implementation

```systemverilog
module IF_Stage (
    input  logic            clk, rst,
    input  logic [XLEN-1:0] next_pc_in,
    input  logic [XLEN-1:0] instruction_in,
    output logic [XLEN-1:0] instruction_out,
    output logic [XLEN-1:0] pc_out,
    output logic [XLEN-1:0] pc_plus_4_out
);
    PC pc_inst (
        .clk(clk),
        .rst(rst),
        .pc_in(next_pc_in),
        .pc_out(pc_out)
    );

    assign instruction_out = instruction_in;
    assign pc_plus_4_out = pc_out + 32'd4;

endmodule
```

#### PC Selection Logic

The PC selection multiplexer determines the next instruction address based on control hazards. This logic prioritizes control flow changes in order of detection:

```systemverilog
always_comb begin
    if (stall_if) begin
        next_pc = if_pc;                    // Hold PC during stall
    end else if (id_ex_jalr) begin
        next_pc = jalr_masked_pc;           // JALR: indirect jump (EX stage)
    end else if (branch_taken) begin
        next_pc = ex_branch_target;         // Taken branch (EX stage)
    end else if (id_jump) begin
        next_pc = jump_target_id;           // JAL: direct jump (ID stage)
    end else begin
        next_pc = if_pc_plus_4;             // Normal sequential execution
    end
end
```

#### Design Rationale

By detecting `JAL` early in the ID stage (since the target is just `PC + Immediate`), we reduce the control hazard penalty from 2 cycles to 1 cycle. However, `JALR` and conditional branches still incur a 2-cycle penalty because they require ALU computation. See **Case 5** below.

> 🎯 **Design Decision:**  
> JAL is a direct jump, so the target address is known immediately from the instruction encoding. JALR is indirect—the target depends on register content—so it can't be resolved until the EX stage. This asymmetry is why we get different penalty costs.

---

### 2.2 Instruction Decode (ID)

**Implementation:** `id_stage.sv`  
**Objective:** Decode the instruction, generate control signals, read registers, and produce the immediate value.

The ID stage is the "brain" of the pipeline, translating binary opcodes into control signals and preparing operands for execution.

#### Instruction Field Extraction

```systemverilog
assign opcode = opcode_t'(instruction[6:0]);
assign rd     = instruction[11:7];
assign funct3 = instruction[14:12];
assign rs1    = instruction[19:15];
assign rs2    = instruction[24:20];
assign funct7 = instruction[31:25];
```

#### ISA Compliance

This stage implements the decoding logic for all RV32I base instructions (Sections 2.2-2.5 of the RISC-V Unprivileged ISA Specification). The `ImmGen` module correctly handles the sign-extension requirements for I-type, S-type, B-type, U-type, and J-type immediate formats.

> 📋 **ISA Reference:**  
> See *RISC-V Unprivileged ISA Specification v20191213*, Section 2: "RV32I Base Integer ISA". All instruction formats and encoding are defined there.

---

### 2.3 Execute (EX)

**Implementation:** `ex_stage.sv`  
**Objective:** Perform ALU operations, resolve branches, and calculate jump/branch targets.

The Execute stage is where the actual computation happens. It receives operands (potentially forwarded from later stages), performs the requested operation, and determines if branches should be taken.

#### 1. Forwarding Multiplexers

The forwarding unit provides two 2-bit control signals (forward_a, forward_b) that select the most recent data:

```systemverilog
always_comb begin
    case (forward_a)
        2'b00:   alu_in_a_forwarded = rs1_data;         // No hazard
        2'b01:   alu_in_a_forwarded = wb_write_data;    // Forward from WB
        2'b10:   alu_in_a_forwarded = ex_mem_alu_result;// Forward from MEM
        default: alu_in_a_forwarded = rs1_data;
    endcase
end
```

#### 2. ALU Source Multiplexers

The alu_src_a signal handles special cases like LUI (Load Upper Immediate) and AUIPC (Add Upper Immediate to PC):

```systemverilog
always_comb begin
    case (alu_src_a)
        2'b00:   alu_in_a = alu_in_a_forwarded;   // Normal: Register
        2'b01:   alu_in_a = pc;                    // AUIPC: PC
        2'b10:   alu_in_a = {XLEN{1'b0}};          // LUI: Zero
        default: alu_in_a = alu_in_a_forwarded;
    endcase
end

assign alu_in_b = alu_src ? imm : rs2_data_forwarded;
```

> 💡 **LUI Trick:**  
> LUI (Load Upper Immediate) loads a 20-bit immediate into bits [31:12]. The RISC-V ISA defines this as: `rd = imm << 12`. By setting A = 0 and B = (imm << 12), we can reuse the ALU's addition operation: `0 + (imm << 12) = imm << 12`. This is an elegant hardware reuse pattern.

#### 3. Branch Resolution Logic

```systemverilog
always_comb begin
    if (branch_en) begin
        case (funct3)
            F3_BEQ:  branch_taken = alu_zero;          // A == B
            F3_BNE:  branch_taken = ~alu_zero;         // A != B
            F3_BLT:  branch_taken = alu_result[0];     // A < B (signed)
            F3_BGE:  branch_taken = ~alu_result[0];    // A >= B (signed)
            F3_BLTU: branch_taken = alu_result[0];     // A < B (unsigned)
            F3_BGEU: branch_taken = ~alu_result[0];    // A >= B (unsigned)
            default: branch_taken = 1'b0;
        endcase
    end else begin
        branch_taken = 1'b0;
    end
end

assign branch_target = pc + imm;
```

> ℹ️ **Implementation Detail:**  
> The ALU computes both signed and unsigned comparison results. BLT/BGE use the signed result (bit 0 of SLT operation), while BLTU/BGEU use the unsigned equivalent. The branch resolution logic simply selects the appropriate comparison output.

---

### 2.4 Memory Access (MEM)

**Implementation:** `mem_stage.sv` (simplified), `pipelined_cpu.sv` (byte enable logic)  
**Objective:** Interface with data memory, handle byte/halfword alignment, and manage Memory-Mapped I/O (MMIO).

The MEM stage translates RISC-V load/store operations into physical memory accesses, respecting byte, halfword, and word boundaries.

#### Byte Enable Generation

RISC-V supports sub-word memory accesses (LB, LH, SB, SH). The byte enable signal (dmem_be) tells the memory controller which bytes to write:

```systemverilog
// From pipelined_cpu.sv
always_comb begin
    case (ex_mem_funct3)
        F3_BYTE: begin  // Store/Load Byte
            case (ex_mem_alu_result[1:0])
                2'b00: dmem_be = 4'b0001;  // Byte 0
                2'b01: dmem_be = 4'b0010;  // Byte 1
                2'b10: dmem_be = 4'b0100;  // Byte 2
                2'b11: dmem_be = 4'b1000;  // Byte 3
            endcase
        end
        F3_HALF: begin  // Store/Load Halfword
            case (ex_mem_alu_result[1])
                1'b0: dmem_be = 4'b0011;   // Lower halfword
                1'b1: dmem_be = 4'b1100;   // Upper halfword
            endcase
        end
        default: dmem_be = 4'b1111;        // Word access
    endcase
end
```

> 📖 **ISA Requirement:**  
> The RISC-V ISA (Section 2.6, "Load and Store Instructions") mandates byte-granular memory access control. Addresses must be naturally aligned for their size (byte at any address, halfword at even addresses, word at 4-byte aligned addresses). This logic ensures compliance.

---

### 2.5 Writeback (WB)

**Implementation:** `pipelined_cpu.sv` (writeback multiplexer)  
**Objective:** Select the correct data to write back to the register file.

The WB stage resolves the final value for the destination register using the mem_to_reg control signal:

```systemverilog
// From pipelined_cpu.sv
always_comb begin
    case (mem_wb_mem_to_reg)
        2'b00: wb_write_data = mem_wb_alu_result;  // R-type, I-type ALU ops
        2'b01: wb_write_data = mem_read_data;      // Load instructions (LW, LH, LB)
        2'b10: wb_write_data = mem_wb_pc_plus_4;   // JAL, JALR (return address)
        default: wb_write_data = {XLEN{1'b0}};     // Safety default
    endcase
end
```

#### ISA Compliance

- `mem_to_reg = 00`: Standard ALU operations (ADD, SUB, AND, etc.)
- `mem_to_reg = 01`: Load instructions that read from memory
- `mem_to_reg = 10`: Jump-and-link instructions that save the return address (PC+4) into rd

> 💡 **Why PC+4 for JAL/JALR?**  
> The RISC-V ISA specifies that JAL and JALR store the address of the next instruction (the instruction immediately after the jump) into the destination register. This enables function calls: the callee saves `ra` somewhere, does work, then executes `JALR x0, 0(ra)` to jump back. The `0(ra)` addressing mode loads the return address from register `ra`.

### 2.6 Pipeline Register Summary

Each pipeline register preserves the architectural state needed by downstream stages. Below is a summary of the data and control signals carried by each register:

| Register | Data Fields | Control Signals | Purpose |
|----------|-------------|-----------------|---------|
| **IF/ID** | `pc`, `instruction`, `pc+4` | None (control generated in ID) | Preserve fetched instruction for decoding |
| **ID/EX** | `pc`, `pc+4`, `rs1_data`, `rs2_data`, `imm`, `rs1`, `rs2`, `rd`, `funct3` | `reg_write`, `mem_write`, `alu_control`, `alu_src`, `alu_src_a`, `mem_to_reg`, `branch`, `jump`, `jalr` | Supply operands and control for execution |
| **EX/MEM** | `alu_result`, `rs2_data`, `rd`, `pc+4`, `funct3`, `rs2` | `reg_write`, `mem_write`, `mem_to_reg` | Interface with memory and preserve results |
| **MEM/WB** | `mem_read_data`, `alu_result`, `rd`, `pc+4` | `reg_write`, `mem_to_reg` | Select data for register writeback |

> 🔧 **Design Note:**  
> We include `rs2` in the EX/MEM register to enable store data forwarding (described in Section 3, Case 4). Without it, store instructions couldn't forward dependent values to memory writes. This is a subtle optimization not always shown in textbook diagrams but critical for correctness.

---

## 3.0 Hazard Resolution

### The Problem: The Pipeline Illusion

In a standard Single-Cycle processor, the concept of a "Data Hazard" does not exist. The entire instruction completes fetching, calculating, and writing back to the register file before the next instruction even begins. The software written for a single cycle processor assumes: "Instruction A finishes completely before Instruction B starts."

However, in our Pipelined design we violate this assumption. We now have up to five instructions executing simultaneously.

> ⚠️ **The Dependency Paradox:**  
> If Instruction B relies on a value calculated by Instruction A, Instruction B might try to read that value from the Register File *before* Instruction A has actually written the value to the register. Without intervention, the CPU would process stale data, leading to incorrect results.

Without intervention, the CPU would process stale data leading to calculation errors. To maintain the illusion of sequential execution while enjoying the speed of parallel processing, we implemented a sophisticated Hazard Resolution system using **Forwarding** (bypassing storage) and **Stalling** (injecting wait states).

### The Solution Architecture

When a Data Hazard occurs, the hardware must choose between an aggressive optimization (Forwarding) or a defensive pause (Stalling).

> 🚀 **Forwarding Strategy:**  
> Forwarding relies on the fact that the calculated data already exists inside the pipeline registers, even though it hasn't been written back to the Register File yet. The Forwarding Unit detects data dependencies and routes the data directly to the ALU inputs via multiplexers. This allows the pipeline to maintain full speed with zero latency penalty for most hazards.

> ⏸️ **Stalling Strategy:**  
> Stalling is the fallback when forwarding is physically impossible (e.g., data is still in RAM). The Hazard Unit freezes the Program Counter and flushes the `ID/EX` register, injecting a "bubble" (NOP) into the pipeline. This forces dependent instructions to wait exactly one cycle, allowing memory data to arrive.

We handle hazards using two dedicated hardware units:

1. **The Forwarding Unit (`src/forwarding_unit.sv`):** A combinational logic block that controls MUXes at the ALU inputs. It "short-circuits" data from later pipeline stages directly to the Execute stage, skipping the Register File entirely.
2. **The Hazard Unit (`src/hazard_unit.sv`):** The "traffic cop" of the CPU. If forwarding is impossible (e.g., waiting for RAM), it freezes the PC and inserts "bubbles" (NOPs) to pause execution.

> 📊 **[INSERT DATAPATH DIAGRAM HERE]**  
> Show the full datapath with Hazard and Forwarding Units annotated. Include MUX select signals and the priority logic that determines which forwarding path wins.

---

### 3.2 Detailed Case Analysis

Below is an analysis of every hazard scenario our architecture handles, including the specific assembly code that triggers it and the hardware's response.

#### Case 1: EX-to-EX Forwarding (Immediate Dependency)

This is the most common hazard. An instruction needs the result of the *immediately preceding* operation.

```assembly
add x1, x2, x3   # In EX/MEM stage (Result calculated, not written)
sub x5, x1, x4   # In ID/EX stage  (Needs x1 NOW)
```

| The Problem | The Fix | Penalty (Cycles) |
|-------------|---------|-----------------|
| The result of the add is in the `EX/MEM` pipeline register. The `sub` instruction is about to enter the ALU. | The Forwarding Unit detects `rs1_ex == rd_mem`. It switches the ALU MUX to grab data directly from the `EX/MEM` register. | 0 |

---

#### Case 2: MEM-to-EX Forwarding (Delayed Dependency)

The dependency is one instruction removed.

```assembly
add x1, x2, x3   # In MEM/WB stage (Waiting to be written)
nop              # (Or any unrelated instruction)
sub x5, x1, x4   # In ID/EX stage (Needs x1)
```

| The Problem | The Fix | Penalty (Cycles) |
|-------------|---------|-----------------|
| The result is in the `MEM/WB` register, not yet in the register file. | The Forwarding Unit detects `rs1_ex == rd_wb`. It switches the ALU MUX to grab data from the `MEM/WB` register. | 0 |

---

#### Case 3: The "Double Hazard" (Priority Logic)

What if both previous instructions write to the same register?

```assembly
addi x1, x0, 10    # Instruction A (In MEM/WB) - Writes 10 to x1
addi x1, x0, 20    # Instruction B (In EX/MEM) - Writes 20 to x1
add  x5, x1, x6    # Instruction C (In ID/EX)  - Needs x1
```

| The Problem | The Fix | Penalty (Cycles) |
|-------------|---------|-----------------|
| Both the `EX/MEM` and `MEM/WB` stages contain a value for `x1`. Which one is correct? | The Forwarding Unit checks the `EX/MEM` hazard first. Since *Instruction B* is more recent, its value (20) overrides *Instruction A*'s value (10). | 0 |

Snippet (`src/forwarding_unit.sv`):

```systemverilog
if (forward_ex_condition) begin
    // Forward from EX/MEM (Most Recent)
end else if (forward_mem_condition) begin
    // Forward from MEM/WB (Older)
end
```

> 🔧 **Priority Resolution:**  
> This is a subtle but critical detail. The forwarding logic must prioritize the most recently computed value. If we forwarded from MEM/WB when EX/MEM had the newer result, we'd compute with stale data. The priority always favors EX/MEM over MEM/WB.

---

#### Case 4: The Load-Use Hazard (The Physical Limit)

This is the only case where forwarding is physically impossible.

```assembly
lw  x1, 0(x2)    # In EX stage (Calculating address, data is still in RAM)
add x3, x1, x4   # In ID stage (Needs x1 immediately)
```

| The Problem | The Fix | Penalty (Cycles) |
|-------------|---------|-----------------|
| The `lw` instruction is currently calculating the address. The data is still inside the memory chip. We cannot forward data we haven't fetched yet. | The Hazard Unit:<br>**1. Stall:** PC_Write and IF/ID_Write are disabled. The `lw` and `add` stay put for 1 cycle.<br>**2. Bubble:** The `ID/EX` register is flushed (control signals set to 0), sending a `NOP` down the pipeline. | 1 |

> ⚠️ **Unavoidable Stall:**  
> This is the only data hazard that cannot be resolved by forwarding. Memory latency is physical—the RAM access takes time. We must stall and wait. This is why modern CPUs use caches and prefetching to minimize load-use hazard penalties.

**Timing Diagram:**

```
Cycle 1:  lw  (EX)  │ add (ID)
Cycle 2:  lw  (MEM) │ BUBBLE (stalled, flushed)
Cycle 3:  lw  (WB)  │ add (EX) ← x1 available via forwarding
```

---

#### Case 5: Control Hazards (Branch Misprediction)

Because we resolve branches in the **Execute (EX)** stage, we don't know if we need to jump until the instruction is halfway through the pipeline.

```assembly
beq x1, x2, LABEL  # Taken! (In EX Stage)
addi x5, x0, 1     # (In ID Stage - Wrong path!)
sub  x6, x0, 2     # (In IF Stage - Wrong path!)
```

| The Problem | The Fix | Penalty (Cycles) |
|-------------|---------|-----------------|
| By the time `beq` decides to take the branch, we have already fetched two instructions we shouldn't have. | The Hazard Unit detects `PCSrc` (Branch Taken) is high. It asserts `Flush_ID` and `Flush_EX`, wiping those two instructions from existence. | 2 |

> ⚠️ **Branch Penalty Trade-off:**  
> Our **2-Cycle Branch Penalty** seems high compared to some architectures. A common optimization is to move branch comparison from the **Execute (EX)** stage to the **Decode (ID)** stage. This would reduce the penalty to just **1 Cycle** (flushing only IF).
>
> **Why didn't we do this?**  
> If we moved branch logic to ID, we'd need to add significant hardware (comparator, adder for target calculation) into the already-congested ID stage. This would increase the Critical Path of the ID stage, forcing us to slow down our entire clock frequency. We chose to accept the 2-cycle penalty to keep the clock fast. Trades are always about picking which metric matters most.

> 📊 **[INSERT CONTROL HAZARD TIMING DIAGRAM HERE]**  
> Show cycles 1-4 with the branch being resolved, wrong instructions flushed, and correct path resuming.

---

## References

1. **Patterson, D. A., & Hennessy, J. L.** (2017). *Computer Organization and Design: The Hardware/Software Interface (RISC-V Edition).* Morgan Kaufmann.
   - Chapter 4: The Processor — 5-stage pipeline architecture
   - Section 4.6: Pipelined datapath and control

2. **RISC-V Foundation.** *The RISC-V Instruction Set Manual Volume I: Unprivileged ISA (v20191213).*
   - Section 2: RV32I Base Integer ISA
   - Section 2.6: Load and Store Instructions
   - Section 12: Instruction Formats and Encoding

3. **RISC-V Software Tools Documentation.** *riscv64-unknown-elf-gcc* and *spike* simulator.

---

**Last Updated:** January 2026  
**Author:** Charles Shields