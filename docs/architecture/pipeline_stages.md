# Pipeline Stages

This document details the operation of the 5-stage pipeline, referencing standard literature.

**Reference:** *Computer Organization and Design: The Hardware/Software Interface (RISC-V Edition)* by Patterson & Hennessy (H&P).

## 1. Instruction Fetch (IF)
**H&P Reference:** Chapter 4.4 "A Simple Implementation Scheme" (Page 271).

The IF stage fetches the 32-bit instruction from memory.
- **Components:** Program Counter (PC), Instruction Memory, Adder (+4).
- **Operation:** `PC` drives the `InstructionMemory` address. The output is latched into the `IF/ID` register.

## 2. Instruction Decode (ID)
**H&P Reference:** Chapter 4.4 (Page 272).

Decodes the instruction and reads register operands.
- **Components:** Register File (`RegFile`), Immediate Generator (`ImmGen`), Control Unit.
- **Optimization:** JAL target calculation happens here to reduce branch penalty to 1 cycle.

## 3. Execute (EX)
**H&P Reference:** Chapter 4.4 (Page 273).

Performs the operation using the ALU.
- **Components:** ALU, Branch Logic, Forwarding MUXes.
- **Forwarding:** The `ForwardingUnit` (H&P Page 307) detects data hazards and bypasses the Register File to supply the most recent result from MEM or WB stages.

## 4. Memory Access (MEM)
**H&P Reference:** Chapter 4.4 (Page 274).

Reads from or writes to data memory.
- **Components:** Data Memory.
- **MMIO:** Memory Mapped I/O is handled here. Address `0xFFFF_FFF0` maps to the LEDs.

## 5. Writeback (WB)
**H&P Reference:** Chapter 4.4 (Page 274).

Writes the result back to the Register File.
- **Components:** Writeback MUX.
- **Hazard Note:** The Register File resolves structural hazards by writing on the rising edge. Note that our implementation uses **write-through forwarding** in the `RegFile` module to ensure the ID stage reads the new value immediately if a read occurs in the same cycle as a write.
