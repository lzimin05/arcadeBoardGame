`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.03.2026 20:15:56
// Design Name: 
// Module Name: clkDelay_tb
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


module clkDelay_tb();
    localparam WIDTH = 4;
    
    logic clk;
    logic rst;
    logic [WIDTH-1:0] threshold;
    logic clk_delay;

    clkDelay #(.WIDTH(WIDTH)) uut (
        .clk(clk),
        .rst(rst),
        .threshold(threshold),
        .clk_delay(clk_delay)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        rst = 1;
        threshold = 4'd5;
        #25;  
        rst = 0;
        #300;
        $display("simulation DONE");
        $stop;
    end

    always @(posedge clk_delay) begin
        $display("clk_delay work - %t", $time);
    end
endmodule
