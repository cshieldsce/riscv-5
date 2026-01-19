import riscv_pkg::*;

module EX_Stage (
    // Data Inputs
    input  logic [XLEN-1:0] pc,
    input  logic [XLEN-1:0] imm,
    input  logic [XLEN-1:0] rs1_data,
    input  logic [XLEN-1:0] rs2_data,
    
    // Forwarding Inputs
    input  logic [1:0]      forward_a,
    input  logic [1:0]      forward_b,
    input  logic [XLEN-1:0] ex_mem_alu_result,
    input  logic [XLEN-1:0] wb_write_data,
    
    // Control Inputs
    input  alu_op_t         alu_control,
    input  logic            alu_src,   // 0: register, 1: immediate
    input  logic [1:0]      alu_src_a, // 0: register, 1: PC, 2: Zero
    input  logic            branch_en,
    input  logic [2:0]      funct3,
    
    // Outputs
    output logic [XLEN-1:0] alu_result,
    output logic            alu_zero,
    output logic            branch_taken,
    output logic [XLEN-1:0] branch_target,
    output logic [XLEN-1:0] rs2_data_forwarded
);

    logic [XLEN-1:0] alu_in_a_forwarded;
    logic [XLEN-1:0] alu_in_a;
    logic [XLEN-1:0] alu_in_b;

    // --- 1. Forwarding MUX for rs1 ---
    always_comb begin
        case (forward_a)
            2'b00:   alu_in_a_forwarded = rs1_data;
            2'b01:   alu_in_a_forwarded = wb_write_data;
            2'b10:   alu_in_a_forwarded = ex_mem_alu_result;
            default: alu_in_a_forwarded = rs1_data;
        endcase
    end

    // --- 2. Forwarding MUX for rs2 (MUST be before alu_in_b assignment) ---
    always_comb begin
        case (forward_b)
            2'b00:   rs2_data_forwarded = rs2_data;
            2'b01:   rs2_data_forwarded = wb_write_data;
            2'b10:   rs2_data_forwarded = ex_mem_alu_result;
            default: rs2_data_forwarded = rs2_data;
        endcase
    end

    // --- 3. Handle LUI/AUIPC MUX ---
    always_comb begin
        case (alu_src_a)
            2'b00:   alu_in_a = alu_in_a_forwarded; // Register
            2'b01:   alu_in_a = pc;                  // PC
            2'b10:   alu_in_a = {XLEN{1'b0}};        // Zero
            default: alu_in_a = alu_in_a_forwarded;
        endcase
    end

    // --- 4. ALU Input B MUX (Register or Immediate) ---
    assign alu_in_b = alu_src ? imm : rs2_data_forwarded;

    // --- 5. ALU Instantiation ---
    ALU alu_inst (
        .A(alu_in_a),
        .B(alu_in_b),
        .ALUControl(alu_control),
        .Result(alu_result),
        .Zero(alu_zero)  // Now correctly drives the output port
    );

    // --- 6. Branch Logic ---
    always_comb begin
        if (branch_en) begin
            case (funct3)
                F3_BEQ:  branch_taken = alu_zero;          // A == B
                F3_BNE:  branch_taken = ~alu_zero;         // A != B
                F3_BLT:  branch_taken = alu_result[0];     // A < B (signed)
                F3_BGE:  branch_taken = ~alu_result[0];    // A >= B (signed)
                F3_BLTU: branch_taken = alu_result[0];     // A < B (unsigned)
                F3_BGEU: branch_taken = ~alu_result[0];    // A >= B (unsigned)
                default: branch_taken = 1'b0;
            endcase
        end else begin
            branch_taken = 1'b0;
        end
    end

    // --- 7. Branch Target Calculation ---
    assign branch_target = pc + imm;

endmodule