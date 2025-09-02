module datapath(
    // Clock and reset
    input  clk,
    input  rst_n,
    
    // Register file write inputs
    input  [3:0]  w_addr1,
    input         w_en1,
    input  [3:0]  w_addr2,
    input         w_en2,
    input  [3:0]  w_addr_ldr,
    input         w_en_ldr,
    input  [31:0] w_data_ldr,
    
    // Register file read addresses
    input  [3:0]  A_addr,
    input  [3:0]  B_addr,
    input  [3:0]  shift_addr,
    input  [3:0]  str_addr,
    input  [3:0]  reg_addr,      // For testing/debugging
    
    // PC control
    input  [1:0]  sel_pc,
    input         load_pc,
    input  [10:0] start_pc,
    
    // Forwarding mux selects
    input  [1:0]  sel_A_in,
    input  [1:0]  sel_B_in,
    input  [1:0]  sel_shift_in,
    
    // Register enables
    input         en_A,
    input         en_B,
    input         en_S,
    
    // Shifter inputs
    input  [31:0] shift_imme,
    input         sel_shift,
    input  [1:0]  shift_op,
    
    // ALU inputs
    input         sel_A,
    input         sel_B,
    input         sel_post_indexing,
    input  [31:0] imme_data,
    input  [2:0]  ALU_op,
    
    // Status register
    input         en_status,
    input         status_rdy,
    input  [31:0] LR_in,
    input         sel_load_LR,
    
    // Outputs
    output logic [31:0] datapath_out,
    output logic [31:0] status_out,
    output logic [31:0] str_data,
    output logic [10:0] PC,
    output logic [31:0] reg_output
);  
  
    /*
    *** Datapath Architecture ***
    The datapath contains:
    1. Register File - 16 ARM registers with multiple read/write ports
    2. ALU - Arithmetic and logic operations
    3. Shifter - Barrel shifter for shift/rotate operations
    4. Status Register - Condition flags (N, Z, C, V)
    5. Pipeline Registers - A, B, S registers for data staging
    6. Forwarding Muxes - Data forwarding for pipeline efficiency
    */

    // Register file signals
    logic [31:0] A_data, B_data, shift_data, str_data_rf;
    logic [10:0] pc_out;
    logic [31:0] reg_output_rf;

    // ALU and shifter signals
    logic [31:0] shift_out;
    logic [31:0] val_A, val_B, ALU_out, shift_amt, status_in;

    // Forwarding mux outputs
    logic [31:0] A_in, B_in, shift_in;

    // Pipeline registers
    logic [31:0] A_reg, B_reg, S_reg, status_out_reg;

    // Write data and address muxes
    logic [31:0] w_data1;
    logic [3:0]  w_addr1_in;

    // Output assignments
    assign PC = pc_out;
    assign reg_output = reg_output_rf;
    assign status_out = status_out_reg;
    assign str_data = str_data_rf;

    // Module instantiations
    regfile regfile(
        .clk(clk),
        .w_data1(w_data1),
        .w_addr1(w_addr1_in),
        .w_en1(w_en1),
        .w_data2(ALU_out),
        .w_addr2(w_addr2),
        .w_en2(w_en2),
        .w_data_ldr(w_data_ldr),
        .w_addr_ldr(w_addr_ldr),
        .w_en_ldr(w_en_ldr),
        .sel_pc(sel_pc),
        .load_pc(load_pc),
        .start_pc(start_pc),
        .dp_pc(ALU_out[10:0]),
        .A_addr(A_addr),
        .B_addr(B_addr),
        .shift_addr(shift_addr),
        .str_addr(str_addr),
        .A_data(A_data),
        .B_data(B_data),
        .shift_data(shift_data),
        .str_data(str_data_rf),
        .pc_out(pc_out),
        .reg_output(reg_output_rf),
        .reg_addr(reg_addr)
    );

    shifter shifter(
        .shift_in(B_reg),
        .shift_op(shift_op),
        .shift_amt(S_reg),
        .shift_out(shift_out)
    );

    ALU alu(
        .val_A(val_A),
        .val_B(val_B),
        .ALU_op(ALU_op),
        .ALU_out(ALU_out),
        .ALU_flags(status_in)
    );

    status_reg_block status_reg(
        .clk(clk),
        .rst_n(rst_n),
        .en_status(en_status),
        .status_rdy(status_rdy),
        .status_in(status_in),
        .status_out(status_out_reg)
    );

    // Combinational logic - multiplexers and data paths
    assign datapath_out = sel_post_indexing ? val_A : ALU_out;
    assign w_data1 = sel_load_LR ? LR_in : ALU_out;
    assign w_addr1_in = sel_load_LR ? 4'd14 : w_addr1;  // LR is R14
    assign val_A = sel_A ? 32'b0 : A_reg;
    assign val_B = sel_B ? imme_data : shift_out; 
    assign shift_amt = sel_shift ? shift_in : shift_imme;

    // Forwarding multiplexers for pipeline efficiency
    always_comb begin
        case (sel_A_in)
            2'b00: A_in = A_data;        // Normal register read
            2'b01: A_in = ALU_out;       // Forward from ALU
            2'b11: A_in = {21'b0, pc_out}; // PC value (32-bit)
            default: A_in = A_data;
        endcase
    end

    always_comb begin
        case (sel_B_in)
            2'b00: B_in = B_data;        // Normal register read
            2'b01: B_in = ALU_out;       // Forward from ALU
            2'b11: B_in = val_B;         // Forward from B path
            default: B_in = B_data;
        endcase
    end

    always_comb begin
        case (sel_shift_in)
            2'b00: shift_in = shift_data; // Normal register read
            2'b01: shift_in = ALU_out;    // Forward from ALU
            2'b11: shift_in = 32'b0;      // Zero for immediate shifts
            default: shift_in = shift_data;
        endcase
    end

    // Pipeline registers with reset functionality
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_reg <= 32'b0;
        end else if (en_A) begin
            A_reg <= A_in;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            B_reg <= 32'b0;
        end else if (en_B) begin
            B_reg <= B_in;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            S_reg <= 32'b0;
        end else if (en_S) begin
            S_reg <= shift_amt;
        end
    end

endmodule