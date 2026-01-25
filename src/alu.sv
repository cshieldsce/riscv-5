import riscv_pkg::*;

/**
 * @brief Arithmetic Logic Unit (ALU) for RISC-V CPU
 * @details Performs arithmetic and logical operations based on the ALUControl signal.
 *          Supports all RV32I integer operations including:
 *          - Arithmetic: ADD, SUB
 *          - Logical: AND, OR, XOR
 *          - Comparison: SLT (signed), SLTU (unsigned)
 *          - Shifts: SLL (logical left), SRL (logical right), SRA (arithmetic right)
 * 
 * @param A           First operand (typically rs1 or PC)
 * @param B           Second operand (typically rs2 or immediate)
 * @param ALUControl  Operation selector from alu_op_t enum
 * @param Result      32-bit output result
 * @param Zero        Flag indicating if Result == 0 (used for branch decisions)
 */
module ALU (
    input  logic [XLEN-1:0] A, B,
    input  alu_op_t         ALUControl,
    output logic [XLEN-1:0] Result,
    output logic            Zero
);
    logic [$clog2(XLEN)-1:0] alu_shamt;                                                             // Shift amount: 5 bits for RV32, 6 bits for RV64
    assign alu_shamt = B[$clog2(XLEN)-1:0];                                                         // Extract valid shift bits from  B

    always_comb begin : ALU_Operation
        case (ALUControl)
            ALU_AND:  Result = A & B;                                                               // Bitwise AND (AND, ANDI)
            ALU_OR:   Result = A | B;                                                               // Bitwise OR (OR, ORI)
            ALU_XOR:  Result = A ^ B;                                                               // Bitwise XOR (XOR, XORI)
            ALU_ADD:  Result = A + B;                                                               // Addition (ADD, ADDI, AUIPC, L/S addr)
            ALU_SUB:  Result = A - B;                                                               // Subtraction (SUB, branch comparisons)
            ALU_SLT:  Result = ($signed(A) < $signed(B)) ? {{XLEN-1{1'b0}}, 1'b1} : {XLEN{1'b0}};   // Set if A < B (signed)
            ALU_SLTU: Result = (A < B) ? {{XLEN-1{1'b0}}, 1'b1} : {XLEN{1'b0}};                     // Set if A < B (unsigned)
            ALU_SLL:  Result = A << alu_shamt;                                                      // Shift left logical (SLL, SLLI)
            ALU_SRL:  Result = A >> alu_shamt;                                                      // Shift right logical (SRL, SRLI)
            ALU_SRA:  Result = $signed(A) >>> alu_shamt;                                            // Shift right arithmetic (SRA, SRAI)
            default:  Result = {XLEN{1'b0}};
        endcase
    end

    assign Zero = (Result == {XLEN{1'b0}});                                                         // Zero flag for branch decisions

endmodule