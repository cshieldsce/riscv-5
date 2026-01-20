# Strategic Documentation Engineering: RISC-V Portfolio

Welcome to the technical thesis and user manual for the `riscv-5` processor. This documentation is engineered to serve three distinct personas: Recruiters, Professors, and Peer Engineers.

## 🧭 The Rationale for Documentation as Code

In the contemporary landscape of digital logic design, the artifact of code—whether SystemVerilog or VHDL—serves merely as the foundation. The true differentiator that distinguishes a competent student from a deployable engineer is high-fidelity, theoretically grounded, and visually distinct documentation. This repository adopts a "Documentation as Code" philosophy, ensuring that architectural intent and verification proof are as rigorous as the RTL itself.

## 🏛️ Navigation Quadrants

### 1. The Architecture Manual (Theory)
A deep dive into the microarchitecture that links RTL modules to textbook concepts.
- **[Theory of Operation](./architecture/manual.md):** Theoretical anchoring to Patterson & Hennessy.
- **[Stage Analysis](./architecture/manual.md#pipeline-stages):** Detailed breakdown of IF, ID, EX, MEM, and WB transitions.

### 2. The Verification Report (Proof)
Objective evidence of correctness and a narrative account of debugging resilience.
- **[Compliance Matrix](./verification/report.md):** Formal RISCOF results for RV32I.
- **[Hazard Handling](./verification/report.md#load-use-hazard-stall):** Timing diagrams (WaveDrom) of temporal interactions.
- **[War Stories](./verification/report.md#war-stories):** Retrospectives on solving "The Frozen Pipeline" and "The Bouncing Branch".

### 3. The Developer Guide (How-To)
Practical instructions for instantiating the core and running simulations.
- **[Technical Onboarding](./developer/guide.md):** Toolchain setup and simulation workflow.
- **[FPGA Integration](./developer/guide.md#fpga-deployment):** Deployment on the Xilinx PYNQ-Z2.

---

## 🏛️ Theoretical Anchor

Every design decision in this core is anchored in the official **RISC-V Instruction Set Manual (Volume I)** and the seminal textbook **Computer Organization and Design: The Hardware/Software Interface** by Patterson and Hennessy. This documentation explicitly maps code to these authoritative texts to prove engineering competence.

---
*Verified RTL. Rigorous Documentation. Silicon-Ready Design.*
