import riscv_pkg::*;

/**
 * @brief Memory Stage (MEM)
 * @details Handles data memory access operations. 
 *          Includes forwarding logic for store instructions to ensure the latest data 
 *          is written to memory if it was just modified in the WB stage.
 *          Generates correct byte enables for sub-word stores.
 * 
 * @param clk               System Clock
 * @param rst               System Reset (Active High)
 * @param ex_mem_mem_write  Memory Write Enable from EX/MEM
 * @param ex_mem_alu_result ALU Result (Memory Address) from EX/MEM
 * @param ex_mem_write_data Data to Store (rs2) from EX/MEM
 * @param ex_mem_funct3     Funct3 (Store Type) from EX/MEM
 * @param ex_mem_rs2        Source Register Address for Store Data
 * @param wb_reg_write      Register Write Enable from WB (for Forwarding)
 * @param wb_rd             Destination Register from WB (for Forwarding)
 * @param wb_write_data     Write Back Data from WB (for Forwarding)
 * @param dmem_addr         Data Memory Address
 * @param dmem_wdata        Data Memory Write Data
 * @param dmem_we           Data Memory Write Enable
 * @param dmem_be           Data Memory Byte Enable
 * @param dmem_funct3       Data Memory Access Type
 */
module MEM_Stage (
    input  logic             clk,         
    input  logic             rst,
    input  logic             ex_mem_mem_write,
    input  logic [XLEN-1:0]  ex_mem_alu_result,
    input  logic [XLEN-1:0]  ex_mem_write_data,
    input  logic [2:0]       ex_mem_funct3,
    input  logic [4:0]       ex_mem_rs2,    
    input  logic             wb_reg_write,
    input  logic [4:0]       wb_rd,
    input  logic [XLEN-1:0]  wb_write_data,
    output logic [ALEN-1:0]  dmem_addr,
    output logic [XLEN-1:0]  dmem_wdata,
    output logic             dmem_we,
    output logic [3:0]       dmem_be,
    output logic [2:0]       dmem_funct3
);
    /**
     * @brief Generate byte enable mask based on funct3 and address alignment
     * @param funct3     Memory operation type (byte, half, word)
     * @param addr_lsb   Lower 2 bits of the address
     * @return           4-bit byte enable mask
     */
    function automatic logic [3:0] get_byte_enable(logic [2:0] funct3, logic [1:0] addr_lsb);
        case (funct3)
            F3_BYTE: begin : ByteEnable
                case (addr_lsb)
                    2'b00: return 4'b0001;
                    2'b01: return 4'b0010;
                    2'b10: return 4'b0100;
                    2'b11: return 4'b1000;
                endcase
            end
            F3_HALF: begin : HalfwordEnable
                case (addr_lsb[1])
                    1'b0: return 4'b0011;
                    1'b1: return 4'b1100;
                endcase
            end
            default: return 4'b1111; // F3_WORD or others
        endcase
    endfunction

    /**
     * @brief Check if WB stage should forward to MEM stage store data
     * @param wb_reg_write Register write enable from WB stage
     * @param wb_rd Destination register from WB stage
     * @param mem_rs2 Source register for store data in MEM stage
     * @return True if wb_reg_write is enabled and wb_rd matches mem_rs2 (and wb_rd != x0)
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
    logic [XLEN-1:0] mem_store_data_fwd;

    assign mem_store_data_fwd = get_store_data(
        wb_reg_write,
        wb_rd,
        ex_mem_rs2,
        wb_write_data,
        ex_mem_write_data
    );

    // --- Memory Interface ---
    assign dmem_addr   = ex_mem_alu_result;
    assign dmem_wdata  = mem_store_data_fwd;
    assign dmem_we     = ex_mem_mem_write;
    assign dmem_funct3 = ex_mem_funct3;

    // --- Byte Enable Generation ---
    assign dmem_be = get_byte_enable(ex_mem_funct3, ex_mem_alu_result[1:0]);

endmodule