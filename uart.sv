`timescale 1ns / 1ps

module uart_rx
    #(parameter logic [15:0] wtime = 16'h2880, htime = 16'h1440)
    (
        input logic clk,
        input logic rx,
        input logic resetn,
        output logic [7:0] data,
        output logic valid
    );
    
    localparam logic [3:0] SLEEP = 4'b1111;
    localparam logic [3:0] RECEIVE_FIRSTDATA = 4'b0000;
    localparam logic [3:0] RECEIVE_LASTDATA  = 4'b1001;
    
    logic [3:0] state    = SLEEP;
    logic [19:0] counter = wtime;
    
    logic rx_latch = 1'b1;
    logic rx_data  = 1'b1;
       
    // metastable
    always_ff @(posedge clk) begin
        rx_latch <= rx;
        rx_data  <= rx_latch;
    end
        
    always_comb
        if (state == RECEIVE_LASTDATA && counter == 0) valid = 1'b1;
        else valid <= 1'b0;
    
    always_ff @(posedge clk) begin
        if(resetn) begin
            if (state < RECEIVE_LASTDATA && counter == 'd0) data <= {rx_data, data[7:1]};
        end else begin
            data <= 10'b0;
        end
    end 
    
    always_ff @(posedge clk) begin
        if (resetn) begin
            if (state == SLEEP && rx_data == 1'b0) state <= RECEIVE_FIRSTDATA;
            else if (state == RECEIVE_FIRSTDATA && counter == htime && rx_data != 1'b0) state <= SLEEP;
            else if (state == RECEIVE_FIRSTDATA && counter == htime && rx_data == 1'b0) state <= state + 1; 
            else if (state == RECEIVE_LASTDATA && counter == 0) state <= SLEEP;
            else if(state < RECEIVE_LASTDATA && counter == 0) state <= state + 1;
        end else begin
            state <= SLEEP;
        end
    end
    
    always_ff @(posedge clk) begin
        if (resetn) begin
            if (state == SLEEP) counter <= wtime;
            else if (state == RECEIVE_FIRSTDATA && counter == htime && rx_data == 1'b0) counter <= wtime;
            else if (~(|counter)) counter <= wtime;
            else counter <= counter - 1;
        end else begin
            counter <= wtime;
        end
    end
endmodule

module uart_tx
    #(parameter logic [15:0] wtime = 16'h2880)
    (
        input logic clk,
        input logic valid,
        input logic [7:0] data,
        input logic resetn,
        output logic ready,
        output logic tx
    );
    
    localparam logic [3:0] SLEEP = 4'b1111;
    localparam logic [3:0] SEND_FIRSTDATA = 4'b0000;
    localparam logic [3:0] SEND_LASTDATA  = 4'b1001;
    
    logic [9:0]  buff    = ~10'd0;
    logic [3:0]  state   = SLEEP;
    logic [19:0] counter = wtime;
    
    assign tx = buff[0];
    
    always_comb 
        if (state == SEND_LASTDATA && counter == 0) ready = 'b1;
        else ready = &state;
        
    always_ff @(posedge clk) begin
        if (resetn) begin
            if (valid & ready) buff <= {1'b1, data, 1'b0};
            else if (counter == 'd0) buff <= {1'b1, buff[9:1]};
        end else begin
            buff <= ~10'd0;
        end
    end
    
    always_ff @(posedge clk) begin
        if (resetn) begin
            if (valid & ready) state <= SEND_FIRSTDATA;
            else if (state == SEND_LASTDATA && counter == 0) state <= SLEEP;
            else if (state < SEND_LASTDATA && counter == 0) state <= state + 1;
        end else begin
            state <= SLEEP;
        end
    end
    
    always_ff @(posedge clk) begin
        if (resetn) begin
            if (valid & ready) counter <= wtime;
            else if (~(|counter)) counter <= wtime;
            else counter <= counter - 1;
        end else begin
            counter <= wtime;
        end
    end
endmodule

module echo
    (
        input logic [3:0] b,
        input logic sys_clock,
        input logic rx,
        output logic tx
    );
    logic valid;
    logic ready;
    logic [7:0] data;
    
    uart_rx #(.wtime(16'h365), .htime(16'h1b3)) RX (.clk(sys_clock), .rx(rx), .resetn(~b[0]), .data(data), .valid(valid));
    uart_tx #(.wtime(16'h365)) TX (.clk(sys_clock), .valid(valid), .data(data), .resetn(~b[0]), .ready(ready), .tx(tx));
endmodule

/*
module rx_char
    (
        input logic [3:0] b,
        input logic sys_clock,
        input logic rx,
        output [7:0] data
    );
    logic valid;
    uart_rx #(.wtime(16'h365), .htime(16'h1b3)) RX (.clk(sys_clock), .rx(rx), .resetn(~b[0]), .data(data), .valid(valid));
endmodule

module tx_char 
    (
        input logic [3:0] b,
        input logic [7:0] data,
        input logic sys_clock,
        output logic tx
    );  
    logic ready;
    logic valid;
    uart_tx #(.wtime(16'h365)) TX (.clk(sys_clock), .valid(valid), .data(data), .resetn(~b[0]), .ready(ready), .tx(tx));
    always_ff @(posedge sys_clock) begin
        if (ready) begin
            valid = 1'b1;
        end else begin
            valid = 1'b0;
        end
    end
endmodule
*/