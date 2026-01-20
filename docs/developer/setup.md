# Developer Setup and Workflow

Technical onboarding for building, simulating, and verifying the `riscv-5` core.

## 1. Environment Configuration

The development environment requires open-source EDA tools.

### Prerequisites
```bash
sudo apt-get update
sudo apt-get install -y iverilog gtkwave python3 python3-pip git
```

### RISC-V Cross-Compiler
```bash
sudo apt-get install gcc-riscv64-unknown-elf
```

### RISCOF Installation
```bash
pip3 install riscof
```

---

## 2. Simulation Procedures

### Functional Regression
Run the standard regression suite:
```bash
./test/scripts/regression_check.sh
```

### Manual Test Execution
To simulate a specific memory image:
```bash
# Compile core and testbench
iverilog -g2012 -o sim.out -I src/ src/pipelined_cpu.sv test/tb/pipelined_cpu_tb.sv
# Execute with memory file
vvp sim.out +TEST=test/mem/fib_test.mem
```

---

## 3. Compliance Testing

To verify ISA compliance:
```bash
./test/verification/run_compliance.sh
```
Results are accessible via the generated HTML report in `test/verification/riscof_work/`.

---

## 4. FPGA Implementation

### Vivado Project Generation
```bash
cd fpga
vivado -mode batch -source create_project.tcl
```

### Hardware Monitoring
Monitor board output via UART at 115200 baud:
```bash
screen /dev/ttyUSB0 115200
```