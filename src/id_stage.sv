import riscv_pkg::*;

/**
 * @brief Instruction Decode Stage (ID)
 * 
 * Decodes the fetched instruction and sets up control signals.
 * Responsibilities:
 * - Decodes opcode, register indices (rs1, rs2, rd), and immediates
 * - Instantiates the Main Control Unit
 * - Instantiates the Register File (read ports)
 * - Instantiates the Immediate Generator
 * - Passes control signals and data to ID/EX pipeline register
 */
module ID_Stage (
    input  logic             clk,
    input  logic             rst,
    
    // Inputs from IF stage (via IF/ID register)
    input  logic [31:0]      instruction,
    input  logic [XLEN-1:0]  pc,
    
    // Inputs from WB stage (Writeback)
    input  logic             reg_write_wb,
    input  logic [XLEN-1:0]  write_data_wb,
    input  logic [4:0]       rd_wb,
    
    // Outputs to ID/EX register and Hazard Unit
    output logic [XLEN-1:0]  read_data1,    // Data from RegFile rs1
    output logic [XLEN-1:0]  read_data2,    // Data from RegFile rs2
    output logic [XLEN-1:0]  imm_out,       // Sign-extended immediate
    output logic [4:0]       rs1,
    output logic [4:0]       rs2,
    output logic [4:0]       rd,
    output opcode_t          opcode,
    output logic [2:0]       funct3,
    output logic [6:0]       funct7,
    
    // Control Signal Outputs
    output logic             reg_write,
    output logic             mem_write,
    output alu_op_t          alu_control,
    output logic             alu_src,       // 0=rs2, 1=imm
    output logic [1:0]       alu_src_a,     // 0=rs1, 1=PC, 2=Zero
    output logic [1:0]       mem_to_reg,    // 0=ALU, 1=Mem, 2=PC+4
    output logic             branch,
    output logic             jump,
    output logic             jalr
);

    // --- Instruction Field Decoding ---
    assign opcode = opcode_t'(instruction[6:0]);
    assign rd     = instruction[11:7];
    assign funct3 = instruction[14:12];
    assign rs1    = instruction[19:15];
    assign rs2    = instruction[24:20];
    assign funct7 = instruction[31:25];

    // --- Control Unit ---
    ControlUnit control_unit_inst (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .reg_write(reg_write),
        .alu_control(alu_control),
        .alu_src_a(alu_src_a),
        .alu_src(alu_src),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .branch(branch),
        .jump(jump),
        .jalr(jalr)
    );

    // --- Register File Instantiation ---
    // Asynchronous read, synchronous write
    RegFile reg_file_inst (
        .clk(clk),
        .rst(rst),
        .RegWrite(reg_write_wb),     // Write enable from WB stage
        .rs1(rs1),                   
        .rs2(rs2),                   
        .rd(rd_wb),                  // Write address from WB stage
        .write_data(write_data_wb),  // Data from WB stage
        .read_data1(read_data1),   
        .read_data2(read_data2)     
    );

    // --- Immediate Generator ---
    // Generates 32-bit sign-extended immediates based on instruction type
    ImmGen imm_gen_inst (
        .instruction(instruction),
        .opcode(opcode),
        .imm_out(imm_out)
    );

endmodule