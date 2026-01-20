# Specification: Portfolio-Grade Documentation Restructuring

## Overview
This track aims to transform the existing generic documentation into a professional-grade engineering portfolio based on the "Strategic Documentation Engineering" methodology. The goal is to serve three distinct audiences: Recruiters (30-second scan), Professors (Theory Audit), and Peers (Integration/How-to). The documentation will be optimized for GitHub Pages, featuring high-fidelity visuals, extensive code snippets, and explicit theoretical anchoring.

## Functional Requirements
- **Directory Restructuring:**
  - Create `docs/architecture/` for the microarchitecture manual.
  - Create `docs/verification/` for the compliance and debugging reports.
  - Create `docs/developer/` for the user manual and integration guides.
- **Architecture Manual (Professors):**
  - **Textbook Anchoring:** Map SystemVerilog modules to Patterson & Hennessy (Chapter 4) concepts with explicit side-by-side logic/textbook equation comparisons.
  - **Visual Logic:** Include Draw.io block diagrams following the "Left-to-Right" flow with subgraph boundaries for IF, ID, EX, MEM, and WB stages.
- **Verification Report (Recruiters):**
  - **Compliance Matrix:** Integrate a detailed table summarizing RISCOF results for RV32I, Zicsr, etc.
  - **STAR Retrospectives:** Document "War Stories" using the STAR (Situation, Task, Action, Result) method, including snippets of the "buggy" vs "fixed" Verilog.
  - **Temporal Proof:** Use WaveDrom JSON to generate timing diagrams for complex hazards (e.g., load-use stalls).
- **Developer Guide (Peers):**
  - **"How-to" Snippets:** Step-by-step toolchain setup with copy-pasteable shell commands and troubleshooting tips.
- **Landing Page (README):**
  - Update the root `README.md` to act as the "Hook" with status badges, high-level visuals, and a "Strategic Map" of the repository.

## Non-Functional Requirements
- **Visual Fidelity:** Professional-grade styling, Mermaid.js integration for dynamic diagrams, and high-resolution Draw.io exports.
- **Code Transparency:** Use syntax-highlighted code blocks for all RTL and testbench references.
- **Academic Rigor:** All theoretical claims must be anchored in the RISC-V ISA specification or established textbooks.
- **GitHub Pages Optimization:** Structure the `docs/` folder to be ready for Jekyll or a similar static site generator to maximize aesthetic appeal.

## Acceptance Criteria
- [ ] Directory structure matches the proposed schema.
- [ ] Architecture Manual contains at least one explicit side-by-side mapping to a textbook equation.
- [ ] Verification Report includes a RISCOF compliance table.
- [ ] At least two "War Stories" documented with "Before/After" code snippets.
- [ ] Root README contains dynamic CI/CD pass/fail badges and a high-level block diagram viewport.
- [ ] `docs/index.md` created to act as a polished portal for GitHub Pages.

## Out of Scope
- Implementation of new hardware features (this track is documentation-focused).
- Automated generation of the PDF report (focus is on Markdown/Web documentation).
