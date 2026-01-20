# ISA Compliance and Verification

Formal verification of the `riscv-5` core is conducted against the RISC-V Instruction Set Architecture (ISA) specifications using the RISCOF framework.

## 1. Compliance Matrix

The following table summarizes the pass rates for the supported ISA extensions. Verification compares the Device Under Test (DUT) state transitions against the Spike golden reference model.

| ISA Extension | Test Suite | Tests Run | Pass Rate | Reference Model |
| :--- | :--- | :--- | :--- | :--- |
| **RV32I** | `riscv-arch-test` | 482 | 100% | `spike` |
| **Zicsr** | `riscv-arch-test` | 120 | 100% | `spike` |
| **Privileged** | `custom-suite` | 50 | 98% | `spike` |

---

## 2. Methodology

### RISCOF Framework
We utilize the industry-standard [RISCOF](https://github.com/riscv-software-src/riscof) framework for architectural testing.

**Verification Lifecycle:**
1. **Test Selection:** Relevant assembly tests are pulled from the `riscv-arch-test` repository.
2. **Compilation:** Tests are compiled via the `riscv64-unknown-elf-gcc` cross-compiler.
3. **Execution:** The RTL core executes the tests in the Icarus Verilog environment, generating a signature file.
4. **Validation:** Signature files are compared against those produced by the Spike golden model.

### ISA Configuration
```yaml
hart0:
  ISA: RV32I
  physical_addr_sz: 32
  User_Spec_Version: '2.3'
  supported_xlen: [32]
```

---

## 3. Continuous Integration
Verification is automated via GitHub Actions to ensure regression-free development.

- **Build Status:** [![CI Status](https://github.com/cshieldsce/riscv-5/actions/workflows/ci.yml/badge.svg)](https://github.com/cshieldsce/riscv-5/actions/workflows/ci.yml)
- **Compliance Status:** [![Compliance Status](https://github.com/cshieldsce/riscv-5/actions/workflows/compliance.yml/badge.svg)](https://github.com/cshieldsce/riscv-5/actions/workflows/compliance.yml)