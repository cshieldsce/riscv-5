import riscv_pkg::*;

/**
 * @brief Writeback Stage (WB)
 * @details Selects the final data to be written back to the Register File.
 *          Muxes between ALU result, Memory Read Data (for loads), and PC+4 (for jumps).
 * 
 * @param mem_wb_mem_to_reg Control Signal: Selects write back source (0=ALU, 1=MEM, 2=PC+4)
 * @param mem_wb_alu_result ALU Result from MEM stage
 * @param mem_wb_pc_plus_4  PC+4 from MEM stage (for JAL/JALR)
 * @param dmem_read_data    Data read from Data Memory (from MEM stage)
 * @param wb_write_data     Final Data to be written to Register File
 */
module WB_Stage (
    input  logic [1:0]       mem_wb_wb_mux_sel,
    input  logic [XLEN-1:0]  mem_wb_alu_result,
    input  logic [XLEN-1:0]  mem_wb_pc_plus_4,
    input  logic [XLEN-1:0]  dmem_read_data,   
    output logic [XLEN-1:0]  wb_write_data
);
    always_comb begin : WriteBackMUX
        case (mem_wb_wb_mux_sel)
            2'b00: wb_write_data = mem_wb_alu_result;     // ALU instructions
            2'b01: wb_write_data = dmem_read_data;        // Load instructions (Memory read)
            2'b10: wb_write_data = mem_wb_pc_plus_4;      // JAL/JALR (Return address)
            default: wb_write_data = {XLEN{1'b0}};        // Fallback: Zero
        endcase
    end

endmodule