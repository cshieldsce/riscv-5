import riscv_pkg::*;

/**
 * @brief Immediate Generator
 * @details Extracts and sign-extends immediate values from instructions.
 *          Supports all RV32I immediate formats (I, S, B, J, U).
 * 
 * @param instruction   32-bit Instruction
 * @param opcode        Decoded Opcode
 * @param imm_out       Sign-extended 32-bit Immediate
 */
module ImmGen (
    input  logic [XLEN-1:0] instruction,
    input  opcode_t         opcode,
    output logic [XLEN-1:0] imm_out
);
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

    always_comb begin : ImmSelection
        case (opcode)
            OP_I_TYPE, 
            OP_LOAD, 
            OP_JALR:   imm_out = extract_imm_i(instruction);
            OP_STORE:  imm_out = extract_imm_s(instruction);
            OP_BRANCH: imm_out = extract_imm_b(instruction);
            OP_JAL:    imm_out = extract_imm_j(instruction);
            OP_LUI, 
            OP_AUIPC:  imm_out = extract_imm_u(instruction);
            default:   imm_out = {XLEN{1'b0}};
        endcase
    end
endmodule