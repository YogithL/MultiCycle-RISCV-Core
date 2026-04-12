import riscv_pkg::*;

module ALU(
    input logic [31:0] A, B,
    input ALU_Opps ALU_Opp,
    output logic [31:0] out,
    output logic [3:0] NZVC
    );
    
    always_comb begin
        out = 32'b0;
        NZVC = 4'b0000;
        
        case(ALU_Opp)
            ALU_ADD: out = A + B;
            ALU_SUB: out = A - B;
            
            ALU_OR: out = A | B;
            ALU_AND: out = A & B;
            ALU_XOR: out = A ^ B;
            
            ALU_SRL: out = A >> B[4:0];
            ALU_SRA: out = $signed(A) >>> B[4:0];
            
            ALU_SLL: out = A << B[4:0];
            
            ALU_SLT: out = $signed(A) < $signed(B) ? 32'h0001 : 32'h0000;
            ALU_SLTU: out = (A) < (B) ? 32'h0001 : 32'h0000;
            
            default:  out = 32'b0;
        endcase
        
        NZVC[0] = ~|out;
        
        NZVC[1] = (out == 32'b0) ? 1'b1 : 1'b0;
        
        if(ALU_Opp == ALU_ADD)
            NZVC[2] = (!(A[31] ^ B[31]) && A[31] != out[31]) ? 1'b1 : 1'b0; //overflow
        else if (ALU_Opp == ALU_SUB)
            NZVC[2] = (A[31] != B[31] && out[31] != A[31]) ? 1'b1 : 1'b0; //overflow
        
        if(ALU_Opp == ALU_ADD)        
            NZVC[3] = (({1'b0, A} + {1'b0, B}) > {1'b0, out}) ? 1'b1 : 1'b0; //carry
        else if (ALU_Opp == ALU_SUB)
            NZVC[3] = (B > A) ? 1'b1 : 1'b0; //borrow
    end
    
endmodule



//Makesure to reset Regs in Sim
module RegFile(
    input logic clk,
    input Control_Flags Control_Flag,
    input logic[4:0] rd_add, rs1_add, rs2_add,
    input logic[31:0] data,
    output logic[31:0] rs1, rs2
    );
    
    //Can force to LUT_RAM if neccessary
    logic[31:0] RegArray[0:31];
    
    always_ff @ (posedge clk) begin
        if(Control_Flag.Reg_Write && (rd_add != 5'b0))
        begin
            RegArray[rd_add] <= data; 
        end
    end
    
    assign rs1 = (rs1_add == 5'b0) ? 32'b0 : RegArray[rs1_add];
    assign rs2 = (rs2_add == 5'b0) ? 32'b0 : RegArray[rs2_add];

endmodule    
    
    
    
module RAM(
    input logic clk,
    input Memory_Flags memFlags,
    input logic[31:0] addr,
    input logic[31:0] din,
    output logic[31:0] dout
    );
    
    logic[31:0] RAM[0:1023];
    
    logic[1:0] byteOffset;
    logic[9:0] wrdAddr;
    
    assign byteOffset = addr[1:0];
    assign wrdAddr = addr[11:2];
    
    always_ff @ (posedge clk) begin
        if(memFlags.memRead)
            dout <= RAM[wrdAddr];
        
        if(memFlags.memWrite) begin
            case(memFlags.dataWidth)
                SZ_Word: begin
                    RAM[wrdAddr][7:0] <= din[7:0];
                    RAM[wrdAddr][15:8] <= din[15:8];
                    RAM[wrdAddr][23:16] <= din[23:16];
                    RAM[wrdAddr][31:24] <= din[31:24];
                end    
                
                SZ_Half: begin
                    if(byteOffset == 0) begin
                        RAM[wrdAddr][7:0] <= din[7:0];
                        RAM[wrdAddr][15:8] <= din[15:8];
                    end
                    
                    if(byteOffset == 2) begin
                        RAM[wrdAddr][23:16] <= din[7:0];
                        RAM[wrdAddr][31:24] <= din[15:8];
                    end                    
                end
                
                SZ_Byte: begin
                    case(byteOffset)
                        2'b00: RAM[wrdAddr][7:0] <= din[7:0];
                        2'b01: RAM[wrdAddr][15:8] <= din[7:0];
                        2'b10: RAM[wrdAddr][23:16] <= din[7:0];
                        2'b11: RAM[wrdAddr][31:24] <= din[7:0];
                    endcase
                end
            endcase
        end
   end
   
endmodule
    
    
    
module ROM(
    input logic clk,
    input logic[31:0] PC,
    output logic[31:0] dout
    );
    
    logic [31:0] ROM[0:1023];
    logic[9:0] wrdAddr;
    
    assign wrdAddr = PC[11:2];
    
    initial begin
        $readmemh("program.mem", ROM);
    end
    
    always_ff @ (posedge clk) begin
        dout <= ROM[wrdAddr];
    end
    
endmodule



module dataExtender(
    input Memory_Flags memFlags,
    input logic[31:0] din,
    input logic[31:0] addr,
    output logic[31:0] dout
    );
    
    logic [31:0] shiftedDin;
    
    always_comb begin
        shiftedDin = din >> 8*(addr[1:0]); 
        
        if(memFlags.loadInstr)
        begin
            case(memFlags.dataWidth)
                SZ_Word: dout = shiftedDin;
                
                SZ_Half: dout = memFlags.signd ? { {16{shiftedDin[15]}}, shiftedDin[15:0]} 
                : { {16{1'b0}}, shiftedDin[15:0]};
                
                SZ_Byte: dout = memFlags.signd ? { {24{shiftedDin[7]}}, shiftedDin[7:0]} 
                : { {24{1'b0}}, shiftedDin[7:0]};
            
                default: dout = shiftedDin;
            endcase
        end
        
        else dout = shiftedDin;
   end
   
endmodule



module ImmGen(
    input logic[31:0] instr,
    input riscv_pkg :: opcodes opcode,
    output logic[31:0] imm
    );
        
    always_comb begin        
        case(opcode)
            OP_Imm, OP_Load, OP_JALR: imm = { {20{instr[31]}} , instr[31:20] };
            OP_LUI, OP_AUIPC: imm = { instr[31:12] , 12'b0 };
            OP_Store: imm = { {20{instr[31]}} , instr[31:25] , instr[11:7] };
            OP_Branch: imm = { {19{instr[31]}} , instr[31] , instr[7] , instr[30:25] , instr[11:8] , 1'b0 };
            OP_JAL: imm = { {11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0 };
            default: imm = 32'b0;
        endcase
    end
        
endmodule       



module Decoder(
    input logic[31:0] instr,
    output riscv_pkg :: opcodes opcode,
    output riscv_pkg :: ALU_Flags ALU_Flag,
    output riscv_pkg :: dataSize dataWidth,
    output riscv_pkg :: Memory_Flags Memory_Flag
    );
    
    assign opcode = opcodes'(instr[6:0]);
    
    always_comb begin
        ALU_Flag = '0;
        dataWidth = SZ_Word;
        Memory_Flag = '0;
        
        case(opcode)
            OP_Reg, OP_Imm: begin
                if(instr[5] == 1'b1)
                    ALU_Flag.ALU_SelectB = 2'b00;
                else
                    ALU_Flag.ALU_SelectB = 2'b11;
                
                //ADD vs SUB and SRA vs SRL
                if(instr[14:12] == 3'b000 && opcode == OP_Reg || instr[14:12] == 3'b101)
                    ALU_Flag.ALU_Opp = ALU_Opps'({instr[30], instr[14:12]});
                else   
                    ALU_Flag.ALU_Opp = ALU_Opps'({1'b0, instr[14:12]});
            end
            
            OP_Load: begin
                Memory_Flag.loadInstr = 1'b1;
                ALU_Flag.ALU_SelectA = 1'b0; //Select Reg
                ALU_Flag.ALU_SelectB = 2'b11; //Select ImmGen
                ALU_Flag.ALU_Opp = ALU_ADD;
                
                if(instr[14:12] <= 2) 
                    Memory_Flag.signd = 1'b1;
                else
                    Memory_Flag.signd = 1'b0;
                
                case(instr[14:12])
                    3'b000: Memory_Flag.dataWidth = SZ_Byte; 
                    3'b001: Memory_Flag.dataWidth = SZ_Half;
                    3'b010: Memory_Flag.dataWidth = SZ_Word;
                    3'b100: Memory_Flag.dataWidth = SZ_Byte;
                    3'b101: Memory_Flag.dataWidth = SZ_Half;
                endcase
            end
            
            //Handle saving PC in FSM
            OP_JAL, OP_Branch, OP_AUIPC: begin
                ALU_Flag.ALU_Opp = ALU_ADD;
                ALU_Flag.ALU_SelectA = 1'b1; //Select PC
                ALU_Flag.ALU_SelectB = 2'b11; //Select ImmGen
                
                if(opcode == OP_AUIPC)
                    Memory_Flag.upperImm = 1'b1;
                else
                    Memory_Flag.upperImm = 1'b0;
            end
            
            OP_Store: begin
                Memory_Flag.loadInstr = 1'b0;
                ALU_Flag.ALU_SelectA = 1'b0; //Select Reg
                ALU_Flag.ALU_SelectB = 2'b11; //Select ImmGen
                ALU_Flag.ALU_Opp = ALU_ADD; 
                
                case(instr[14:12])
                    3'b000: Memory_Flag.dataWidth = SZ_Byte; 
                    3'b001: Memory_Flag.dataWidth = SZ_Half;
                    3'b010: Memory_Flag.dataWidth = SZ_Word;
                endcase
            end
            
            //Handle saving PC in FSM
            OP_JALR: begin
                ALU_Flag.ALU_Opp = ALU_ADD;
                ALU_Flag.ALU_SelectA = 1'b0; //Select Reg
                ALU_Flag.ALU_SelectB = 2'b11; //Select ImmGen
            end
            
            OP_LUI: begin
                Memory_Flag.upperImm = 1'b1;
                ALU_Flag.ALU_Opp = ALU_ADD;
                ALU_Flag.ALU_SelectA = 1'b0; //Select Reg
                ALU_Flag.ALU_SelectB = 2'b11; //Select ImmGen
            end
        endcase
    end
endmodule



module BranchManager(
    input riscv_pkg :: Control_Flags Control_Flag,
    input logic[3:0] NZVC,
    input branchTypes branchType,
    input logic[31:0] PC_next,
    input logic[31:0] target_addr,
    output logic[31:0] PC
    );
    
    logic branchTaken = 1'b0;
    
    always_comb begin
        case(branchType)
            BR_BEQ: branchTaken = NZVC[1] ? (1'b1) : (1'b0);
            BR_BNE: branchTaken = NZVC[1] ? (1'b0) : (1'b1);
            BR_BLT: branchTaken = NZVC[0] ^ NZVC[2] ? (1'b1) : (1'b0); //Mistake found by UVM missing V check
            BR_BGE: branchTaken = ~(NZVC[0] ^ NZVC[2]) ? (1'b1) : (1'b0); 
            BR_BLTU: branchTaken = NZVC[3] ? (1'b1) : (1'b0);
            BR_BGEU: branchTaken = (~NZVC[3] || NZVC[1]) ? (1'b1) : (1'b0);
            default: branchTaken = 1'b0;
        endcase
    end
    
    always_comb begin
        if((branchTaken && Control_Flag.branchEnable) || Control_Flag.jump)
            PC = target_addr;
        else
            PC = PC_next;
    end
     
endmodule
    
    

module controller(
    input logic clk, reset,
    input logic [3:0] NZVC,
    input riscv_pkg :: opcodes opcode,
    
    input riscv_pkg :: ALU_Flags in_ALU_Flag,
    input riscv_pkg :: Memory_Flags in_Memory_Flag,
    
    output riscv_pkg :: ALU_Flags out_ALU_Flag,
    output riscv_pkg :: Memory_Flags out_Memory_Flag,
    output riscv_pkg :: Control_Flags Control_Flag
    );
    
    
    
    
    
    
    
           
                
                

            

                    
                 
    
        




    
    
    
    
   
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    