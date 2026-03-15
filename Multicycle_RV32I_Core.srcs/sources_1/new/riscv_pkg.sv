package riscv_pkg;

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
        SZ_Word = 3'b100,
        SZ_Half = 3'b010,
        SZ_Byte = 3'b001
    } dataSize;
    
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
        logic store;
        logic memWriteInstr;
        logic memRead;
    } Memory_Flags;
    
    typedef struct packed
    {
        logic register;
        logic RegStore;
        logic RegLoad;
        logic [1:0] RegMux;
    } Register_Flags;
    
    typedef struct packed
    {
        logic branch;
        logic jump;
        logic upperImm;
        logic PC_Load;
        logic IR_Write;
        logic branchEnable;
        logic TR_Load;
    } Control_Flags;
    
    
    

endpackage : riscv_pkg