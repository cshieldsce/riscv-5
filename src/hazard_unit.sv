import riscv_pkg::*;

/**
 * @brief Hazard Detection Unit
 * 
 * Manages pipeline stalls and flushes to resolve hazards that cannot be 
 * handled by forwarding alone.
 * 
 * Handled Hazards:
 * 1. Load-Use Hazard: Instruction in ID needs data from a Load in EX.
 *    - Action: Stall IF and ID, flush EX (insert bubble).
 * 2. ALU-to-Branch Hazard: Branch in ID depends on ALU result still in EX.
 *    - Action: Stall IF and ID, flush EX (insert bubble).
 * 3. Control Hazards: Branch Taken or Jumps.
 *    - Action: Flush fetched instructions in pipeline stages to discard wrong path.
 */
module HazardUnit (
    // Inputs from ID Stage (Current Instruction)
    input  logic [4:0] id_rs1,
    input  logic [4:0] id_rs2,
    input  logic       id_branch,

    // Inputs from EX Stage (Previous Instruction)
    input  logic [4:0] id_ex_rd,
    input  logic       id_ex_mem_read, // High if instruction in EX is a Load
    
    // Control Hazard Signals
    input  logic       PCSrc,          // High if branch/JALR is taken (resolved in EX)
    input  logic       jump_id_stage,  // High if JAL is detected (resolved in ID)
    
    // Pipeline Control Outputs
    output logic       stall_if,       // Freeze PC and IF Stage
    output logic       stall_id,       // Freeze IF/ID Pipeline Register
    output logic       flush_ex,       // Flush ID/EX Pipeline Register (Insert NOP)
    output logic       flush_id        // Flush IF/ID Pipeline Register (Discard Fetch)
);

    // --- Local Helper Functions ---
    
    /**
     * @brief Check if register dependency exists (excluding x0)
     */
    function automatic logic has_register_dependency(
        input logic [4:0] rd,
        input logic [4:0] rs1,
        input logic [4:0] rs2
    );
        return (rd != 5'b0) && ((rd == rs1) || (rd == rs2));
    endfunction

    /**
     * @brief Detect Load-Use hazard
     */
    function automatic logic is_load_use_hazard(
        input logic       ex_is_load,
        input logic [4:0] ex_rd,
        input logic [4:0] id_rs1,
        input logic [4:0] id_rs2
    );
        return ex_is_load && has_register_dependency(ex_rd, id_rs1, id_rs2);
    endfunction

    /**
     * @brief Detect ALU-to-Branch hazard
     */
    function automatic logic is_alu_branch_hazard(
        input logic       ex_is_load,
        input logic [4:0] ex_rd,
        input logic       id_is_branch,
        input logic [4:0] id_rs1,
        input logic [4:0] id_rs2
    );
        return !ex_is_load && 
               id_is_branch && 
               has_register_dependency(ex_rd, id_rs1, id_rs2);
    endfunction

    // --- Hazard Detection Logic ---
    
    always_comb begin : HazardDetection
        // Default: Normal Operation
        stall_if = 1'b0;
        stall_id = 1'b0;
        flush_ex = 1'b0;
        flush_id = 1'b0;

        // 1. DATA HAZARD: LOAD-USE
        if (is_load_use_hazard(id_ex_mem_read, id_ex_rd, id_rs1, id_rs2)) begin
            stall_if = 1'b1;
            stall_id = 1'b1;
            flush_ex = 1'b1;
        end
        
        // 2. DATA HAZARD: ALU-to-BRANCH
        else if (is_alu_branch_hazard(id_ex_mem_read, id_ex_rd, id_branch, id_rs1, id_rs2)) begin
            stall_if = 1'b1;
            stall_id = 1'b1;
            flush_ex = 1'b1;
        end

        // 3. CONTROL HAZARD: BRANCH TAKEN / JALR
        else if (PCSrc) begin
            flush_id = 1'b1;
            flush_ex = 1'b1;
        end
        
        // 4. CONTROL HAZARD: UNCONDITIONAL JUMP (JAL)
        else if (jump_id_stage) begin
            flush_id = 1'b1;
        end
    end

endmodule