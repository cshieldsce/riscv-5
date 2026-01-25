import riscv_pkg::*;

/**
 * @brief Main Control Unit Decoder for RISC-V CPU
 * @details Decodes RISC-V instruction opcodes and generates control signals for datapath.
 *          Implements the control logic for RV32I base instruction set:
 *          - R-type: Register-register operations (ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU)
 *          - I-type: Immediate operations (ADDI, SLTI, XORI, ORI, ANDI, SLLI, SRLI, SRAI) and Loads (LB, LH, LW, LBU, LHU)
 *          - S-type: Store operations (SB, SH, SW)
 *          - B-type: Conditional branches (BEQ, BNE, BLT, BGE, BLTU, BGEU)
 *          - U-type: Upper immediate operations (LUI, AUIPC)
 *          - J-type: Unconditional jumps (JAL, JALR)
 * 
 * @param opcode      7-bit instruction opcode [6:0]
 * @param funct3      3-bit function field [14:12] (operation selector within opcode class)
 * @param funct7      7-bit function field [31:25] (distinguishes ADD/SUB, SRL/SRA in R-type)
 * @param reg_write   Output: Enable register file write
 * @param alu_control Output: ALU operation selector (from alu_op_t enum)
 * @param alu_src_a   Output: ALU input A mux: 00=rs1, 01=PC, 10=zero
 * @param alu_src     Output: ALU input B mux: 0=rs2, 1=immediate
 * @param mem_write   Output: Enable data memory write
 * @param mem_to_reg  Output: Result mux: 00=ALU, 01=Memory, 10=PC+4
 * @param branch      Output: Enable conditional branch logic
 * @param jump        Output: Enable unconditional jump (JAL)
 * @param jalr        Output: Enable jump-and-link register (JALR)
 */
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
    always_comb begin : ControlLogic
        // --- Default signal values to prevent latches ---
        reg_write   = 1'b0;
        alu_control = ALU_ADD;        
        alu_src_a   = 2'b00;          
        alu_src     = 1'b0;          
        mem_write   = 1'b0;           
        mem_to_reg  = 2'b00;          
        branch      = 1'b0;           
        jump        = 1'b0;           
        jalr        = 1'b0;           

        case (opcode)
            OP_R_TYPE: begin : RegisterArithmetic
                reg_write  = 1'b1;                                                         // Write result to rd
                alu_src    = 1'b0;                                                         // ALU input B = rs2 (not immediate)
                mem_to_reg = 2'b00;                                                        // Write ALU result to rd

                case (funct3)
                    F3_ADD_SUB: alu_control = alu_op_t'((funct7[5]) ? ALU_SUB : ALU_ADD);  // ADD / SUB (based on funct7[5])
                    F3_SLL:     alu_control = ALU_SLL;                                     // Shift left logical
                    F3_SLT:     alu_control = ALU_SLT;                                     // Set less than (signed)
                    F3_SLTU:    alu_control = ALU_SLTU;                                    // Set less than unsigned
                    F3_XOR:     alu_control = ALU_XOR;                                     // Bitwise XOR
                    F3_SRL_SRA: alu_control = alu_op_t'((funct7[5]) ? ALU_SRA : ALU_SRL);  // SRL / SRA (based on funct7[5])
                    F3_OR:      alu_control = ALU_OR;                                      // Bitwise OR
                    F3_AND:     alu_control = ALU_AND;                                     // Bitwise AND
                    default:    alu_control = ALU_ADD;                                     // Safe fallback
                endcase
            end

            OP_I_TYPE: begin : ImmediateArithmetic
                reg_write  = 1'b1;                                                         // Write result to rd
                alu_src    = 1'b1;                                                         // ALU input B = immediate (not rs2)
                mem_to_reg = 2'b00;                                                        // Write ALU result to rd

                case (funct3)
                    F3_ADD_SUB: alu_control = ALU_ADD;                                     // ADDI (no SUBI)
                    F3_SLL:     alu_control = ALU_SLL;                                     // SLLI
                    F3_SLT:     alu_control = ALU_SLT;                                     // SLTI
                    F3_SLTU:    alu_control = ALU_SLTU;                                    // SLTIU
                    F3_XOR:     alu_control = ALU_XOR;                                     // XORI
                    F3_SRL_SRA: alu_control = alu_op_t'((funct7[5]) ? ALU_SRA : ALU_SRL);  // SRLI / SRAI
                    F3_OR:      alu_control = ALU_OR;                                      // ORI
                    F3_AND:     alu_control = ALU_AND;                                     // ANDI
                    default:    alu_control = ALU_ADD;                                     // Safe fallback
                endcase
            end
            
            OP_LOAD: begin : LoadFromMemory
                reg_write   = 1'b1;                             // Write loaded data to rd
                alu_src     = 1'b1;                             // ALU input B = offset immediate
                mem_to_reg  = 2'b01;                            // Write memory data to rd (not ALU result)
                alu_control = ALU_ADD;                          // Compute address: rs1 + offset
            end

            OP_STORE: begin : StoreToMemory
                alu_src     = 1'b1;                             // ALU input B = offset immediate
                mem_write   = 1'b1;                             // Enable memory write
                alu_control = ALU_ADD;                          // Compute address: rs1 + offset
            end

            OP_BRANCH: begin : ConditionalBranches
                branch      = 1'b1;                             // Enable branch logic
                alu_src     = 1'b0;                             // ALU input B = rs2 (compare registers)
                mem_to_reg  = 2'b00;                            // Branch doesn't write to register
                
                case (funct3)
                    F3_BEQ, F3_BNE:   alu_control = ALU_SUB;    // Equality check (rs1 - rs2)
                    F3_BLT, F3_BGE:   alu_control = ALU_SLT;    // Signed comparison (rs1 < rs2)
                    F3_BLTU, F3_BGEU: alu_control = ALU_SLTU;   // Unsigned comparison (rs1 < rs2)
                    default:          alu_control = ALU_SUB;    // Safe fallback
                endcase
            end

            OP_JAL: begin : UnconditionalJump
                jump        = 1'b1;                             // Enable unconditional jump
                reg_write   = 1'b1;                             // Write return address to rd
                mem_to_reg  = 2'b10;                            // Write PC+4 to rd (return address)
                alu_control = ALU_ADD;                          // Compute jump target: PC + offset
            end

            OP_JALR: begin : JumpAndLinkRegisters
                jalr        = 1'b1;                             // Enable JALR-specific logic
                reg_write   = 1'b1;                             // Write return address to rd
                alu_src     = 1'b1;                             // ALU input B = offset immediate
                mem_to_reg  = 2'b10;                            // Write PC+4 to rd (return address)
                alu_control = ALU_ADD;                          // Compute jump target: rs1 + offset
            end

            OP_LUI: begin : LoadUpperImmediate
                reg_write   = 1'b1;                             // Write result to rd
                alu_src     = 1'b1;                             // ALU input B = immediate (already shifted by ImmGen)
                alu_src_a   = 2'b10;                            // ALU input A = 0 (compute 0 + imm)
                mem_to_reg  = 2'b00;                            // Write ALU result to rd
                alu_control = ALU_ADD;                          // Simply pass through immediate
            end

            OP_AUIPC: begin : AddUpperImmediateToPC
                reg_write   = 1'b1;                             // Write result to rd
                alu_src     = 1'b1;                             // ALU input B = immediate
                alu_src_a   = 2'b01;                            // ALU input A = PC
                mem_to_reg  = 2'b00;                            // Write ALU result to rd
                alu_control = ALU_ADD;                          // Compute PC + immediate
            end

            OP_SYSTEM: begin : SystemInstructions
                // --- Not implemented in this CPU - executes as NOP ---
            end

            OP_FENCE: begin : MemoryOrdering
                // --- Not implemented in this CPU - executes as NOP ---
            end
            
            default: begin : UnknownOpcode
                // --- All signals remain at default values (prevents latches) ---
            end
        endcase
    end
endmodule