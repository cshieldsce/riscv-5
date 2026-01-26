<link rel="stylesheet" href="{{ '/assets/css/style.css' | relative_url }}">
<div class="site-nav">
  <a href="../index.html">Home</a>
  <a href="./manual.html">Architecture Overview</a>
  <a href="./stages.html">Pipeline Stages</a>
  <a href="./hazards.html">Hazard Resolution</a>
  <a href="../verification/report.html">Verification</a>
  <a href="../developer/guide.html">Setup Guide</a>
</div>

# 2. Pipeline Stages & Microarchitectural Logic

This section maps the theoretical pipeline stages from *Patterson & Hennessy* to our SystemVerilog implementation, proving that each stage faithfully implements the RISC-V ISA specification.

## Complete Datapath
Before diving into individual stages, here's the full pipeline with all major signals labeled:

![Complete Pipelined Datapath](../images/pipeline_complete.svg)
*Figure 3: Complete datapath showing pipeline registers, forwarding paths, and hazard detection units. Based on Patterson & Hennessy Figure 4.51.*

This diagram maps directly to our SystemVerilog implementation in [`src/pipelined_cpu.sv`](../../src/pipelined_cpu.sv).


## 2.1 Instruction Fetch (IF)

![IF Stage Detail](../images/stage_if.svg)
*Figure 4: IF stage showing PC selection multiplexer and instruction memory interface.*

**Implementation:** `if_stage.sv`  
**Objective:** Fetch the next instruction from memory and calculate `PC+4`.

The IF stage is responsible for maintaining program flow. It receives a `next_pc` value (either sequential or redirected due to branches/jumps) and outputs the current PC, the fetched instruction, and the default next address (`PC+4`).

### RTL Implementation

```verilog
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

### PC Selection Logic

The PC selection multiplexer determines the next instruction address based on control hazards. This logic prioritizes control flow changes in order of detection:

```verilog
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

### Design Rationale

By detecting `JAL` early in the ID stage (since the target is just `PC + Immediate`), we reduce the control hazard penalty from 2 cycles to 1 cycle. However, `JALR` and conditional branches still incur a 2-cycle penalty because they require ALU computation. See **Case 5** below.

<div class="callout note"><span class="title">Design Decision</span>
JAL is a direct jump, so the target address is known immediately from the instruction encoding. JALR is indirect—the target depends on register content—so it can't be resolved until the EX stage. This asymmetry is why we get different penalty costs.
</div>

---

## 2.2 Instruction Decode (ID)

![ID Stage Detail](../images/stage_id.svg)
*Figure 5: ID stage with control unit, register file, and immediate generator.*

**Implementation:** `id_stage.sv`  
**Objective:** Decode the instruction, generate control signals, read registers, and produce the immediate value.

The ID stage is the "brain" of the pipeline, translating binary opcodes into control signals and preparing operands for execution.

### Instruction Field Extraction

```verilog
assign opcode = opcode_t'(instruction[6:0]);
assign rd     = instruction[11:7];
assign funct3 = instruction[14:12];
assign rs1    = instruction[19:15];
assign rs2    = instruction[24:20];
assign funct7 = instruction[31:25];
```

### ISA Compliance

This stage implements the decoding logic for all RV32I base instructions (Sections 2.2-2.5 of the RISC-V Unprivileged ISA Specification). The `ImmGen` module correctly handles the sign-extension requirements for I-type, S-type, B-type, U-type, and J-type immediate formats.

<div class="callout note"><span class="title">ISA Reference</span>
See <em>RISC-V Unprivileged ISA Specification v20191213</em>, Section 2: "RV32I Base Integer ISA". All instruction formats and encoding are defined there.
</div>

---

## 2.3 Execute (EX)

![EX Stage Detail](../images/stage_ex.svg)
*Figure 6: EX stage showing forwarding multiplexers and branch resolution logic.*

**Implementation:** `ex_stage.sv`  

The `EX` stage is where the actual computation happens. It receives operands (potentially forwarded from later stages), performs the requested operation, and determines if branches should be taken.

### 1. Forwarding Multiplexers

The forwarding unit provides two 2-bit control signals (`forward_a`, `forward_b`) that select the most recent data:

```verilog
always_comb begin
    case (forward_a)
        2'b00:   alu_in_a_forwarded = rs1_data;         // No hazard
        2'b01:   alu_in_a_forwarded = wb_write_data;    // Forward from WB
        2'b10:   alu_in_a_forwarded = ex_mem_alu_result;// Forward from MEM
        default: alu_in_a_forwarded = rs1_data;
    endcase
end
```

### 2. ALU Source Multiplexers

The `alu_src_a` signal handles special cases like `LUI` (Load Upper Immediate) and `AUIPC` (Add Upper Immediate to PC):

```verilog
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

<div class="callout tip"><span class="title">LUI Trick</span>
LUI (Load Upper Immediate) loads a 20-bit immediate into bits [31:12]. The RISC-V ISA defines this as: <code>rd = imm << 12</code>. By setting <code>A = 0</code> and <code>B = (imm << 12)</code>, we can reuse the ALU's addition operation: <code>0 + (imm << 12) = imm << 12</code>. This is an elegant hardware reuse pattern.
</div>

### 3. Branch Resolution Logic

```verilog
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

<div class="callout note"><span class="title">Implementation Detail</span>
The ALU computes both signed and unsigned comparison results. <code>BLT</code>/<code>BGE</code> use the signed result (bit 0 of SLT operation), while <code>BLTU</code>/<code>BGEU</code> use the unsigned equivalent. The branch resolution logic simply selects the appropriate comparison output.
</div>

---

## 2.4 Memory Access (MEM)

**Implementation:** `mem_stage.sv` (simplified), `pipelined_cpu.sv` (byte enable logic)  

The `MEM` stage translates RISC-V load/store operations into physical memory accesses, respecting byte, halfword, and word boundaries. It also manages Memory-Mapped I/O (MMIO) for our FPGA implementation.

### Byte Enable Generation

RISC-V supports sub-word memory accesses (`LB`, `LH`, `SB`, `SH`). The byte enable signal (`dmem_be`) tells the memory controller which bytes to write:

```verilog
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

<div class="callout note"><span class="title">ISA Requirement</span>
See <em>RISC-V Unprivileged ISA Specification</em>, Section 2.6: "Load and Store Instructions". The ISA mandates byte-granular memory access control. Addresses must be naturally aligned for their size (byte at any address, halfword at even addresses, word at 4-byte aligned addresses). This logic ensures compliance.
</div>

---

## 2.5 Writeback (WB)

**Implementation:** `pipelined_cpu.sv` (writeback multiplexer)  

The `WB` stage resolves the final value for the destination register using the `mem_to_reg` control signal:

```verilog
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

### ISA Compliance

- `mem_to_reg = 00`: Standard ALU operations (ADD, SUB, AND, etc.)
- `mem_to_reg = 01`: Load instructions that read from memory
- `mem_to_reg = 10`: Jump-and-link instructions that save the return address (PC+4) into rd

<div class="callout tip"><span class="title">Why PC+4 for JAL/JALR?</span>
See <em>RISC-V Unprivileged ISA Specification</em>, Section 2.5: "Control Transfer Instructions". JAL and JALR store the address of the next instruction into the destination register to enable function returns. The callee can execute <code>JALR x0, 0(ra)</code> to jump back using the saved return address.
</div>

## 2.6 Pipeline Register Summary

Each pipeline register preserves the architectural state needed by downstream stages. Below is a summary of the data and control signals carried by each register:

| Register | Data Fields | Control Signals | Purpose |
|----------|-------------|-----------------|---------|
| **IF/ID** | `pc`, `instruction`, `pc+4` | None (control generated in ID) | Preserve fetched instruction for decoding |
| **ID/EX** | `pc`, `pc+4`, `rs1_data`, `rs2_data`, `imm`, `rs1`, `rs2`, `rd`, `funct3` | `reg_write`, `mem_write`, `alu_control`, `alu_src`, `alu_src_a`, `mem_to_reg`, `branch`, `jump`, `jalr` | Supply operands and control for execution |
| **EX/MEM** | `alu_result`, `rs2_data`, `rd`, `pc+4`, `funct3`, `rs2` | `reg_write`, `mem_write`, `mem_to_reg` | Interface with memory and preserve results |
| **MEM/WB** | `mem_read_data`, `alu_result`, `rd`, `pc+4` | `reg_write`, `mem_to_reg` | Select data for register writeback |

<div class="callout note"><span class="title">Design Note</span>
We include <code>rs2</code> in the <code>EX/MEM</code> register to enable store data forwarding (described in <a href="./hazards.html#case-4-the-load-use-hazard-the-physical-limit">Hazard Resolution, Case 4</a>). Without it, store instructions couldn't forward dependent values to memory writes. This is a subtle optimization not always shown in textbook diagrams but critical for correctness.
</div>

---
*riscv-5: a 5-Stage Pipelined RISC-V Processor (RV32I) by [Charlie Shields](https://github.com/cshieldsce), 2026*