import riscv_pkg::*;

module InstructionMemory #(
    parameter MEM_INIT_FILE = ""
)(
    input  logic            clk, 
    input  logic            rst, 
    input  logic            en,
    input  logic [ALEN-1:0] Address,
    output logic [XLEN-1:0] Instruction
);

    logic [ALEN-1:0] word_addr;
    
    // Force Block RAM synthesis
    (* rom_style = "block" *) logic [XLEN-1:0] rom_memory [0:RAM_MEMORY_SIZE];

    initial begin
        $readmemh(MEM_INIT_FILE, rom_memory);
    end

    assign word_addr = Address >> 2;
    assign Instruction = (word_addr < RAM_MEMORY_SIZE) ? rom_memory[word_addr] : NOP_A;
endmodule