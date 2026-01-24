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
    // ROM Array (Size defined in riscv_pkg)
    logic [XLEN-1:0] rom_memory [0:RAM_MEMORY_SIZE];

    initial begin : InitROM
        for (int i = 0; i < RAM_MEMORY_SIZE; i++) rom_memory[i] = 32'h00000013; // NOP (ADDI x0, x0, 0)
    end

    logic [ALEN-1:0] word_addr;
    
    // Word Alignment: RISC-V instructions are 4-byte aligned
    assign word_addr = Address >> 2;
    
    // --- COMBINATIONAL READ (Asynchronous) ---
    // Fetch instruction immediately when address changes.
    // Returns NOP (ADDI x0, x0, 0) if address is out of bounds.
    assign Instruction = (word_addr < RAM_MEMORY_SIZE) ? rom_memory[word_addr] : 32'h00000013;
endmodule