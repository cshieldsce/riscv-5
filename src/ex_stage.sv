import riscv_pkg::*;

/**
 * @brief Execute Stage (EX)
 * 
 * Performs ALU operations and resolves branches.
 * Responsibilities:
 * - ALU operand MUXing (Forwarding logic + Source selection)
 * - ALU calculation
 * - Branch target calculation (PC + Immediate)
 * - Branch resolution (Comparator)
 */
module EX_Stage (
    // Data Inputs
    input  logic [XLEN-1:0] pc,
    input  logic [XLEN-1:0] imm,
    input  logic [XLEN-1:0] rs1_data,
    input  logic [XLEN-1:0] rs2_data,
    
    // Forwarding Inputs (from Forwarding Unit)
    input  logic [1:0]      forward_a, // Mux select for SrcA
    input  logic [1:0]      forward_b, // Mux select for SrcB (reg portion)
    input  logic [XLEN-1:0] ex_mem_alu_result, // Forwarded from MEM stage
    input  logic [XLEN-1:0] wb_write_data,     // Forwarded from WB stage
    
    // Control Inputs
    input  alu_op_t         alu_control,
    input  logic            alu_src,   // ALU B Src: 0: register, 1: immediate
    input  logic [1:0]      alu_src_a, // ALU A Src: 0: register, 1: PC, 2: Zero
    input  logic            branch_en,
    input  logic [2:0]      funct3,    // Branch type
    
    // Outputs
    output logic [XLEN-1:0] alu_result,
    output logic            alu_zero,
    output logic            branch_taken,
    output logic [XLEN-1:0] branch_target,
    output logic [XLEN-1:0] rs2_data_forwarded // Passed to MEM stage for Store
);

    logic [XLEN-1:0] alu_in_a_forwarded;
    logic [XLEN-1:0] alu_in_a;
    logic [XLEN-1:0] alu_in_b;

    always_comb begin : ForwardA_MUX
        case (forward_a)
            2'b00:   alu_in_a_forwarded = rs1_data;          // Forward rs1 from Register File
            2'b01:   alu_in_a_forwarded = wb_write_data;     // Forward write data from WB
            2'b10:   alu_in_a_forwarded = ex_mem_alu_result; // Forward ALU result from MEM
            default: alu_in_a_forwarded = rs1_data;          // Fallback: rs1 from Register File
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
        case (alu_src_a)
            2'b00:   alu_in_a = alu_in_a_forwarded;  // Regular register op
            2'b01:   alu_in_a = pc;                  // AUIPC
            2'b10:   alu_in_a = {XLEN{1'b0}};        // LUI
            default: alu_in_a = alu_in_a_forwarded;  // Fallback: regular register op
        endcase
    end

    // --- ALU Input B MUX: ---
    // Selects between Register (rs2) and Immediate
    assign alu_in_b = alu_src ? imm : rs2_data_forwarded;

    // --- ALU Instantiation ---
    ALU alu_inst (
        .A(alu_in_a),
        .B(alu_in_b),
        .ALUControl(alu_control),
        .Result(alu_result),
        .Zero(alu_zero)
    );

    always_comb begin : BranchResolution
        if (branch_en) begin : BranchEnabled
            case (funct3)
                F3_BEQ:  branch_taken = alu_zero;          // A == B
                F3_BNE:  branch_taken = ~alu_zero;         // A != B 
                F3_BLT:  branch_taken = alu_result[0];     // A < B (signed) 
                F3_BGE:  branch_taken = ~alu_result[0];    // A >= B (signed) 
                F3_BLTU: branch_taken = alu_result[0];     // A < B (unsigned) 
                F3_BGEU: branch_taken = ~alu_result[0];    // A >= B (unsigned)
                default: branch_taken = 1'b0;
            endcase
        end else begin : BranchDisabled
            branch_taken = 1'b0;
        end
    end

    // --- Branch Target Calculation ---
    assign branch_target = pc + imm;

endmodule