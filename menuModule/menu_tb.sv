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
    logic clk;
    logic rst;
    logic btn_up, btn_down, btn_selected, btn_home;
    logic snake_over, snake_exit, tetris_over, tetris_exit;
    
    logic run_snake, run_tetris;
    logic [1:0] selected_game;
    logic [1:0] system_status;
    logic clk_delay_tb;

    menu uut (
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
        repeat(5) @(posedge clk); // Держим кнопку 10 тактов
        #1 btn = 0;
    endtask

    initial begin
        rst = 1;
        btn_up = 0; btn_down = 0; btn_selected = 0; btn_home = 0;
        snake_over = 0; snake_exit = 0; tetris_over = 0; tetris_exit = 0;
        
        #50 rst = 0;
        
        repeat(2) press_button(btn_down);
        press_button(btn_selected);
        #100 snake_exit = 1;
        #10 snake_exit = 0;
        press_button(btn_up);
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
