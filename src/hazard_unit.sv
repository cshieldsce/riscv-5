import riscv_pkg::*;

/**
 * @brief Hazard Detection Unit
 * @details Manages pipeline stalls and flushes to resolve hazards that cannot be 
 *          handled by forwarding alone.
 * 
 *          Handled Hazards:
 *          1. Load-Use Hazard: Instruction in ID needs data from a Load in EX.
 *             - Action: Stall IF and ID, flush EX (insert bubble).
 *          2. ALU-to-Branch Hazard: Branch in ID depends on ALU result still in EX.
 *             - Action: Stall IF and ID, flush EX (insert bubble).
 *          3. Control Hazards: Branch Taken or Jumps.
 *             - Action: Flush fetched instructions in pipeline stages to discard wrong path.
 * 
 * @param id_rs1         Source Register 1 from ID Stage
 * @param id_rs2         Source Register 2 from ID Stage
 * @param id_branch      Branch instruction detected in ID Stage
 * @param id_ex_rd       Destination Register from EX Stage (ID/EX reg)
 * @param id_ex_mem_read Memory Read Enable from EX Stage (ID/EX reg) - indicates Load
 * @param PCSrc          Branch/Jump Taken signal (from EX Stage)
 * @param jump_id_stage  Unconditional Jump detected in ID Stage
 * @param stall_if       Output: Stall IF Stage (Freeze PC)
 * @param stall_id       Output: Stall ID Stage (Freeze IF/ID reg)
 * @param flush_ex       Output: Flush EX Stage (Clear ID/EX reg)
 * @param flush_id       Output: Flush ID Stage (Clear IF/ID reg)
 */
module HazardUnit (
    input  logic [4:0] id_rs1,
    input  logic [4:0] id_rs2,
    input  logic       id_branch,
    input  logic [4:0] id_ex_rd,
    input  logic       id_ex_mem_read,
    input  logic       PCSrc,         
    input  logic       jump_id_stage,
    output logic       stall_if,       
    output logic       stall_id,       
    output logic       flush_ex,       
    output logic       flush_id        
);
    /**
     * @brief Check if register dependency exists (excluding x0)
     * @param rd Destination register
     * @param rs1 Source register 1
     * @param rs2 Source register 2
     * @return True if rd matches rs1 or rs2 (and rd != x0)
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
     * @param ex_is_load Load instruction in EX stage
     * @param ex_rd Destination register from EX stage
     * @param id_rs1 Source register 1 from ID stage
     * @param id_rs2 Source register 2 from ID stage
     * @return True if load and dependency exists
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
     * @param ex_is_load Load instruction in EX stage
     * @param ex_rd Destination register from EX stage
     * @param id_is_branch Branch instruction in ID stage
     * @param id_rs1 Source register 1 from ID stage
     * @param id_rs2 Source register 2 from ID stage
     * @return True if not load, is branch, and dependency exists
     */
    function automatic logic is_alu_branch_hazard(
        input logic       ex_is_load,
        input logic [4:0] ex_rd,
        input logic       id_is_branch,
        input logic [4:0] id_rs1,
        input logic [4:0] id_rs2
    );
        return !ex_is_load && id_is_branch && has_register_dependency(ex_rd, id_rs1, id_rs2);
    endfunction

    always_comb begin : HazardDetection
        // --- Default: Normal Operation --- 
        stall_if = 1'b0;
        stall_id = 1'b0;
        flush_ex = 1'b0;
        flush_id = 1'b0;

        if (is_load_use_hazard(id_ex_mem_read, id_ex_rd, id_rs1, id_rs2)) begin : LoadUse_Flush
            stall_if = 1'b1;
            stall_id = 1'b1;
            flush_ex = 1'b1;
        end
        
        else if (is_alu_branch_hazard(id_ex_mem_read, id_ex_rd, id_branch, id_rs1, id_rs2)) begin : ALUBranch_Flush
            stall_if = 1'b1;
            stall_id = 1'b1;
            flush_ex = 1'b1;
        end

        else if (PCSrc) begin : BranchJALR_Flush
            flush_id = 1'b1;
            flush_ex = 1'b1;
        end
        
        else if (jump_id_stage) begin : JAL_Flush
            flush_id = 1'b1;
        end
    end

endmodule