# Developer Guide: Technical Onboarding

This guide provides the technical instructions for building, simulating, and extending the `riscv-5` core. For this audience, clarity of instruction and reproducibility of results are paramount.

## 1. Toolchain Dependencies

The project relies on standard open-source EDA tools and the RISC-V GNU toolchain.

### 1.1 Required Packages
```bash
sudo apt-get update
sudo apt-get install -y iverilog gtkwave python3 python3-pip git
# Install the RISC-V GCC cross-compiler
sudo apt-get install gcc-riscv64-unknown-elf
```

### 1.2 RISCOF Framework
```bash
pip3 install riscof
```

---

## 2. Functional Simulation Workflow

We use **Icarus Verilog** for simulation and **GTKWave** for waveform analysis.

### 2.1 Running the Regression Suite
To verify the core's basic functionality against the provided assembly programs:
```bash
./test/scripts/regression_check.sh
```

### 2.2 Manual Execution
To compile the core and testbench against a specific memory initialization file (`.mem`):
```bash
# Compile core and testbench
iverilog -g2012 -o sim.out -I src/ src/pipelined_cpu.sv test/tb/pipelined_cpu_tb.sv
# Run simulation with memory file
vvp sim.out +TEST=test/mem/fib_test.mem
```

---

## 3. Compliance Verification Workflow

To run the full **RISC-V Architectural Test Suite** and generate a formal compliance report:
```bash
# Execute the RISCOF runner
./test/verification/run_compliance.sh
```
*The resulting HTML report will be located in `test/verification/riscof_work/report.html`.*

---

## 4. FPGA Deployment (PYNQ-Z2)

The core is optimized for Xilinx Zynq-7000 series FPGAs.

### 4.1 Project Generation
Use the provided TCL script to generate the Vivado project:
```bash
cd fpga
vivado -mode batch -source create_project.tcl
```

### 4.2 UART Communication
Monitor core output via UART at **115200 baud**.

---
*Built for the Silicon Industry. Verified for the Future.*
