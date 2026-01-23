import riscv_pkg::*;

/*
 * Module: RegFile
 * 
 * Description:
 *  32x32-bit Register File (x0-x31).
 *  - Reads are asynchronous.
 *  - Writes are synchronous on posedge clk.
 *  - x0 is hardwired to 0.
 *  - Supports write-through forwarding to resolve WB-to-ID hazards.
 *
 * Inputs:
 *  - clk, rst: System clock and reset
 *  - RegWrite: Write enable signal
 *  - rs1, rs2: Read addresses (5-bit)
 *  - rd: Write address (5-bit)
 *  - write_data: Data to write (32-bit)
 *
 * Outputs:
 *  - read_data1: Data from rs1
 *  - read_data2: Data from rs2
 */
module RegFile (
    input  logic             clk,
    input  logic             rst,
    input  logic             RegWrite,
    
    input  logic [4:0]       rs1,         
    input  logic [4:0]       rs2,         
    input  logic [4:0]       rd,          
    input  logic [XLEN-1:0]  write_data,  
    
    output logic [XLEN-1:0]  read_data1, 
    output logic [XLEN-1:0]  read_data2
);

    logic [XLEN-1:0] register_memory [0:REG_SIZE-1]; // 32 registers of XLEN bits

    // ASYNC READ (With x0 Protection and Write-Through Forwarding)
    // If reading from the register currently being written, bypass the memory and use write_data.
    assign read_data1 = (rs1 == 5'b0) ? 32'b0 : 
                        ((rs1 == rd) && RegWrite) ? write_data : register_memory[rs1];
                        
    assign read_data2 = (rs2 == 5'b0) ? 32'b0 : 
                        ((rs2 == rd) && RegWrite) ? write_data : register_memory[rs2];

    // SYNCHRONOUS WRITE
    always_ff @(posedge clk) begin
        if (rst) begin
             for (int i=0; i<REG_SIZE; i++) register_memory[i] <= 0;
        end else if (RegWrite && (rd != 5'b0)) begin
             register_memory[rd] <= write_data;
        end
    end
    
    initial begin
        for (int i=0; i<REG_SIZE; i++) register_memory[i] = 0;
    end

endmodule