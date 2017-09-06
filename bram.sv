`timescale 1ns / 1ps
module bram
    #(parameter logic DWIDTH='d8, AWIDTH='d8) 
    (
        input logic sys_clock,
        input logic we_0,
        input logic we_1,
        input logic [AWIDTH-1:0] addr_0,
        input logic [AWIDTH-1:0] addr_1,
        inout logic [DWIDTH-1:0] data_0,
        inout logic [DWIDTH-1:0] data_1,
        
        input logic oe_0,
        input logic oe_1
    );
    
    localparam logic DEPTH = 1 << AWIDTH;
    
    logic [DWIDTH-1:0] d_0, d_1;
    logic [DWIDTH-1:0] mem [0:DEPTH-1];
    
    assign data_0 = (oe_0 && !we_0) ? d_0 : 'bz;
    assign data_1 = (oe_1 && !we_1) ? d_1 : 'bz;
    
    // Write
    always_ff @(posedge sys_clock) begin
        if (we_0) mem[addr_0] <= data_0;
        if (we_1) mem[addr_1] <= data_1;
    end
    
    // Read
    always_ff @(posedge sys_clock) begin
        if (oe_0 && !we_0) d_0 <= mem[addr_0];
        if (oe_1 && !we_1) d_1 <= mem[addr_1];
    end
    
    // Initialization
    integer i;
    initial begin
        for(i=0; i<DEPTH; ++i) begin
            mem[i] = 'b0;
        end
    end
endmodule

