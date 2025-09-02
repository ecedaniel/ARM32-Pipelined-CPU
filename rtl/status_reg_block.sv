module status_reg_block(
    // Clock and reset
    input  clk,
    input  rst_n,
    
    // Control inputs
    input         en_status,    // Enable status register update
    input         status_rdy,   // Status ready signal
    
    // Data inputs/outputs
    input  [31:0] status_in,    // New status flags from ALU
    output logic [31:0] status_out  // Current status flags
);

    /*
    *** Status Register Block ***
    Manages ARM32 condition flags in the status register:
    
    Bit 31: N (Negative) - Set when result is negative
    Bit 30: Z (Zero)     - Set when result is zero
    Bit 29: C (Carry)    - Set when carry out occurs
    Bit 28: V (Overflow) - Set when signed overflow occurs
    Bits 27-0: Reserved  - Unused bits
    
    The status register is updated when en_status is high,
    and the output can be either the current register value
    or the new input value based on status_rdy.
    */

    // Status register storage
    logic [31:0] status_reg;

    // Output logic - select between current register or new input
    assign status_out = status_rdy ? status_in : status_reg;

    // Status register update with reset
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            status_reg <= 32'b0;  // Reset all flags to zero
        end else if (en_status) begin
            status_reg <= status_in;
        end
    end

endmodule