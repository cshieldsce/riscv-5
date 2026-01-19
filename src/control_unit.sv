import riscv_pkg::*;

module ControlUnit (
    input  opcode_t         opcode,
    input  logic [2:0]      funct3,
    input  logic [6:0]      funct7,
    output logic            RegWrite,
    output alu_op_t         ALUControl,
    output logic [1:0]      ALUSrcA,
    output logic            ALUSrc,
    output logic            MemWrite,
    output logic [1:0]      MemToReg,
    output logic            Branch,
    output logic            Jump,
    output logic            Jalr
);
    always_comb begin
        // Default control signals
        RegWrite   = 1'b0;
        ALUControl = ALU_ADD;
        ALUSrcA    = 2'b00;
        ALUSrc     = 1'b0;
        MemWrite   = 1'b0;
        MemToReg   = 2'b00;
        Branch     = 1'b0;
        Jump       = 1'b0;
        Jalr       = 1'b0;

        case (opcode)

            // Handle R-type instructions
            OP_R_TYPE: begin 
                RegWrite = 1'b1;
                ALUSrc   = 1'b0;
                MemToReg = 2'b00;

                case (funct3)
                    F3_ADD_SUB: ALUControl = alu_op_t'((funct7[5]) ? ALU_SUB : ALU_ADD);
                    F3_SLL:     ALUControl = ALU_SLL;
                    F3_SLT:     ALUControl = ALU_SLT;
                    F3_SLTU:    ALUControl = ALU_SLTU;
                    F3_XOR:     ALUControl = ALU_XOR;
                    F3_SRL_SRA: ALUControl = alu_op_t'((funct7[5]) ? ALU_SRA : ALU_SRL);
                    F3_OR:      ALUControl = ALU_OR;
                    F3_AND:     ALUControl = ALU_AND;
                    default:    ALUControl = ALU_ADD;
                endcase
            end

            // Handle I-type instructions (addi)
            OP_I_TYPE: begin
                RegWrite = 1'b1;
                ALUSrc   = 1'b1;
                MemToReg = 2'b00;

                case (funct3)
                    F3_ADD_SUB: ALUControl = ALU_ADD;
                    F3_SLL:     ALUControl = ALU_SLL;
                    F3_SLT:     ALUControl = ALU_SLT;
                    F3_SLTU:    ALUControl = ALU_SLTU;
                    F3_XOR:     ALUControl = ALU_XOR;
                    F3_SRL_SRA: ALUControl = alu_op_t'((funct7[5]) ? ALU_SRA : ALU_SRL);
                    F3_OR:      ALUControl = ALU_OR;
                    F3_AND:     ALUControl = ALU_AND;
                    default:    ALUControl = ALU_ADD;
                endcase
            end
            
            // Handle I-type instructions (Load Word)
            OP_LOAD: begin 
                RegWrite   = 1'b1;
                ALUSrc     = 1'b1;
                MemToReg   = 2'b01;
                ALUControl = ALU_ADD;
            end

            // Handle S-type instructions
            OP_STORE: begin
                ALUSrc     = 1'b1;
                MemWrite   = 1'b1;
                ALUControl = ALU_ADD;
            end

            // Handle B-type instructions
            OP_BRANCH: begin
                Branch     = 1'b1;
                ALUSrc     = 1'b0;       // Use ReadData2 (rs2)
                MemToReg   = 2'b00;
                
                case (funct3)
                    F3_BEQ, F3_BNE:   ALUControl = ALU_SUB;
                    F3_BLT, F3_BGE:   ALUControl = ALU_SLT;
                    F3_BLTU, F3_BGEU: ALUControl = ALU_SLTU;
                    default:          ALUControl = ALU_SUB;
                endcase
            end

            // Handle J-type instructions
            OP_JAL: begin
                Jump       = 1'b1;
                RegWrite   = 1'b1;
                MemToReg   = 2'b10;      // PC+4 for jal
                ALUControl = ALU_ADD;
            end

            OP_JALR: begin
                Jalr       = 1'b1;
                RegWrite   = 1'b1;
                ALUSrc     = 1'b1;       // Use immediate
                MemToReg   = 2'b10;      // PC+4 for jalr
                ALUControl = ALU_ADD;
            end

            // Handle U-type instructions
            OP_LUI: begin
                RegWrite   = 1'b1;
                ALUSrc     = 1'b1;       // Use immediate
                ALUSrcA    = 2'b10;      // Zero
                MemToReg   = 2'b00;
                ALUControl = ALU_ADD;
            end

            OP_AUIPC: begin
                RegWrite   = 1'b1;
                ALUSrc     = 1'b1;       // Use immediate
                ALUSrcA    = 2'b01;      // PC
                MemToReg   = 2'b00;
                ALUControl = ALU_ADD;
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