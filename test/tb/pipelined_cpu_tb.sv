import riscv_pkg::*;

module pipelined_cpu_tb;

    logic clk, rst;
    reg [2047:0] test_file;

    // Memory interface signals
    logic [ALEN-1:0] imem_addr;
    logic [31:0]     imem_data; // Instruction is always 32 bits
    logic            imem_en;   // Instruction Memory Enable
    
    logic [ALEN-1:0] dmem_addr;
    logic [XLEN-1:0] dmem_rdata, dmem_wdata;
    logic dmem_we;
    logic [3:0] dmem_be;
    logic [2:0] dmem_funct3;
    logic [LED_WIDTH-1:0] leds_out;
    logic                 uart_tx_wire;

    // CPU instance
    PipelinedCPU cpu_inst (
        .clk(clk),
        .rst(rst),
        .imem_addr(imem_addr),
        .imem_data(imem_data),
        .imem_en(imem_en),
        .dmem_addr(dmem_addr),
        .dmem_rdata(dmem_rdata),
        .dmem_wdata(dmem_wdata),
        .dmem_we(dmem_we),
        .dmem_be(dmem_be),
        .dmem_funct3(dmem_funct3)
    );

    // Instruction memory instance
    InstructionMemory imem_inst (
        .clk(clk),
        .en(imem_en),
        .Address(imem_addr),
        .Instruction(imem_data)
    );

    // Data memory instance
    DataMemory #(
        .CLKS_PER_BIT(868) // 100MHz / 115200 = 868
    ) dmem_inst (
        .clk(clk),
        .MemWrite(dmem_we),
        .be(dmem_be),
        .funct3(dmem_funct3),
        .Address(dmem_addr),
        .WriteData(dmem_wdata),
        .ReadData(dmem_rdata),
        .leds_out(),
        .uart_tx_wire(uart_tx_wire)
    );

    // Clock generator
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, pipelined_cpu_tb);
        
        // Load test program from command line argument
        if ($value$plusargs("TEST=%s", test_file)) begin
            $display("Loading Test: %0s", test_file);
            $readmemh(test_file, imem_inst.rom_memory);
            $readmemh(test_file, dmem_inst.ram_memory);
        end else begin
            $display("Error: No test file specified. Use +TEST=<filename>");
            $finish;
        end

        $display("\n-----------------------------------------------");
        $display("[*] Starting execution...");
        $display("\nFirst 4 instructions in memory:");
        $display("  [0x00]: %h", imem_inst.rom_memory[0]);
        $display("  [0x04]: %h", imem_inst.rom_memory[1]);
        $display("  [0x08]: %h", imem_inst.rom_memory[2]);
        $display("  [0x0C]: %h", imem_inst.rom_memory[3]);
        
        // Apply reset
        rst = 1;
        repeat(2) @(posedge clk); 
        rst = 0;
                
        $display("Execution started. Waiting for completion or timeout...\n");
        
        // Timeout mechanism to prevent infinite simulation
        #100000; 
        
        $display("\n-----------------------------------------------");
        $display("[*] Simulation Checkpoint (Time: %0t)", $time);
        
        // --- SELF-CHECKING LOGIC FOR CI ---
        if (test_file == "mem/fib_test.mem") begin
            // Fibonacci(10) should eventually reach 55. 
            // In your fib_test.mem, x2 holds the current value.
            if (cpu_inst.id_stage_inst.reg_file_inst.register_memory[2] == 55 || dmem_inst.led_reg == 55) begin
                $display("INTEGRATION TEST: Fibonacci Result 55 detected. STATUS: PASS");
            end else begin
                $display("INTEGRATION TEST: Fibonacci Result incorrect (Got %d, Expected 55). STATUS: FAIL", cpu_inst.id_stage_inst.reg_file_inst.register_memory[2]);
            end
        end 
        
        else if (test_file == "mem/complex_branch_test.mem") begin
            // Markers: x3=1, x4=2, x5=3, x6=4 if all branches taken correctly.
            if (cpu_inst.id_stage_inst.reg_file_inst.register_memory[3] == 1 &&
                cpu_inst.id_stage_inst.reg_file_inst.register_memory[4] == 2 &&
                cpu_inst.id_stage_inst.reg_file_inst.register_memory[5] == 3 &&
                cpu_inst.id_stage_inst.reg_file_inst.register_memory[6] == 4) begin
                $display("INTEGRATION TEST: All 4 Complex Branches passed markers. STATUS: PASS");
            end else begin
                $display("INTEGRATION TEST: Branch markers incomplete. STATUS: FAIL");
            end
        end

        else if (test_file == "mem/lui_test.mem") begin
            // x2 should be 0x12345001
            if (cpu_inst.id_stage_inst.reg_file_inst.register_memory[2] == 32'h12345001) begin
                $display("INTEGRATION TEST: LUI + Forwarding check correct. STATUS: PASS");
            end else begin
                $display("INTEGRATION TEST: LUI Result incorrect (Got %h). STATUS: FAIL", cpu_inst.id_stage_inst.reg_file_inst.register_memory[2]);
            end
        end

        $display("[*] Simulation ended.");
        $display("-----------------------------------------------\n");

        $finish;
    end

endmodule