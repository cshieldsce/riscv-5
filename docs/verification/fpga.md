<link rel="stylesheet" href="{{ '/assets/css/style.css' | relative_url }}">
<div class="site-nav">
  <a href="../index.html">Home</a>
  <a href="../architecture//manual.html">Architecture Overview</a>
  <a href="../architecture//stages.html">Pipeline Stages</a>
  <a href="../architecture//hazards.html">Hazard Resolution</a>
  <a href="./report.html">Design Verification</a>
  <a href= ./fpga.html>FPGA Implementation</a>
  <a href="../developer/guide.html">Setup Guide</a>
</div>

# FPGA Implementation & Hardware Validation

This page documents the process and results of deploying the `riscv-5` core on real FPGA hardware. Here, we showcase synthesis results, resource utilization, timing closure, and a live demonstration of the core running the Fibonacci test.

---

## 1. Synthesis Overview

- **Target Board:** Xilinx PYNQ-Z2 (Zynq-7000)
- **Toolchain:** Vivado 2025.2
- **Top Module:** `pynq_z2_top.sv`

### Synthesis Summary

| Resource      | Used | Available | Utilization |
|---------------|------|-----------|-------------|
| LUTs          |      |           |             |
| Flip-Flops    |      |           |             |
| BRAMs         |      |           |             |
| DSP Slices    |      |           |             |

*(Insert Vivado synthesis report table or screenshot here)*

---

## 2. Timing Report

- **Target Clock Frequency:** XX MHz
- **Achieved Clock Period:** XX ns
- **Slack:** XX ns

*(Insert screenshot or summary of timing closure from Vivado)*

---

## 3. Block Diagram

*(Insert exported block diagram image from Vivado here)*

---

## 4. Hardware Demo

### Fibonacci Test on FPGA

Below is a demonstration of the `riscv-5` core running the Fibonacci test in hardware. The result is displayed in binary via the onboard LEDs.

<video controls src="path/to/your/video.mp4" width="480"></video>
<!-- Replace with your video link and thumbnail -->

*(Optionally, embed the video directly if your documentation host supports it)*


---

---

## 6. Additional Notes

- **Bitstream:** [Download link or instructions]
- **Test Program:** [`fib_test.mem`](../../test/mem/fib_test.mem)
- **Setup Instructions:** See [Developer Guide](../developer/guide.html#fpga-deployment)

---

*For questions or contributions, see the [GitHub repository](https://github.com/cshieldsce/riscv-5).*