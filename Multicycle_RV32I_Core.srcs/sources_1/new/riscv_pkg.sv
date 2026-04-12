package riscv_pkg;
//Regmux remeber 
    typedef enum logic[2:0]
    {
        FETCH_ADDR,
        FETCH_DATA,
        DECODE,
        EXEC,
        MEM_ACC,
        WRITE_BCK
    } state_t;

    typedef enum logic[3:0]
    {
        // Arithmetic
        ALU_ADD = 4'b0000, 
        ALU_SUB = 4'b1000,   
                            
        // Logical
        ALU_OR = 4'b0110,
        ALU_AND = 4'b0111,
        ALU_XOR = 4'b0100,
        
        // Shifts           
        ALU_SRL = 4'b0101, 
        ALU_SRA = 4'b1101, 

        // More Logical     
        ALU_SLL = 4'b0001, 
        ALU_SLT = 4'b0010,
        ALU_SLTU = 4'b0011
    } ALU_Opps;
    
    typedef enum logic[2:0]
    {
        BR_BEQ  = 3'b000, //Branch if equal
        BR_BNE  = 3'b001, //Branch if not equal
        BR_BLT  = 3'b100, //Branch if less than (Signed)
        BR_BGE  = 3'b101, //Branch if greater or equal (Signed)
        BR_BLTU = 3'b110, //Branch if less than (Unsigned)
        BR_BGEU = 3'b111  //Branch if greater or equal (Unsigned)
    }branchTypes;
    
    typedef enum logic[2:0]
    {
        SZ_Word = 3'b100,
        SZ_Half = 3'b010,
        SZ_Byte = 3'b001
    } dataSize;
    
    typedef enum logic[6:0]
    {
        // R-Type (1)
        OP_Reg = 7'b0110011, 
    
        // I-Type (2)
        OP_Imm = 7'b0010011, 
    
        // I-Type (2)
        OP_Load = 7'b0000011, 
    
        // I-Type (2)
        OP_JALR = 7'b1100111, 
    
        // S-Type (3)
        OP_Store = 7'b0100011, 
    
        // B-Type (4)
        OP_Branch = 7'b1100011, 
    
        // U-Type (5)
        OP_LUI = 7'b0110111, 
        
        // U-Type (5)
        OP_AUIPC = 7'b0010111, 
    
        // J-Type (6)
        OP_JAL = 7'b1101111  
    } opcodes;
    
    typedef struct packed
    {
        ALU_Opps ALU_Opp;
        logic [1:0] ALU_SelectB;
        logic ALU_SelectA;
    } ALU_Flags;
    
    typedef struct packed
    {
        dataSize dataWidth;
        logic signd;
        logic loadInstr;
        logic storeInstr;
        logic upperImm;
        logic memWrite;
        logic memRead;
    } Memory_Flags;
        
    typedef struct packed
    {
        logic branch;
        logic branchEnable;
        logic jump;
        logic PC_Write;
        logic IR_Write;
        logic Reg_Write;
        logic ALUOut_Write;
    } Control_Flags;
    
    
    

endpackage : riscv_pkg