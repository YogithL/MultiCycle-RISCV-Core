import riscv_pkg::*;

//Makesure to assign ALU_Opp = {IR[30],ALU_Opp} in TOP
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
        
        NZVC[0] = out[31];
        
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
    input logic regWrite,
    input logic[4:0] rd_add, rs1_add, rs2_add,
    input logic[31:0] data,
    output logic[31:0] rs1, rs2
    );
    
    //Can force to LUT_RAM if neccessary
    logic[31:0] RegArray[0:31];
    
    always_ff @ (posedge clk) begin
        if(regWrite && (rd_add != 5'b0))
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
    
    logic[31:0] RAM[0:1024];
    
    logic[1:0] byteOffset;
    logic[9:0] wrdAddr;
    
    assign byteOffset = addr[1:0];
    assign wrdAddr = addr[11:2];
    
    always_ff @ (posedge clk) begin
        if(memFlags.memRead)
            dout <= RAM[wrdAddr];
        
        if(memFlags.memWrite) begin
            RAM[wrdAddr] <= 
    
    
    
    
    
    