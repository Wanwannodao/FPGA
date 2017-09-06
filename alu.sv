`timescale 1ns / 1ps
module alu
    (
        input logic [3:0] a,      // src1
        input logic [3:0] b,      // src2
        input logic [2:0] cntl,   // ALU control
        output logic [3:0] result // result
    );
    always_comb begin
        case (cntl)
            3'b000: result = a;
            3'b010: result = a & b;
            3'b011: result = a | b;
            3'b100: result = a <<< 1;
            3'b101: result = a >>> 1;
            3'b110: result = a + b;
            3'b111: result = a - b;
        endcase
    end 
endmodule


