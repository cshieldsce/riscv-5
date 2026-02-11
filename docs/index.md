<link rel="stylesheet" href="{{ '/assets/css/style.css' | relative_url }}">
<div class="site-nav">
  <a href="./index.html">Home</a>
  <a href="./architecture/manual.html">Architecture Overview</a>
  <a href="./architecture/stages.html">Pipeline Stages</a>
  <a href="./architecture/hazards.html">Hazard Resolution</a>
  <a href="./verification/report.html">Design Verification</a>
  <a href="./verification/fpga.html">FPGA Implementation</a>
  <a href="./developer/guide.html">Setup Guide</a>
</div>

# Documentation

Welcome to the technical deep-dive and user manual for the `riscv-5` processor. This documentation provides a comprehensive background on the project's design, verification, and implementation.

## Project Development

The `riscv-5` core is an educational yet rigorously verified implementation of the RISC-V RV32I Base Integer Instruction Set. It was designed with a focus on clean, synthesizable SystemVerilog code and strict adherence to the official ISA specifications.

## Articles

### 1. The Architecture Manual (Theory)
A deep dive into the microarchitecture of the core.
- **[Theory of Operation](./architecture/manual.html):** Theoretical anchoring to Patterson & Hennessy.
- **[Stage Analysis](./architecture/stages.html):** Detailed breakdown of IF, ID, EX, MEM, and WB transitions.
- **[Hazard Resolution](./architecture/hazards.html):** Forwarding, stalling, and control hazards.

### 2. The Verification Report (Proof)
Objective evidence of correctness and a narrative account of debugging resilience.
- **[Compliance Matrix](./verification/report.html):** Formal RISCOF results for RV32I.
- **[Hazard Handling](./verification/report.html#load-use-hazard-stall):** Timing diagrams (WaveDrom) of temporal interactions.

### 3. The Setup Guide (How-To)
Practical instructions for instantiating the core and running simulations.
- **[Technical Onboarding](./developer/guide.html):** Toolchain setup and simulation workflow.
- **[FPGA Integration](./verification/fpga.html):** Deployment on the Xilinx PYNQ-Z2.

---

## Key References

<div class="callout note"><span class="title">Standard Compliance</span>
Every design decision in this core is anchored in the official <strong>RISC-V Instruction Set Manual (Volume I)</strong> and the seminal textbook <strong>Computer Organization and Design: The Hardware/Software Interface</strong> by Patterson and Hennessy.
</div>

---
*Verified RTL. Rigorous Documentation. Silicon-Ready Design.*