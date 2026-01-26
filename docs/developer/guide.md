<link rel="stylesheet" href="{{ '/assets/css/style.css' | relative_url }}">
<div class="site-nav">
  <a href="../index.html">Home</a>
  <a href="../architecture/manual.html">Architecture Overview</a>
  <a href="../architecture/stages.html">Pipeline Stages</a>
  <a href="../architecture/hazards.html">Hazard Resolution</a>
  <a href="../verification/report.html">Design Verification</a>
  <a href="../verification/fpga.html">FPGA Implementation</a>
  <a href="./guide.html">Setup Guide</a>
</div>

# Setup Guide

This guide provides the technical instructions for building, simulating, and extending the `riscv-5` core.

## 1. Toolchain Dependencies

The project relies on standard open-source EDA tools and the RISC-V GNU toolchain.

### 1.1 Required Packages
```bash
sudo apt-get update
sudo apt-get install -y iverilog gtkwave python3 python3-pip git
# Install the RISC-V GCC cross-compiler
sudo apt-get install gcc-riscv64-unknown-elf
```

### 1.2 RISCOF Compliance Framework
```bash
pip3 install riscof
```

### 1.3 Project Setup
```bash
# Clone the repository
git clone https://github.com/cshieldsce/riscv-5.git
cd riscv-5

# Fetch external dependencies (RISC-V Architecture Test Suite)
./setup_project.sh
```
The `setup_project.sh` script will:
- Clone the [RISC-V Architecture Test Suite](https://github.com/riscv-non-isa/riscv-arch-test) into `test/verification/riscv-arch-test/`
- Verify that `riscv64-unknown-elf-gcc` is available in your PATH

### 1.4 Verify Installation
```bash
# Check tools
iverilog -v
riscv64-unknown-elf-gcc --version
riscof --version

# Verify test suite was cloned
ls test/verification/riscv-arch-test/
```

---

## 2. Functional Simulation Workflow

We use **Icarus Verilog** for simulation, you can also use **GTKWave** for waveform analysis.

### 2.1 Running Individual Tests
```bash
# Navigate to testbench directory
cd test/tb

# Compile the core with a specific test
iverilog -g2012 -I ../../src/ -o sim.out \
    ../../src/riscv_pkg.sv \
    ../../src/*.sv \
    pipelined_cpu_tb.sv

# Run with a memory file
vvp sim.out +TEST=../mem/fib_test.mem

# View waveforms
gtkwave waveform.vcd
```

2.2 Running the Regression Suite


### 2.2 Manual Execution
To compile the core and testbench against a specific memory initialization file (`.mem`):
```bash
# Compile core and testbench
iverilog -g2012 -o sim.out -I src/ src/pipelined_cpu.sv test/tb/pipelined_cpu_tb.sv
# Run simulation with memory file
vvp sim.out +TEST=test/mem/fib_test.mem
```

<!-- ELABORATION POINT: Insert a section on "How to interpret the VCD waveforms". List the key signals (e.g., pc, instr, reg_write) that a developer should watch to debug an execution error. -->

---

## 3. Compliance Verification Workflow

To run the full **RISC-V Architectural Test Suite** and generate a formal compliance report:
```bash
# Execute the RISCOF runner
./test/verification/run_compliance.sh
```
*The resulting HTML report will be located in `test/verification/riscof_work/report.html`.*

<!-- ELABORATION POINT: Explain the role of the `elf2hex.py` script in your verification flow. Why is it necessary to convert the ELF output from GCC into a hex format for the RTL simulator? -->

---

## 4. FPGA Deployment (PYNQ-Z2)

The core is optimized for Xilinx Zynq-7000 series FPGAs.

### 4.1 Project Generation
Use the provided TCL script to generate the Vivado project:
```bash
cd fpga
vivado -mode batch -source create_project.tcl
```

---
*riscv-5: a 5-Stage Pipelined RISC-V Processor (RV32I) by [Charlie Shields](https://github.com/cshieldsce), 2026*