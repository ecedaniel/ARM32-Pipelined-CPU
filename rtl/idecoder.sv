module idecoder(
    // Input
    input  [31:0] instr,     // 32-bit ARM instruction
    
    // Decoded instruction fields
    output logic [3:0]  cond,      // Condition code
    output logic [6:0]  opcode,    // Opcode for instruction
    output logic        en_status, // Enable status register
    output logic [3:0]  rn,        // Rn (first operand register)
    output logic [3:0]  rd,        // Rd (destination register)
    output logic [3:0]  rs,        // Rs (shift register)
    output logic [3:0]  rm,        // Rm (second operand register)
    output logic [1:0]  shift_op,  // Shift operation type
    output logic [4:0]  imm5,      // 5-bit immediate value
    output logic [11:0] imm12,     // 12-bit immediate value
    output logic [23:0] imm24,     // 24-bit immediate for branching
    output logic        P,         // Pre-indexing flag
    output logic        U,         // Up/Down flag
    output logic        W          // Write-back flag
);

    /*
    *** ARM32 Instruction Decoder ***
    Decodes 32-bit ARM instructions into control signals and operands.
    
    Instruction Types:
    - Data Processing (00): ADD, SUB, AND, ORR, EOR, MOV, CMP
    - Memory Access (01): LDR, STR with various addressing modes
    - Branch (10): B, BL, BX, BLX
    
    Addressing Modes:
    - Immediate: Uses immediate values
    - Register: Uses register operands
    - Register Shifted: Uses register with shift operations
    */

    // Internal signals for instruction type detection
    logic type_I;   // Immediate addressing
    logic type_RS;  // Register shifted addressing

    // Extract instruction fields
    assign cond = instr[31:28];      // Condition code
    assign type_I = instr[25];       // Immediate bit
    assign P = instr[24];            // Pre-indexing flag
    assign U = instr[23];            // Up/Down flag
    assign W = instr[21];            // Write-back flag
    assign en_status = instr[20];    // Status register enable
    assign rn = instr[19:16];        // First operand register
    assign rd = instr[15:12];        // Destination register
    assign rs = instr[11:8];         // Shift register
    assign rm = instr[3:0];          // Second operand register
    assign shift_op = instr[6:5];    // Shift operation type
    assign imm5 = instr[11:7];       // 5-bit immediate
    assign imm12 = instr[11:0];      // 12-bit immediate
    assign imm24 = instr[23:0];      // 24-bit immediate for branches

    // Determine if register shifted addressing
    assign type_RS = ~type_I & (instr[4] == 1'b1);

    // Opcode generation based on instruction type
    always_comb begin
        case (instr[27:26])
            2'b00: begin // Data Processing Instructions
                if (instr[27:21] == 7'b0011001) begin // NOP
                    opcode = 7'b0000000;
                end else if (instr[27:21] == 7'b0001000) begin // HALT
                    opcode = 7'b0000001;
                end else if (instr[27:21] == 7'b0001001) begin // BX and BLX
                    if (instr[5] == 1'b0) begin  // BX
                        opcode = 7'b1001001;
                    end else begin              // BLX
                        opcode = 7'b1001101;
                    end
                end else begin
                    if (type_I) begin
                        // Immediate addressing
                        case (instr[24:21])
                            4'b0100: opcode = 7'b0000100; // ADD immediate
                            4'b0010: opcode = 7'b0001001; // SUB immediate
                            4'b1010: opcode = 7'b0001010; // CMP immediate
                            4'b0000: opcode = 7'b0001011; // AND immediate
                            4'b1100: opcode = 7'b0001100; // ORR immediate
                            4'b0001: opcode = 7'b0001101; // EOR immediate
                            4'b1101: opcode = 7'b0000000; // MOV immediate
                            default: opcode = 7'b0000001; // HALT
                        endcase
                    end else if (type_RS) begin
                        // Register shifted addressing
                        case (instr[24:21])
                            4'b0100: opcode = 7'b0111000; // ADD register shifted
                            4'b0010: opcode = 7'b0111001; // SUB register shifted
                            4'b1010: opcode = 7'b0111010; // CMP register shifted
                            4'b0000: opcode = 7'b0111011; // AND register shifted
                            4'b1100: opcode = 7'b0111100; // ORR register shifted
                            4'b0001: opcode = 7'b0111101; // EOR register shifted
                            4'b1101: opcode = 7'b0110000; // MOV register shifted
                            default: opcode = 7'b0000001; // HALT
                        endcase
                    end else begin
                        // Register addressing
                        case (instr[24:21])
                            4'b0100: opcode = 7'b0011000; // ADD register
                            4'b0010: opcode = 7'b0011001; // SUB register
                            4'b1010: opcode = 7'b0011010; // CMP register
                            4'b0000: opcode = 7'b0011011; // AND register
                            4'b1100: opcode = 7'b0011100; // ORR register
                            4'b0001: opcode = 7'b0011101; // EOR register
                            4'b1101: opcode = 7'b0010000; // MOV register
                            default: opcode = 7'b0000001; // HALT
                        endcase
                    end
                end
            end

            2'b01: begin // Memory Access Instructions (LDR/STR)
                if (instr[20] == 1'b1) begin // LDR
                    if (instr[25] == 1'b0) begin // Immediate addressing
                        if (instr[19:16] == 4'b1111) begin // LDR literal
                            opcode = 7'b1000000;
                        end else begin // LDR immediate
                            opcode = 7'b1100000;
                        end
                    end else begin // LDR register
                        opcode = 7'b1101000;
                    end
                end else begin // STR
                    if (instr[25] == 1'b0) begin // STR immediate
                        opcode = 7'b1110000;
                    end else begin // STR register
                        opcode = 7'b1111000;
                    end
                end
            end

            2'b10: begin // Branch Instructions
                if (instr[25:24] == 2'b10) begin // B (branch)
                    opcode = 7'b1001000;
                end else begin // BL (branch with link)
                    opcode = 7'b1001100;
                end
            end

            default: begin // Undefined instruction
                opcode = 7'b0000001; // HALT
            end
        endcase
    end
endmodule
