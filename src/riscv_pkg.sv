package riscv_pkg;

    // --- ARCHITECTURAL PARAMETERS ---
    parameter XLEN = 32;
    parameter ALEN = 32;

    // --- MEMORY SIZE PARAMETERS ---
`ifndef SYNTHESIS
    localparam int RAM_MEMORY_SIZE = 1048576; // 4MB for Simulation
`else
    localparam int RAM_MEMORY_SIZE = 4096;    // 16KB for FPGA
`endif
    parameter      REG_SIZE        = 32;      // Number of registers in the Register File

    // --- Memory-Mapped I/O Addresses ---
    localparam logic [XLEN-1:0] MMIO_LED_ADDR    = 32'h8000_0000;
    localparam logic [XLEN-1:0] MMIO_TOHOST_ADDR = 32'h8000_1000;
    parameter  logic [XLEN-1:0] NOP_A            = 32'h00000013; // ADDI x0, x0, 0
    localparam int              LED_WIDTH        = 4;

    // --- OPCODES (RV32I) ---
    typedef enum logic [6:0] {
        OP_R_TYPE   = 7'b0110011, // add, sub, sll...
        OP_I_TYPE   = 7'b0010011, // addi, slti...
        OP_LOAD     = 7'b0000011, // lb, lh, lw...
        OP_STORE    = 7'b0100011, // sb, sh, sw...
        OP_BRANCH   = 7'b1100011, // beq, bne...
        OP_JAL      = 7'b1101111, // jal
        OP_JALR     = 7'b1100111, // jalr
        OP_LUI      = 7'b0110111, // lui (Load Upper Immediate)
        OP_AUIPC    = 7'b0010111, // auipc (Add Upper Immediate to PC)
        OP_SYSTEM   = 7'b1110011, // ecall, csrrw...
        OP_FENCE    = 7'b0001111  // fence
    } opcode_t;

    // --- ALU OPERATIONS ---
    typedef enum logic [3:0] {
        ALU_ADD  = 4'b0010,       // Addition
        ALU_SUB  = 4'b0110,       // Subtraction
        ALU_AND  = 4'b0000,       // AND
        ALU_OR   = 4'b0001,       // OR
        ALU_XOR  = 4'b1001,       // XOR
        ALU_SLL  = 4'b1010,       // Shift Left Logical
        ALU_SRL  = 4'b1011,       // Shift Right Logical
        ALU_SRA  = 4'b1100,       // Shift Right Arithmetic
        ALU_SLT  = 4'b0111,       // Set Less Than (signed)
        ALU_SLTU = 4'b1000        // Set Less Than (unsigned)
    } alu_op_t;

    // --- FUNCT3 CODES (ALU / R-Type / I-Type) ---
    typedef enum logic [2:0] {
        F3_ADD_SUB = 3'b000,      // add, sub, addi
        F3_SLL     = 3'b001,      // sll, slli
        F3_SLT     = 3'b010,      // slt, slti
        F3_SLTU    = 3'b011,      // sltu, sltiu
        F3_XOR     = 3'b100,      // xor, xori
        F3_SRL_SRA = 3'b101,      // srl, sra, srli, srai
        F3_OR      = 3'b110,      // or, ori
        F3_AND     = 3'b111       // and, andi
    } funct3_alu_t;

    // --- FUNCT3 CODES (Memory) ---
    typedef enum logic [2:0] {
        F3_BYTE  = 3'b000,        // Load/Store Byte
        F3_HALF  = 3'b001,        // Load/Store Halfword
        F3_WORD  = 3'b010,        // Load/Store Word
        F3_LBU   = 3'b100,        // Load Byte Unsigned
        F3_LHU   = 3'b101         // Load Halfword Unsigned
    } funct3_mem_t;

    // --- FUNCT3 CODES (Branch) ---
    typedef enum logic [2:0] {
        F3_BEQ  = 3'b000,         // Branch if Equal 
        F3_BNE  = 3'b001,         // Branch if Not Equal
        F3_BLT  = 3'b100,         // Branch if Less Than (signed)
        F3_BGE  = 3'b101,         // Branch if Greater or Equal (signed)
        F3_BLTU = 3'b110,         // Branch if Less Than (unsigned)
        F3_BGEU = 3'b111          // Branch if Greater or Equal (unsigned)
    } funct3_branch_t;

endpackage
