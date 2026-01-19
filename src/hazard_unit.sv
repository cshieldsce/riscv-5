import riscv_pkg::*;

module HazardUnit (
    // Inputs from ID Stage (Current Instruction)
    input  logic [4:0] id_rs1,
    input  logic [4:0] id_rs2,
    input  logic       id_branch,

    // Inputs from EX Stage (Previous Instruction)
    input  logic [4:0] id_ex_rd,
    input  logic       id_ex_mem_read, // High if instruction in EX is a load
    
    // Inputs from Branch Logic
    input  logic       PCSrc,        // High if branch is taken
    
    // Early jump detection from ID stage
    input  logic       jump_id_stage,
    
    // Outputs to Control Signals
    output logic       stall_if,        // Freeze PC
    output logic       stall_id,        // Freeze IF/ID register
    output logic       flush_ex,        // Flush ID/EX register (insert NOP)
    output logic       flush_id         // Flush IF/ID register
);

    logic id_ex_is_alu_write;
    assign id_ex_is_alu_write = (id_ex_rd != 0) && !id_ex_mem_read;

    always_comb begin : HazardUnit
        // Default values (no hazards)
        stall_if = 0;
        stall_id = 0;
        flush_ex = 0;
        flush_id = 0;

        // Hazard detection is prioritized. The first condition to match takes precedence.

        // ========================================================================
        // PRIORITY 1: LOAD-USE HAZARD
        // ========================================================================
        // Stalls the pipeline for one cycle if the instruction in ID depends on
        // a load instruction currently in EX. This is the highest priority stall.
        if (id_ex_mem_read && ((id_ex_rd == id_rs1) || (id_ex_rd == id_rs2))) begin
            stall_if = 1; 
            stall_id = 1;
            flush_ex = 1; // Insert a bubble
        end
        
        // ========================================================================
        // PRIORITY 2: ALU-to-BRANCH HAZARD
        // ========================================================================
        // Stalls if a branch in ID depends on an ALU result from EX.
        else if ((id_ex_rd != 0) && !id_ex_mem_read && id_branch && ((id_ex_rd == id_rs1) || (id_ex_rd == id_rs2))) begin
             stall_if = 1;
             stall_id = 1;
             flush_ex = 1; // Insert a bubble
        end

        // ========================================================================
        // PRIORITY 3: CONTROL HAZARDS (Jumps and Taken Branches)
        // ========================================================================
        // These hazards flush instructions that were fetched from the wrong path.
        else if (PCSrc) begin // Branch/JALR is taken (resolved in EX)
            flush_id = 1;
            flush_ex = 1;
        end
        else if (jump_id_stage) begin // JAL is in ID stage
            flush_id = 1;
        end
    end
endmodule