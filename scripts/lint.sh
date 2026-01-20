#!/bin/bash
# Simple linter script for SystemVerilog

echo "Checking for snake_case filenames in src/..."
bad_files=$(find src -name "*.sv" | grep -vE '^[a-z0-9_]+\.sv$')
if [ -n "$bad_files" ]; then
    echo "ERROR: The following files do not follow snake_case naming:"
    echo "$bad_files"
    exit 1
else
    echo "PASSED: All src filenames are snake_case."
fi

echo "Checking for mixed indentation (tabs) in src/..."
if grep -r $'	' src/*.sv; then
    echo "WARNING: Tabs detected. Use 2 spaces."
    # Don't fail for now, just warn
else
    echo "PASSED: No tabs found."
fi
