# Developer Setup & Workflow

This guide provides a step-by-step technical onboarding for building, simulating, and verifying the `riscv-5` core.

## 1. Toolchain Installation

The core is developed and verified using open-source tools. Follow these steps to set up your environment on a Linux-based system (Ubuntu/Debian recommended).

### Required Packages
```bash
sudo apt-get update
sudo apt-get install -y iverilog gtkwave python3 python3-pip git
```

### RISC-V GNU Toolchain
To compile assembly and C code for the core, you need the RISC-V GCC cross-compiler.
```bash
# We recommend using pre-built binaries or your distribution's package
sudo apt-get install gcc-riscv64-unknown-elf
```

### RISCOF (Compliance Framework)
```bash
pip3 install riscof
```

---

## 2. Simulation Workflow

We use **Icarus Verilog** for simulation. The project includes a regression script to quickly verify core integration.

### Run Functional Regression
```bash
./test/scripts/regression_check.sh
```

### Manual Simulation
To simulate a specific memory file (`.mem`):
```bash
# Compile
iverilog -g2012 -o sim.out -I src/ src/pipelined_cpu.sv test/tb/pipelined_cpu_tb.sv
# Run
vvp sim.out +TEST=test/mem/fib_test.mem
```

---

## 3. Verification Workflow (RISCOF)

To ensure the core remains compliant with the ISA specification, run the full RISCOF suite.

```bash
# Execute the compliance runner
./test/verification/run_compliance.sh
```
*The results will be generated in `test/verification/riscof_work/report.html`.*

---

## 4. FPGA Deployment (Vivado)

### Project Generation
The project includes a TCL script to automatically generate the Vivado project for the PYNQ-Z2.
```bash
cd fpga
vivado -mode batch -source create_project.tcl
```

### UART Communication
When running on the hardware, the core communicates via UART at **115200 baud**. Use `screen` or `minicom` to view output:
```bash
screen /dev/ttyUSB0 115200
```

---
*Contributions are welcome. Please ensure all code passes the `lint.sh` and `regression_check.sh` before submitting a PR.*
