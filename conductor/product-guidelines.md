# Product Guidelines: riscv-5

## Tone and Voice
- **Balanced Technical:** Maintain a tone that is precise and formal (datasheet quality), yet educational and clear (textbook quality).
- **Efficient Clarity:** Be concise. Respect the reader's time by providing high-value information without fluff.
- **Authoritative yet Approachable:** Demonstrate expertise while showing an ability to explain complex concepts to peers.

## Visual Identity (Modern Technical)
- **Aesthetic:** A "Modern Technical" look—combining the structure and rigor of an academic textbook with a clean, minimalist web aesthetic (GitHub Pages compatible).
- **Typography:** Clear sans-serif for body text; monospaced fonts for code and signals.
- **Color Palette:** Professional neutral tones with high-contrast accent colors for diagrams and highlights.
- **Diagrams:** Use a unified style (Draw.io/SVG) with consistent line weights, colors, and notation to ensure a cohesive look across all documentation.

## Documentation Standards
- **Module Headers:** Every SystemVerilog module must include a standard header block:
  - Purpose/Description
  - Input/Output Definitions
  - Parameter descriptions
  - Dependency/Interface notes
- **Commit Messages:** Use clear, descriptive summaries (e.g., `feat(ex): implement alu forwarding logic`) followed by a brief "why" if the change is complex.

## Code Quality & Style
- **Descriptive Naming (A/B Mix):** Use ISA-standard names for architectural state (e.g., `pc`, `x1-x31`). Use descriptive, purpose-driven names for internal signals (e.g., `hazard_stall_request`, `wb_reg_write_data`).
- **Self-Documenting Logic:** Code should be readable at a glance. Use comments sparingly to explain *why* logic exists, rather than *what* it is doing (which should be clear from the signal names).
