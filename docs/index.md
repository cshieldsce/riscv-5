<link rel="stylesheet" href="{{ '/assets/css/style.css' | relative_url }}">
<div class="site-nav">
  <a href="./index.html">Home</a>
  <a href="./architecture/manual.html">Architecture Overview</a>
  <a href="./architecture/stages.html">Pipeline Stages</a>
  <a href="./architecture/hazards.html">Hazard Resolution</a>
  <a href="./verification/report.html">Verification</a>
  <a href="./developer/guide.html">Developer Guide</a>
</div>

# Strategic Documentation Engineering: RISC-V Portfolio

Welcome to the technical deep-dive and user manual for the `riscv-5` processor. This documentation was created to give you background on this project from both a high and low level.

## Project Development

I first learned about RISC-V when studying ARM assembly during a course I was taking at the Universiy of Glasgow while abroad. Upon learning of it's open source and free use nature I finally found the answer to a lifelong pursuit of mine. I can make my own CPU? I began my journey learning the riscv isa and starting off by building a single cycle cpu. Once done with that I moved on to the 5 stage, and then the FPGA. After running the fib test on the FPGA i finally said this project is complete.  

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