# Tech Stack: riscv-5

## Hardware Description
- **Language:** SystemVerilog
- **Standards:** IEEE 1800-2017
- **Architecture:** 5-stage pipelined RV32I (Base Integer ISA)

## Design & Synthesis
- **Target Platform:** Xilinx PYNQ-Z2 FPGA (Zynq-7000 SoC)
- **Tooling:** Vivado Design Suite (TCL-based project creation)
- **Top-Level:** `pynq_z2_top.sv` with memory-mapped I/O

## Verification & Simulation
- **Compliance:** RISCOF (RISC-V Compliance Framework)
- **Reference Model:** Spike (RISC-V ISA Simulator)
- **Test Suite:** `riscv-arch-test`
- **Automation:** GitHub Actions (CI), Shell scripts (`lint.sh`, `regression_check.sh`)
- **Unit Testing:** SystemVerilog testbenches for individual pipeline stages

## Documentation & Assets
- **Static Site:** Jekyll / GitHub Pages
- **Diagrams:** Draw.io (SVG exports)
- **Formatting:** Markdown
