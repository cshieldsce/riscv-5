import riscv_pkg::*;

/**
 * @brief Arithmetic Logic Unit (ALU) for RISC-V CPU
 * 
 * Performs arithmetic and logical operations based on the ALUControl signal.
 * Supports all RV32I integer operations including:
 * - Arithmetic: ADD, SUB
 * - Logical: AND, OR, XOR
 * - Comparison: SLT (signed), SLTU (unsigned)
 * - Shifts: SLL (logical left), SRL (logical right), SRA (arithmetic right)
 * 
 * @param A           First operand (typically rs1 or PC)
 * @param B           Second operand (typically rs2 or immediate)
 * @param ALUControl  Operation selector from alu_op_t enum
 * @param Result      32-bit output result
 * @param Zero        Flag indicating if Result == 0 (used for branch decisions)
 */
module ALU (
    input  logic [XLEN-1:0] A, B, // First operand (typically rs1 or PC)
    input  alu_op_t         ALUControl,
    output logic [XLEN-1:0] Result,
    output logic            Zero
);
    // Extract shift amount: Only lower log2(XLEN) bits used per RISC-V spec
    // For RV32I: bits [4:0] = 0-31 range, For RV64I: bits [5:0] = 0-63 range
    logic [$clog2(XLEN)-1:0] shamt;
    assign shamt = B[$clog2(XLEN)-1:0];

    always_comb begin : ALU_Operation
        case (ALUControl)
            ALU_AND:  Result = A & B;                                                               // Bitwise AND (AND, ANDI)
            ALU_OR:   Result = A | B;                                                               // Bitwise OR (OR, ORI)
            ALU_XOR:  Result = A ^ B;                                                               // Bitwise XOR (XOR, XORI)
            ALU_ADD:  Result = A + B;                                                               // Addition (ADD, ADDI, AUIPC, L/S addr)
            ALU_SUB:  Result = A - B;                                                               // Subtraction (SUB, branch comparisons)
            ALU_SLT:  Result = ($signed(A) < $signed(B)) ? {{XLEN-1{1'b0}}, 1'b1} : {XLEN{1'b0}};   // Set if A < B (signed)
            ALU_SLTU: Result = (A < B) ? {{XLEN-1{1'b0}}, 1'b1} : {XLEN{1'b0}};                     // Set if A < B (unsigned)
            ALU_SLL:  Result = A << shamt;                                                          // Shift left logical (SLL, SLLI)
            ALU_SRL:  Result = A >> shamt;                                                          // Shift right logical (SRL, SRLI)
            ALU_SRA:  Result = $signed(A) >>> shamt;                                                // Shift right arithmetic (SRA, SRAI)
            default:  Result = {XLEN{1'b0}};
        endcase
    end

    assign Zero = (Result == {XLEN{1'b0}});

endmodule