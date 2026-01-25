import riscv_pkg::*;

/**
 * @brief Instruction Memory (Read-Only)
 * @details Stores the program code to be executed.
 *          Implemented as a ROM (Read-Only Memory) with asynchronous read access.
 *          Note: Asynchronous reads simplify the single-cycle IF stage timing.
 * 
 * @param clk        System clock (unused for async read)
 * @param rst        System reset (unused for ROM)
 * @param en         Enable signal (unused, assumes always enabled)
 * @param Address    Byte address of the instruction
 * @param Instruction 32-bit fetched instruction
 */
module InstructionMemory (
    input  logic            clk, 
    input  logic            rst, 
    input  logic            en,
    input  logic [ALEN-1:0] Address,
    output logic [XLEN-1:0] Instruction
);
    logic [ALEN-1:0] word_addr;
    logic [XLEN-1:0] rom_memory [0:RAM_MEMORY_SIZE]; // Size defined in riscv_pkg

    initial begin : InitROM
        for (int i = 0; i < RAM_MEMORY_SIZE; i++) rom_memory[i] = NOP_A;
    end

    // --- Note: RISC-V instructions are 4-byte aligned --- 
    assign word_addr = Address >> 2;
    
    // --- Asynchronous Read ---
    // Fetch instruction immediately when address changes.
    assign Instruction = (word_addr < RAM_MEMORY_SIZE) ? rom_memory[word_addr] : NOP_A;
endmodule