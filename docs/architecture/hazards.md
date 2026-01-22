<link rel="stylesheet" href="{{ '/assets/css/style.css' | relative_url }}">
<div class="site-nav">
  <a href="../index.html">Home</a>
  <a href="./manual.html">Architecture Overview</a>
  <a href="./stages.html">Pipeline Stages</a>
  <a href="./hazards.html">Hazard Resolution</a>
  <a href="../verification/report.html">Verification</a>
  <a href="../developer/guide.html">Developer Guide</a>
</div>

# 3.0 Hazard Resolution

## The Problem: The Pipeline Illusion

In a standard Single-Cycle processor, the concept of a "Data Hazard" does not exist. The entire instruction completes fetching, calculating, and writing back to the register file before the next instruction even begins. The software written for a single cycle processor assumes: "Instruction A finishes completely before Instruction B starts."

However, in our Pipelined design we violate this assumption. We now have up to five instructions executing simultaneously.

<div class="callout warn"><span class="title">The Dependency Paradox</span>
If Instruction B relies on a value calculated by Instruction A, Instruction B might try to read that value from the Register File <em>before</em> Instruction A has actually written the value to the register. Without intervention, the CPU would process stale data, leading to incorrect results.
</div>

Without intervention, the CPU would process stale data leading to calculation errors. To maintain the illusion of sequential execution while enjoying the speed of parallel processing, we implemented a sophisticated Hazard Resolution system using **Forwarding** (bypassing storage) and **Stalling** (injecting wait states).

## The Solution Architecture

When a Data Hazard occurs, the hardware must choose between an aggressive optimization (Forwarding) or a defensive pause (Stalling).

<div class="callout tip"><span class="title">Forwarding Strategy</span>
Forwarding relies on the fact that the calculated data already exists inside the pipeline registers, even though it hasn't been written back to the Register File yet. The Forwarding Unit detects data dependencies and routes the data directly to the ALU inputs via multiplexers. This allows the pipeline to maintain full speed with zero latency penalty for most hazards.
</div>

<div class="callout tip"><span class="title">Stalling Strategy</span>
Stalling is the fallback when forwarding is physically impossible (e.g., data is still in RAM). The Hazard Unit freezes the Program Counter and flushes the <code>ID/EX</code> register, injecting a "bubble" (NOP) into the pipeline. This forces dependent instructions to wait exactly one cycle, allowing memory data to arrive.
</div>

We handle hazards using two dedicated hardware units:

1. **The Forwarding Unit (`src/forwarding_unit.sv`):** A combinational logic block that controls MUXes at the ALU inputs. It "short-circuits" data from later pipeline stages directly to the Execute stage, skipping the Register File entirely.
2. **The Hazard Unit (`src/hazard_unit.sv`):** The "traffic cop" of the CPU. If forwarding is impossible (e.g., waiting for RAM), it freezes the PC and inserts "bubbles" (NOPs) to pause execution.

<div class="callout note"><span class="title">Diagram Placeholder</span>
<strong>[INSERT DATAPATH DIAGRAM HERE]</strong><br/>
Show the full datapath with Hazard and Forwarding Units annotated. Include MUX select signals and the priority logic that determines which forwarding path wins.
</div>

---

## 3.2 Detailed Case Analysis

Below is an analysis of every hazard scenario our architecture handles, including the specific assembly code that triggers it and the hardware's response.

### Case 1: EX-to-EX Forwarding (Immediate Dependency)

This is the most common hazard. An instruction needs the result of the *immediately preceding* operation.

```asm
add x1, x2, x3   # In EX/MEM stage (Result calculated, not written)
sub x5, x1, x4   # In ID/EX stage  (Needs x1 NOW)
```

| The Problem | The Fix | Penalty (Cycles) |
|-------------|---------|-----------------|
| The result of the add is in the `EX/MEM` pipeline register. The `sub` instruction is about to enter the ALU. | The Forwarding Unit detects `rs1_ex == rd_mem`. It switches the ALU MUX to grab data directly from the `EX/MEM` register. | 0 |

---

### Case 2: MEM-to-EX Forwarding (Delayed Dependency)

The dependency is one instruction removed.

```asm
add x1, x2, x3   # In MEM/WB stage (Waiting to be written)
nop              # (Or any unrelated instruction)
sub x5, x1, x4   # In ID/EX stage (Needs x1)
```

| The Problem | The Fix | Penalty (Cycles) |
|-------------|---------|-----------------|
| The result is in the `MEM/WB` register, not yet in the register file. | The Forwarding Unit detects `rs1_ex == rd_wb`. It switches the ALU MUX to grab data from the `MEM/WB` register. | 0 |

---

### Case 3: The "Double Hazard" (Priority Logic)

What if both previous instructions write to the same register?

```asm
addi x1, x0, 10    # Instruction A (In MEM/WB) - Writes 10 to x1
addi x1, x0, 20    # Instruction B (In EX/MEM) - Writes 20 to x1
add  x5, x1, x6    # Instruction C (In ID/EX)  - Needs x1
```

| The Problem | The Fix | Penalty (Cycles) |
|-------------|---------|-----------------|
| Both the `EX/MEM` and `MEM/WB` stages contain a value for `x1`. Which one is correct? | The Forwarding Unit checks the `EX/MEM` hazard first. Since *Instruction B* is more recent, its value (20) overrides *Instruction A*'s value (10). | 0 |

Snippet (`src/forwarding_unit.sv`):

```verilog
if (forward_ex_condition) begin
    // Forward from EX/MEM (Most Recent)
end else if (forward_mem_condition) begin
    // Forward from MEM/WB (Older)
end
```

<div class="callout note"><span class="title">Priority Resolution</span>
This is a subtle but critical detail. The forwarding logic must prioritize the most recently computed value. If we forwarded from MEM/WB when EX/MEM had the newer result, we'd compute with stale data. The priority always favors EX/MEM over MEM/WB.
</div>

---

### Case 4: The Load-Use Hazard (The Physical Limit)

This is the only case where forwarding is physically impossible.

```asm
lw  x1, 0(x2)    # In EX stage (Calculating address, data is still in RAM)
add x3, x1, x4   # In ID stage (Needs x1 immediately)
```

| The Problem | The Fix | Penalty (Cycles) |
|-------------|---------|-----------------|
| The `lw` instruction is currently calculating the address. The data is still inside the memory chip. We cannot forward data we haven't fetched yet. | The Hazard Unit:<br>**1. Stall:** PC_Write and IF/ID_Write are disabled. The `lw` and `add` stay put for 1 cycle.<br>**2. Bubble:** The `ID/EX` register is flushed (control signals set to 0), sending a `NOP` down the pipeline. | 1 |

<div class="callout warn"><span class="title">Unavoidable Stall</span>
This is the only data hazard that cannot be resolved by forwarding. Memory latency is physical—the RAM access takes time. We must stall and wait. This is why modern CPUs use caches and prefetching to minimize load-use hazard penalties.
</div>

**Timing Diagram:**

```
Cycle 1:  lw  (EX)  │ add (ID)
Cycle 2:  lw  (MEM) │ BUBBLE (stalled, flushed)
Cycle 3:  lw  (WB)  │ add (EX) ← x1 available via forwarding
```

---

### Case 5: Control Hazards (Branch Misprediction)

Because we resolve branches in the **Execute (EX)** stage, we don't know if we need to jump until the instruction is halfway through the pipeline.

```asm
beq x1, x2, LABEL  # Taken! (In EX Stage)
addi x5, x0, 1     # (In ID Stage - Wrong path!)
sub  x6, x0, 2     # (In IF Stage - Wrong path!)
```

| The Problem | The Fix | Penalty (Cycles) |
|-------------|---------|-----------------|
| By the time `beq` decides to take the branch, we have already fetched two instructions we shouldn't have. | The Hazard Unit detects `PCSrc` (Branch Taken) is high. It asserts `Flush_ID` and `Flush_EX`, wiping those two instructions from existence. | 2 |

<div class="callout warn"><span class="title">Branch Penalty Trade-off</span>
Our <strong>2-Cycle Branch Penalty</strong> seems high compared to some architectures. A common optimization is to move branch comparison from the <strong>Execute (EX)</strong> stage to the <strong>Decode (ID)</strong> stage. This would reduce the penalty to just <strong>1 Cycle</strong> (flushing only IF).
<br/><br/>
<strong>Why didn't we do this?</strong><br/>
If we moved branch logic to ID, we'd need to add significant hardware (comparator, adder for target calculation) into the already-congested ID stage. This would increase the Critical Path of the ID stage, forcing us to slow down our entire clock frequency. We chose to accept the 2-cycle penalty to keep the clock fast. Trade-offs are always about picking which metric matters most.
</div>

<div class="callout note"><span class="title">Diagram Placeholder</span>
<strong>[INSERT CONTROL HAZARD TIMING DIAGRAM HERE]</strong><br/>
Show cycles 1-4 with the branch being resolved, wrong instructions flushed, and correct path resuming.
</div>

---