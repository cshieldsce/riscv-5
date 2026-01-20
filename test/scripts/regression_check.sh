#!/bin/bash

# Ensure we are in the script directory
cd "$(dirname "$0")"

echo "Starting Regression Check..."

# 1. Mock Synthesis Check
echo "Checking Synthesis Compatibility..."
# We try to compile the top level with SYNTHESIS defined.
# We expect errors about missing IP (clk_wiz, ila), but NOT syntax errors in our code.
# Ensure riscv_pkg.sv is compiled first
iverilog -g2012 -D SYNTHESIS -o synth_check.out ../../src/riscv_pkg.sv $(ls ../../src/*.sv | grep -v ../../src/riscv_pkg.sv) > synth_check.log 2>&1

# Check if the log contains syntax errors other than missing modules
if grep -q "syntax error" synth_check.log; then
    echo "FAILED: Syntax errors found in Synthesis mode."
    cat synth_check.log
    exit 1
else
    echo "PASSED: No syntax errors found in Synthesis mode (ignoring missing IPs)."
fi

# 2. Compliance Check
echo "Running Compliance Tests..."
if ../verification/run_compliance.sh; then
     echo "PASSED: Compliance tests executed successfully."
else
     echo "FAILED: Compliance tests failed."
     exit 1
fi

echo "Regression Check Complete."
