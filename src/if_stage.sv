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
    logic [XLEN-1:0] if_pc_reg;
    logic [XLEN-1:0] if_next_pc;
    logic [XLEN-1:0] if_pc_plus_4_calc;

    assign if_pc_plus_4_calc = calc_pc_plus_4(if_pc_reg);
    assign if_next_pc = select_next_pc(
        stall,
        jalr_taken,
        branch_taken,
        jal_taken,
        jalr_target,
        branch_target,
        jal_target,
        if_pc_plus_4_calc,
        if_pc_reg
    );

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