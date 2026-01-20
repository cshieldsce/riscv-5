# RISC-V Pipelined Processor Documentation

This documentation provides a technical deep-dive into the implementation, verification, and deployment of the RV32I 5-stage pipelined processor.

## Strategic Organization

The documentation is organized by technical domain to facilitate efficient review:

### Microarchitecture
*Focus on theoretical mapping and RTL implementation.*
- **[Architecture Overview](./architecture/theory_of_operation.md):** Theoretical anchoring to textbooks.
- **[Pipelined Datapath](./architecture/datapath.md):** Detailed analysis of stage transitions and timing.
- **[Hazard Handling](./architecture/pipeline_notes.md):** Forwarding and stall logic implementation.

### Verification and Compliance
*Focus on proof of correctness and debugging.*
- **[Compliance Matrix](./verification/compliance.md):** Formal RISCOF results and methodology.
- **[Hazard Analysis and Retrospectives](./verification/hazards.md):** Timing diagrams and debugging case studies.

### Development and Integration
*Focus on tools and hardware deployment.*
- **[Environment Setup](./developer/setup.md):** Toolchain and simulation prerequisites.
- **[FPGA Deployment](./developer/fpga.md):** Synthesis and implementation on PYNQ-Z2.
- **[Peripherals](./developer/soc_peripherals.md):** UART and MMIO definitions.

---

*Verified RTL. Rigorous Documentation. Silicon-Ready Design.*
