import riscv_pkg::*;

/**
 * @brief Data Memory Module with Memory-Mapped I/O for RISC-V CPU
 * @details Implements synchronous RAM with support for:
 *          - Unaligned memory access (byte/halfword/word loads and stores)
 *          - Byte-enable control for partial word writes
 *          - Sign-extension and zero-extension for sub-word loads
 *          - Memory-mapped I/O (LED register at 0x80000000)
 *          - RISC-V compliance test support (tohost register)
 * 
 *          Memory Layout:
 *          - 0x00000000 - 0x003FFFFF: RAM (4MB simulation / 16KB FPGA)
 *          - 0x80000000: LED register (write-only, 4 bits)
 *          - 0x80001000: ToHost register (simulation only)
 * 
 * @param clk        System clock
 * @param rst        Synchronous reset (active high)
 * @param MemWrite   Enable memory write
 * @param be         Byte enable [3:0] (be[i]=1 writes byte i)
 * @param funct3     Load/Store type from instruction (LB, LH, LW, LBU, LHU, SB, SH, SW)
 * @param Address    Byte-addressed memory location
 * @param WriteData  Data to write to memory (32 bits)
 * @param ReadData   Data read from memory (sign/zero-extended as needed)
 * @param leds_out   LED output pins (connected to FPGA LEDs)
 */
module DataMemory (
    input  logic             clk,
    input  logic             rst, 
    input  logic             MemWrite,
    input  logic [3:0]       be,
    input  logic [2:0]       funct3,
    input  logic [ALEN-1:0]  Address,
    input  logic [XLEN-1:0]  WriteData,
    output logic [XLEN-1:0]  ReadData, 
    output logic [3:0]       leds_out
);
    // MEMORY ARRAYS
    logic [XLEN-1:0] ram_memory [0:RAM_MEMORY_SIZE];    // Main RAM (size defined in riscv_pkg)
    logic [3:0]      mem_led_reg;                       // 4-bit LED register at 0x80000000
    
    // ADDRESS DECODING
    logic [ALEN-1:0] mem_word_addr;                     // Word-aligned address (Address / 4)
    logic [1:0]      mem_byte_offset;                   // Byte position within word (0-3)
    
    assign mem_word_addr    = Address >> 2;             // Divide by 4 to get word index
    assign mem_byte_offset  = Address[1:0];             // Extract lower 2 bits for byte position
    assign leds_out         = mem_led_reg;              // Connect LED register to output pins

    // PIPELINE REGISTERS
    logic [XLEN-1:0]  mem_rdata_reg;                    // Raw 32-bit word from RAM
    logic [2:0]       mem_funct3_reg;                   // Registered load type (LB/LH/LW/LBU/LHU)
    logic [1:0]       mem_byte_offset_reg;              // Registered byte offset for extraction
    logic [ALEN-1:0]  mem_addr_reg;                     // Registered address for MMIO detection

    // WRITE DATA ALIGNMENT
    logic [XLEN-1:0] mem_wdata_shifted;                 // Write data shifted to align with byte offset

    always_ff @(posedge clk) begin : MemoryAccess
        if (rst) begin : ResetMemory
            mem_led_reg       <= 4'b0000;
            mem_rdata_reg     <= {XLEN{1'b0}};
        end else begin : NormalOperation

            // READ PATH
            if (mem_word_addr < RAM_MEMORY_SIZE) begin : ValidRead
                mem_rdata_reg <= ram_memory[mem_word_addr];    // Read full 32-bit word
            end else begin : OutOfBoundsRead
                mem_rdata_reg <= {XLEN{1'b0}};                 // Out-of-bounds reads return 0
            end

            // Register control signals for next cycle (pipeline stage)
            mem_funct3_reg      <= funct3;
            mem_byte_offset_reg <= mem_byte_offset;
            mem_addr_reg        <= Address;

            // WRITE PATH
            if (MemWrite) begin : MemoryWrite                  
                if (Address == 32'h80000000) begin : LEDWrite
                    mem_led_reg <= WriteData[3:0];             // Update LED register (lower 4 bits)
                end

`ifndef SYNTHESIS
                // RISC-V COMPLIANCE TEST SUPPORT
                else if (Address == 32'h80001000) begin : ToHostWrite
                    if (WriteData[0] == 1'b1) begin : ToHostFinish
                        $display("Simulation hit tohost finish. Status: PASS");
                        dump_signature();
                        $finish;
                    end
                end
`endif
                
                // RAM Write with Byte-Enable Support (SB, SH, SW)
                else if (mem_word_addr < RAM_MEMORY_SIZE) begin : RAMWrite
                    // Shift write data to align with target byte position
                    mem_wdata_shifted = WriteData << (mem_byte_offset * 8);

                    // Write each byte lane individually based on byte-enable
                    // be[0]=byte 0, be[1]=byte 1, be[2]=byte 2, be[3]=byte 3
                    for (int i = 0; i < (XLEN/8); i++) begin : ByteEnableWrite
                        if (be[i]) 
                            ram_memory[mem_word_addr][(i*8)+:8] <= mem_wdata_shifted[(i*8)+:8];
                    end
                end
            end : MemoryWrite
        end : NormalOperation
    end : MemoryAccess

`ifndef SYNTHESIS
    // COMPLIANCE TEST SIGNATURE DUMP 
    task dump_signature;
        integer f;
        integer i;
        begin : DumpSignature
            f = $fopen("signature.txt", "w");
            for (i = 524288; i < 524288 + 2048; i = i + 1) begin : SignatureDumpLoop // 0x200000 / 4 = 524288
                $fwrite(f, "%h\n", ram_memory[i]);                                   // Write each word in hex
            end
            $fclose(f);
            $display("Signature dumped to signature.txt");
        end
    endtask
`endif

    // READ DATA FORMATTING (extracts and sign/zero-extends sub-word loads)
    logic [XLEN-1:0] mem_formatted_rdata;

    always_comb begin : ReadDataFormatting
        case (mem_funct3_reg)
            F3_BYTE: begin : LoadByte
                mem_formatted_rdata = riscv_pkg::sign_extend_byte(riscv_pkg::get_byte(mem_rdata_reg, mem_byte_offset_reg));
            end

            F3_HALF: begin : LoadHalfword
                mem_formatted_rdata = riscv_pkg::sign_extend_half(riscv_pkg::get_halfword(mem_rdata_reg, mem_byte_offset_reg[1]));
            end

            F3_WORD: begin : LoadWord
                mem_formatted_rdata = mem_rdata_reg;
            end

            F3_LBU: begin : LoadByteUnsigned
                mem_formatted_rdata = riscv_pkg::zero_extend_byte(riscv_pkg::get_byte(mem_rdata_reg, mem_byte_offset_reg));
            end

            F3_LHU: begin : LoadHalfwordUnsigned
                mem_formatted_rdata = riscv_pkg::zero_extend_half(riscv_pkg::get_halfword(mem_rdata_reg, mem_byte_offset_reg[1]));
            end

            default: begin : DefaultCase
                mem_formatted_rdata = mem_rdata_reg;  // Fallback: return full word
            end
        endcase
    end

    always_comb begin : OutputMultiplexer
        if (mem_addr_reg == 32'h80000000) begin : LEDRead        // MMIO Read for LEDs
            ReadData = {{(XLEN-LED_WIDTH){1'b0}}, mem_led_reg};  // Return LED register value (zero-extended)
        end else begin : NormalRead
            ReadData = mem_formatted_rdata;                      // Return RAM data with proper formatting
        end
    end

endmodule