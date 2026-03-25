`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.03.2026 20:12:46
// Design Name: 
// Module Name: menu
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


module menu #(
    parameter MAX_RECORD_FOR_SNAKE = 255,
    parameter MAX_RECORD_FOR_TETRIS = 1000,
    parameter ADDR_MAX_RECORD_FOR_SNAKE = $clog2(MAX_RECORD_FOR_SNAKE + 1),
    parameter ADDR_MAX_RECORD_FOR_TETRIS = $clog2(MAX_RECORD_FOR_TETRIS + 1)
)(
	input logic clk,
	input logic rst,

	//джостик (вверх, вниз и нажатие)
	input logic btn_up,
	input logic btn_down,
	input logic btn_selected,
	input logic btn_home, //кнопка домой, чтобы можно было вернуться в меню после проигрыша (кнопка btn_selected будет чтобы начать заново)
	
	//состояния от игр (выход и завершение)
	input logic snake_over,
	input logic snake_exit,
	input logic tetris_over,
	input logic tetris_exit,
	
	//рекорд игры, последний трай
	input logic [ADDR_MAX_RECORD_FOR_SNAKE-1:0]snake_record,
    input logic [ADDR_MAX_RECORD_FOR_TETRIS-1:0]tetris_record,
    
    //лучший рекорд, выводить
    output logic [ADDR_MAX_RECORD_FOR_SNAKE-1:0]the_best_snake_record,
    output logic [ADDR_MAX_RECORD_FOR_TETRIS-1:0]the_best_tetris_record, 
    

	//выбор игр и управления ими
	output logic run_snake,
	output logic run_tetris,
	output logic [1:0] selected_game,

	//состояния события 
	output logic [1:0] system_status, //(00-Menu; 01-Play; 10-GameOver)
	output logic clk_delay_tb //клок задержки для выбора игры (для ТБ)
);
	typedef enum logic [1:0] {STATUS_MENU, STATUS_PLAY, STATUS_GAMEOVER} status_type;
	var status_type next_status, status;
	//надо реализовать задержку чтобы переключения игр была медленее!
	var logic clk_delay;
	clkDelay #(.WIDTH(8)) btnDelay (
		.clk(clk),
		.rst(rst),
		.threshold(8'b00000100),
		.clk_delay(clk_delay)
	);

	assign system_status = status; // Чтобы видеть состояние снаружи	
    assign clk_delay_tb = clk_delay;
    
	always_ff @(posedge clk, posedge rst) begin
		if(rst) begin
			status <= STATUS_MENU;
			selected_game <= 0;
			run_snake <= 0;
			run_tetris <= 0;
			the_best_snake_record <= 0;
			the_best_tetris_record <= 0;
		end else begin
			status <= next_status;
			unique case (status)
				STATUS_MENU: begin
					run_snake <= 0;
					run_tetris <= 0;
					if (btn_down && clk_delay) begin
						if(selected_game == 2'b01) begin
							selected_game <= 2'b00;
						end else begin
							selected_game <= selected_game + 1;
						end
					end else if(btn_up && clk_delay) begin
						if(selected_game == 2'b00) begin
							selected_game <= 2'b01;
						end else begin
							selected_game <= selected_game - 1;
						end
					end
					if (btn_selected) begin
						unique case (selected_game)
							0: begin
								run_snake <= 1;
							end
							1: begin
								run_tetris <= 1;
							end
							default: ;
						endcase
					end
				end
				STATUS_PLAY: begin
					unique case (selected_game)
        				0: begin
							run_snake  <= 1;
						end
        				1: begin
							run_tetris <= 1;
						end
        				default: ;
   					endcase	
				end
				STATUS_GAMEOVER: begin
				    unique case (selected_game)
				        0: begin
				            if(the_best_snake_record < snake_record) begin
				                the_best_snake_record <= snake_record;
				            end
				            run_snake <= 0;
				            
				        end
				        1: begin
				            if(the_best_tetris_record < tetris_record) begin
				                the_best_tetris_record <= tetris_record;
				            end
				            run_tetris <= 0;
				        end
				        default: ;
                    endcase
				end
				default: ;
			endcase
		end
	end

	always_comb begin
		next_status = status;
		unique case (status)
			STATUS_MENU: begin
				if (btn_selected) begin
					next_status = STATUS_PLAY;
				end
			end
			STATUS_PLAY: begin
				if(snake_exit || tetris_exit) begin
					next_status = STATUS_MENU;
				end
				else if(snake_over || tetris_over) begin
					next_status = STATUS_GAMEOVER;
				end
			end
			STATUS_GAMEOVER: begin
				if (btn_selected) begin
					next_status = STATUS_PLAY; // добавить возможность выйти в меню!
				end else if (btn_home) begin
					next_status = STATUS_MENU;
				end	
			end
			default: next_status = STATUS_MENU;
		endcase
	end
endmodule

/*
reg c_reg // 
reg[2:0] // 000-down; 001-up; 010-left; 011-right; 100-static

menu menuU(
	.clc(clc_main), 
	.rst(rst), 
	.btn_up(reg == 2'b01), 
	.btn_down(reg == 2'b00),
	
)
*/
