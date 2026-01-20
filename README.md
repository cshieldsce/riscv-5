# RISC-V 5-Stage Pipelined Processor (RV32I)

[![CI Status](https://github.com/cshieldsce/riscv-5/actions/workflows/ci.yml/badge.svg)](https://github.com/cshieldsce/riscv-5/actions/workflows/ci.yml)
[![Compliance Status](https://github.com/cshieldsce/riscv-5/actions/workflows/compliance.yml/badge.svg)](https://github.com/cshieldsce/riscv-5/actions/workflows/compliance.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-gray.svg)](https://opensource.org/licenses/MIT)

A high-fidelity, silicon-ready implementation of the RISC-V RV32I ISA, optimized for microarchitectural transparency and formal compliance. This project serves as a comprehensive demonstration of digital design maturity, bridging the gap between academic theory and industrial-grade verification.

---

## 🏛️ Architecture at a Glance

The core implements a classic 5-stage Harvard-architecture pipeline, strictly adhering to the microarchitectural patterns defined in *Patterson & Hennessy (Chapter 4)*.

[INSERT DRAW.IO DIAGRAM: High-Level Block Diagram Viewport (LR Flow, Subgraph Boundaries for IF, ID, EX, MEM, WB)]

### Core Technical Specifications
- **ISA Support:** Base RV32I (User-level ISA Vol. I v2.3).
- **Pipeline Depth:** 5 stages (`IF`, `ID`, `EX`, `MEM`, `WB`) with decoupled inter-stage registers.
- **Hazard Management:** Full operand forwarding (EX-EX, MEM-EX) and hardware stall detection for load-use hazards.
- **Control Flow:** Static not-taken branch prediction with single-cycle flush penalty.
- **Verification:** 100% pass rate on official RISC-V Architectural Test Suite (RISCOF).

---

## 🗺️ Documentation Portal

Structured to meet the specific requirements of recruiters, academic evaluators, and peer engineers.

### 💼 For Recruiters: The "30-Second Scan"
- **[Verification Compliance Matrix](./docs/verification/report.md#compliance-matrix):** Objective proof of ISA adherence.
- **[Debugging War Stories](./docs/verification/report.md#war-stories):** STAR retrospectives on resolving complex microarchitectural hazards.

### 🎓 For Professors: The "Theoretical Audit"
- **[Architecture Manual](./docs/architecture/manual.md):** Formal mapping of RTL modules to Patterson & Hennessy textbook equations.
- **[Datapath Topology](./docs/architecture/manual.md#pipeline-stages):** Stage-by-stage analysis of signal transitions.

### 🛠️ For Peers: The "Integration View"
- **[Developer Guide](./docs/developer/guide.md):** Step-by-step instructions for toolchain setup and functional simulation.

---

## 📦 Project Structure

```text
├── src/           # Synthesizable SystemVerilog RTL
├── test/          # RISCOF Framework, Testbenches, and Memory Images
├── docs/          # Strategic Documentation (Architecture, Verification, Developer)
└── fpga/          # Vivado TCL Scripts and PYNQ-Z2 Constraints
```

---
*Built with precision. Verified for compliance. Documented for clarity.*
