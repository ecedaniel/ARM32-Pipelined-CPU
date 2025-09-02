module shifter(
    input  [31:0] shift_in,    // Input data to be shifted
    input  [1:0]  shift_op,    // Shift operation type
    input  [4:0]  shift_amt,   // Shift amount (0-31)
    output logic [31:0] shift_out  // Shifted output
);

    /*
    *** Shift Operations ***
    00: Logical Left Shift (LSL) - Fill with zeros
    01: Logical Right Shift (LSR) - Fill with zeros  
    10: Arithmetic Right Shift (ASR) - Fill with sign bit
    11: Rotate Right (ROR) - Circular shift
    
    *** Shift Amount ***
    - 5 bits allows shifts from 0 to 31 positions
    - Shifts >= 32 are undefined in ARM, so we clamp to 31
    */

    logic [4:0] valid_shift_amt;
    logic [31:0] rotate_amount;

    // Clamp shift amount to valid range (0-31)
    assign valid_shift_amt = (shift_amt > 5'd31) ? 5'd31 : shift_amt;
    
    // Calculate rotate amount for ROR operation
    assign rotate_amount = 32 - valid_shift_amt;

    always_comb begin
        case (shift_op)
            2'b00: begin // Logical Left Shift (LSL)
                shift_out = shift_in << valid_shift_amt;
            end
            2'b01: begin // Logical Right Shift (LSR)
                shift_out = shift_in >> valid_shift_amt;
            end
            2'b10: begin // Arithmetic Right Shift (ASR)
                shift_out = $signed(shift_in) >>> valid_shift_amt;
            end
            2'b11: begin // Rotate Right (ROR)
                if (valid_shift_amt == 5'd0) begin
                    shift_out = shift_in;  // No rotation
                end else begin
                    shift_out = (shift_in >> valid_shift_amt) | 
                               (shift_in << rotate_amount);
                end
            end
            default: begin // Default case (should never occur)
                shift_out = shift_in;
            end
        endcase
    end

endmodule
