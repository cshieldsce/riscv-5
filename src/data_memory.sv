import riscv_pkg::*;

module DataMemory #(
    parameter CLKS_PER_BIT = 87
)(
    input  logic             clk,
    input  logic             rst, 
    input  logic             MemWrite,
    input  logic [3:0]       be,
    input  logic [2:0]       funct3,
    input  logic [ALEN-1:0]  Address,
    input  logic [XLEN-1:0]  WriteData,
    output logic [XLEN-1:0]  ReadData, 
    output logic [3:0]       leds_out,
    output logic             uart_tx_wire
);
    
    // UART TX Instance
    logic [7:0] uart_data;
    logic       uart_start;
    logic       uart_busy;

    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) uart_inst (
        .clk(clk),
        .rst(rst),
        .tx_start(uart_start),
        .tx_data(uart_data),
        .tx(uart_tx_wire),
        .tx_busy(uart_busy),
        .tx_done()
    );

`ifndef SYNTHESIS
    logic [31:0] ram_memory [0:1048575]; // 4MB for Simulation
`else
    logic [31:0] ram_memory [0:4095];    // 16KB for FPGA
`endif

    logic [3:0]  led_reg;
    
    logic [ALEN-1:0] word_addr;
    logic [1:0]      byte_offset;
    
    assign word_addr = Address >> 2;          
    assign byte_offset = Address[1:0];        
    assign leds_out = led_reg;

    // Pipeline registers
    logic [31:0] mem_read_word_reg;
    logic [2:0]  funct3_reg;
    logic [1:0]  byte_offset_reg;
    logic [ALEN-1:0] address_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            led_reg <= 4'b0000;     // EXPLICIT RESET
            uart_start <= 1'b0;
            mem_read_word_reg <= 32'b0;
        end else begin
            // READ: Always read (synchronous BRAM behavior)
`ifndef SYNTHESIS
            if (word_addr < 1048576) 
`else
            if (word_addr < 4096) 
`endif
                mem_read_word_reg <= ram_memory[word_addr];
            else
                mem_read_word_reg <= 32'b0;

            funct3_reg <= funct3;
            byte_offset_reg <= byte_offset;
            address_reg <= Address;

            // WRITE
            if (MemWrite) begin
                // 1. LED Register (0x80000000)
                if (Address == 32'h80000000) begin
                    led_reg <= WriteData[3:0];
                end
                
                // 2. UART TX Register (0x80000004)
                else if (Address == 32'h80000004) begin
                    if (!uart_busy) begin
                        uart_data  <= WriteData[7:0];
                        uart_start <= 1'b1;
                    end
                end

`ifndef SYNTHESIS
                // 3. ToHost (0x80001000) - Compliance Trigger
                else if (Address == 32'h80001000) begin
                    if (WriteData[0] == 1'b1) begin
                        $display("Simulation hit tohost finish. Status: PASS");
                        dump_signature();
                        $finish;
                    end
                end
`endif
                
                // 4. RAM Write (Byte Enabled)
`ifndef SYNTHESIS
                else if (word_addr < 1048576) begin
`else
                else if (word_addr < 4096) begin
`endif
                    logic [31:0] wdata_shifted;
                    wdata_shifted = WriteData << (byte_offset * 8);

                    if (be[0]) ram_memory[word_addr][7:0]   <= wdata_shifted[7:0];
                    if (be[1]) ram_memory[word_addr][15:8]  <= wdata_shifted[15:8];
                    if (be[2]) ram_memory[word_addr][23:16] <= wdata_shifted[23:16];
                    if (be[3]) ram_memory[word_addr][31:24] <= wdata_shifted[31:24];
                end
            end else begin
                uart_start <= 1'b0;
            end
        end
    end

`ifndef SYNTHESIS
    task dump_signature;
        integer f;
        integer i;
        begin
            f = $fopen("signature.txt", "w");
            // Dump the data section starting at 0x200000 (Word index 524288)
            // Dump 4KB worth of data (1024 words) which should cover the signature
            for (i = 524288; i < 524288 + 2048; i = i + 1) begin
                $fwrite(f, "%h\n", ram_memory[i]);
            end
            $fclose(f);
            $display("Signature dumped to signature.txt");
        end
    endtask
`endif

    logic [XLEN-1:0] formatted_read_data;

    // READ FORMATTING (combinational)
    always_comb begin
        case (funct3_reg)
            F3_BYTE: begin
                case (byte_offset_reg)
                    2'b00: formatted_read_data = {{(XLEN-8){mem_read_word_reg[7]}},  mem_read_word_reg[7:0]};
                    2'b01: formatted_read_data = {{(XLEN-8){mem_read_word_reg[15]}}, mem_read_word_reg[15:8]};
                    2'b10: formatted_read_data = {{(XLEN-8){mem_read_word_reg[23]}}, mem_read_word_reg[23:16]};
                    2'b11: formatted_read_data = {{(XLEN-8){mem_read_word_reg[31]}}, mem_read_word_reg[31:24]};
                    default: formatted_read_data = 32'b0;
                endcase
            end
            F3_HALF: begin
                case (byte_offset_reg[1])
                    1'b0: formatted_read_data = {{(XLEN-16){mem_read_word_reg[15]}}, mem_read_word_reg[15:0]};
                    1'b1: formatted_read_data = {{(XLEN-16){mem_read_word_reg[31]}}, mem_read_word_reg[31:16]};
                    default: formatted_read_data = 32'b0;
                endcase
            end
            F3_WORD: formatted_read_data = mem_read_word_reg;
            F3_LBU: begin
                case (byte_offset_reg)
                    2'b00: formatted_read_data = {{(XLEN-8){1'b0}}, mem_read_word_reg[7:0]};
                    2'b01: formatted_read_data = {{(XLEN-8){1'b0}}, mem_read_word_reg[15:8]};
                    2'b10: formatted_read_data = {{(XLEN-8){1'b0}}, mem_read_word_reg[23:16]};
                    2'b11: formatted_read_data = {{(XLEN-8){1'b0}}, mem_read_word_reg[31:24]};
                    default: formatted_read_data = 32'b0;
                endcase
            end
            F3_LHU: begin
                case (byte_offset_reg[1])
                    1'b0: formatted_read_data = {{(XLEN-16){1'b0}}, mem_read_word_reg[15:0]};
                    1'b1: formatted_read_data = {{(XLEN-16){1'b0}}, mem_read_word_reg[31:16]};
                    default: formatted_read_data = 32'b0;
                endcase
            end
            default: formatted_read_data = mem_read_word_reg;
        endcase
    end

    // MMIO Read Multiplexer
    always_comb begin
        if (address_reg == 32'h80000008) begin
            ReadData = {31'b0, uart_busy}; // UART Status: bit 0 is busy
        end else if (address_reg == 32'h80000000) begin
            ReadData = {28'b0, led_reg};   // Optional: Read back LED values
        end else begin
            ReadData = formatted_read_data;
        end
    end

endmodule