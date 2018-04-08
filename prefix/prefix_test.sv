`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/08/2018 03:00:55 PM
// Design Name: 
// Module Name: prefix_test
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


module prefix_test();
    localparam n = 6;
    localparam w = 2**6;
    bit clk, reset;
    typedef struct packed {
        bit [w-1:0] a, b;
    } test;
    typedef struct packed {
        bit cout;
        bit [w-1:0] s;
    } result;

    bit [w-1:0] a, b, s;
    bit cin, cout;
    int cnt;
    test   test_q[$];
    result ans_q[$];
    result res_q[$]; 

    prefix_adder_pipelined #(n) dut(clk, reset, a, b, cin, s, cout);

    always begin
        clk = 1; #5; clk = 0; #5;
    end

    initial begin
        cin = 0;
        cnt = 0;
        reset = 1;
        for (int i = 0; i < 100; ++i) begin
            for (int j = 0; j < 100; ++j) begin
                test_q.push_back('{i, j});
            end
        end
        #12; reset = 0;
    end

    always @(posedge clk) begin
        if (~reset) begin
        { a, b } = test_q.pop_front();
        ans_q.push_back( {a + b + cin} );
        if (cnt > n + 1) begin
            res_q.push_back( '{ cout, s } ); 
        end
        cnt++;
        end
    end 

    always @(negedge clk) begin
        if (~reset & cnt > n + 2) begin
            result tmp_t, tmp;
            tmp_t = ans_q.pop_front();
            tmp   = res_q.pop_front();

            $display("Answer %b, %b", tmp_t.cout, tmp_t.s );
            $display("Output %b, %b", tmp.cout, tmp.s);
        end

        if ( cnt == 100*100 ) begin
            $finish;
        end
    end
endmodule
