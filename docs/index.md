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

Welcome to the technical deep-dive and user manual for the `riscv-5` processor. This documentation was created to give you background on this project and it's design.

## Project Development

////


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
- **[War Stories](./verification/report.html#war-stories):** Retrospectives on solving "The Frozen Pipeline" and "The Bouncing Branch".

### 3. The Setup Guide (How-To)
Practical instructions for instantiating the core and running simulations.
- **[Technical Onboarding](./developer/guide.html):** Toolchain setup and simulation workflow.
- **[FPGA Integration](./verification/fpga.html):** Deployment on the Xilinx PYNQ-Z2.

---

## Key References

Every design decision in this core is anchored in the official **RISC-V Instruction Set Manual (Volume I)** and the seminal textbook **Computer Organization and Design: The Hardware/Software Interface** by Patterson and Hennessy.

---
*Verified RTL. Rigorous Documentation. Silicon-Ready Design.*