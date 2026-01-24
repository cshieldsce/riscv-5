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
    // Moved to riscv_pkg.sv

    always_comb begin : ImmSelection
        case (opcode)
            OP_I_TYPE, 
            OP_LOAD, 
            OP_JALR:   imm_out = riscv_pkg::extract_imm_i(instruction);
            OP_STORE:  imm_out = riscv_pkg::extract_imm_s(instruction);
            OP_BRANCH: imm_out = riscv_pkg::extract_imm_b(instruction);
            OP_JAL:    imm_out = riscv_pkg::extract_imm_j(instruction);
            OP_LUI, 
            OP_AUIPC:  imm_out = riscv_pkg::extract_imm_u(instruction);
            default:   imm_out = {XLEN{1'b0}};
        endcase
    end
endmodule