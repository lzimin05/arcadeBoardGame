`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.03.2026 00:23:58
// Design Name: 
// Module Name: randomizer_lfsr_tb
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


module randomizer_lfsr_tb();

    localparam WIDTH = 8;
    localparam DEFAULT_SEED = 16'hACE1;
    
    logic clk;
    logic rst;
    logic enable;
    logic [7:0] seed_in;
    logic [WIDTH-1:0] value;
    logic ready;

    randomizer_lfsr #(.WIDTH(WIDTH), .DEFAULT_SEED(DEFAULT_SEED)) uut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .seed_in(seed_in),
        .value(value),  
        .ready(ready) 
    );

    initial clk = 0;
    always #5 clk = ~clk;
    
    initial begin
        rst = 1;
        enable = 0;
        seed_in = 0;
        #50 rst = 0;
        #20 enable = 1;
        #20 enable = 0;
        #50;
        #20 enable = 1;
        #20 enable = 0;
        #50;
        #20 enable = 1;
        #20 enable = 0;
        #50;
        #300;
        $display("simulation DONE");
        $stop;
    end
endmodule
