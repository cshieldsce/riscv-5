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
        for (i = (524288/4); i < (524288/4) + 2048; i = i + 1)
            $fwrite(f, "%h\n", ram_memory[i]);
        $fclose(f);
        $display("Signature dumped to signature.txt");
    endtask
`endif

    // --- Memory and Registers ---
    localparam int RAM_ADDR_BITS = $clog2(RAM_MEMORY_SIZE);

    // Word-addressed RAM for BRAM inference
    (* ram_style = "block" *) logic [XLEN-1:0] ram_memory [0:RAM_MEMORY_SIZE-1];
    logic [LED_WIDTH-1:0]  mem_led_reg;
    logic [RAM_ADDR_BITS-1:0] mem_word_addr;
    logic [1:0]            mem_byte_offset;
    logic [XLEN-1:0]       mem_rdata_word;
    logic [2:0]            mem_funct3_reg;
    logic [1:0]            mem_byte_offset_reg;
    logic [ALEN-1:0]       mem_addr_reg;

    // --- Address Decode (Combinational) ---
    always_comb begin : AddressDecode
        mem_word_addr   = Address[RAM_ADDR_BITS+1:2];
        mem_byte_offset = Address[1:0];
    end

    // --- Write Logic (Combinational) ---
    logic [3:0] mem_wren;

    always_comb begin : WriteEnableGen
        mem_wren = MemWrite ? be : 4'b0;
    end

    // --- Combined Read/Write Logic (Synchronous) ---
    always_ff @(posedge clk) begin : RAM_Access_Logic
        // --- Write Port ---
        if (mem_wren[0]) ram_memory[mem_word_addr][7:0]   <= WriteData[7:0];
        if (mem_wren[1]) ram_memory[mem_word_addr][15:8]  <= WriteData[15:8];
        if (mem_wren[2]) ram_memory[mem_word_addr][23:16] <= WriteData[23:16];
        if (mem_wren[3]) ram_memory[mem_word_addr][31:24] <= WriteData[31:24];

        // --- Read Port ---
        if (mem_word_addr < RAM_MEMORY_SIZE) begin : ReadOperation
            mem_rdata_word <= ram_memory[mem_word_addr];
        end else begin : OutOfBoundsRead
            mem_rdata_word <= {XLEN{1'b0}};
        end

        // --- MMIO LED Register Write ---
        if (rst) begin
             mem_led_reg <= {LED_WIDTH{1'b0}};
        end else if (MemWrite && (Address == MMIO_LED_ADDR)) begin
            mem_led_reg <= WriteData[LED_WIDTH-1:0];                
        end

        mem_funct3_reg      <= funct3;
        mem_byte_offset_reg <= Address[1:0];
        mem_addr_reg        <= Address;
    end

    // --- Read Data Formatting (Combinational) ---
    logic [XLEN-1:0] mem_formatted_rdata;

    always_comb begin : ReadDataFormatting
        case (mem_funct3_reg)
            F3_BYTE: begin : LoadByte
                mem_formatted_rdata = extend_value(get_slice(mem_rdata_word, mem_byte_offset_reg, 1), 8, 1'b1);
            end

            F3_HALF: begin : LoadHalfword
                mem_formatted_rdata = extend_value(get_slice(mem_rdata_word, mem_byte_offset_reg, 2), 16, 1'b1);
            end

            F3_WORD: begin : LoadWord
                mem_formatted_rdata = mem_rdata_word;
            end

            F3_LBU: begin : LoadByteUnsigned
                mem_formatted_rdata = extend_value(get_slice(mem_rdata_word, mem_byte_offset_reg, 1), 8, 1'b0);
            end

            F3_LHU: begin : LoadHalfwordUnsigned
                mem_formatted_rdata = extend_value(get_slice(mem_rdata_word, mem_byte_offset_reg, 2), 16, 1'b0);
            end

            default: begin : DefaultCase
                mem_formatted_rdata = mem_rdata_word;   
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

    // --- LED Output (driven from MMIO register) ---
    assign leds_out = mem_led_reg;

endmodule