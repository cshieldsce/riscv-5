# RISC-V Pipelined Processor (RV32I)

[![CI Status](https://github.com/cshieldsce/riscv-5/actions/workflows/ci.yml/badge.svg)](https://github.com/cshieldsce/riscv-5/actions/workflows/ci.yml)
[![Compliance Status](https://github.com/cshieldsce/riscv-5/actions/workflows/compliance.yml/badge.svg)](https://github.com/cshieldsce/riscv-5/actions/workflows/compliance.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> **Strategic Documentation Engineering Portfolio Piece.** This repository demonstrates a production-grade 5-stage pipelined RISC-V core, featuring rigorous verification and FPGA deployment.

---

## 🏛️ Vision

To deliver a silicon-ready, cycle-accurate RISC-V (RV32I) implementation that serves as a high-fidelity reference for modern microarchitecture. This project bridges the gap between academic theory (Patterson & Hennessy) and industrial-grade SystemVerilog engineering.

## 🚀 Key Features

- **5-Stage Pipelined Datapath:** Fully decoupled `IF`, `ID`, `EX`, `MEM`, and `WB` stages.
- **Advanced Hazard Management:** Robust forwarding logic and load-use stall detection to maximize IPC.
- **Strict ISA Compliance:** 100% pass rate on the official RISC-V Architectural Test Suite (RISCOF).
- **Silicon-Ready RTL:** Synthesizable SystemVerilog optimized for Xilinx Zynq-7000 (PYNQ-Z2) FPGA.
- **Rigorous Verification:** CI/CD integration with Spike (Golden Model) for regression testing.

---

## 🗺️ Architectural Roadmap

The core is structured to follow the "Store-and-Forward" model described in *Patterson & Hennessy (Chapter 4)*.

<p align="center">
  <img src="docs/pipeline.png" alt="Processor Pipeline Diagram" width="800">
</p>

### Documentation Portal (GitHub Pages)
Explore the deep technical details of the implementation:
- 🎓 **[Architecture Manual](./docs/architecture/theory_of_operation.md):** Theoretical mapping to textbooks.
- 💼 **[Verification Report](./docs/verification/compliance.md):** Compliance Matrix and "War Stories".
- 🛠️ **[Developer Guide](./docs/developer/setup.md):** Toolchain and simulation workflow.

---

## 🛠️ Quick Start

### 1. Execute Regression Tests
Run a quick functional check using the Fibonacci sequence:
```bash
./test/scripts/regression_check.sh
```

### 2. Run Compliance Suite
Execute the full **RISCOF** suite (requires `riscof`, `spike`, and `riscv64-gcc`):
```bash
./test/verification/run_compliance.sh
```

---

## 📦 Project Structure

```text
├── src/           # Synthesizable RTL (SystemVerilog)
├── test/          # Verification environment (RISCOF, Testbenches)
├── fpga/          # FPGA deployment scripts (Vivado TCL)
└── docs/          # Strategic documentation and diagrams
```

## 📜 References

- **The Bible:** *Computer Organization and Design (RISC-V Edition)* - Patterson & Hennessy.
- **The Spec:** *RISC-V Instruction Set Manual Volume I: Unprivileged ISA*.

---
*Built for the Silicon Industry. Verified for the Future.*