# riscv-5: Verified Pipelined Core

![CI Status](https://github.com/cshieldsce/riscv-5/actions/workflows/ci.yml/badge.svg) ![Compliance Status](https://github.com/cshieldsce/riscv-5/actions/workflows/compliance.yml/badge.svg)

> A fully verified, 5-stage pipelined RISC-V processor (RV32I) implemented in SystemVerilog.

## Architecture Overview

This project is a Harvard-architecture RISC-V core designed to be cycle-accurate and strictly compliant to the ISA specification. Verification is prioritized by using the official RISC-V test suite (RISCOF) to validate every instruction against the standard golden model. 

![alt text](docs/pipeline.png)

### Features
- 5-Stage Pipeline: `IF`, `ID`, `EX`, `MEM`, `WB` stages with pipeline registers.
- Hazard Management: Resolves data, load-use, and control hazards to manage pipeline stalls and control flow.
- Verified Compliance: Passing the official RISC-V rv32i_m/I architectural test suite.
- Automated CI/CD: GitHub Actions workflows that re-verify the core against the ISA spec.

### Supported Instructions (RV32I)

The core has been validated against the **RISC-V Architectural Test Suite** and supports the following instruction types:

- **Arithmetic:** `add`, `sub`, `addi`, `slt`, `sltu`, `slti`, `sltiu`
- **Logic:** `and`, `or`, `xor`, `andi`, `ori`, `xori`
- **Shifts:** `sll`, `srl`, `sra`, `slli`, `srli`, `srai`
- **Memory:** `lw`, `sw`, `lb`, `lbu`, `lh`, `lhu`, `sb`, `sh`
- **Control Flow:** `beq`, `bne`, `blt`, `bge`, `bltu`, `bgeu`, `jal`, `jalr`
- **Large Constants:** `lui`, `auipc`

## Project Structure

- `src/`: Core RTL (SystemVerilog) including the package and 5-stage pipeline registers.
- `verification/`: RISCOF compliance suite setup, Golden reference model (Spike), and plugins.
- `test/`:
    - `tb/`: SystemVerilog testbenches for individual modules and core integration.
    - `scripts/`: Automated regression and compilation scripts.
- `fpga/`: Vivado project creation scripts and physical constraint files (`.xdc`) for PYNQ-Z2.
- `docs/`: Extensive documentation including Theory of Operation and Waveform analysis.

## Quick Start: Simulation & Verification

### 1. Simple Integration Test
To run a quick execution test using the Fibonacci sequence:
```bash
./test/scripts/regression_check.sh
```
This script verifies that the RTL compiles for both Simulation and FPGA, and then runs a subset of tests.

### 2. Full Compliance Suite
To run the full **RISC-V Architectural Test Suite** (requires `riscof`, `spike`, and `riscv64-unknown-elf-gcc`):
```bash
./verification/run_compliance.sh
```
The resulting `report.html` will be generated in `verification/riscof_work/`.

## FPGA Implementation (PYNQ-Z2)

This core is silicon-ready and optimized for Xilinx Zynq-7000 series FPGAs. It uses Synchronous BRAM and includes a UART MMIO peripheral.

### Vivado Project Creation
1. Generate the project:
   ```bash
   cd fpga && vivado -mode batch -source create_project.tcl
   ```
2. Open the generated project in the Vivado GUI.
3. Generate Bitstream and Program the PYNQ-Z2 board.
4. Monitor output via Serial at **115200 baud**.

---

## Tools & Requirements

- **Simulator:** [Icarus Verilog](https://steveicarus.github.io/iverilog/) (`iverilog`) v12.0+
- **Verification:** [RISCOF](https://github.com/riscv-software-src/riscof) (RISC-V Architectural Test Framework)
- **Reference Model:** [Spike](https://github.com/riscv-software-src/riscv-isa-sim)
- **Toolchain:** `riscv64-unknown-elf-gcc`
- **Language:** SystemVerilog (IEEE 1800-2012)

## Roadmap

Phase 1: Single-Cycle Core (Completed)
Phase 2: 5-Stage Pipelining (Completed)
Phase 3: ISA Completeness (Completed)

Phase 4: C-Readiness & Hardening (Completed)

- [x] **Complex Branching:** Implement BNE, BLT, BGE, etc., to support standard C control flow.
- [x] **Compliance:** Integrated RISCOF and passed the official RV32I test suite.
- [x] **Memory Expansion:** Increased I-Mem and D-Mem to 4MB each to support large binaries.
- [x] **MMIO Hardening:** Standardized `tohost` (0x80001000) for test termination.

Phase 5: FPGA & Peripherals (Future)

- [ ] UART: Implement Serial Transmit (MMIO) for printf support.
- [ ] Physical Constraints: Map pins to the specific FPGA board.

## References

- [Computer Organization and Design | The Hardware/Software Interface | RISC-V Edition by David A. Patterson & John L. Hennessy | Chapter 4 - The Processor](https://www.cs.sfu.ca/~ashriram/Courses/CS295/assets/books/HandP_RISCV.pdf)

- [The RISC-V Instruction Set Manual Volume I | Unprivileged Architecture](https://docs.riscv.org/reference/isa/_attachments/riscv-unprivileged.pdf)
