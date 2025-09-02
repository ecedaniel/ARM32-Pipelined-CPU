module tb_regfile(output err);

    //regs for testbench
    reg [31:0] w_data1, w_data2, w_data_ldr, A_data, B_data, shift_data, str_data, reg_output;
    reg [3:0] A_addr, B_addr, shift_addr, str_addr, w_addr1, w_addr2, w_addr_ldr, reg_addr;
    reg [1:0] sel_pc;
    reg [10:0] start_pc, dp_pc, pc_out;
    reg w_en1, w_en2, w_en_ldr, load_pc, clk;
    integer error_count = 0;

    // tasks
    task check(input [31:0] expected, input [31:0] actual, input [3:0] addr, integer test_num);
        begin
            if (expected !== actual) begin
            $display("Test %d failed. Expected: %d, Actual: %d", test_num, expected, actual);
            error_count = error_count + 1;
            end
        end
    endtask: check

    // clk task
    task clkR;
        begin
            clk = 1'b0;
            #5;
            clk = 1'b1;
            #5;
        end
    endtask: clkR

    // DUT
    regfile regfile(
        .clk(clk),
        .w_data1(w_data1),
        .w_addr1(w_addr1),
        .w_en1(w_en1),
        .w_data2(w_data2),
        .w_addr2(w_addr2),
        .w_en2(w_en2),
        .w_data_ldr(w_data_ldr),
        .w_addr_ldr(w_addr_ldr),
        .w_en_ldr(w_en_ldr),
        .A_addr(A_addr),
        .B_addr(B_addr),
        .shift_addr(shift_addr),
        .str_addr(str_addr),
        .reg_addr(reg_addr),
        .sel_pc(sel_pc),
        .load_pc(load_pc),
        .start_pc(start_pc),
        .dp_pc(dp_pc),
        .A_data(A_data),
        .B_data(B_data),
        .shift_data(shift_data),
        .str_data(str_data),
        .pc_out(pc_out),
        .reg_output(reg_output)
    );

    integer i = 0;
    initial begin
        // Initialize all signals
        w_data1 = 0; w_data2 = 0; w_data_ldr = 0;
        w_addr1 = 0; w_addr2 = 0; w_addr_ldr = 0;
        w_en1 = 0; w_en2 = 0; w_en_ldr = 0;
        A_addr = 0; B_addr = 0; shift_addr = 0; str_addr = 0; reg_addr = 0;
        sel_pc = 0; load_pc = 0; start_pc = 0; dp_pc = 0;
        
        $display("Starting register file tests...");
        
        // Test R0 always returns zero (ARM convention)
        $display("Testing R0 zero behavior...");
        w_data1 = 32'hDEADBEEF;  // Try to write non-zero to R0
        w_addr1 = 4'd0;
        w_en1 = 1'b1;
        A_addr = 4'd0;
        clkR;
        check(32'b0, A_data, 4'd0, 100);  // R0 should still read as zero
        
        // Test register write and read
        $display("Testing register write/read...");
        for (i = 1; i < 8; i = i + 1) begin  // Start from R1 (R0 is zero)
            w_data1 = i;
            w_addr1 = i;
            w_en1 = 1'b1;
            w_data2 = i + 8;
            w_addr2 = i + 8;
            w_en2 = 1'b1;
            A_addr = i;
            clkR;
            check(i, A_data, A_addr, i);
        end

        // Test multiple read ports
        $display("Testing multiple read ports...");
        for (i = 1; i < 14; i = i + 1) begin  // Test R1-R14
            w_en1 = 1'b0; w_en2 = 1'b0;
            A_addr = i;
            B_addr = i + 1;
            shift_addr = i + 2;
            str_addr = i + 3;
            reg_addr = i + 4;
            #10;
            if (i <= 7) check(i, A_data, A_addr, i + 200);
            if (i + 1 <= 7) check(i + 1, B_data, B_addr, i + 201);
            if (i + 2 <= 7) check(i + 2, shift_data, shift_addr, i + 202);
        end
        
        // Test LDR write port
        $display("Testing LDR write port...");
        w_data_ldr = 32'h12345678;
        w_addr_ldr = 4'd10;
        w_en_ldr = 1'b1;
        w_en1 = 0; w_en2 = 0;
        reg_addr = 4'd10;
        clkR;
        check(32'h12345678, reg_output, 4'd10, 300);

        // print test summary
        if (error_count == 0) begin
            $display("All register file tests passed!");
        end else begin
            $display("Failed %d register file tests", error_count);
        end
        
        err = (error_count > 0);
    end
endmodule: tb_regfile
