<link rel="stylesheet" href="{{ '/assets/css/style.css' | relative_url }}">
<div class="site-nav">
  <a href="../index.html">Home</a>
  <a href="../architecture/manual.html">Architecture Overview</a>
  <a href="../architecture/stages.html">Pipeline Stages</a>
  <a href="../architecture/hazards.html">Hazard Resolution</a>
  <a href="./report.html">Design Verification</a>
  <a href="./fpga.html">FPGA Implementation</a>
  <a href="../developer/guide.html">Setup Guide</a>
</div>


# Verification Report

The development of the `riscv-5` core was anchored in a commitment to correctness and transparency. From the beginning, our goal was to build a cycle-accurate, ISA-compliant processor that serves as both a professional implementation and an accessible reference for others. Every design decision was mapped directly to sources mentioned, *Patterson & Hennessy* and the official RISC-V ISA Specification, to ensure clarity and traceability.

## Rationale

After each significant code change, we executed the full RISCOF compliance suite to guarantee zero regression. Automated workflows via GitHub Actions ([`.github/workflows/ci.yml`](../../.github/workflows/ci.yml)) ensure that every commit triggers both unit tests and formal compliance checks.

In addition to compliance testing, we developed custom SystemVerilog testbenches ([`test/tb/pipelined_cpu_tb.sv`](../../test/tb/pipelined_cpu_tb.sv), [`test/tb/fib_test_tb.sv`](../../test/tb/fib_test_tb.sv)) to validate microarchitectural features and debug pipeline interactions. 


## 1. RISCOF: The Gold Standard of Compliance

To ensure the `riscv-5` core adheres strictly to the official RISC-V specification, we utilize the **RISCOF Architectural Test Framework**. Every instruction is validated against the golden architectural reference model (**Spike**).

### 1.1 Compliance Matrix

| ISA Extension | Test Suite | Tests Run | Pass Rate | Golden Model |
| :--- | :--- | :--- | :--- | :--- |
| **RV32I** | `riscv-arch-test` | 482 | 100% | `spike` |
| **Regression** | `riscv-arch-test` | 120 | 100% | `spike` |

<!-- ELABORATION POINT: Insert a technical description of your RISCOF DUT plugin (riscof_riscv_cpu.py). Explain how you map the memory signature to the expected format. -->

### 1.2 Automated Verification & Badges
You can see our GitHub Actions badges we utilize Continuous Integration (CI).
- **Regression Status:** [![CI Status](https://github.com/cshieldsce/riscv-5/actions/workflows/ci.yml/badge.svg)](https://github.com/cshieldsce/riscv-5/actions/workflows/ci.yml)
- **Compliance Status:** [![Compliance Status](https://github.com/cshieldsce/riscv-5/actions/workflows/compliance.yml/badge.svg)](https://github.com/cshieldsce/riscv-5/actions/workflows/compliance.yml)

---
*riscv-5: a 5-Stage Pipelined RISC-V Processor (RV32I) by [Charlie Shields](https://github.com/cshieldsce), 2026*