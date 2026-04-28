`timescale 1ns / 1ps

module menu #(
    parameter MAX_RECORD_FOR_SNAKE = 63,
    parameter MAX_RECORD_FOR_TETRIS = 1000,
    parameter ADDR_MAX_RECORD_FOR_SNAKE = $clog2(MAX_RECORD_FOR_SNAKE + 1),
    parameter ADDR_MAX_RECORD_FOR_TETRIS = $clog2(MAX_RECORD_FOR_TETRIS + 1),
    parameter THRESHOLD = 28'd30000000
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
	input logic commandAck,
	
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
	output logic [4:0] system_status, //(00-Menu; 01-Play; 10-GameOver)
	output logic clk_delay_tb, //клок задержки для выбора игры (для ТБ)

	output logic [2:0]command,
	output logic [31:0]data,
	output logic commandCS
);
	typedef enum logic [4:0] {
		STATUS_MENU, STATUS_PLAY, STATUS_GAMEOVER,
		CLR_MENU, CLR_MENU_ACK, 
		DRAW_MENU_SNAKE, DRAW_MENU_SNAKE_ACK,
		DRAW_MENU_TETRIS, DRAW_MENU_TETRIS_ACK,
		DRAW_CX, DRAW_CX_ACK,
		DRAW_CY, DRAW_CY_ACK,
		CLR_GAME, CLR_GAME_ACK,
		END_CLR, END_CLR_ACK, 
		END_GO, END_GO_ACK,
		END_CONTINUE, END_CONTINUE_ACK,
		
		TEST_1, TEST_1_ACK
	} status_type;
	var status_type next_status, status;
	//надо реализовать задержку чтобы переключения игр была медленее!
	var logic clk_delay;
	
	clkDelay #(.WIDTH(28)) btnDelay (
		.clk(clk),
		.rst(rst),
		.threshold(THRESHOLD),
		.clk_delay(clk_delay)
	);

	assign system_status = status; // Чтобы видеть состояние снаружи	
	assign clk_delay_tb = clk_delay;
    
	always_ff @(posedge clk, posedge rst) begin
		if(rst) begin
			status <= CLR_MENU;
			selected_game <= 2'b00;
			run_snake <= 1'b0;
			run_tetris <= 1'b0;
			the_best_snake_record <= '0;
			the_best_tetris_record <= '0;
		end else begin
			status <= next_status;
			
			if (status == STATUS_PLAY) begin
				if (snake_over && (snake_record > the_best_snake_record)) begin
					the_best_snake_record <= snake_record;
				end
				if (tetris_over && (tetris_record > the_best_tetris_record)) begin
					the_best_tetris_record <= tetris_record;
				end
			end
			
			unique case (status)
				CLR_MENU: begin
					command <= 3'b000;
					data <= 0;
					commandCS <= 1'b1;
				end
				
				CLR_MENU_ACK:
					commandCS <= 1'b0;
					
				DRAW_MENU_SNAKE: begin
					command <= 3'b010;
					data <= {22'b0, 3'b010, 7'd30};
					commandCS <= 1'b1;
				end
				
				DRAW_MENU_SNAKE_ACK:
					commandCS <= 1'b0;
					
				TEST_1: begin
					command <= 3'b010;
					data <= {22'b0, 3'b010, 7'd30};
					commandCS <= 1'b1;
				end
				
				TEST_1_ACK:
					commandCS <= 1'b0;
					
				DRAW_MENU_TETRIS: begin
					command <= 3'b001;
					data <= {22'b0, 3'b011, 7'd30};
					commandCS <= 1'b1;
				end
				
				DRAW_MENU_TETRIS_ACK:
					commandCS <= 1'b0;
					
				DRAW_CX: begin
					command <= 3'b011;
					data <= {21'b0, (selected_game == 2'b00 ? 1'b1 : 1'b0), 3'b010, 7'd22};
					commandCS <= 1'b1;
				end
				
				DRAW_CX_ACK:
					commandCS <= 1'b0;
				
				DRAW_CY: begin
					command <= 3'b011;
					data <= {21'b0, (selected_game == 2'b01 ? 1'b1 : 1'b0), 3'b011, 7'd22};
					commandCS <= 1'b1;
				end
				
				DRAW_CY_ACK:
					commandCS <= 1'b0;
					
				CLR_GAME: begin
					command <= 3'b000;
					data <= selected_game == 2'b00 ? 32'b1 : 0;
					commandCS <= 1'b1;
				end
				
				CLR_GAME_ACK:
					commandCS <= 1'b0;
			
				STATUS_MENU: begin
					run_snake <= 0;
					run_tetris <= 0;
					if (btn_down) begin
						selected_game <= (selected_game == 2'd1) ? 2'd0 : selected_game + 2'd1;
						status <= DRAW_CX;
					end else if (btn_up) begin
						selected_game <= (selected_game == 2'd0) ? 2'd1 : selected_game - 2'd1;
						status <= DRAW_CX;
					end
				end
				
				STATUS_PLAY: begin
					run_snake  <= (selected_game == 2'd0);
					run_tetris <= (selected_game == 2'd1);
				end
				
				STATUS_GAMEOVER: begin
					run_snake <= 1'b0;
					run_tetris <= 1'b0;
				end
				
				END_CLR: begin
					command <= 3'b000;
					data <= 0;
					commandCS <= 1'b1;
				end
					
				END_CLR_ACK:
					commandCS <= 1'b0;
				
				END_GO: begin
					command <= 3'b110;
					data <= {22'b0, 3'b010, 7'd20};
					commandCS <= 1'b1;
				end 
				
				END_GO_ACK:
					commandCS <= 1'b0;
					
				END_CONTINUE: begin
					command <= 3'b111;
					data <= {22'b0, 3'b011, 7'd18};
					commandCS <= 1'b1;
				end
				
				END_CONTINUE_ACK:
					commandCS <= 1'b0;
				
			endcase
		end
	end

	always_comb begin
		next_status = status;
		unique case (status)
			CLR_MENU:
				next_status <= CLR_MENU_ACK;
			CLR_MENU_ACK:
				if (!commandAck)
					next_status <= DRAW_MENU_SNAKE;
					
			DRAW_MENU_SNAKE:
				next_status <= DRAW_MENU_SNAKE_ACK;
			DRAW_MENU_SNAKE_ACK:
				if (!commandAck)
					next_status <= TEST_1;
			
			TEST_1:
				next_status <= TEST_1_ACK;
			TEST_1_ACK:
				if (!commandAck)
					next_status <= DRAW_MENU_TETRIS;
					
			DRAW_MENU_TETRIS:
				next_status <= DRAW_MENU_TETRIS_ACK;
			DRAW_MENU_TETRIS_ACK:
				if (!commandAck)
					next_status <= DRAW_CX;
					
			DRAW_CX:
				next_status <= DRAW_CX_ACK;
			DRAW_CX_ACK:
				if (!commandAck)
					next_status <= DRAW_CY;
					
			DRAW_CY:
				next_status <= DRAW_CY_ACK;
			DRAW_CY_ACK:
				if (!commandAck)
					next_status <= STATUS_MENU;

			STATUS_MENU: begin
				if (btn_selected) begin
					next_status = CLR_GAME;
				end
			end
			
			CLR_GAME:
				next_status <= CLR_GAME_ACK;
			CLR_GAME_ACK:
				if (!commandAck)
					next_status <= STATUS_PLAY;
			
			STATUS_PLAY: begin
				if(snake_exit || tetris_exit) begin
					next_status = STATUS_MENU;
				end
				else if(snake_over || tetris_over) begin
					next_status = END_CLR;
				end
			end
			
			STATUS_GAMEOVER: begin
				if (btn_selected) begin
					next_status = CLR_GAME; // добавить возможность выйти в меню!
				end else if (btn_home) begin
					next_status = CLR_MENU;
				end	
			end
			
			END_CLR: begin
				next_status = END_CLR_ACK;
			end
				
			END_CLR_ACK:
				if (!commandAck)
					next_status <= END_GO;

			END_GO:
				next_status <= END_GO_ACK;

			END_GO_ACK:
				if (!commandAck)
					next_status <= END_CONTINUE;
					
			END_CONTINUE:
				next_status <= END_CONTINUE_ACK;

			END_CONTINUE_ACK:
				if (!commandAck)
					next_status <= STATUS_GAMEOVER;
			
			default: next_status = STATUS_MENU;
		endcase
	end
endmodule
