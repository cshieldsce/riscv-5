import riscv_pkg::*;

/**
 * @brief Memory Stage (MEM)
 * 
 * Handles data memory access operations. 
 * Includes forwarding logic for store instructions to ensure the latest data 
 * is written to memory if it was just modified in the WB stage.
 * Generates correct byte enables for sub-word stores.
 */
module MEM_Stage (
    input  logic             clk,         
    input  logic             rst,
    
    // Inputs from EX/MEM Pipeline Register
    input  logic             ex_mem_reg_write,
    input  logic             ex_mem_mem_write,
    input  logic [1:0]       ex_mem_mem_to_reg, // Used to check if we are reading
    input  logic [XLEN-1:0]  ex_mem_alu_result,
    input  logic [XLEN-1:0]  ex_mem_write_data, // Data to store (Rs2)
    input  logic [4:0]       ex_mem_rd,
    input  logic [2:0]       ex_mem_funct3,
    input  logic [4:0]       ex_mem_rs2,        // Source register for store data

    // Inputs from WB Stage (for Forwarding)
    input  logic             wb_reg_write,
    input  logic [4:0]       wb_rd,
    input  logic [XLEN-1:0]  wb_write_data,

    // Outputs to Data Memory
    output logic [ALEN-1:0]  dmem_addr,
    output logic [XLEN-1:0]  dmem_wdata,
    output logic             dmem_we,
    output logic [3:0]       dmem_be,
    output logic [2:0]       dmem_funct3
);

    // --- Local Helper Functions ---
    
    /**
     * @brief Check if WB stage should forward to MEM stage store data
     * @param wb_reg_write Register write enable from WB stage
     * @param wb_rd Destination register from WB stage
     * @param mem_rs2 Source register for store data in MEM stage
     * @return True if forwarding is required
     */
    function automatic logic should_forward_store_data(
        input logic       wb_reg_write,
        input logic [4:0] wb_rd,
        input logic [4:0] mem_rs2
    );
        return wb_reg_write && (wb_rd != 5'b0) && (wb_rd == mem_rs2);
    endfunction

    /**
     * @brief Select correct store data (with forwarding if needed)
     * @param wb_reg_write Register write enable from WB stage
     * @param wb_rd Destination register from WB stage
     * @param mem_rs2 Source register for store data in MEM stage
     * @param wb_data Data from WB stage
     * @param mem_data Original data from EX/MEM register
     * @return Forwarded data if hazard exists, otherwise original data
     */
    function automatic logic [XLEN-1:0] get_store_data(
        input logic              wb_reg_write,
        input logic [4:0]        wb_rd,
        input logic [4:0]        mem_rs2,
        input logic [XLEN-1:0]   wb_data,
        input logic [XLEN-1:0]   mem_data
    );
        if (should_forward_store_data(wb_reg_write, wb_rd, mem_rs2)) begin : ForwardStoreData
            return wb_data;
        end else begin : NoForwardStoreData
            return mem_data;
        end
    endfunction

    // --- Store Data Forwarding ---
    logic [XLEN-1:0] mem_store_data;

    // Solves hazard: Store instruction follows an instruction writing to the store's source register.
    assign mem_store_data = get_store_data(
        wb_reg_write,
        wb_rd,
        ex_mem_rs2,
        wb_write_data,
        ex_mem_write_data
    );

    // --- Memory Interface ---
    assign dmem_addr   = ex_mem_alu_result;
    assign dmem_wdata  = mem_store_data;
    assign dmem_we     = ex_mem_mem_write;
    assign dmem_funct3 = ex_mem_funct3;

    // Byte Enable Generation
    assign dmem_be = riscv_pkg::get_byte_enable(ex_mem_funct3, ex_mem_alu_result[1:0]);

endmodule