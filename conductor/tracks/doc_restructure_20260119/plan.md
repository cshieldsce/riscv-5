# Implementation Plan: Portfolio-Grade Documentation Restructuring

This plan outlines the steps to restructure and enhance the project's documentation into a professional portfolio, adhering to the "Strategic Documentation Engineering" methodology.

## Phase 1: Foundation & Infrastructure
- [x] Task: Restructure documentation directory hierarchy (2dd8599)
    - [ ] Create `docs/architecture/`, `docs/verification/`, and `docs/developer/` directories
    - [ ] Move existing relevant notes into new structures
- [x] Task: Initialize GitHub Pages portal (416638c)
    - [ ] Create `docs/index.md` with a polished, modern landing page design
    - [ ] Define the "Strategic Map" of the documentation for different audiences
- [x] Task: Conductor - User Manual Verification 'Phase 1: Foundation & Infrastructure' (Protocol in workflow.md)

## Phase 2: The "Hook" (Landing Page)
- [x] Task: Update root `README.md` for the 30-second scan (61f3c4d)
    - [ ] Add dynamic CI/CD and compliance badges
    - [ ] Insert a high-level architectural block diagram viewport (Exported from Draw.io)
    - [ ] Craft a compelling "Vision" and "Key Features" section
- [x] Task: Conductor - User Manual Verification 'Phase 2: The "Hook"' (Protocol in workflow.md)

## Phase 3: The "Theory Audit" (Architecture Manual)
- [x] Task: Map RTL to Patterson & Hennessy (Chapter 4) (92267d5)
    - [ ] Create `docs/architecture/datapath.md` with side-by-side logic/textbook mappings
    - [ ] Document the 5-stage pipeline registers and control signals with textbook citations
- [x] Task: Visualizing the Pipeline with Draw.io XML (5259648)
    - [ ] Generate **Draw.io XML source files** for the 5-stage datapath
    - [ ] Implement specific subgraph boundaries for IF, ID, EX, MEM, and WB stages
    - [ ] Verify that signal connections in XML match `pipelined_cpu.sv`
- [x] Task: Conductor - User Manual Verification 'Phase 3: The "Theory Audit"' (Protocol in workflow.md)

## Phase 4: The "Proof" (Verification Report)
- [ ] Task: Document Compliance and RISCOF Results
    - [ ] Create `docs/verification/compliance.md` with the Verification Compliance Matrix
    - [ ] Detail the test environment (Spike vs. RTL) and coverage metrics
- [ ] Task: Narrative Debugging (War Stories)
    - [ ] Draft at least two "War Stories" using the STAR method (e.g., "The Frozen Pipeline", "The Bouncing Branch")
    - [ ] Include "Before/After" code snippets for each story
- [ ] Task: Temporal Proof with WaveDrom
    - [ ] Create `docs/verification/hazards.md`
    - [ ] Implement **WaveDrom JSON** timing diagrams for load-use stalls and forwarding paths
- [ ] Task: Conductor - User Manual Verification 'Phase 4: The "Proof"' (Protocol in workflow.md)

## Phase 5: The "How-To" (Developer Guide)
- [ ] Task: Technical Onboarding Guide
    - [ ] Create `docs/developer/setup.md` with copy-pasteable toolchain setup snippets
    - [ ] Document the build and simulation workflow (Verilator/Icarus)
- [ ] Task: Conductor - User Manual Verification 'Phase 5: The "How-To"' (Protocol in workflow.md)

## Phase 6: Final Integration & Aesthetic Polish
- [ ] Task: Final Visual Audit and Linking
    - [ ] Ensure all code snippets use correct syntax highlighting
    - [ ] Cross-link all documents for seamless navigation on GitHub Pages
- [ ] Task: Conductor - User Manual Verification 'Phase 6: Final Integration' (Protocol in workflow.md)
