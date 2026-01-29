<link rel="stylesheet" href="{{ '/assets/css/style.css' | relative_url }}">
<div class="site-nav">
  <a href="../index.html">Home</a>
  <a href="./manual.html">Architecture Overview</a>
  <a href="./stages.html">Pipeline Stages</a>
  <a href="./hazards.html">Hazard Resolution</a>
  <a href="../verification/report.html">Design Verification</a>
  <a href="../verification/fpga.html">FPGA Implementation</a>
  <a href="../developer/guide.html">Setup Guide</a>
</div>

## 1. Introduction

The architecture of the `riscv-5` core is anchored to the official RISC-V ISA Specification and the seminal microarchitecture text *Patterson & Hennessy (RISC-V Edition)*.

### The Single-Cycle Problem

To understand why we build pipelined processors, we first have to look at the limitations of a **Single Cycle CPU**. In a single-cycle implementation, the entire execution of an instruction—fetching from memory, decoding, calculating in the ALU, accessing data memory, and finally writing back to registers must happen in exactly one clock tick.

You can think of a Single Cycle CPU as one giant combinational circuit, and the critical path as "one long wire" spanning from the Fetch to Writeback. If the signal has to travel through 50 gates to get from the Instruction Memory to the Register Writeback, your clock cycle must be long enough for the electricity to traverse all 50 gates at once. While this design is simple to understand, it is practically inefficient.

<div class="callout tip"><span class="title">FPGA Tip</span>
If you have used Xilinx Vivado to synthesize a core, you likely encountered <strong>Total Negative Slack (TNS)</strong>. In a Single Cycle CPU, the "Critical Path" (the longest path between two registers) is effectively the entire length of the CPU. Vivado will report timing violations because the signal physically cannot travel to the logic gates fast enough.
</div>

## 1.1 The Pipelining Solution

<div class="img-wrapper diagram">
  <img src="../images/pipeline_stages_clean.svg" alt="Simplified pipelined datapath">
  <span class="caption">Figure 1: The theoretical 5-stage RISC-V datapath as described in Patterson & Hennessy.</span>
</div>

### The Pipelined Datapath

Pipelining solves this by breaking that "one long wire" into smaller, independent segments separated by Pipeline Registers. Instead of one cycle needing to cover the Fetch to Writeback distance, the clock cycle only needs to be long enough for the longest individual stage (e.g., just the Execute stage).

This architecture shift dramatically increases **Throughput**. While the time to execute one individual instruction (Latency) stays roughly the same, the rate at which we finish instructions skyrockets.

| Metric | Single Cycle CPU | Pipelined CPU |
|--------|------------------|---------------|
| **Clock Speed** | Low (~10 MHz) | High (**50-100 MHz+**) |
| **Instructions Per Cycle** | 1 | 1 (Ideal) |
| **Logic Depth** | 50+ Gates (Deep) | ~10 Gates (Shallow) |
| **Vivado Timing** | Negative Slack (-) | Positive Slack (+) |

<div class="callout warn"><span class="title">Latency vs Throughput</span>
It is a common misconception that pipelining reduces the execution time of a single instruction; in fact, individual latency often increases slightly due to register overhead. The true performance gain comes from throughput, as the processor completes one instruction every clock cycle rather than waiting for the entire datapath to finish. We accept this minor latency cost to achieve a massive increase in overall system frequency and processing rate.
</div>

---

## 1.2 Building the Core

### Motivations

This project began with a desire to explore **SystemVerilog** through the lens of functional hardware design. The goal was to build a core that is not only functional but also clean, readable, and strictly typed.

<div class="callout tip"><span class="title">Personal Note</span>
I found the Hennessy & Patterson book to be what many referred to as the "gold standard" reference for RISC-V. Reading it in conjunction with the official ISA spec provided the perfect balance of theory and practical specification.
</div>

---

## 1.3 References
The following references, particularly the highlighted chapters and sections, directly informed the design and implementation of this core’s pipelined architecture and instruction set support. They served as both theoretical foundation and practical guide throughout development.

1. **Patterson, D. A., & Hennessy, J. L.** (2017). *Computer Organization and Design: The Hardware/Software Interface (RISC-V Edition).* Morgan Kaufmann.
   - Chapter 4: The Processor: 5 stage pipeline architecture
   - Section 4.6: Pipelined datapath and control

2. **RISC-V Foundation.** *The RISC-V Instruction Set Manual Volume I: Unprivileged ISA (v20191213).*
   - Section 2: RV32I Base Integer Instruction Set
   - Section 2.5: Control Transfer Instructions
   - Section 2.6: Load and Store Instructions

3. **RISC-V Software Tools Documentation.** *riscv64-unknown-elf-gcc* and *spike* simulator.

---
*riscv-5: a 5-Stage Pipelined RISC-V Processor (RV32I) by [Charlie Shields](https://github.com/cshieldsce), 2026*

<script src="{{ '/assets/js/lightbox.js' | relative_url }}"></script>