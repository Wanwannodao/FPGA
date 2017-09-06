`timescale 1ns / 1ps
module acc_machine(
        input logic resetn,
        input logic clk,
        output logic [3:0] acc_out
    );
    
    localparam logic [1:0] IF = 2'b01; // inst fetch
    localparam logic [1:0] EX = 2'b10; // execution
    logic [1:0] state = IF;
    
    logic [3:0] opecode = 4'b0;
    logic [3:0] operand = 4'b0;
    
    logic [3:0] pc = 4'b0;       // program counter register
    logic [3:0] acc = 4'b0;      // accumulator register
    
    logic [2:0] cntl = 3'b0;     // alu controll
    logic [3:0] result = 4'b0;   // alu result
    logic [3:0] b = 4'b0;        // alu src b
    // ALU
    alu ALU(.a(acc), .b(b), .cntl(cntl), .result(result));
       
    // DMEM
    //logic d_oe = 1'b0;
    logic d_we = 1'b0;
    logic [3:0] d = 4'b0;
    dmem #(.DWIDTH('d4), .AWIDTH('d4)) DMEM(.clk(clk), .w_en(d_we), .addr(operand), .wdata(acc), .odata(d));
    
    logic taken = 1'b0;
    
    // IMEM
    logic [7:0] imem[0:1<<4];
    integer i;
    initial begin
        imem[0] = 8'b00000000;
        imem[1] = 8'b00011000;
        imem[2] = 8'b01101001;
        imem[3] = 8'b10001010;
        for (i=4; i<(1<<4); ++i) begin
            imem[i] = 8'b0;
        end
    end
    
    assign acc_out = acc;
    
    always_comb begin
        if (opecode == 4'b1001 && |acc != 1'b0) begin
            taken <= 1'b1;
        end else if (opecode == 4'b1010 && |acc == 1'b0) begin
            taken <= 1'b1;
        end
    end
    
    // PC
    always_ff @(posedge clk) begin
        if (resetn) begin
            if(state == IF) begin
                if (taken) begin
                    pc <= operand;
                end else begin
                    pc <= pc + 1;
                end
            end
        end else begin
            pc <= 4'b0;
        end
    end
    // Opecode, Operand
    assign {opecode, operand} = imem[pc];
    
    always_comb begin
        if (state == EX && opecode == 4'b1000) begin
            d_we <= 1'b1;
        end else begin
            d_we <= 1'b0;
        end
    end
    
    always_comb begin
        if (state == EX && opecode != 4'b0001 && opecode != 4'b1000) begin
            cntl <= opecode[2:0];
            b <= d;
        end else begin
            cntl <= 3'b0;
            b <= 4'b0;
        end
    end
    
    // ACC
    always_ff @(posedge clk) begin
        if (resetn) begin
            if (state == EX && opecode == 4'b0001) begin
                acc <= d;
            end else if (state == EX && opecode == 4'b1100) begin
                acc <= operand;
            end else if (state == EX && opecode == 4'b1111) begin
                acc <= acc - operand;
            end else if (state == EX && opecode != 4'b0001 && opecode != 4'b1000) begin
                acc <= result;
            end
        end else begin
            acc <= 4'b0;
        end
    end
    
    // state
    always_ff @(posedge clk) begin
        if (resetn) begin
            if (state == IF) state <= EX;
            else state <= IF;
        end else begin
            state <= IF;
        end
    end
endmodule
