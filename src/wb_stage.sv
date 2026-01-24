import riscv_pkg::*;

/**
 * @brief Writeback Stage (WB)
 * 
 * Selects the final data to be written back to the Register File.
 * Muxes between ALU result, Memory Read Data (for loads), and PC+4 (for jumps).
 */
module WB_Stage (
    input  logic [1:0]       mem_wb_mem_to_reg,
    input  logic [XLEN-1:0]  mem_wb_alu_result,
    input  logic [XLEN-1:0]  mem_wb_pc_plus_4,
    input  logic [XLEN-1:0]  dmem_read_data,    // Direct from Memory (Bypass)

    output logic [XLEN-1:0]  wb_write_data
);

    // --- Write Back Mux ---
    always_comb begin : WriteBackMUX
        case (mem_wb_mem_to_reg)
            2'b00: wb_write_data = mem_wb_alu_result;     // ALU instructions
            2'b01: wb_write_data = dmem_read_data;        // Load instructions (Memory read)
            2'b10: wb_write_data = mem_wb_pc_plus_4;      // JAL/JALR (Return address)
            default: wb_write_data = {XLEN{1'b0}};
        endcase
    end

endmodule