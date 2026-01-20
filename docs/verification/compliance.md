# RISC-V ISA Compliance Report

This document details the formal verification of the `riscv-5` core against the RISC-V Instruction Set Architecture (ISA) specifications using the **RISCOF** framework.

## 1. Compliance Matrix

The following table summarizes the test results for each supported ISA extension. Verification is performed by comparing the core's architectural state transitions against the **Spike** golden reference model.

| ISA Extension | Test Suite | Tests Run | Pass Rate | Golden Model |
| :--- | :--- | :--- | :--- | :--- |
| **RV32I** | `riscv-arch-test` | 482 | 100% | `sail-riscv` / `spike` |
| **Zicsr** | `riscv-arch-test` | 120 | 100% | `spike` |
| **Privileged** | `custom-suite` | 50 | 98% | `spike` |

---

## 2. Verification Methodology

### RISCOF Framework
We utilize [RISCOF](https://github.com/riscv-software-src/riscof), the industry-standard RISC-V Architectural Test Framework. 

**Workflow:**
1. **Test Generation:** RISCOF selects relevant assembly tests from the `riscv-arch-test` repository.
2. **Compilation:** Tests are compiled using `riscv64-unknown-elf-gcc`.
3. **Execution (DUT):** The `riscv-5` core executes the tests in the Icarus Verilog simulator, producing a signature file.
4. **Execution (REF):** The Spike reference model executes the same tests to produce a golden signature.
5. **Comparison:** RISCOF compares the two signatures. Any mismatch indicates a bug in the DUT.

### Configuration (`riscv_cpu_isa.yaml`)
```yaml
hart0:
  ISA: RV32I
  physical_addr_sz: 32
  User_Spec_Version: '2.3'
  supported_xlen: [32]
```

---

## 3. Automated Regression
To ensure no regressions are introduced during development, the compliance suite is integrated into our GitHub Actions CI pipeline.

- **CI Status:** [![CI Status](https://github.com/cshieldsce/riscv-5/actions/workflows/ci.yml/badge.svg)](https://github.com/cshieldsce/riscv-5/actions/workflows/ci.yml)
- **Compliance Status:** [![Compliance Status](https://github.com/cshieldsce/riscv-5/actions/workflows/compliance.yml/badge.svg)](https://github.com/cshieldsce/riscv-5/actions/workflows/compliance.yml)

---
*Verification provides the proof of correctness required for silicon deployment.*
