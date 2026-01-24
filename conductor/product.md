# Initial Concept
# riscv-5: A Pipelined Processor (RV32I)

[![CI Status](https://github.com/cshieldsce/riscv-5/actions/workflows/ci.yml/badge.svg)](https://github.com/cshieldsce/riscv-5/actions/workflows/ci.yml)
[![Compliance Status](https://github.com/cshieldsce/riscv-5/actions/workflows/compliance.yml/badge.svg)](https://github.com/cshieldsce/riscv-5/actions/workflows/compliance.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-gray.svg)](https://opensource.org/licenses/MIT)
[![Documentation](https://img.shields.io/badge/docs-GitHub%20Pages-blue)](https://cshieldsce.github.io/riscv-5/)

A synthesizable 5-stage pipelined RISC-V core (RV32I) implemented in SystemVerilog, featuring integrated hazard detection, data forwarding, and formal verification via the RISCOF framework.

---

## Design Overview

This project implements a cycle-accurate RISC-V processor that adheres to the RV32I unprivileged ISA specification. The project also follows the architectural patterns from *Patterson & Hennessy* while incorporating some modern hazard mitigation techniques.

### Complete Datapath

![Complete Pipelined Datapath](docs/images/pipeline_complete.svg)
*5-stage pipeline with integrated forwarding unit and hazard detection*

# Product Definition: riscv-5

## Vision
To deliver a professional-grade, synthesizable 5-stage pipelined RISC-V processor that serves as a premier portfolio piece for recruiters and a high-caliber academic project. The project prioritizes technical rigor, industry-standard verification, and exceptional clarity in both code and documentation.

## Primary Goals
- **Portfolio Excellence:** Demonstrate technical depth and communication skills to recruiters and hiring managers.
- **Academic Rigor:** Serve as a high-quality reference for professors and classmates, adhering to textbook architectural patterns.
- **ISA Compliance:** Ensure 100% pass rates on RISC-V architectural tests (RV32I).
- **Synthesizability:** Maintain a design ready for FPGA implementation (specifically targeting the PYNQ-Z2).

## Key Features & Artifacts
- **Architectural Manual:** A detailed guide explaining pipeline stages, hazard logic, and design decisions with professional diagrams.
- **Automated Verification:** Robust CI/CD integration with the RISCOF framework to generate transparent compliance reports.
- **Clean Code Implementation:** Descriptive naming for custom logic while strictly adhering to ISA-standard names for architectural registers and signals.
- **Hazard Mitigation:** Integrated forwarding and hazard detection units to minimize stall cycles and maximize pipeline efficiency.

## Target Audience
- **Industry Professionals:** Hiring managers and engineers looking for evidence of system-level understanding and clean implementation.
- **Academic Community:** Professors and students seeking a clear, well-documented example of a modern pipelined CPU.
