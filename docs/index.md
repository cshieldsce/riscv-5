# RISC-V Pipelined Processor Portfolio

Welcome to the comprehensive documentation for my RV32I 5-stage pipelined processor. This project demonstrates a deep dive into computer architecture, from RTL implementation in SystemVerilog to verification with RISCOF and FPGA deployment.

## 🚀 Strategic Roadmap

This documentation is structured to provide value to three primary audiences:

### 💼 For Recruiters (30-Second Scan)
*See the "Hook" and evidence of engineering maturity.*
- **[High-Level Overview](../README.md):** Vision, features, and status badges.
- **[Verification Compliance Matrix](./verification/compliance.md):** Proof of correctness.
- **[War Stories](./verification/hazards.md):** Narrative retrospectives on solving complex microarchitectural bugs.

### 🎓 For Professors (Theory Audit)
*Verify the implementation against established architectural principles.*
- **[Architecture Manual](./architecture/theory_of_operation.md):** Mapping SystemVerilog to Patterson & Hennessy.
- **[Pipelined Datapath](./architecture/datapath.md):** Detailed stage-by-stage analysis.
- **[Hazard Handling](./architecture/pipeline_notes.md):** Theoretical anchoring of forwarding and stalls.

### 🛠️ For Peers (How-To)
*Technical details for building, simulating, and extending the core.*
- **[Developer Setup](./developer/setup.md):** Toolchain and environment configuration.
- **[FPGA Integration](./developer/fpga.md):** Deployment on PYNQ-Z2.
- **[SoC Peripherals](./developer/soc_peripherals.md):** Memory-mapped I/O and UART.

---

*Built with passion for digital logic and RISC-V. Optimized for GitHub Pages.*