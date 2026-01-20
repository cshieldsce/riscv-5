import riscv_pkg::*;

module ControlUnit (
    input  opcode_t         opcode,
    input  logic [2:0]      funct3,
    input  logic [6:0]      funct7,
    output logic            reg_write,
    output alu_op_t         alu_control,
    output logic [1:0]      alu_src_a,
    output logic            alu_src,
    output logic            mem_write,
    output logic [1:0]      mem_to_reg,
    output logic            branch,
    output logic            jump,
    output logic            jalr
);
    always_comb begin
        // Default control signals
        reg_write   = 1'b0;
        alu_control = ALU_ADD;
        alu_src_a    = 2'b00;
        alu_src     = 1'b0;
        mem_write   = 1'b0;
        mem_to_reg   = 2'b00;
        branch     = 1'b0;
        jump       = 1'b0;
        jalr       = 1'b0;

        case (opcode)

            // Handle R-type instructions
            OP_R_TYPE: begin 
                reg_write = 1'b1;
                alu_src   = 1'b0;
                mem_to_reg = 2'b00;

                case (funct3)
                    F3_ADD_SUB: alu_control = alu_op_t'((funct7[5]) ? ALU_SUB : ALU_ADD);
                    F3_SLL:     alu_control = ALU_SLL;
                    F3_SLT:     alu_control = ALU_SLT;
                    F3_SLTU:    alu_control = ALU_SLTU;
                    F3_XOR:     alu_control = ALU_XOR;
                    F3_SRL_SRA: alu_control = alu_op_t'((funct7[5]) ? ALU_SRA : ALU_SRL);
                    F3_OR:      alu_control = ALU_OR;
                    F3_AND:     alu_control = ALU_AND;
                    default:    alu_control = ALU_ADD;
                endcase
            end

            // Handle I-type instructions (addi)
            OP_I_TYPE: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                mem_to_reg = 2'b00;

                case (funct3)
                    F3_ADD_SUB: alu_control = ALU_ADD;
                    F3_SLL:     alu_control = ALU_SLL;
                    F3_SLT:     alu_control = ALU_SLT;
                    F3_SLTU:    alu_control = ALU_SLTU;
                    F3_XOR:     alu_control = ALU_XOR;
                    F3_SRL_SRA: alu_control = alu_op_t'((funct7[5]) ? ALU_SRA : ALU_SRL);
                    F3_OR:      alu_control = ALU_OR;
                    F3_AND:     alu_control = ALU_AND;
                    default:    alu_control = ALU_ADD;
                endcase
            end
            
            // Handle I-type instructions (Load Word)
            OP_LOAD: begin 
                reg_write   = 1'b1;
                alu_src     = 1'b1;
                mem_to_reg   = 2'b01;
                alu_control = ALU_ADD;
            end

            // Handle S-type instructions
            OP_STORE: begin
                alu_src     = 1'b1;
                mem_write   = 1'b1;
                alu_control = ALU_ADD;
            end

            // Handle B-type instructions
            OP_BRANCH: begin
                branch     = 1'b1;
                alu_src     = 1'b0;       // Use ReadData2 (rs2)
                mem_to_reg   = 2'b00;
                
                case (funct3)
                    F3_BEQ, F3_BNE:   alu_control = ALU_SUB;
                    F3_BLT, F3_BGE:   alu_control = ALU_SLT;
                    F3_BLTU, F3_BGEU: alu_control = ALU_SLTU;
                    default:          alu_control = ALU_SUB;
                endcase
            end

            // Handle J-type instructions
            OP_JAL: begin
                jump       = 1'b1;
                reg_write   = 1'b1;
                mem_to_reg   = 2'b10;      // PC+4 for jal
                alu_control = ALU_ADD;
            end

            OP_JALR: begin
                jalr       = 1'b1;
                reg_write   = 1'b1;
                alu_src     = 1'b1;       // Use immediate
                mem_to_reg   = 2'b10;      // PC+4 for jalr
                alu_control = ALU_ADD;
            end

            // Handle U-type instructions
            OP_LUI: begin
                reg_write   = 1'b1;
                alu_src     = 1'b1;       // Use immediate
                alu_src_a    = 2'b10;      // Zero
                mem_to_reg   = 2'b00;
                alu_control = ALU_ADD;
            end

            OP_AUIPC: begin
                reg_write   = 1'b1;
                alu_src     = 1'b1;       // Use immediate
                alu_src_a    = 2'b01;      // PC
                mem_to_reg   = 2'b00;
                alu_control = ALU_ADD;
            end

            // Handle system instructions
            OP_SYSTEM: begin
                // NOP behavior
            end

            OP_FENCE: begin
                // NOP behavior
            end
            
            default: begin
                // Prevent latches
            end
        endcase
    end
endmodule