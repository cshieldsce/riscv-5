import riscv_pkg::*;

/**
 * @brief Instruction Fetch Stage (IF)
 * @details Responsibilities:
 *          - Manages Program Counter (PC)
 *          - Calculates next PC based on control flow decisions
 *          - Fetches instructions from memory
 *          - Handles PC stalls and control hazards
 * 
 * @param clk               System Clock
 * @param rst               System Reset (Active High)
 * @param stall             Stall signal from Hazard Unit (Freeze PC)
 * @param branch_taken      Branch Taken flag from EX Stage
 * @param jalr_taken        JALR Taken flag from EX Stage
 * @param jal_taken         JAL Taken flag from ID Stage
 * @param branch_target     Branch Target Address from EX Stage
 * @param jalr_target       JALR Target Address from EX Stage
 * @param jal_target        JAL Target Address from ID Stage
 * @param instruction_in    Raw Instruction from Instruction Memory
 * @param pc_out            Current Program Counter
 * @param pc_plus_4         Program Counter + 4
 * @param instruction_out   Instruction for ID Stage
 */
module IF_Stage (
    input  logic             clk,
    input  logic             rst,
    input  logic             stall,              
    input  logic             branch_taken,      
    input  logic             jalr_taken,        
    input  logic             jal_taken,        
    input  logic [XLEN-1:0]  branch_target,     
    input  logic [XLEN-1:0]  jalr_target,       
    input  logic [XLEN-1:0]  jal_target,     
    input  logic [XLEN-1:0]  instruction_in,
    output logic [XLEN-1:0]  pc_out,           
    output logic [XLEN-1:0]  pc_plus_4,        
    output logic [XLEN-1:0]  instruction_out 
);

    // --- Next PC Logic ---
    logic [XLEN-1:0] if_pc_reg;
    logic [XLEN-1:0] if_next_pc;
    logic [XLEN-1:0] if_pc_plus_4_calc;

    assign if_pc_plus_4_calc = if_pc_reg + 4;

    always_comb begin: SelectNextPC
        if (stall) begin : Stalled
            if_next_pc = if_pc_reg;        
        end else if (jalr_taken) begin : JALRTaken
            if_next_pc = jalr_target;          
        end else if (branch_taken) begin : BranchTaken
            if_next_pc = branch_target;       
        end else if (jal_taken) begin : JALTaken
            if_next_pc = jal_target;         
        end else begin : IncrementPC
            if_next_pc = if_pc_plus_4_calc;
        end 
    end

    always_ff @(posedge clk) begin : PC_Register
        if (rst) begin : ResetPC
            if_pc_reg <= {XLEN{1'b0}};
        end else begin : UpdatePC
            if_pc_reg <= if_next_pc;
        end
    end

    // --- Outputs ---
    assign pc_out          = if_pc_reg;
    assign pc_plus_4       = if_pc_plus_4_calc;
    assign instruction_out = instruction_in;
endmodule