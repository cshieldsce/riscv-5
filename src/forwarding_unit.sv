import riscv_pkg::*;

/**
 * @brief Forwarding Unit
 * @details Solves Data Hazards by forwarding data from later pipeline stages (MEM, WB) 
 *          to the EX stage, bypassing the Register File.
 * 
 *          Logic Priorities:
 *          1. EX Hazard (Highest): Data is in the EX/MEM pipeline register (just computed).
 *          2. MEM Hazard (Lowest): Data is in the MEM/WB pipeline register (waiting for WB).
 *             - Note: Only forward from MEM/WB if the EX/MEM stage is NOT writing to the 
 *               same register (Double Hazard condition).
 * 
 * @param id_ex_rs1        Source Register 1 from ID/EX Pipeline Register
 * @param id_ex_rs2        Source Register 2 from ID/EX Pipeline Register
 * @param ex_mem_rd        Destination Register from EX/MEM Pipeline Register
 * @param ex_mem_reg_write Register Write Enable from EX/MEM Pipeline Register
 * @param mem_wb_rd        Destination Register from MEM/WB Pipeline Register
 * @param mem_wb_reg_write Register Write Enable from MEM/WB Pipeline Register
 * @param forward_a        Output: Forwarding MUX A Select (00=Reg, 10=MEM, 01=WB)
 * @param forward_b        Output: Forwarding MUX B Select (00=Reg, 10=MEM, 01=WB)
 */
module ForwardingUnit (
    input  logic [4:0] id_ex_rs1,       // Source register 1 address (EX stage)
    input  logic [4:0] id_ex_rs2,       // Source register 2 address (EX stage)
    
    // Inputs from MEM stage (The instruction immediately preceding the one in EX)
    input  logic [4:0] ex_mem_rd,       // Destination register address
    input  logic       ex_mem_reg_write,// Register write enable
    
    // Inputs from WB stage (The instruction 2 cycles ahead of the one in EX)
    input  logic [4:0] mem_wb_rd,       // Destination register address
    input  logic       mem_wb_reg_write,// Register write enable
    
    output logic [1:0] forward_a,       // Forwarding MUX A select: 00=Reg, 10=MEM, 01=WB
    output logic [1:0] forward_b        // Forwarding MUX B select: 00=Reg, 10=MEM, 01=WB
);

    // --- LOCAL HELPER FUNCTIONS ---
    
    /**
     * @brief Check if EX/MEM stage creates a data hazard
     * @param rd Destination register from EX/MEM stage
     * @param rs Source register in ID/EX stage
     * @param reg_write Write enable from EX/MEM stage
     * @return True if hazard exists
     */
    function automatic logic has_ex_hazard(
        input logic [4:0] rd,
        input logic [4:0] rs,
        input logic reg_write
    );
        return reg_write && (rd != 5'b0) && (rd == rs);
    endfunction

    /**
     * @brief Check if MEM/WB stage creates a data hazard
     * @param mem_rd Destination register from MEM/WB stage
     * @param ex_rd Destination register from EX/MEM stage
     * @param rs Source register in ID/EX stage
     * @param mem_reg_write Write enable from MEM/WB stage
     * @param ex_reg_write Write enable from EX/MEM stage
     * @return True if hazard exists (and EX hazard does NOT take precedence)
     */
    function automatic logic has_mem_hazard(
        input logic [4:0] mem_rd,
        input logic [4:0] ex_rd,
        input logic [4:0] rs,
        input logic mem_reg_write,
        input logic ex_reg_write
    );
        logic mem_match, ex_match;
        mem_match = mem_reg_write && (mem_rd != 5'b0) && (mem_rd == rs);
        ex_match  = ex_reg_write && (ex_rd != 5'b0) && (ex_rd == rs);
        
        // Forward from MEM/WB only if no EX hazard (double hazard prevention)
        return mem_match && !ex_match;
    endfunction

    // --- Forwarding Logic ---
    
    always_comb begin : ForwardingLogic
        // Default: No forwarding (use values read from Register File in ID stage)
        forward_a = 2'b00;
        forward_b = 2'b00;

        if (has_ex_hazard(ex_mem_rd, id_ex_rs1, ex_mem_reg_write)) begin : EXHazardA
            forward_a = 2'b10;
        end
        
        if (has_ex_hazard(ex_mem_rd, id_ex_rs2, ex_mem_reg_write)) begin : EXHazardB
            forward_b = 2'b10;
        end

        if (has_mem_hazard(mem_wb_rd, ex_mem_rd, id_ex_rs1, mem_wb_reg_write, ex_mem_reg_write)) begin : MEMHazardA
            forward_a = 2'b01;
        end
        
        if (has_mem_hazard(mem_wb_rd, ex_mem_rd, id_ex_rs2, mem_wb_reg_write, ex_mem_reg_write)) begin : MEMHazardB
            forward_b = 2'b01;
        end
    end

endmodule