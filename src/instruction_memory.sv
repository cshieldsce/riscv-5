import riscv_pkg::*;

module InstructionMemory (
    input  logic            clk, // Clock not needed for async read, but kept for interface
    input  logic            rst, // Reset not needed for ROM
    input  logic            en,
    input  logic [ALEN-1:0] Address,
    output logic [XLEN-1:0]     Instruction
);
    logic [XLEN-1:0] rom_memory [0:RAM_MEMORY_SIZE];   // ROM array

    initial begin
        // Initialize memory to 0
        for (int i = 0; i < RAM_MEMORY_SIZE; i++) rom_memory[i] = 0;
    end

    logic [ALEN-1:0] word_addr;
    assign word_addr = Address >> 2;
    
    // --- COMBINATIONAL READ (Asynchronous) ---
    // This ensures Instruction is ready in the SAME cycle as Address
    assign Instruction = (word_addr < RAM_MEMORY_SIZE) ? rom_memory[word_addr] : 32'h00000013;

endmodule