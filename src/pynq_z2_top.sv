import riscv_pkg::*;

module pynq_z2_top (
    input  logic       sysclk,
    input  logic       reset_btn,
    output logic [3:0] led,
    output logic       uart_tx
);

    // --- Clock Generation ---
    logic cpu_clk;
    logic clk_locked;
    logic cpu_reset;

    // Instantiate the Clocking Wizard
    // It takes 125MHz and outputs stable 10MHz
    clk_wiz_0 clk_gen (
        .clk_out1(cpu_clk),
        .locked(clk_locked),
        .clk_in1(sysclk)
    );

    // Combine external reset with the clock stability flag
    // The CPU is held in reset if the button is pressed OR the clock isn't ready.
    assign cpu_reset = reset_btn || !clk_locked;

    // --- CPU Signals ---
    logic [ALEN-1:0] imem_addr;
    logic [31:0]     imem_data;
    logic            imem_en;
    
    logic [ALEN-1:0] dmem_addr;
    logic [XLEN-1:0] dmem_rdata, dmem_wdata;
    logic            dmem_we;
    logic [3:0]      dmem_be;
    logic [2:0]      dmem_funct3;
    logic [3:0]      dmem_leds; // Missing declaration added here

    // CPU Instance
    PipelinedCPU cpu_inst (
        .clk(cpu_clk),
        .rst(cpu_reset),
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

    // Instruction Memory
    InstructionMemory imem_inst (
        .clk(cpu_clk),
        .rst(cpu_reset),
        .en(imem_en),
        .Address(imem_addr),
        .Instruction(imem_data)
    );

    // Data Memory
    DataMemory dmem_inst (
        .clk(cpu_clk),
        .rst(cpu_reset),
        .MemWrite(dmem_we),
        .be(dmem_be),
        .funct3(dmem_funct3),
        .Address(dmem_addr),
        .WriteData(dmem_wdata),
        .ReadData(dmem_rdata),
        .leds_out(dmem_leds)
    );

    // --- LED Output Mapping ---
    // Display the lower 4 bits of the CPU's memory-mapped LED register.
    // This allows visual verification of programs (like Fibonacci).
    assign led = dmem_leds;

    // --- ILA Debug ---
    // ILA Probe Signals with mark_debug attribute
    (* mark_debug = "true" *) logic [XLEN-1:0] ila_pc;
    (* mark_debug = "true" *) logic [31:0]     ila_instruction;
    (* mark_debug = "true" *) logic [2:0]      ila_hazard_signals; // stall_id, flush_ex, id_branch
    (* mark_debug = "true" *) logic            ila_branch_taken;
    (* mark_debug = "true" *) logic [XLEN-1:0] ila_branch_target;
    (* mark_debug = "true" *) logic            ila_alu_zero;
    (* mark_debug = "true" *) logic [2:0]      ila_mem_wb_controls; // ex_mem_reg_write, mem_wb_reg_write, mem_wb_mem_to_reg[0]
    (* mark_debug = "true" *) logic [XLEN-1:0] ila_rs1_data;
    (* mark_debug = "true" *) logic [XLEN-1:0] ila_rs2_data;
    (* mark_debug = "true" *) logic [XLEN-1:0] ila_alu_result;
    (* mark_debug = "true" *) logic [4:0]      ila_mem_wb_rd; // Register being written in WB
    (* mark_debug = "true" *) logic [XLEN-1:0] ila_wb_data;   // Data being written in WB

    // Tap into CPU internals
    // NOTE: Pipeline Stage Mismatch in Debug Signals
    // ila_pc is probing the EXECUTE stage (id_ex_pc).
    // ila_instruction is probing the DECODE stage (if_id_instruction).
    // This means 'ila_instruction' shows the instruction *following* the one at 'ila_pc'.
    assign ila_pc = cpu_inst.id_ex_pc; 
    assign ila_instruction = cpu_inst.if_id_instruction;
    
    // Hazard/Control Signals (Combined into 3-bit probe)
    // [2] = id_branch (from ID_Stage)
    // [1] = flush_ex (from HazardUnit)
    // [0] = stall_id (from HazardUnit)
    assign ila_hazard_signals = {cpu_inst.id_branch, cpu_inst.flush_ex, cpu_inst.stall_id};

    assign ila_branch_taken = cpu_inst.branch_taken;
    assign ila_branch_target = cpu_inst.ex_branch_target;
    assign ila_alu_zero = cpu_inst.ex_zero;
    
    // Memory/Writeback Control Signals (Combined into 3-bit probe)
    // [2] = ex_mem_reg_write (RegWrite signal entering MEM)
    // [1] = mem_wb_reg_write (RegWrite signal entering WB)
    // [0] = mem_wb_mem_to_reg[0] (MemRead signal in WB)
    assign ila_mem_wb_controls = {cpu_inst.ex_mem_reg_write, cpu_inst.mem_wb_reg_write, cpu_inst.mem_wb_mem_to_reg[0]};

    assign ila_rs1_data = cpu_inst.id_ex_read_data1;
    assign ila_rs2_data = cpu_inst.id_ex_read_data2;
    assign ila_alu_result = cpu_inst.ex_alu_result;
    
    assign ila_mem_wb_rd = cpu_inst.mem_wb_rd;
    assign ila_wb_data = cpu_inst.wb_write_data;

    // ILA Instance
    ila_0 my_ila (
        .clk(cpu_clk), 
        .probe0(ila_pc),                // 32-bit
        .probe1(ila_instruction),       // 32-bit
        .probe2(ila_hazard_signals),    // 3-bit (was ila_branch_en, 1-bit)
        .probe3(ila_branch_taken),      // 1-bit
        .probe4(ila_branch_target),     // 32-bit
        .probe5(ila_alu_zero),          // 1-bit
        .probe6(ila_mem_wb_controls),   // 3-bit (was ila_funct3, 3-bit)
        .probe7(ila_rs1_data),          // 32-bit
        .probe8(ila_rs2_data),          // 32-bit
        .probe9(ila_alu_result),        // 32-bit
        .probe10(ila_mem_wb_rd),        // 5-bit (was ila_pcsrc, 1-bit)
        .probe11(ila_wb_data)           // 32-bit (NEW probe)
    );

endmodule
