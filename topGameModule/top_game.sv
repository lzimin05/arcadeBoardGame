`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.03.2026 16:35:37
// Design Name: 
// Module Name: top_game
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


module top_game #(
    parameter SNAKE_GRID_W = 16,
    parameter SNAKE_GRID_H = 16,
    parameter SNAKE_SPEED  = 25000000,
    parameter SNAKE_ADDR_W = $clog2(SNAKE_GRID_W),
    parameter SNAKE_ADDR_H = $clog2(SNAKE_GRID_H),
    parameter MAX_RECORD_FOR_SNAKE = 255,
    parameter ADDR_MAX_RECORD_FOR_SNAKE = $clog2(MAX_RECORD_FOR_SNAKE + 1)
)(
    input  logic clk,
    input  logic rst,
    
    input  logic btn_up,
    input  logic btn_down,
    input  logic btn_left,
    input  logic btn_right,
    input  logic btn_selected, 
    input  logic btn_home,
    
    output logic [1:0]  system_status,
    output logic [7:0]  score,
    output logic [SNAKE_ADDR_W-1:0] snake_x [0:255],
    output logic [SNAKE_ADDR_H-1:0] snake_y [0:255],
    output logic [SNAKE_ADDR_W-1:0] food_x,
    output logic [SNAKE_ADDR_H-1:0] food_y,
    output logic [8:0]  snake_len,
    output logic [ADDR_MAX_RECORD_FOR_SNAKE-1:0] the_best_snake_record
);


    logic run_snake;
    logic snake_over;
    logic snake_exit;
    logic snake_rst;
    logic [1:0] selected_game;
    
    assign snake_rst = rst || (system_status == 2'b00); 

    menu #(
        .MAX_RECORD_FOR_SNAKE(MAX_RECORD_FOR_SNAKE)
    ) menu_inst (
        .clk(clk),
        .rst(rst),
        .btn_up(btn_up),
        .btn_down(btn_down),
        .btn_selected(btn_selected),
        .btn_home(btn_home),
        .snake_over(snake_over),
        .snake_exit(snake_exit),
        .tetris_over(1'b0),
        .tetris_exit(1'b0),
        .snake_record(score),
        .tetris_record(11'b0),
        .the_best_snake_record(the_best_snake_record),
        .the_best_tetris_record(),
        .run_snake(run_snake),
        .run_tetris(),
        .selected_game(selected_game),
        .system_status(system_status),
        .clk_delay_tb()
    );

    snake #(
        .GRID_W(SNAKE_GRID_W),
        .GRID_H(SNAKE_GRID_H),
        .SPEED_THRESHOLD(SNAKE_SPEED),
        .ADDR_W(SNAKE_ADDR_W),
        .ADDR_H(SNAKE_ADDR_H)
    ) snake_inst (
        .clk(clk),
        .rst(snake_rst),
        .run(run_snake),
        .btn_up(btn_up),
        .btn_down(btn_down),
        .btn_left(btn_left),
        .btn_right(btn_right),
        .request_exit(snake_exit),
        .game_over(snake_over),
        .score(score),
        .snake_len(snake_len),
        .snake_x(snake_x),
        .snake_y(snake_y),
        .food_x(food_x),
        .food_y(food_y)
    );

endmodule



