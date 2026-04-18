import riscv_pkg::*;

module riscv_controller(
    input logic clk, reset,
    input logic[3:0] branchTaken,
    input logic[31:0] instr,
        
    output riscv_pkg :: ALU_Flags ALU_Flag,
    output riscv_pkg :: Memory_Flags Memory_Flag,
    output riscv_pkg :: Control_Flags Control_Flag
    );
    
    assign opcode = opcodes'(instr[6:0]);
    state_t currentState;
    state_t nextState;
    logic[31:0] oldPC;
    
    //State Register
    always_ff @ (posedge clk) begin
        currentState <= nextState;
    end
    
    //Next State Cloud
    always_comb begin
        case(currentState)
            FETCH_ADDR: nextState = FETCH_DATA;
            
            FETCH_DATA: nextState = DECODE;
            
            DECODE: nextState = EXEC;
            
            EXEC: begin
                if(opcode == OP_Load || opcode == OP_Store)
                    nextState = MEM_ACC;
                else
                    nextState = WRITE_BCK;
            end
            
            MEM_ACC: nextState = WRITE_BCK;
            
            WRITE_BCK: nextState = FETCH_ADDR;
         endcase
     end
    
    //Output Cloud
    always_comb begin
        ALU_Flag = '0;
        Memory_Flag = '0;
        Control_Flag = '0;

        case(currentState)
            FETCH_ADDR: begin
                Control_Flag.memRead = 1'b1; //Reading current PC-Value
                Control_Flag.oldPC_Write = 1'b1;l
                
                //Next PC value calculation
                ALU_Flag.ALU_Opp = ALU_ADD;
                ALU_Flag.ALU_SelectA = 1'b1;
                ALU_Flag.ALU_SelectB = 2'b10;
                Control_Flag.ALUOut_Write = 1'b1;
            end
             
            FETCH_DATA: begin
                Control_Flag.IR_Write = 1'b1;
                Control_Flag.PCMux = 2'b00; //Select ALUOut reg
                Control_Flag.PC_Write = 1'b1;
            end
                

endmodule
