module ALU(
    input  [31:0] val_A,
    input  [31:0] val_B,
    input  [2:0]  ALU_op,
    output logic [31:0] ALU_out,
    output logic [7:0]  ALU_flags
);

/* 
    ALU Operations:
    000: Addition
    001: Subtraction  
    010: AND
    011: OR
    100: XOR
    101: NOT
    
    Output flags:
    7: Negative flag
    6: Zero flag
    5: Invalid flag (unused)
    4: Overflow flag
    3: Greater than or Equal flag
    2: Less than flag
    1: Greater than flag
    0: Less than or Equal flag 
*/

    logic [31:0] sum_result;
    logic [31:0] diff_result;
    logic        overflow_add, overflow_sub;
    logic        signed_ge, signed_lt, signed_gt, signed_le;

    always_comb begin
        // Calculate arithmetic results
        sum_result = $signed(val_A) + $signed(val_B);
        diff_result = $signed(val_A) - $signed(val_B);
        
        // Overflow detection for signed arithmetic
        overflow_add = (val_A[31] == val_B[31]) && (val_A[31] != sum_result[31]);
        overflow_sub = (val_A[31] != val_B[31]) && (val_A[31] != diff_result[31]);
        
        // Comparison flags for signed values
        signed_ge = ($signed(val_A) >= $signed(val_B));
        signed_lt = ($signed(val_A) < $signed(val_B));
        signed_gt = ($signed(val_A) > $signed(val_B));
        signed_le = ($signed(val_A) <= $signed(val_B));
        
        // ALU operation selection
        case(ALU_op)
            3'b000: begin // Addition
                ALU_out = sum_result;
                ALU_flags[4] = overflow_add;
            end
            3'b001: begin // Subtraction
                ALU_out = diff_result;
                ALU_flags[4] = overflow_sub;
            end
            3'b010: begin // AND
                ALU_out = val_A & val_B;
                ALU_flags[4] = 1'b0;
            end
            3'b011: begin // OR
                ALU_out = val_A | val_B;
                ALU_flags[4] = 1'b0;
            end
            3'b100: begin // XOR
                ALU_out = val_A ^ val_B;
                ALU_flags[4] = 1'b0;
            end
            3'b101: begin // NOT
                ALU_out = ~val_A;
                ALU_flags[4] = 1'b0;
            end
            default: begin // Default case
                ALU_out = 32'b0;
                ALU_flags[4] = 1'b0;
            end
        endcase
        
        // Common flags for all operations
        ALU_flags[7] = ALU_out[31];                    // Negative flag
        ALU_flags[6] = (ALU_out == 32'b0);             // Zero flag
        ALU_flags[5] = 1'b0;                           // Invalid flag (unused)
        ALU_flags[3] = signed_ge;                      // Greater than or Equal
        ALU_flags[2] = signed_lt;                      // Less than
        ALU_flags[1] = signed_gt;                      // Greater than
        ALU_flags[0] = signed_le;                      // Less than or Equal
    end

endmodule
