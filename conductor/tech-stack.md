# Tech Stack

## Hardware Description & Simulation
- **HDL Language:** SystemVerilog (IEEE 1800-2012)
- **Simulator:** [Icarus Verilog](https://steveicarus.github.io/iverilog/) (`iverilog`) v12.0+
- **Waveform Viewer:** GTKWave (implicit for `.vcd` files found in project)

## Verification Framework
- **Compliance Framework:** [RISCOF](https://github.com/riscv-software-src/riscof) (RISC-V Architectural Test Framework)
- **Reference Model:** [Spike](https://github.com/riscv-software-src/riscv-isa-sim) (RISC-V ISA Simulator)
- **Toolchain:** `riscv64-unknown-elf-gcc` (for test compilation and binary generation)

## FPGA Implementation
- **Target Platform:** PYNQ-Z2 (Xilinx Zynq-7000 SoC)
- **Synthesis & Implementation:** Xilinx Vivado
- **Host Communication:** UART (MMIO) for terminal output

## CI/CD & Documentation
- **Automation:** GitHub Actions
- **Documentation Platform:** GitHub Pages
- **Diagramming Tools:** Draw.io, Mermaid.js, WaveDrom