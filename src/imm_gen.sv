import riscv_pkg::*;

/**
 * @brief Immediate Generator
 * 
 * Extracts and sign-extends immediate values from instructions.
 * Supports all RV32I immediate formats.
 */
module ImmGen (
    input  logic [XLEN-1:0] instruction,
    input  opcode_t         opcode,
    output logic [XLEN-1:0] imm_out
);
    // --- Local Helper Functions ---
    
    function automatic logic [XLEN-1:0] extract_imm_i(logic [31:0] inst);
        return {{(XLEN-12){inst[31]}}, inst[31:20]};
    endfunction
    
    function automatic logic [XLEN-1:0] extract_imm_s(logic [31:0] inst);
        return {{(XLEN-12){inst[31]}}, inst[31:25], inst[11:7]};
    endfunction
    
    function automatic logic [XLEN-1:0] extract_imm_b(logic [31:0] inst);
        return {{(XLEN-13){inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
    endfunction
    
    function automatic logic [XLEN-1:0] extract_imm_j(logic [31:0] inst);
        return {{(XLEN-21){inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
    endfunction
    
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