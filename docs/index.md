---
layout: default
title: riscv-5
hero: true
permalink: /
image: /images/pipeline_complete.svg
---

<section class="hero">
  <div class="hero-text">
    <h1>A 5-stage pipelined RISC-V core, verified and running on FPGA.</h1>
    <p class="lede">
      RV32I in SystemVerilog. Synthesizes on a Xilinx Zynq-7000 (PYNQ-Z2)
      and passes {{ site.results.riscof_rv32i_pass }} of {{ site.results.riscof_rv32i_total }}
      RISCOF compliance tests against the {{ site.results.riscof_golden_model }} golden model.
    </p>
    <p class="hero-links">
      <a class="primary" href="{{ '/architecture/' | relative_url }}">Architecture</a>
      <a href="{{ '/verification/' | relative_url }}">Verification</a>
      <a href="https://github.com/cshieldsce/riscv-5">Source on GitHub</a>
    </p>
  </div>
  <div class="hero-figure">
    <img src="{{ '/images/pipeline_complete.svg' | relative_url }}"
         alt="riscv-5 datapath: five pipeline stages with forwarding paths and hazard logic">
  </div>
</section>

## How the pipeline works

A single-cycle CPU has to be slow on purpose: every clock has to be long enough for a signal to traverse the entire datapath from instruction fetch to register writeback, so the critical path is the whole machine. A pipelined CPU breaks that critical path into shorter stages separated by registers. Each clock only has to cover one stage. In steady state, one instruction completes every cycle even though any individual instruction still takes five cycles end to end.

`riscv-5` has the five canonical stages. **IF** holds the program counter and fetches the next instruction from a small ROM. **ID** decodes the instruction word, reads up to two registers from the register file, and produces an immediate value sign-extended to 32 bits. **EX** runs the ALU, computes branch targets, and resolves whether a branch is taken. **MEM** does loads and stores against the data memory and handles byte-enable masking for sub-word access. **WB** writes a result back into the register file. Pipeline registers between every pair of stages carry the in-flight architectural state forward each clock.

The interesting part of any pipeline is not the stages themselves, but what happens when they collide. Two instructions in flight can want the same data at the same time, with the producer one or two slots ahead of the consumer. A taken branch can change the PC after later instructions have already been fetched. The pipeline has to either bypass the right value into the right place at the right cycle (forwarding), pause a stage until the value is ready (stalling), or throw away wrongly-fetched instructions (flushing). Those three mechanisms, and the code that arbitrates between them, are most of the actual complexity in the design. The [Hazards & Forwarding]({{ '/architecture/hazards/' | relative_url }}) page walks through every case with timing diagrams.

The full datapath, including the forwarding multiplexers in EX and the hazard-detection wires that drive the stalls and flushes, is in the hero figure at the top of this page. The [Pipeline Stages]({{ '/architecture/stages/' | relative_url }}) page zooms in on each stage with the SystemVerilog that implements it.

## Three design choices worth a look

**Resolving JAL in ID, not EX.** The textbook flow puts every branch and jump resolution in EX. JAL is unconditional and its target is `PC + Imm`, both of which are available immediately in ID. Resolving JAL one stage earlier saves one cycle of fetch penalty per JAL: the only instruction that gets flushed is the one already in IF, not the one in IF *and* the one in ID. JALR can't get the same treatment because its target depends on a register that might not be ready. See [PC selection priority]({{ '/architecture/stages/' | relative_url }}#fetch).

**LUI through the ALU, no dedicated unit.** LUI loads a 20-bit immediate into the upper bits of a destination register: `rd = imm << 12`. A naive implementation adds a separate datapath for it. Instead, I have the immediate generator emit the already-shifted value as the U-type immediate, drive the ALU with `A = 0` and `B = imm_shifted`, and use the existing ADD path. LUI becomes a regular instruction as far as the ALU is concerned. No new logic, no new control signal. AUIPC works the same way with PC instead of zero on the A input. See the [EX stage]({{ '/architecture/stages/' | relative_url }}#execute).

**Async LUTRAM for instruction fetch, not synchronous BRAM.** The first FPGA bring-up used a synchronous block-RAM for the instruction memory: the addressed word lands on the bus the cycle *after* the address is presented. That extra cycle of latency is fine in a single-cycle CPU but wrong in a 5-stage pipeline where IF/ID expects the fetched word to be available the same cycle the PC updates. The result was a real, debuggable bug that branches refused to fire on hardware while RISCOF still passed in simulation. The fix was to switch the instruction memory to a combinational read, which synthesizes to LUTRAM on the Zynq-7000. The [bouncing-branch postmortem]({{ '/verification/' | relative_url }}#bouncing-branch) on the verification page walks through the diagnosis and the Vivado ILA captures that confirmed the fix.

## What's not there

I scoped this project to the RV32I base integer ISA and stopped there. The core does not implement the M extension (no hardware multiply or divide). It has no CSRs at all; `SYSTEM` and `FENCE` opcodes decode as NOPs, so `ecall`, `ebreak`, and the Zicsr instructions are not functional. There is no instruction or data cache, and no exception or interrupt handling.

Memory is a single flat region starting at `0x0000_0000` (4 MB in simulation, 16 KB ROM on the FPGA), with a 4-bit memory-mapped LED register at `0x8000_0000` and a `tohost` test-completion address at `0x8000_1000` that the simulation harness monitors.

## Where to go next

- [Architecture]({{ '/architecture/' | relative_url }}) walks through the datapath, each pipeline stage, and how I resolve hazards with forwarding, stalling, and flushing.
- [Verification]({{ '/verification/' | relative_url }}) shows the RISCOF compliance matrix and the postmortems, including a branch bug I tracked down with a Vivado ILA capture.
- [FPGA]({{ '/fpga/' | relative_url }}) covers synthesis on the Zynq-7000, timing closure, and the hardware demo video.
- [Setup]({{ '/setup/' | relative_url }}) is the toolchain quickstart: clone, install Icarus and RISCOF and Vivado, build, and simulate.
