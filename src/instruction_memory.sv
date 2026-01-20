import riscv_pkg::*;

module InstructionMemory (
    input  logic            clk, // Clock not needed for async read, but kept for interface
    input  logic            rst, // Reset not needed for ROM
    input  logic            en,
    input  logic [ALEN-1:0] Address,
    output logic [31:0]     Instruction
);

`ifndef SYNTHESIS
    logic [31:0] rom_memory [0:1048575]; // 4MB for Simulation
`else
    logic [31:0] rom_memory [0:4095];    // 16KB for FPGA
`endif

    initial begin
        // Initialize memory to 0
        for (int i = 0; i < 1048576; i++) rom_memory[i] = 0;
    end

    logic [ALEN-1:0] word_addr;
    assign word_addr = Address >> 2;
    
    // --- COMBINATIONAL READ (Asynchronous) ---
    // This ensures Instruction is ready in the SAME cycle as Address
`ifndef SYNTHESIS
    assign Instruction = (word_addr < 1048576) ? rom_memory[word_addr] : 32'h00000013;
`else
    assign Instruction = (word_addr < 4096) ? rom_memory[word_addr] : 32'h00000013;
`endif

endmodule