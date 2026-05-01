`timescale 1ns / 1ps

module top_game #(
    parameter SNAKE_GRID_W = 10,
    parameter SNAKE_GRID_H = 19,
    parameter SNAKE_SPEED  = 25000000,
    parameter SNAKE_ADDR_W = $clog2(SNAKE_GRID_W),
    parameter SNAKE_ADDR_H = $clog2(SNAKE_GRID_H),
    parameter MAX_RECORD_FOR_SNAKE = SNAKE_GRID_W * SNAKE_GRID_H - 1,
    parameter ADDR_MAX_RECORD_FOR_SNAKE = $clog2(MAX_RECORD_FOR_SNAKE + 1)
)(
    input logic clk,
    input logic inrst,
	 
	 input logic [5:0]buttons_in,
	 output logic [5:0]leds,
	
	 output logic screenRst,
	 output logic screenClk,
	 output logic screenCE,
	 output logic screenDC,
	 output logic screenDIn 
);

    logic [SNAKE_ADDR_W-1:0] internal_snake_x [0:SNAKE_GRID_W * SNAKE_GRID_H - 1];
    logic [SNAKE_ADDR_H-1:0] internal_snake_y [0:SNAKE_GRID_W * SNAKE_GRID_H - 1];
    logic [SNAKE_ADDR_W-1:0] internal_food_x;
    logic [SNAKE_ADDR_H-1:0] internal_food_y;
	 
	 logic [4:0]  system_status;
    logic [7:0]  score;
    logic [8:0]  snake_len;
    logic [ADDR_MAX_RECORD_FOR_SNAKE-1:0] the_best_snake_record;

    logic run_snake;
    logic snake_over;
    logic snake_exit;
    logic snake_rst;
	 
	 logic run_tetris;
    logic tetris_over;
    logic tetris_exit;
    logic tetris_rst;
	 
    logic [1:0] selected_game;
	 
	 logic [2:0]command;
	 logic [31:0]data;
	 logic commandCS;
	 logic commandAck;
	 
	 logic [2:0]commandMenu;
	 logic [31:0]dataMenu;
	 logic commandCSMenu;
	 
	 logic [2:0]commandSnake;
	 logic [31:0]dataSnake;
	 logic commandCSSnake;
	 
	 logic [2:0]commandTetris;
    logic [31:0]dataTetris;
    logic commandCSTetris;
	 
	 always_comb begin
		if (commandCSMenu) begin
			command = commandMenu;
			data = dataMenu;
			commandCS = 1'b1;
		end else if (commandCSSnake) begin
			command = commandSnake;
			data = dataSnake;
			commandCS = 1'b1;
		end else if (commandCSTetris) begin
        		command = commandTetris; 
        		data = dataTetris; 
        		commandCS = 1'b1;
		end else begin
			commandCS = 1'b0;
			command = '0;
			data = '0;
		end
	 end
	 
	 logic rst;
	 
	 ButtonDriver bd0(.rst(rst), .clk(clk), .in(inrst), .out(rst));
	 ButtonDriver bd1(.rst(rst), .clk(clk), .in(buttons_in[0]), .out(leds[0]));
	 ButtonDriver bd2(.rst(rst), .clk(clk), .in(buttons_in[1]), .out(leds[1]));
	 ButtonDriver bd3(.rst(rst), .clk(clk), .in(buttons_in[2]), .out(leds[2]));
	 ButtonDriver bd4(.rst(rst), .clk(clk), .in(buttons_in[3]), .out(leds[3]));
	 ButtonDriver bd5(.rst(rst), .clk(clk), .in(buttons_in[4]), .out(leds[4]));
	 ButtonDriver bd6(.rst(rst), .clk(clk), .in(buttons_in[5]), .out(leds[5]));
    
    assign snake_rst = rst || (system_status == 5'd0 || system_status == 5'd2); 
	 
	 logic [5:0]buttons;
	 assign buttons = leds;
	 
	 GPU screen(
		.rst(rst),
		.clk(clk),
		.commandCS(commandCS),
		.command(command),
		.data(data),
		.commandAck(commandAck),
		
		.screenRst(screenRst),
		.screenClk(screenClk),
		.screenCE(screenCE),
		.screenDC(screenDC),
		.screenDIn(screenDIn)
	);

    menu #(
        .MAX_RECORD_FOR_SNAKE(MAX_RECORD_FOR_SNAKE)
    ) menu_inst (
        .clk(clk),
        .rst(rst),
        .btn_up(buttons[5]),
        .btn_down(buttons[4]),
        .btn_selected(buttons[3]),
        .btn_home(buttons[2]),
        .snake_over(snake_over),
        .snake_exit(snake_exit),
        .tetris_over(1'b0),
        .tetris_exit(1'b0),
		  .commandAck(commandAck),
        .snake_record(8'b0),
        .tetris_record(11'b0),
        .the_best_snake_record(the_best_snake_record),
        .the_best_tetris_record(),
        .run_snake(run_snake),
        .run_tetris(run_tetris),
        .selected_game(selected_game),
        .system_status(system_status),
        .clk_delay_tb(),
		  .command(commandMenu),
		  .data(dataMenu),
		  .commandCS(commandCSMenu)
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
		  .btn_up(buttons[5]),
        .btn_down(buttons[4]),
        .btn_left(buttons[1]),
        .btn_right(buttons[0]),
		  .commandAck(commandAck),
        .request_exit(snake_exit),
        .game_over(snake_over),
        .score(score),
        .snake_len(snake_len),
        .snake_x(internal_snake_x),
        .snake_y(internal_snake_y),
        .food_x(internal_food_x),
        .food_y(internal_food_y),
		  .command(commandSnake),
		  .data(dataSnake),
		  .commandCS(commandCSSnake)
    );
	 
	     tetris tetris_inst (
        .clk(clk),
        .rst(tetris_rst),
        .run(run_tetris),
        .btn_up(buttons[5]),    
        .btn_down(buttons[4]),  
        .btn_left(buttons[1]),  
        .btn_right(buttons[0]), 
        .commandAck(commandAck),
        .game_over(tetris_over),
        .score(score_tetris),
        .command(commandTetris),
        .data(dataTetris),
        .commandCS(commandCSTetris)
    );
endmodule
