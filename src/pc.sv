import riscv_pkg::*;

/**
 * @brief Program Counter (PC) Register
 * 
 * Holds the address of the current instruction.
 * Updates synchronously on the rising edge of the clock.
 * 
 * @param clk     System clock
 * @param rst     System reset (Active High) - Resets PC to 0x00000000
 * @param pc_in   Next PC value
 * @param pc_out  Current PC value
 */
module PC (
    input  logic            clk, 
    input  logic            rst,
    input  logic [XLEN-1:0] pc_in,
    output logic [XLEN-1:0] pc_out = {XLEN{1'b0}} // Initialize to 0
);

    always_ff @(posedge clk) begin : PC_Update
        if (rst) begin : ResetPC
            pc_out <= {XLEN{1'b0}};
        end else begin : UpdatePC
            pc_out <= pc_in;
        end
    end

endmodule