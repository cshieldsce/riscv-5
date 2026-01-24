# Implementation Plan: Refactor RISC-V CPU for Better Code Self-Documentation

This plan outlines the steps to refactor the RISC-V CPU codebase to enhance its self-documentation and portfolio presentation, ensuring zero regression in functionality.

## Phase 1: Global Logic Centralization and Packages
Focus on extracting reusable logic and constants into `riscv_pkg.sv` to reduce duplication and improve clarity across the project.

- [ ] Task: Audit codebase for reusable logic and constants
    - [ ] Scan all files in `src/` for duplicated functions or hardcoded constants.
    - [ ] Document candidates for `riscv_pkg.sv`.
- [ ] Task: Refactor `riscv_pkg.sv`
    - [ ] Move identified helper functions and constants to `riscv_pkg.sv`.
    - [ ] Update imports in affected modules.
    - [ ] Verify that the project compiles successfully.
- [ ] Task: Run Compliance Suite to ensure zero regression.

## Phase 2: Frontend Pipeline Refactoring (IF and ID Stages)
Apply the new header standards and signal naming conventions to the early stages of the pipeline.

- [ ] Task: Refactor IF Stage (`if_stage.sv`, `pc.sv`, `instruction_memory.sv`)
    - [ ] Update module headers with architectural context and I/O descriptions.
    - [ ] Rename internal signals using the `if_` prefix and descriptive naming.
    - [ ] Extract local helper functions where logic can be simplified.
- [ ] Task: Refactor ID Stage (`id_stage.sv`, `imm_gen.sv`, `reg_file.sv`)
    - [ ] Update module headers with architectural context and I/O descriptions.
    - [ ] Rename internal signals using the `id_` prefix and descriptive naming.
    - [ ] Extract local helper functions for decoding logic or control signal generation.
- [ ] Task: Run Compliance Suite to ensure zero regression.

## Phase 3: Execution and Backend Refactoring (EX, MEM, WB)
Apply refactoring to the remaining execution stages and memory interface.

- [ ] Task: Refactor EX Stage (`ex_stage.sv`, `alu.sv`)
    - [ ] Update module headers.
    - [ ] Rename internal signals using the `ex_` prefix.
    - [ ] Refactor ALU or mux logic into helper functions for clarity.
- [ ] Task: Refactor MEM and WB Stages (`mem_stage.sv`, `data_memory.sv`, `wb_stage.sv`)
    - [ ] Update module headers.
    - [ ] Rename internal signals using `mem_` and `wb_` prefixes.
- [ ] Task: Run Compliance Suite to ensure zero regression.

## Phase 4: Control and Hazard Logic Refactoring
Refactor the most complex coordination logic in the CPU.

- [ ] Task: Refactor Hazard and Forwarding Units (`hazard_unit.sv`, `forwarding_unit.sv`, `control_unit.sv`)
    - [ ] Update headers with detailed architectural reasoning.
    - [ ] Rename complex internal signals (e.g., stall requests, forwarding mux selects) for maximum clarity.
    - [ ] Add "why" comments to complex combinatorial logic blocks.
- [ ] Task: Run Compliance Suite to ensure zero regression.

## Phase 5: Verification and Final Polish
Ensure the refactoring has not introduced any bugs and the overall presentation is cohesive.

- [ ] Task: Regression Testing
    - [ ] Run all local unit tests (`test/tb/*.sv`).
    - [ ] Run the full RISCOF compliance suite (`run_compliance.sh`).
    - [ ] Fix any logic regressions discovered.
- [ ] Task: Final Documentation Review
    - [ ] Review all headers in `src/` for consistency with `product-guidelines.md`.
    - [ ] Ensure the Architectural Manual diagrams match the updated naming.
- [ ] Task: Generate Final Report
    - [ ] Compile a comprehensive report summarizing all changes and verification results.
