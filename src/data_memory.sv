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
    input  logic                  clk,
    input  logic                  rst, 
    input  logic                  MemWrite,
    input  logic [3:0]            be,
    input  logic [2:0]            funct3,
    input  logic [ALEN-1:0]       Address,
    input  logic [XLEN-1:0]       WriteData,
    output logic [XLEN-1:0]       ReadData, 
    output logic [LED_WIDTH-1:0]  leds_out
);
    /**
     * @brief Extract a slice from a word based on size and offset
     * @param word       32-bit input word
     * @param offset     Byte offset (0-3)
     * @param size_bytes Size in bytes (1=byte, 2=half, 4=word)
     * @return           Selected slice, right-aligned
     */
    function automatic logic [31:0] get_slice(
        input logic [31:0] word,
        input logic [1:0]  offset,
        input int          size_bytes
    );
        case (size_bytes)
            1: return {24'b0, word[offset*8 +: 8]};      // Byte
            2: return {16'b0, word[offset[1]*16 +: 16]}; // Halfword (ignore offset[0])
            4: return word;                              // Word
            default: return 32'b0;
        endcase
    endfunction

    /**
     * @brief Sign/zero extend a value to XLEN bits
     * @param value       Input value (up to 32 bits)
     * @param input_bits  Width of input value (8, 16, 32)
     * @param sign_extend 1=sign extend, 0=zero extend
     * @return            XLEN-bit extended value
     */
    function automatic logic [XLEN-1:0] extend_value(
        input logic [31:0] value,
        input int          input_bits,
        input logic        sign_extend
    );
        logic sign_bit;
        case (input_bits)
            8: begin
                sign_bit = sign_extend ? value[7] : 1'b0;
                return {{(XLEN-8){sign_bit}}, value[7:0]};
            end
            16: begin
                sign_bit = sign_extend ? value[15] : 1'b0;
                return {{(XLEN-16){sign_bit}}, value[15:0]};
            end
            32: begin
                return value;
            end
            default: return {XLEN{1'b0}};
        endcase
    endfunction

    /**
     * @brief Write to RAM with byte-enable masking
     * @param word_addr    Word-aligned address in RAM
     * @param data         32-bit data to write
     * @param byte_enables 4-bit byte enable mask
     * @param byte_offset  Byte offset within the word (0-3)
     */
    task automatic write_ram_with_byte_enable(
        input logic [ALEN-1:0]  word_addr,
        input logic [XLEN-1:0]  data,
        input logic [3:0]       byte_enables,
        input logic [1:0]       byte_offset
    );
        logic [XLEN-1:0] shifted_data;
        shifted_data = data << (byte_offset * 8);
        
        for (int i = 0; i < (XLEN/8); i++) begin
            if (byte_enables[i])
                ram_memory[word_addr][(i*8)+:8] <= shifted_data[(i*8)+:8];
        end
    endtask

`ifndef SYNTHESIS
    /**
     * @brief Handle tohost register write (compliance tests)
     * @param data Data written to tohost register
     */
    task automatic handle_tohost_write(input logic [XLEN-1:0] data);
        if (data[0] == 1'b1) begin
            $display("Simulation hit tohost finish. Status: PASS");
            dump_signature();
            $finish;
        end
    endtask

    /**
     * @brief Dump signature memory region to file
     * This is used for RISC-V compliance tests.
     */
    task dump_signature;
        integer f, i;
        f = $fopen("signature.txt", "w");
        for (i = 524288; i < 524288 + 2048; i = i + 1)
            $fwrite(f, "%h\n", ram_memory[i]);
        $fclose(f);
        $display("Signature dumped to signature.txt");
    endtask
`endif

    // --- Memory and Registers ---
    logic [XLEN-1:0]       ram_memory [0:RAM_MEMORY_SIZE]; 
    logic [LED_WIDTH-1:0]  mem_led_reg;                   
    logic [ALEN-1:0]       mem_word_addr;                   
    logic [1:0]            mem_byte_offset;                   
    logic [XLEN-1:0]       mem_rdata_reg;                   // Full 32-bit word from RAM
    logic [2:0]            mem_funct3_reg;                  // Registered load type (LB/LH/LW/LBU/LHU)
    logic [1:0]            mem_byte_offset_reg;             // Registered byte offset for extraction
    logic [ALEN-1:0]       mem_addr_reg;                    // Registered address for MMIO detection
    logic [XLEN-1:0]       mem_wdata_shifted;               // Write data shifted to align with byte offset

    // --- Synchronous Memory Access ---
    assign mem_word_addr    = Address >> 2;                 // Get word address by shifting right 2
    assign mem_byte_offset  = Address[1:0];                 // Extract lower 2 bits for byte position
    assign leds_out         = mem_led_reg;                  // Connect LED register to output pins

    always_ff @(posedge clk) begin : MemoryAccess
        if (rst) begin : ResetMemory
            mem_led_reg       <= {LED_WIDTH{1'b0}};
            mem_rdata_reg     <= {XLEN{1'b0}};
        end else begin : NormalOperation

            if (mem_word_addr < RAM_MEMORY_SIZE) begin : ReadOperation
                mem_rdata_reg <= ram_memory[mem_word_addr];         
            end else begin : OutOfBoundsRead
                mem_rdata_reg <= {XLEN{1'b0}};                      
            end

            // --- Register Data for Next Cycle ---
            mem_funct3_reg      <= funct3;                          
            mem_byte_offset_reg <= mem_byte_offset;                 
            mem_addr_reg        <= Address;                         

            if (MemWrite) begin : WriteOperation                  
                if (Address == MMIO_LED_ADDR) begin : WriteLED
                    mem_led_reg <= WriteData[LED_WIDTH-1:0];                
                end

                `ifndef SYNTHESIS
                // --- RISC-V Compliance Test ToHost Register Write ---
                else if (Address == MMIO_TOHOST_ADDR) begin : WriteToHost
                    handle_tohost_write(WriteData);
                end
                `endif
                
                else if (mem_word_addr < RAM_MEMORY_SIZE) begin : WriteRAM
                    write_ram_with_byte_enable(mem_word_addr, WriteData, be, mem_byte_offset);
                end
            end
        end 
    end

    // --- Read Data Formatting ---
    logic [XLEN-1:0] mem_formatted_rdata;

    always_comb begin : ReadDataFormatting
        case (mem_funct3_reg)
            F3_BYTE: begin : LoadByte
                mem_formatted_rdata = extend_value(get_slice(mem_rdata_reg, mem_byte_offset_reg, 1), 8, 1'b1);
            end

            F3_HALF: begin : LoadHalfword
                mem_formatted_rdata = extend_value(get_slice(mem_rdata_reg, mem_byte_offset_reg, 2), 16, 1'b1);
            end

            F3_WORD: begin : LoadWord
                mem_formatted_rdata = mem_rdata_reg;
            end

            F3_LBU: begin : LoadByteUnsigned
                mem_formatted_rdata = extend_value(get_slice(mem_rdata_reg, mem_byte_offset_reg, 1), 8, 1'b0);
            end

            F3_LHU: begin : LoadHalfwordUnsigned
                mem_formatted_rdata = extend_value(get_slice(mem_rdata_reg, mem_byte_offset_reg, 2), 16, 1'b0);
            end

            default: begin : DefaultCase
                mem_formatted_rdata = mem_rdata_reg;   
            end
        endcase
    end

    always_comb begin : OutputMultiplexer
        if (mem_addr_reg == MMIO_LED_ADDR) begin : LEDRead       // MMIO Read for LEDs
            ReadData = {{(XLEN-LED_WIDTH){1'b0}}, mem_led_reg};  // Return LED register value (zero-extended)
        end else begin : NormalRead
            ReadData = mem_formatted_rdata;                      // Return RAM data with formatted data
        end
    end

endmodule