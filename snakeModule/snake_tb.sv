`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.03.2026 17:06:13
// Design Name: 
// Module Name: snake_tb
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

`timescale 1ns / 1ps

module snake_tb();

    localparam GRID_W = 16;
    localparam GRID_H = 16;
    localparam ADDR_W = $clog2(GRID_W);
    localparam ADDR_H = $clog2(GRID_H);
    localparam SPEED_THRESHOLD = 20; 

    logic clk, rst, run;
    logic btn_up, btn_down, btn_left, btn_right;
    
    logic request_exit, game_over;
    logic [7:0] score;
    logic [8:0] snake_len;
    
    logic [ADDR_W-1:0] tb_snake_x [0:255];
    logic [ADDR_H-1:0] tb_snake_y [0:255];
    logic [ADDR_W-1:0] food_x, food_y;

    snake #(
        .GRID_W(GRID_W), .GRID_H(GRID_H), .SPEED_THRESHOLD(SPEED_THRESHOLD)
    ) dut (
        .clk(clk), 
        .rst(rst), 
        .run(run),
        .btn_up(btn_up), 
        .btn_down(btn_down), 
        .btn_left(btn_left), 
        .btn_right(btn_right),
        .request_exit(request_exit), 
        .game_over(game_over), 
        .score(score), 
        .snake_len(snake_len),
        .snake_x(tb_snake_x), 
        .snake_y(tb_snake_y),
        .food_x(food_x), 
        .food_y(food_y)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    task press_button(ref logic btn);
        @(posedge clk);
        #1 btn = 1;
        repeat(5) @(posedge clk); 
        #1 btn = 0;
    endtask

    initial begin
        wait(run);
        $display("--- Start Snake Simulation ---");
        forever begin
            @(posedge dut.game_tick);
            #1;
            $display("T: %t | Head: [%d,%d] | Food: [%d,%d] | Score: %d", 
                      $time, tb_snake_x[0], tb_snake_y[0], food_x, food_y, score);
            if (game_over) begin
                $display("!!! GAME OVER !!!");
                $finish;
            end
        end
    end

    initial begin
        rst = 1; 
        run = 0;
        btn_up = 0; 
        btn_down = 0; 
        btn_left = 0; 
        btn_right = 0;
        
        repeat(10) @(posedge clk);
        rst = 0;
        #10 run = 1;

        repeat(5) @(posedge dut.game_tick);

        $display(">>> Pressing UP");
        press_button(btn_up);

        repeat(5) @(posedge dut.game_tick);
        $display(">>> Pressing LEFT");
        press_button(btn_left);

        wait(game_over);
        #100;
        $finish;
    end

endmodule
