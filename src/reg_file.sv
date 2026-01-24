import riscv_pkg::*;

/**
 * @brief 32x32-bit RISC-V Register File (x0-x31)
 * 
 * Features:
 *  - Asynchronous dual-port reads
 *  - Synchronous write on posedge clk
 *  - x0 hardwired to zero
 *  - Write-through forwarding to resolve WB-to-ID hazards
 * 
 * Write-Through Forwarding:
 *  If an instruction reads a register in the same cycle it's being written,
 *  the new value is forwarded directly, bypassing the memory array.
 */
module RegFile (
    input  logic             clk,
    input  logic             rst,
    input  logic             RegWrite,       // Write enable
    
    input  logic [4:0]       rs1,            // Read address 1
    input  logic [4:0]       rs2,            // Read address 2
    input  logic [4:0]       rd,             // Write address
    input  logic [XLEN-1:0]  write_data,     // Write data
    
    output logic [XLEN-1:0]  read_data1,     // Read data 1
    output logic [XLEN-1:0]  read_data2      // Read data 2
);

    // --- Register Memory ---
    
    logic [XLEN-1:0] register_memory [0:REG_SIZE-1];

    // --- Local Helper Functions ---
    
    /**
     * @brief Check if write-through forwarding is needed
     * @param rs Source register being read
     * @param rd Destination register being written
     * @param reg_write Write enable signal
     * @return True if forwarding should occur
     */
    function automatic logic should_forward(
        input logic [4:0] rs,
        input logic [4:0] rd,
        input logic       reg_write
    );
        return reg_write && (rs != 5'b0) && (rs == rd);
    endfunction

    /**
     * @brief Read register value with x0 hardwiring and forwarding
     * @param rs Source register address
     * @param rd Destination register being written
     * @param reg_write Write enable signal
     * @param write_data Data being written
     * @return Register value (0 for x0, forwarded data, or memory value)
     */
    function automatic logic [XLEN-1:0] read_register(
        input logic [4:0]       rs,
        input logic [4:0]       rd,
        input logic             reg_write,
        input logic [XLEN-1:0]  write_data
    );
        if (rs == 5'b0) begin : ReadX0
            return {XLEN{1'b0}}; // As per RISC-V Spec: x0 is always 0
        end else if (should_forward(rs, rd, reg_write)) begin : WBForwarding
            return write_data;
        end else begin : NormalRead
            return register_memory[rs];
        end
    endfunction

    // --- Asynchronous Read Ports ---
    
    assign read_data1 = read_register(rs1, rd, RegWrite, write_data);
    assign read_data2 = read_register(rs2, rd, RegWrite, write_data);

    // --- Synchronous Write Port ---
    
    always_ff @(posedge clk) begin: WriteRegister
        if (rst) begin : ResetRegisters
            for (int i = 0; i < REG_SIZE; i++) begin : ZeroReset
                register_memory[i] <= {XLEN{1'b0}};
            end
        end else if (RegWrite && (rd != 5'b0)) begin : WriteEnable
            register_memory[rd] <= write_data;
        end
    end

    // --- Initialization ---
    
    initial begin : InitRegisters
        for (int i = 0; i < REG_SIZE; i++) begin : ZeroInit
            register_memory[i] = {XLEN{1'b0}};
        end
    end

endmodule