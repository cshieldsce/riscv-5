import riscv_pkg::*;

/**
 * @brief Instruction Fetch Stage (IF)
 * 
 * Responsibilities:
 * - Manages Program Counter (PC)
 * - Calculates next PC based on control flow decisions
 * - Fetches instructions from memory
 * - Handles PC stalls and control hazards
 */
module IF_Stage (
    input  logic             clk,
    input  logic             rst,
    
    // Control inputs
    input  logic             stall,              // Freeze PC (from Hazard Unit)
    input  logic             branch_taken,       // Branch taken in EX stage
    input  logic             jalr_taken,         // JALR taken in EX stage
    input  logic             jal_taken,          // JAL detected in ID stage
    
    // Target address inputs
    input  logic [XLEN-1:0]  branch_target,      // Branch target from EX
    input  logic [XLEN-1:0]  jalr_target,        // JALR target from EX (pre-masked)
    input  logic [XLEN-1:0]  jal_target,         // JAL target from ID
    
    // Instruction input
    input  logic [XLEN-1:0]  instruction_in,     // From instruction memory
    
    // Outputs
    output logic [XLEN-1:0]  pc_out,             // Current PC
    output logic [XLEN-1:0]  pc_plus_4,          // PC + 4
    output logic [XLEN-1:0]  instruction_out     // Fetched instruction
);
    // --- Local Signals ---
    
    logic [XLEN-1:0] pc_reg;
    logic [XLEN-1:0] next_pc;
    logic [XLEN-1:0] pc_plus_4_calc;

    // --- Local Helper Functions ---
    
    /**
     * @brief Calculate PC + 4 (next sequential instruction)
     * @param pc Current program counter
     * @return PC incremented by 4
     */
    function automatic logic [XLEN-1:0] calc_pc_plus_4(logic [XLEN-1:0] pc);
        return pc + 4;
    endfunction

    /**
     * @brief Select next PC based on control flow
     * @param stall Stall signal (hold current PC)
     * @param jalr_taken JALR taken flag
     * @param branch_taken Branch taken flag
     * @param jal_taken JAL taken flag
     * @param jalr_target JALR target address
     * @param branch_target Branch target address
     * @param jal_target JAL target address
     * @param pc_plus_4 Sequential next address
     * @param current_pc Current PC (for stall)
     * @return Next PC value
     */
    function automatic logic [XLEN-1:0] select_next_pc(
        input logic             stall,
        input logic             jalr_taken,
        input logic             branch_taken,
        input logic             jal_taken,
        input logic [XLEN-1:0]  jalr_target,
        input logic [XLEN-1:0]  branch_target,
        input logic [XLEN-1:0]  jal_target,
        input logic [XLEN-1:0]  pc_plus_4,
        input logic [XLEN-1:0]  current_pc
    );
        if (stall) begin : PC_Stall
            return current_pc;        
        end else if (jalr_taken) begin : JALR_Taken
            return jalr_target;          
        end else if (branch_taken) begin : Branch_Taken
            return branch_target;       
        end else if (jal_taken) begin : JAL_Taken
            return jal_target;          
        end else begin : Sequential_Execution
            return pc_plus_4;         
        end
    endfunction

    // --- Next PC Logic ---
    assign pc_plus_4_calc = calc_pc_plus_4(pc_reg);
    
    assign next_pc = select_next_pc(
        stall,
        jalr_taken,
        branch_taken,
        jal_taken,
        jalr_target,
        branch_target,
        jal_target,
        pc_plus_4_calc,
        pc_reg
    );

    // --- Program Counter Register ---
    always_ff @(posedge clk) begin : PC_Register
        if (rst) begin : ResetPC
            pc_reg <= {XLEN{1'b0}};
        end else begin : UpdatePC
            pc_reg <= next_pc;
        end
    end

    // --- Outputs ---
    assign pc_out         = pc_reg;
    assign pc_plus_4      = pc_plus_4_calc;
    assign instruction_out = instruction_in;
endmodule