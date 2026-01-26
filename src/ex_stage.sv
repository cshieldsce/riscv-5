import riscv_pkg::*;

/**
 * @brief Execute Stage (EX)
 * @details Performs ALU operations and resolves branches.
 *          Responsibilities:
 *          - ALU operand MUXing (Forwarding logic + Source selection)
 *          - ALU calculation
 *          - Branch target calculation (PC + Immediate)
 *          - Branch resolution (Comparator)
 * 
 * @param pc                 Program Counter
 * @param imm                Immediate value
 * @param rs1_data           Data from Register File (rs1)
 * @param rs2_data           Data from Register File (rs2)
 * @param forward_a          Forwarding Select A (00=Reg, 01=WB, 10=MEM)
 * @param forward_b          Forwarding Select B (00=Reg, 01=WB, 10=MEM)
 * @param ex_mem_alu_result  Forwarded ALU result from MEM stage
 * @param wb_write_data      Forwarded write data from WB stage
 * @param alu_control        ALU Operation Control
 * @param op_a_sel           ALU Source A Select (0=Reg, 1=PC, 2=Zero)
 * @param op_b_sel           ALU Source B Select (0=Reg, 1=Imm)
 * @param branch_en          Branch Enable
 * @param funct3             Branch Type (BEQ, BNE, etc.)
 * @param alu_result         ALU Calculation Result
 * @param alu_zero           Zero Flag (Result == 0)
 * @param branch_taken       Branch Taken Flag
 * @param branch_target      Calculated Branch Target Address
 * @param rs2_data_forwarded Forwarded rs2 data (for Store operations)
 */
module EX_Stage (
    input  logic [XLEN-1:0] pc,
    input  logic [XLEN-1:0] imm,
    input  logic [XLEN-1:0] rs1_data,
    input  logic [XLEN-1:0] rs2_data,
    input  logic [1:0]      forward_a,
    input  logic [1:0]      forward_b,
    input  logic [XLEN-1:0] ex_mem_alu_result,
    input  logic [XLEN-1:0] wb_write_data,
    input  alu_op_t         alu_control,
    input  logic [1:0]      op_a_sel,
    input  logic            op_b_sel,
    input  logic            branch_en,
    input  logic [2:0]      funct3,
    output logic [XLEN-1:0] alu_result,
    output logic            alu_zero,
    output logic            branch_taken,
    output logic [XLEN-1:0] branch_target,
    output logic [XLEN-1:0] rs2_data_forwarded
);
    // --- ALU Operand MUXing with Forwarding (A and B) ---
    logic [XLEN-1:0] ex_alu_in_a_fwd;
    logic [XLEN-1:0] ex_alu_in_a;
    logic [XLEN-1:0] ex_alu_in_b;

    always_comb begin : ForwardA_MUX
        case (forward_a)
            2'b00:   ex_alu_in_a_fwd = rs1_data;            // Forward rs1 from Register File
            2'b01:   ex_alu_in_a_fwd = wb_write_data;       // Forward write data from WB
            2'b10:   ex_alu_in_a_fwd = ex_mem_alu_result;   // Forward ALU result from MEM
            default: ex_alu_in_a_fwd = rs1_data;            // Fallback: rs1 from Register File
        endcase
    end

    always_comb begin : ForwardB_MUX
        case (forward_b)
            2'b00:   rs2_data_forwarded = rs2_data;          // Forward rs2 from Register File
            2'b01:   rs2_data_forwarded = wb_write_data;     // Forward write data from WB
            2'b10:   rs2_data_forwarded = ex_mem_alu_result; // Forward ALU result from MEM
            default: rs2_data_forwarded = rs2_data;          // Fallback: rs2 from Register File
        endcase
    end

    always_comb begin : ALUInputA_MUX
        case (op_a_sel)
            2'b00:   ex_alu_in_a = ex_alu_in_a_fwd;          // Regular register op
            2'b01:   ex_alu_in_a = pc;                       // AUIPC
            2'b10:   ex_alu_in_a = {XLEN{1'b0}};             // LUI
            default: ex_alu_in_a = ex_alu_in_a_fwd;          // Fallback: regular register op
        endcase
    end

    assign ex_alu_in_b = op_b_sel ? imm : rs2_data_forwarded;

    // -- Branch Resolution ---
    ALU alu_inst (
        .A(ex_alu_in_a),
        .B(ex_alu_in_b),
        .ALUControl(alu_control),
        .Result(alu_result),
        .Zero(alu_zero)
    );

    always_comb begin : BranchResolution
        if (branch_en) begin : BranchEnabled
            case (funct3)
                F3_BEQ:  branch_taken = alu_zero;            // A == B
                F3_BNE:  branch_taken = ~alu_zero;           // A != B 
                F3_BLT:  branch_taken = alu_result[0];       // A < B (signed) 
                F3_BGE:  branch_taken = ~alu_result[0];      // A >= B (signed) 
                F3_BLTU: branch_taken = alu_result[0];       // A < B (unsigned) 
                F3_BGEU: branch_taken = ~alu_result[0];      // A >= B (unsigned)
                default: branch_taken = 1'b0;                // Branch not taken
            endcase
        end else begin : BranchDisabled
            branch_taken = 1'b0;
        end
    end
    
    assign branch_target = pc + imm;

endmodule