import riscv_pkg::*;

module InstructionMemory (
    input  logic            clk, // Clock not needed for async read, but kept for interface
    input  logic            rst, // Reset not needed for ROM
    input  logic            en,
    input  logic [ALEN-1:0] Address,
    output logic [31:0]     Instruction
);

    logic [31:0] rom_memory [0:4095];

    initial begin
        $readmemh("fib_test.mem", rom_memory);
    end

    logic [ALEN-1:0] word_addr;
    assign word_addr = Address >> 2;
    
    // --- COMBINATIONAL READ (Asynchronous) ---
    // This ensures Instruction is ready in the SAME cycle as Address
    assign Instruction = (word_addr < 4096) ? rom_memory[word_addr] : 32'h00000013;

endmodule