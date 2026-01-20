#!/bin/bash
# setup_project.sh: Initialize the repository by fetching external dependencies.

echo "--- RISC-V 5-Stage Core Project Setup ---"

# 1. Fetch RISC-V Architecture Test Suite
if [ ! -d "verification/riscv-arch-test" ]; then
    echo "[*] Cloning RISC-V Arch Test Suite..."
    git clone https://github.com/riscv-non-isa/riscv-arch-test verification/riscv-arch-test
else
    echo "[+] RISC-V Arch Test Suite already present."
fi

# 2. Check for toolchain
if ! command -v riscv64-unknown-elf-gcc &> /dev/null; then
    echo "[!] WARNING: riscv64-unknown-elf-gcc not found in PATH."
    echo "    Please install the RISC-V GNU Toolchain to run compliance tests."
fi

echo "[*] Setup complete."
