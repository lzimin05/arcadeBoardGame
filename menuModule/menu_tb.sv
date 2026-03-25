`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.03.2026 20:38:48
// Design Name: 
// Module Name: menu_tb
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

module menu_tb();
    localparam MAX_SNAKE = 255;
    localparam MAX_TETRIS = 1000;
    localparam W_SNAKE = $clog2(MAX_SNAKE + 1);
    localparam W_TETRIS = $clog2(MAX_TETRIS + 1);

    logic clk;
    logic rst;
    logic btn_up, btn_down, btn_selected, btn_home;
    logic snake_over, snake_exit, tetris_over, tetris_exit;
    
    logic [W_SNAKE-1:0] snake_record;
    logic [W_TETRIS-1:0] tetris_record;
    logic [W_SNAKE-1:0] the_best_snake_record;
    logic [W_TETRIS-1:0] the_best_tetris_record;

    logic run_snake, run_tetris;
    logic [1:0] selected_game;
    logic [1:0] system_status;
    logic clk_delay_tb;

    menu #(
        .MAX_RECORD_FOR_SNAKE(MAX_SNAKE),
        .MAX_RECORD_FOR_TETRIS(MAX_TETRIS)
    ) uut (
        .clk(clk),
        .rst(rst),
        .btn_up(btn_up),
        .btn_down(btn_down),
        .btn_selected(btn_selected),
        .btn_home(btn_home),
        .snake_over(snake_over),
        .snake_exit(snake_exit),
        .tetris_over(tetris_over),
        .tetris_exit(tetris_exit),
        .snake_record(snake_record),
        .tetris_record(tetris_record),
        .the_best_snake_record(the_best_snake_record),
        .the_best_tetris_record(the_best_tetris_record),
        .run_snake(run_snake),
        .run_tetris(run_tetris),
        .selected_game(selected_game),
        .system_status(system_status),
        .clk_delay_tb(clk_delay_tb)
    );

    initial clk = 0;
    always #5 clk = ~clk;
    
    task press_button(ref logic btn);
        @(posedge clk);
        #1 btn = 1;
        repeat(10) @(posedge clk); 
        #1 btn = 0;
    endtask

    initial begin
        rst = 1;
        btn_up = 0; btn_down = 0; btn_selected = 0; btn_home = 0;
        snake_over = 0; snake_exit = 0; tetris_over = 0; tetris_exit = 0;
        snake_record = 0; tetris_record = 0;
        
        #50 rst = 0;
        
        repeat(2) press_button(btn_down);
        
        snake_record = 8'd42;
        press_button(btn_selected);
        #100 snake_over = 1;
        #10 snake_over = 0;
        
        #50;
        press_button(btn_up);
        tetris_record = 10'd120;
        press_button(btn_selected);
        #100 tetris_over = 1;
        #10 tetris_over = 0; 
        
        #100;
        press_button(btn_home);
        
        #300;
        $display("simulation DONE");
        $stop;
    end
endmodule

