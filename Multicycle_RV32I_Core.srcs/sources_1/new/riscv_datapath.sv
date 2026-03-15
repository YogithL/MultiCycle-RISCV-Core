import riscv_pkg::*;

//Makesure to assign ALU_Opp = {IR[30],ALU_Opp} in TOP
module ALU(
    input logic [31:0] A, B,
    input ALU_Opps ALU_Opp,
    output logic [31:0] out,
    output logic [3:0] NZVC,
    output logic branchEnable
    );
    
    always_comb begin
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
        
        NZVC[2] = (!(A[31] ^ B[31]) && A[31] != out[31]) ? 1'b1 : 1'b0;
        
        NZVC[3] = (({1'b0, A} + {1'b0, B}) > {1'b0, out}) ? 1'b1 : 1'b0;
    end
    
endmodule
    
    
    
    
    
    
    