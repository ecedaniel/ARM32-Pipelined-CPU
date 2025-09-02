module cpu (
    // Clock and reset
    input  clk,
    input  rst_n,
    
    // Instruction and data inputs
    input  [31:0] instr,
    input  [31:0] ram_data2,
    input  [10:0] start_pc,
    input  [3:0]  reg_addr,  // For testing/debugging
    
    // Control outputs
    output logic         waiting,
    output logic         ram_w_en1,
    output logic         ram_w_en2,
    output logic [10:0]  ram_addr2,
    output logic [31:0]  ram_in2,
    
    // Status and data outputs
    output logic [31:0]  status_out,
    output logic [31:0]  datapath_out,
    output logic [10:0]  pc_out,
    output logic [31:0]  reg_output
);

    /*
    *** CPU Architecture Overview ***
    The CPU consists of three main components:
    1. Instruction Decoder (idecoder) - Decodes ARM32 instructions
    2. Datapath - Contains ALU, register file, and data processing logic
    3. Controller - State machine that controls instruction execution pipeline
    
    *** Instruction Pipeline ***
    Fetch → Decode → Execute → Memory → Write Back
    */

    // Instruction register
    logic [31:0] instr_reg;

    // Instruction decoder outputs
    logic [3:0]  cond;           // Condition code
    logic [6:0]  opcode;         // Operation code
    logic        en_status_decode; // Enable status register decode
    logic [3:0]  rn, rd, rs, rm; // Register addresses
    logic [1:0]  shift_op;       // Shift operation type
    logic [4:0]  imm5;           // 5-bit immediate
    logic [11:0] imm12;          // 12-bit immediate
    logic [23:0] imm24;          // 24-bit immediate
    logic        P, U, W;        // Memory addressing flags
    
    // rt is same as rd for this implementation
    logic [3:0] rt;
    assign rt = rd;

    // Datapath outputs
    logic [31:0] status_out_dp;
    logic [31:0] datapath_out_dp;
    logic [31:0] str_data_dp;
    logic [10:0] pc_out_dp;
    logic [31:0] reg_output_dp;

    // Controller outputs
    logic        waiting_ctrl;
    logic        w_en1, w_en2, w_en_ldr, sel_load_LR;
    logic [1:0]  sel_A_in, sel_B_in, sel_shift_in;
    logic        en_A, en_B, en_C, en_S;
    logic        sel_A, sel_B, sel_post_indexing;
    logic [2:0]  ALU_op;
    logic        en_status, status_rdy_ctrl;
    logic        load_ir, load_pc_ctrl;
    logic [1:0]  sel_pc_ctrl;
    logic        ram_w_en1_ctrl, ram_w_en2_ctrl;

    // Output assignments
    assign waiting = waiting_ctrl;
    assign status_out = status_out_dp;
    assign datapath_out = datapath_out_dp;
    assign pc_out = pc_out_dp;
    assign reg_output = reg_output_dp;
    assign ram_addr2 = datapath_out_dp[10:0];
    assign ram_in2 = str_data_dp;
    assign ram_w_en1 = ram_w_en1_ctrl;
    assign ram_w_en2 = ram_w_en2_ctrl;

    // idecoder module
    idecoder idecoder(
        .instr(instr_reg),
        .cond(cond),
        .opcode(opcode),
        .en_status(en_status_decode),
        .rn(rn),
        .rd(rd),
        .rs(rs),
        .rm(rm),
        .shift_op(shift_op),
        .imm5(imm5),
        .imm12(imm12),
        .imm24(imm24),
        .P(P),
        .U(U),
        .W(W)
    );

    // Datapath module
    datapath datapath(
        .clk(clk),
        .rst_n(rst_n),
        .LR_in(ram_data2),
        .sel_load_LR(sel_load_LR),
        .w_addr1(rd),
        .w_en1(w_en1),
        .w_addr2(rn),
        .w_en2(w_en2),
        .w_addr_ldr(rt),           // For LDR
        .w_en_ldr(w_en_ldr),
        .w_data_ldr(ram_data2),    // For LDR
        .A_addr(rn),
        .B_addr(rm),
        .shift_addr(rs),
        .str_addr(rt),
        .reg_addr(reg_addr),       // For testing/debugging
        .sel_pc(sel_pc_ctrl),
        .load_pc(load_pc_ctrl),
        .start_pc(start_pc),
        .sel_A_in(sel_A_in),
        .sel_B_in(sel_B_in),
        .sel_shift_in(sel_shift_in),
        .en_A(en_A),
        .en_B(en_B),
        .en_S(en_S),
        .shift_imme({27'd0, imm5}),
        .sel_shift(1'b0),          // Fixed: provide default value
        .shift_op(shift_op),
        .sel_A(sel_A),
        .sel_B(sel_B),
        .sel_post_indexing(sel_post_indexing),
        .imme_data({20'd0, imm12}),
        .ALU_op(ALU_op),
        .en_status(en_status),
        .status_rdy(status_rdy_ctrl),
        .datapath_out(datapath_out_dp),
        .status_out(status_out_dp),
        .str_data(str_data_dp),
        .PC(pc_out_dp),
        .reg_output(reg_output_dp)
    );

    // Controller module
    controller controller(
        .clk(clk),
        .rst_n(rst_n),
        .opcode(opcode),
        .status_reg(status_out_dp),
        .cond(cond),
        .P(P),
        .U(U),
        .W(W),
        .en_status_decode(en_status_decode),
        .waiting(waiting_ctrl),
        .w_en1(w_en1),
        .w_en2(w_en2),
        .w_en_ldr(w_en_ldr),
        .sel_load_LR(sel_load_LR),
        .sel_A_in(sel_A_in),
        .sel_B_in(sel_B_in),
        .sel_shift_in(sel_shift_in),
        .en_A(en_A),
        .en_B(en_B),
        .en_C(en_C),
        .en_S(en_S),
        .sel_A(sel_A),
        .sel_B(sel_B),
        .sel_post_indexing(sel_post_indexing),
        .ALU_op(ALU_op),
        .en_status(en_status),
        .status_rdy(status_rdy_ctrl),
        .load_ir(load_ir),
        .load_pc(load_pc_ctrl),
        .sel_pc(sel_pc_ctrl),
        .ram_w_en1(ram_w_en1_ctrl),
        .ram_w_en2(ram_w_en2_ctrl)
    );

    // Instruction register - stores current instruction during execution
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            instr_reg <= 32'b0;
        end else if (load_ir) begin
            instr_reg <= instr;
        end
    end

endmodule