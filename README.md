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


### Key Features

- **5-Stage Pipeline:** IF → ID → EX → MEM → WB stages with pipeline registers
- **Data Forwarding:** Resolves RAW hazards via EX→EX and MEM→EX bypass paths
- **Load-Use Stalls:** Automatic bubble insertion for unavoidable data hazards
- **ISA Compliance:** 100% pass rate on RISC-V Architectural Test Suite (RISCOF)
- **FPGA-Ready:** Synthesized and verified on Xilinx PYNQ-Z2 (Zynq-7000)

---

## Documentation

**[Full Documentation Site →](https://cshieldsce.github.io/riscv-5/)**

Comprehensive technical documentation including:
- **[Architecture Manual](https://cshieldsce.github.io/riscv-5/architecture/manual.html)** - Theoretical foundations and design rationale
- **[Pipeline Stages](https://cshieldsce.github.io/riscv-5/architecture/stages.html)** - Microarchitectural implementation details
- **[Hazard Resolution](https://cshieldsce.github.io/riscv-5/architecture/hazards.html)** - Forwarding logic and stall mechanisms
- **[Verification Report](https://cshieldsce.github.io/riscv-5/verification/report.html)** - ISA compliance testing and results
- **[Developer Guide](https://cshieldsce.github.io/riscv-5/developer/guide.html)** - Setup instructions and workflow

---

## Quick Start
```bash
# 1. Install dependencies
sudo apt-get install -y iverilog gtkwave python3-pip git gcc-riscv64-unknown-elf
pip3 install riscof

# 2. Clone and setup project
git clone https://github.com/cshieldsce/riscv-5.git
cd riscv-5
./setup_project.sh

# 3. Run compliance tests
./test/verification/run_compliance.sh
```
---

## Project Structure

```text
riscv-5/
├── src/                    # SystemVerilog RTL
│   ├── pipelined_cpu.sv    # Top-level module
│   ├── control_unit.sv     # Instruction decoder
│   ├── hazard_unit.sv      # Stall/flush logic
│   └── forwarding_unit.sv  # Bypass control
├── test/
│   ├── verification/       # RISCOF compliance framework
│   ├── mem/                # Hex memory test files
│   ├── tb/                 # SystemVerilog testbenches
│   └── scripts/            # Automation scripts
├── fpga/
│   ├── constraints/        # XDC timing constraints
│   └── build.tcl           # Vivado synthesis script
├── docs/                   # GitHub Pages documentation
│   ├── architecture/       # Design documentation
│   ├── verification/       # Test reports
│   └── images/             # Datapath diagrams
└── .github/workflows/      # CI/CD automation
```
---

## References

- [RISC-V ISA Specification v2.2](https://riscv.org/technical/specifications/)
- *Computer Organization and Design: The Hardware/Software Interface (RISC-V Edition)* - Patterson & Hennessy
- [RISC-V Architectural Test Suite](https://github.com/riscv-non-isa/riscv-arch-test)
---
