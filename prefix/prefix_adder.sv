`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/19/2018 04:18:21 AM
// Design Name: 
// Module Name: prefix_adder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

typedef enum { black, gray } cell_type;

module pg_block #(parameter L=2, cell_type T=black) (
    input bit [2**L-1:0] p_h, p_l, g_h, g_l,
    output bit [2**(L+1)-1:0] p, g 
);
    function bit [1:0] black_cell 
        ( int i, 
          input bit [2**L-1:0] p_h, p_l, g_h, g_l );
        return {  p_h[i] & p_l[2**L-1], 
                 (p_h[i] & g_l[2**L-1]) | g_h[i] };
    endfunction

    function bit gray_cell 
        ( int i,
          input bit [2**L-1:0] p_h, g_h, g_l );
        return (p_h[i] & g_l[2**L-1]) | g_h[i];
    endfunction

    always_comb begin 
        bit [2**L-1:0] p_tmp, g_tmp;
        if (T == black) begin
            for (int i = 0; i < 2**L; ++i) begin
                { p_tmp[i], g_tmp[i] } = black_cell(i, p_h, p_l, g_h, g_l); 
            end
        end else begin
            for (int i = 0; i < 2**L; ++i) begin
                g_tmp[i] = gray_cell(i, p_h, g_h, g_l); 
            end
            p_tmp = 0;
        end  

        p = { p_tmp, p_l };
        g = { g_tmp, g_l };  
    end

endmodule

module ff #(parameter N = 2)( 
    input bit clk, reset,
    input bit [N-1:0] d, 
    output bit [N-1:0] q 
);
    always_ff @(posedge clk) begin
        q <= reset ? 0 : d; 
    end
endmodule

module prefix_adder_pipelined #(parameter N=5) (
    input bit clk, reset,
    input bit [2**N-1:0] a, b,
    input bit cin,
    output bit [2**N-1:0] s,
    output bit cout
);
    typedef struct packed {
        bit [2**N-1:0] a, b; 
        bit [2**N:0]   p, g;
    } stage;
    // preprocess 
    stage stage_reg[N+1]; // pg + in
    localparam reg_width = 2*2**N + 2*(2**N + 1);   

    ff #(reg_width) stage_0 ( .clk(clk) , .reset(reset), 
                           .d({ a, b, 
                              { a | b, 1'b0 },
                              { a & b, cin } }), 
                           .q({ stage_reg[0].a, stage_reg[0].b, 
                                stage_reg[0].p, stage_reg[0].g })); 

    genvar i, j;
    generate
    for (i = 0; i < N; ++i) begin
        localparam w = 2**i; // width of a block
        bit [2**N-1:0] p_tmp, g_tmp; 

        localparam h0 = w; // base of the high-part
        pg_block #( .L(i), .T(gray) ) blk( stage_reg[i].p[h0+w-1:h0], stage_reg[i].p[h0-1:0],
                                           stage_reg[i].g[h0+w-1:h0], stage_reg[i].g[h0-1:0],
                                           p_tmp[h0+w-1:0], g_tmp[h0+w-1:0] ); 

        for (j = 1; j < 2**(N-i-1); ++j) begin
            localparam l = 2*w*j, h = l+w; // base of the low-part, high-part 
            pg_block #( .L(i), .T(black)) blk( stage_reg[i].p[h+w-1:h], stage_reg[i].p[h-1:l],
                                               stage_reg[i].g[h+w-1:h], stage_reg[i].g[h-1:l],
                                               p_tmp[h+w-1:l], g_tmp[h+w-1:l] ); 
        end

        ff #(reg_width) stage( .clk(clk), .reset(reset), 
                            .d({ stage_reg[i].a, stage_reg[i].b, 
                               { stage_reg[i].p[2**N], p_tmp }, 
                               { stage_reg[i].g[2**N], g_tmp } }), 
                            .q({ stage_reg[i+1].a, stage_reg[i+1].b, 
                                 stage_reg[i+1].p, stage_reg[i+1].g }) ); 
    end
    endgenerate 

    // sum
    assign s    = stage_reg[N].a ^ stage_reg[N].b ^ stage_reg[N].g[2**N-1:0]; 
    assign cout = stage_reg[N].g[2**N] | (stage_reg[N].g[2**N-1] & stage_reg[N].p[2*N]); 
endmodule

