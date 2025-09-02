module regfile(
    // Clock
    input  clk,
    
    // Write ports
    input  [31:0] w_data1,
    input  [3:0]  w_addr1,
    input         w_en1,
    input  [31:0] w_data2,
    input  [3:0]  w_addr2,
    input         w_en2,
    input  [31:0] w_data_ldr,
    input  [3:0]  w_addr_ldr,
    input         w_en_ldr,
    
    // Read addresses
    input  [3:0]  A_addr,
    input  [3:0]  B_addr,
    input  [3:0]  shift_addr,
    input  [3:0]  str_addr,
    input  [3:0]  reg_addr,
    
    // PC control
    input  [1:0]  sel_pc,
    input         load_pc,
    input  [10:0] start_pc,
    input  [10:0] dp_pc,
    
    // Outputs
    output logic [31:0] A_data,
    output logic [31:0] B_data,
    output logic [31:0] shift_data,
    output logic [31:0] str_data,
    output logic [10:0] pc_out,
    output logic [31:0] reg_output
);

    /*
    *** About ***
    - 16 registers (R0-R15) 32 bits each
    - 4 bits for address (0-15)
    - 32 bits for data
    - Read is combinational
    - Write is sequential
    - R0 is always zero (ARM convention)

    *** Registers ***
    R0  - Always Zero (hardwired to 0)
    R1  - General Purpose
    R2  - General Purpose
    R3  - General Purpose
    R4  - General Purpose
    R5  - General Purpose
    R6  - General Purpose
    R7  - Holds System Call Number
    R8  - General Purpose
    R9  - General Purpose
    R10 - General Purpose
    R11 - Frame Pointer (FP)
    R12 - Intra Procedural Call (IP)
    R13 - Stack Pointer (SP)
    R14 - Link Register (LR)
    R15 - Program Counter (PC)
    */

    logic [31:0] registers[1:15];  // R1-R15 (R0 is hardwired to zero)
    logic [10:0] pc_in;

    // Initialize registers
    initial begin
        for (int i = 1; i <= 15; i++) begin
            registers[i] = 32'b0;
        end
    end

    // Read logic with R0 hardwired to zero
    function logic [31:0] read_register(input [3:0] addr);
        if (addr == 4'd0) begin
            return 32'b0;  // R0 is always zero
        end else begin
            return registers[addr];
        end
    endfunction

    // Combinational read outputs
    assign A_data      = read_register(A_addr);
    assign B_data      = read_register(B_addr);
    assign shift_data  = read_register(shift_addr);
    assign str_data    = read_register(str_addr);
    assign reg_output  = read_register(reg_addr);
    assign pc_out      = registers[4'd15][10:0];  // PC is 11 bits
    assign pc_in       = pc_out + 1'b1;
    
    // Sequential write logic with priority
    always_ff @(posedge clk) begin
        // Write priority: w_en1 > w_en2 > w_en_ldr
        if (w_en1 && w_addr1 != 4'd0) begin
            registers[w_addr1] <= w_data1;
        end else if (w_en2 && w_addr2 != 4'd0) begin
            registers[w_addr2] <= w_data2;
        end else if (w_en_ldr && w_addr_ldr != 4'd0) begin
            registers[w_addr_ldr] <= w_data_ldr;
        end
        
        // PC update (highest priority)
        if (load_pc) begin
            case (sel_pc)
                2'b01: registers[4'd15] <= {21'b0, start_pc};
                2'b11: registers[4'd15] <= {21'b0, dp_pc};
                default: registers[4'd15] <= {21'b0, pc_in};
            endcase
        end
    end

endmodule
