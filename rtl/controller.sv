module controller(
    // Clock and reset
    input  clk,
    input  rst_n,
    
    // Instruction and status inputs
    input  [6:0]  opcode,
    input  [31:0] status_reg,
    input  [3:0]  cond,
    input         P,
    input         U,
    input         W,
    input         en_status_decode,
    
    // Control outputs
    output logic         waiting,
    output logic         w_en1,
    output logic         w_en2,
    output logic         w_en_ldr,
    output logic         sel_load_LR,
    output logic [1:0]   sel_A_in,
    output logic [1:0]   sel_B_in,
    output logic [1:0]   sel_shift_in,
    output logic         en_A,
    output logic         en_B,
    output logic         en_C,
    output logic         en_S,
    output logic         sel_A,
    output logic         sel_B,
    output logic         sel_post_indexing,
    output logic [2:0]   ALU_op,
    output logic         en_status,
    output logic         status_rdy,
    output logic         load_ir,
    output logic         load_pc,
    output logic [1:0]   sel_pc,
    output logic         ram_w_en1,
    output logic         ram_w_en2
);
    
    /*
    *** State Machine States ***
    - reset: Initial state, system reset
    - load_pc_start: Load initial PC value
    - fetch: Fetch instruction from memory
    - fetch_wait: Wait for memory access
    - decode: Decode instruction
    - execute: Execute instruction
    - memory_increment_pc: Memory access and PC increment
    - memory_wait: Wait for memory access completion
    - write_back: Write back results
    */
    localparam [3:0] RESET = 4'd0;
    localparam [3:0] FETCH = 4'd1;
    localparam [3:0] FETCH_WAIT = 4'd2;
    localparam [3:0] DECODE = 4'd3;
    localparam [3:0] EXECUTE = 4'd4;
    localparam [3:0] MEMORY_INCREMENT_PC = 4'd5;
    localparam [3:0] MEMORY_WAIT = 4'd6;
    localparam [3:0] WRITE_BACK = 4'd7;
    localparam [3:0] LOAD_PC_START = 4'd8;

    /*
    *** Instruction Opcodes ***
    */
    localparam [6:0] NOP = 7'b0000000;
    localparam [6:0] HLT = 7'b0000001;
    localparam [6:0] MOV_I = 7'b0001000;
    localparam [3:0] CMP = 4'b1010;

    /*
    *** ALU Operations ***
    */
    localparam [2:0] ALU_ADD = 3'b000;
    localparam [2:0] ALU_SUB = 3'b001;
    localparam [2:0] ALU_AND = 3'b010;
    localparam [2:0] ALU_ORR = 3'b011;
    localparam [2:0] ALU_XOR = 3'b100;

    // Status register bits
    logic N, Z, C, V;
    assign N = status_reg[31];
    assign Z = status_reg[30];
    assign C = status_reg[29];
    assign V = status_reg[28];

    // State register
    logic [3:0] state;

    // State machine - sequential logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= RESET;
        end else begin
            case (state)
                RESET: begin
                    state <= LOAD_PC_START;
                end
                LOAD_PC_START: begin
                    state <= FETCH;
                end
                FETCH: begin
                    state <= FETCH_WAIT;
                end
                FETCH_WAIT: begin
                    state <= DECODE;
                end
                DECODE: begin
                    state <= EXECUTE;
                end
                EXECUTE: begin
                    state <= MEMORY_INCREMENT_PC;
                end
                MEMORY_INCREMENT_PC: begin
                    state <= MEMORY_WAIT;
                end
                MEMORY_WAIT: begin
                    state <= WRITE_BACK;
                end
                WRITE_BACK: begin
                    state <= FETCH;
                end
                default: begin
                    state <= RESET;
                end
            endcase
        end
    end

    // Combinational logic - control signal generation
    always_comb begin
        // Default values for all outputs
        waiting = 1'b1;
        w_en1 = 1'b0;
        w_en2 = 1'b0;
        w_en_ldr = 1'b0;
        sel_load_LR = 1'b0;
        sel_A_in = 2'b00;
        sel_B_in = 2'b00;
        sel_shift_in = 2'b00;
        en_A = 1'b0;
        en_B = 1'b0;
        en_C = 1'b0;
        en_S = 1'b0;
        sel_A = 1'b0;
        sel_B = 1'b0;
        sel_post_indexing = 1'b0;
        ALU_op = ALU_ADD;
        en_status = 1'b0;
        status_rdy = 1'b0;
        load_ir = 1'b0;
        load_pc = 1'b0;
        sel_pc = 2'b00;
        ram_w_en1 = 1'b0;
        ram_w_en2 = 1'b0;

        case (state)
            RESET: begin
                waiting = 1'b1;
            end
            
            LOAD_PC_START: begin
                waiting = 1'b1;
                load_pc = 1'b1;
                sel_pc = 2'b01;
            end
            
            FETCH: begin
                waiting = 1'b1;
            end
            
            FETCH_WAIT: begin
                waiting = 1'b1;
            end
            
            DECODE: begin
                waiting = 1'b1;
                load_ir = 1'b1;
            end
            
            EXECUTE: begin
                waiting = 1'b1;

                // Normal data processing instructions
                if (opcode[6] == 1'b0 && cond != 4'b1111) begin
                    if (opcode[3]) begin
                        en_A = 1'b1;
                    end
                    if (opcode[4]) begin
                        en_B = 1'b1;
                    end
                    en_S = 1'b1;
                    if (opcode[4]) begin
                        sel_shift_in = 2'b00;
                    end else begin
                        sel_shift_in = 2'b00;
                    end
                end 
                // Memory instructions (STR/LDR)
                else if (opcode[6:5] == 2'b11 || opcode[6:3] == 4'b1000) begin
                    // Immediate addressing
                    if (opcode[3] == 1'b0) begin
                        if (opcode[6:4] == 3'b100) begin // LDR literal
                            sel_A_in = 2'b11; // Load from PC
                        end
                        sel_B_in = 2'b00; // Load from immediate
                        en_A = 1'b1;
                        en_B = 1'b0;
                        en_S = 1'b0;
                        sel_shift_in = 2'b00;
                    end 
                    // Register addressing
                    else begin
                        sel_A_in = 2'b00; // Load from Rn
                        sel_B_in = 2'b00; // Load from Rm
                        en_A = 1'b1;
                        en_B = 1'b1;
                        en_S = 1'b1;
                        sel_shift_in = 2'b00;
                    end
                end 
                // Branch instructions
                else if (opcode[6:3] == 4'b1001) begin
                    en_A = 1'b0;
                    if (opcode[1]) begin
                        en_B = 1'b1;
                    end
                    en_S = 1'b1;
                    sel_shift_in = 2'b11;
                end
            end
            
            MEMORY_INCREMENT_PC: begin
                waiting = 1'b1;
                en_C = 1'b1;

                // Normal data processing instructions
                if (opcode[6] == 1'b0 && cond != 4'b1111) begin
                    // Increment PC
                    sel_pc = 2'b00;
                    load_pc = 1'b1;

                    // ALU operation
                    case (opcode[2:0])
                        3'b000: ALU_op = ALU_ADD;
                        3'b001: ALU_op = ALU_SUB;
                        3'b010: ALU_op = ALU_AND;
                        3'b011: ALU_op = ALU_ORR;
                        3'b100: ALU_op = ALU_XOR;
                        default: ALU_op = ALU_ADD;
                    endcase

                    // Select inputs
                    if (opcode[3] == 1'b0) begin
                        sel_A = 1'b1;
                    end
                    if (opcode[4] == 1'b0) begin
                        sel_B = 1'b1;
                    end

                    sel_post_indexing = 1'b0;
                    sel_load_LR = 1'b0;
                    en_status = en_status_decode;
                    
                    // Write back (except for CMP)
                    if (opcode[3:0] != CMP) begin
                        w_en1 = 1'b1;
                    end

                    ram_w_en2 = 1'b0;
                end 
                // Memory instructions (STR/LDR)
                else if (opcode[6:5] == 2'b11 || opcode[6:3] == 4'b1000) begin
                    // Increment PC
                    sel_pc = 2'b00;
                    load_pc = 1'b1;

                    // ALU operation
                    if (U == 1'b0) begin
                        ALU_op = ALU_SUB;
                    end else begin
                        ALU_op = ALU_ADD;
                    end

                    sel_A = 1'b0; // Always from Rn
                    sel_post_indexing = ~P;
                    
                    if (opcode[3] == 1'b1) begin
                        sel_B = 1'b0; // Register addressing
                    end else begin
                        sel_B = 1'b1; // Immediate addressing
                    end

                    sel_load_LR = 1'b0;
                    en_status = en_status_decode;
                    w_en1 = 1'b0;
                    w_en2 = ~P | W;

                    // Memory write enable
                    if (opcode[4] == 1'b1) begin // STR
                        ram_w_en2 = 1'b1;
                    end else begin // LDR
                        ram_w_en2 = 1'b0;
                    end
                end 
                // Branch instructions
                else if (opcode[6:3] == 4'b1001) begin
                    // Conditional branch
                    if ((cond == 4'b0000 && Z) || 
                        (cond == 4'b0001 && ~Z) || 
                        (cond == 4'b0010 && C) || 
                        (cond == 4'b0011 && ~C) || 
                        (cond == 4'b0100 && N) || 
                        (cond == 4'b0101 && ~N) || 
                        (cond == 4'b0110 && V) || 
                        (cond == 4'b0111 && ~V) || 
                        (cond == 4'b1000 && C && ~Z) || 
                        (cond == 4'b1001 && (~C || Z)) || 
                        (cond == 4'b1010 && (N == V)) || 
                        (cond == 4'b1011 && (N != V)) || 
                        (cond == 4'b1100 && (~Z && (N == V))) || 
                        (cond == 4'b1101 && (Z || (N != V))) || 
                        (cond == 4'b1110)) begin
                        sel_pc = 2'b11;
                        load_pc = 1'b1;
                    end else begin
                        sel_pc = 2'b00;
                        load_pc = 1'b1;
                    end

                    // Write to LR if applicable
                    if (opcode[2] == 1'b1) begin
                        w_en1 = 1'b1;
                        sel_load_LR = 1'b0;
                    end

                    ALU_op = ALU_ADD;
                    sel_A = 1'b1;
                    
                    if (opcode[1] == 1'b1) begin
                        sel_B = 1'b0;
                    end else begin
                        sel_B = 1'b1;
                    end

                    sel_post_indexing = 1'b0;
                    en_status = 1'b0;
                end
            end
            
            MEMORY_WAIT: begin
                waiting = 1'b1;
                status_rdy = 1'b1;
            end
            
            WRITE_BACK: begin
                waiting = 1'b1;
                // LDR write back
                if (opcode[6:4] == 3'b110 || opcode[6:3] == 4'b1000) begin
                    w_en_ldr = 1'b1;
                end
            end
            
            default: begin
                waiting = 1'b1;
            end
        endcase
    end
    
    

endmodule
