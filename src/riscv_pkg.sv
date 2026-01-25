package riscv_pkg;

    // --- ARCHITECTURAL PARAMETERS ---
    parameter XLEN = 32;
    parameter ALEN = 32;
    parameter LED_WIDTH  = 4;

    // --- MEMORY SIZE PARAMETERS ---

`ifndef SYNTHESIS
    localparam int RAM_MEMORY_SIZE = 1048576; // 4MB for Simulation
`else
    localparam int RAM_MEMORY_SIZE = 4096; // 16KB for FPGA
`endif

    parameter REG_SIZE = 32; // Number of registers in the Register File
    
    // --- MEMORY MAP ---
    parameter logic [ALEN-1:0] MMIO_LED_ADDR = 32'hFFFF_FFF0;
    parameter logic [XLEN-1:0] NOP_A = 32'h00000013; // ADDI x0, x0, 0

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
        ALU_ADD  = 4'b0010,
        ALU_SUB  = 4'b0110,
        ALU_AND  = 4'b0000,
        ALU_OR   = 4'b0001,
        ALU_XOR  = 4'b1001,
        ALU_SLL  = 4'b1010,
        ALU_SRL  = 4'b1011,
        ALU_SRA  = 4'b1100,
        ALU_SLT  = 4'b0111,
        ALU_SLTU = 4'b1000
    } alu_op_t;

    // --- FUNCT3 CODES (ALU / R-Type / I-Type) ---
    typedef enum logic [2:0] {
        F3_ADD_SUB = 3'b000, // add, sub, addi
        F3_SLL     = 3'b001, // sll, slli
        F3_SLT     = 3'b010, // slt, slti
        F3_SLTU    = 3'b011, // sltu, sltiu
        F3_XOR     = 3'b100, // xor, xori
        F3_SRL_SRA = 3'b101, // srl, sra, srli, srai
        F3_OR      = 3'b110, // or, ori
        F3_AND     = 3'b111  // and, andi
    } funct3_alu_t;

    // --- FUNCT3 CODES (Memory) ---
    typedef enum logic [2:0] {
        F3_BYTE  = 3'b000, // lb, sb
        F3_HALF  = 3'b001, // lh, sh
        F3_WORD  = 3'b010, // lw, sw
        F3_LBU   = 3'b100, // lbu
        F3_LHU   = 3'b101  // lhu
    } funct3_mem_t;

    // --- FUNCT3 CODES (Branch) ---
    typedef enum logic [2:0] {
        F3_BEQ  = 3'b000,
        F3_BNE  = 3'b001,
        F3_BLT  = 3'b100,
        F3_BGE  = 3'b101,
        F3_BLTU = 3'b110,
        F3_BGEU = 3'b111
    } funct3_branch_t;

    // --- Immediate Extraction Helper Functions ---

    /**
     * @brief Extract and sign-extend I-Type immediate
     * @param inst       32-bit instruction
     * @return           XLEN-bit sign-extended immediate
     */
    function automatic logic [XLEN-1:0] extract_imm_i(logic [31:0] inst);
        return {{(XLEN-12){inst[31]}}, inst[31:20]};
    endfunction

    /**
     * @brief Extract and sign-extend S-Type immediate
     * @param inst       32-bit instruction
     * @return           XLEN-bit sign-extended immediate
     */
    function automatic logic [XLEN-1:0] extract_imm_s(logic [31:0] inst);
        return {{(XLEN-12){inst[31]}}, inst[31:25], inst[11:7]};
    endfunction

    /**
     * @brief Extract and sign-extend B-Type immediate
     * @param inst       32-bit instruction
     * @return           XLEN-bit sign-extended immediate
     */
    function automatic logic [XLEN-1:0] extract_imm_b(logic [31:0] inst);
        return {{(XLEN-13){inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
    endfunction

    /**
     * @brief Extract and sign-extend J-Type immediate
     * @param inst       32-bit instruction
     * @return           XLEN-bit sign-extended immediate
     */
    function automatic logic [XLEN-1:0] extract_imm_j(logic [31:0] inst);
        return {{(XLEN-21){inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
    endfunction

    /**
     * @brief Extract U-Type immediate (upper 20 bits)
     * @param inst       32-bit instruction
     * @return           XLEN-bit immediate (lower 12 bits zeroed)
     */
    function automatic logic [XLEN-1:0] extract_imm_u(logic [31:0] inst);
        return {inst[31:12], 12'b0};
    endfunction

    // --- Bit Slice Helper Functions ---
    
    /**
     * @brief Extract a byte from a word based on byte offset
     * @param word       32-bit input word
     * @param offset     Byte position (0-3)
     * @return           Selected 8-bit byte
     */
    function automatic logic [7:0] get_byte(logic [31:0] word, logic [1:0] offset);
        case (offset)
            2'b00: return word[7:0];
            2'b01: return word[15:8];
            2'b10: return word[23:16];
            2'b11: return word[31:24];
        endcase
    endfunction

    /**
     * @brief Extract a halfword from a word based on halfword offset
     * @param word       32-bit input word
     * @param offset     Halfword position (0=lower, 1=upper)
     * @return           Selected 16-bit halfword
     */
    function automatic logic [15:0] get_halfword(logic [31:0] word, logic offset);
        return offset ? word[31:16] : word[15:0];
    endfunction

    /**
     * @brief Sign-extend an 8-bit value to XLEN bits
     * @param value      8-bit signed value
     * @return           XLEN-bit sign-extended value
     */
    function automatic logic [XLEN-1:0] sign_extend_byte(logic [7:0] value);
        return {{(XLEN-8){value[7]}}, value};
    endfunction

    /**
     * @brief Sign-extend a 16-bit value to XLEN bits
     * @param value      16-bit signed value
     * @return           XLEN-bit sign-extended value
     */
    function automatic logic [XLEN-1:0] sign_extend_half(logic [15:0] value);
        return {{(XLEN-16){value[15]}}, value};
    endfunction

    /**
     * @brief Zero-extend an 8-bit value to XLEN bits
     * @param value      8-bit unsigned value
     * @return           XLEN-bit zero-extended value
     */
    function automatic logic [XLEN-1:0] zero_extend_byte(logic [7:0] value);
        return {{(XLEN-8){1'b0}}, value};
    endfunction

    /**
     * @brief Zero-extend a 16-bit value to XLEN bits
     * @param value      16-bit unsigned value
     * @return           XLEN-bit zero-extended value
     */
    function automatic logic [XLEN-1:0] zero_extend_half(logic [15:0] value);
        return {{(XLEN-16){1'b0}}, value};
    endfunction

    /**
     * @brief Generate byte enable mask based on funct3 and address alignment
     * @param funct3     Memory operation type (byte, half, word)
     * @param addr_lsb   Lower 2 bits of the address
     * @return           4-bit byte enable mask
     */
    function automatic logic [3:0] get_byte_enable(logic [2:0] funct3, logic [1:0] addr_lsb);
        case (funct3)
            F3_BYTE: begin : ByteEnable
                case (addr_lsb)
                    2'b00: return 4'b0001;
                    2'b01: return 4'b0010;
                    2'b10: return 4'b0100;
                    2'b11: return 4'b1000;
                endcase
            end
            F3_HALF: begin : HalfwordEnable
                case (addr_lsb[1])
                    1'b0: return 4'b0011;
                    1'b1: return 4'b1100;
                endcase
            end
            default: return 4'b1111; // F3_WORD or others
        endcase
    endfunction

endpackage
