import riscv_pkg::*;

/**
 * @brief Generic Pipeline Register
 * 
 * Stores data between pipeline stages to separate combinational logic blocks.
 * Supports synchronous reset, synchronous clear (flush), and enable (stall).
 * 
 * @param WIDTH   Width of the data bus to store (default: 32)
 * 
 * @param clk     System clock
 * @param rst     System reset (Active High)
 * @param en      Enable signal (1 = Update, 0 = Hold/Stall)
 * @param clear   Synchronous Clear/Flush (1 = Reset to 0, used for control hazards)
 * @param in      Input data from previous stage
 * @param out     Output data to next stage
 */
module PipelineRegister #(
    parameter WIDTH = 32
)(
    input  logic             clk, 
    input  logic             rst, 
    input  logic             en,    // Enable (High for normal op, Low for Stall)
    input  logic             clear, // Flush (High to clear register)
    input  logic [WIDTH-1:0] in,    // Data Input
    output logic [WIDTH-1:0] out    // Data Output
);

    always_ff @(posedge clk) begin : PipelineRegLogic
        if (rst) begin
            out <= '0; 
        end else if (clear) begin : Flush
            out <= '0; 
        end else if (en) begin : Update
            out <= in; 
        end
        // Else: Hold current value (Stall)
    end

endmodule