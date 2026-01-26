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

# Strategic Documentation Engineering: RISC-V Portfolio

Welcome to the technical deep-dive and user manual for the `riscv-5` processor. This documentation was created to give you background on this project from both a high and low level.

## Project Development

## Project Development

My introduction to RISC-V happened while I was studying ARM assembly during a semester abroad at the University of Glasgow. Discovering that RISC-V was open source and free to use felt like unlocking a lifelong dream, the chance to design and build my own CPU from scratch. I dove into the RISC-V ISA, starting with a single-cycle CPU to get a feel for the basics. Once that was working, I challenged myself to implement a full 5-stage pipeline, learning a ton about hazards and microarchitecture along the way. The final milestone was getting the design running on an FPGA and watching it pass the Fibonacci test in hardware, a moment that truly made the project feel complete.

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
- **[FPGA Integration](./developer/guide.html#fpga-deployment):** Deployment on the Xilinx PYNQ-Z2.

---

## 🏛️ Theoretical Anchor

Every design decision in this core is anchored in the official **RISC-V Instruction Set Manual (Volume I)** and the seminal textbook **Computer Organization and Design: The Hardware/Software Interface** by Patterson and Hennessy. This documentation explicitly maps code to these authoritative texts to prove engineering competence.

---
*Verified RTL. Rigorous Documentation. Silicon-Ready Design.*