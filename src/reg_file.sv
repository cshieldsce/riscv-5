import riscv_pkg::*;

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

    logic [XLEN-1:0] register_memory [0:31];

    // ASYNC READ (With x0 Protection)
    assign read_data1 = (rs1 == 5'b0) ? 32'b0 : register_memory[rs1];
    assign read_data2 = (rs2 == 5'b0) ? 32'b0 : register_memory[rs2];

    // SYNCHRONOUS WRITE
    always_ff @(posedge clk) begin
        if (rst) begin
             for (int i=0; i<32; i++) register_memory[i] <= 0;
        end else if (RegWrite && (rd != 5'b0)) begin
             register_memory[rd] <= write_data;
        end
    end
    
    initial begin
        for (int i=0; i<32; i++) register_memory[i] = 0;
    end

endmodule