module snake #(
    parameter GRID_W = 19,
    parameter GRID_H = 8,
    parameter SPEED_THRESHOLD = 25000000,
    parameter ADDR_W = $clog2(GRID_W),
    parameter ADDR_H = $clog2(GRID_H),
    parameter GRID_CELLS = GRID_W * GRID_H,
    parameter MAX_SNAKE = GRID_CELLS-1
)(
    input  logic clk,
    input  logic rst,
    input  logic run,
    input  logic btn_up,
    input  logic btn_down,
    input  logic btn_left,
    input  logic btn_right,
	 input logic commandAck,
    output logic request_exit,
    output logic game_over,
    output logic [7:0] score,
    output logic [8:0] snake_len,
    output logic [4:0] snake_x [0:MAX_SNAKE],
    output logic [3:0] snake_y [0:MAX_SNAKE],
    output logic [4:0] food_x,
    output logic [3:0] food_y,
	 
	 output logic [2:0]command,
	 output logic [31:0]data,
	 output logic commandCS
);
    
    logic game_tick;
    logic signed [1:0] dir_x, dir_y;
    logic signed [1:0] next_dir_x, next_dir_y;
    logic [15:0] rng_value;
    
    logic [4:0] future_x;
    logic [3:0] future_y;

    logic [4:0] cand_x;
    logic [3:0] cand_y;
	 
	 logic [8:0] check_idx;
	 logic is_occupied_reg;
	
	 logic [8:0] move_idx;
	 logic [4:0] new_head_x;
	 logic [3:0] new_head_y;
	 logic move_pending; //флаг - идет ли процесс перемещения
	
	 logic [8:0] collision_idx;
	 logic collision_found; //столкновение есть!
	 
	 typedef enum logic [1:0] {INIT, STATUS_IDLE, STATUS_GENERATE} food_st; //еда ждет, когда ее съедят или генерация еды происходит
	 var food_st food_status;
	 logic [9:0] cells_checked;
	 
	 enum { 
		WAIT, 
		DRAW_FOOD, DRAW_FOOD_ACK, 
		DRAW_TOP, DRAW_TOP_ACK, 
		DRAW_BOTTOM, DRAW_BOTTOM_ACK, 
		DRAW_SCORE, DRAW_SCORE_ACK,
		MOVE_BODY, MOVE_HEAD, 
		CHECK_COLLISION 
	 } draw_st;
	 
	 logic draw_food;
	 logic draw_score;
	 
    clkDelay #(.WIDTH(25)) gameTimer (
        .clk(clk), 
        .rst(rst), 
        .threshold(SPEED_THRESHOLD), 
        .clk_delay(game_tick) 
    );

    randomizer_lfsr #(.WIDTH(16)) randomizer (
        .clk(clk), 
        .rst(rst), 
        .enable(1'b1), 
        .seed_in(8'h00), 
        .value(rng_value), 
        .ready()
    );

    always_comb begin
        future_x = snake_x[0];
        future_y = snake_y[0];
        //  2'sb01 (1) и 2'sb11 (-1)
        if (next_dir_x == 2'sb01)  future_x = snake_x[0] + 1'b1;
        if (next_dir_x == 2'sb11)  future_x = snake_x[0] - 1'b1;
        if (next_dir_y == 2'sb01)  future_y = snake_y[0] + 1'b1;
        if (next_dir_y == 2'sb11)  future_y = snake_y[0] - 1'b1;
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
				draw_food <= 1'b0;
				draw_score <= 1'b1;
				draw_st <= WAIT;
            game_over  <= 1'b0;
            score      <= '0;
            snake_len  <= 9'd1;
            snake_x[0] <= 9;
            snake_y[0] <= 4;
            food_x     <= 5'd10;
            food_y     <= 4'd0;
            dir_x      <= 2'sb01;
            dir_y      <= 2'sb00;
            next_dir_x <= 2'sb01;
            next_dir_y <= 2'sb00;
				for (int i = 1; i <= MAX_SNAKE; i++) begin
                snake_x[i] <= '0;
                snake_y[i] <= '0;
            end
				food_status <= INIT;
				check_idx <= '0;
				is_occupied_reg <= 1'b0;
				move_pending <= 1'b0;
        end else if (run && !game_over) begin
				case (draw_st)
					WAIT: begin
						if (draw_food) begin
							draw_food <= 1'b0;
							draw_st <= DRAW_FOOD;
						end else if (draw_score) begin
							draw_score <= 1'b0;
							draw_st <= DRAW_SCORE;
						end
					end
					
					DRAW_FOOD: begin
						command <= 3'b101;
						data <= {
							24'b0,
							food_x + 5'd1,
							food_y + 4'd3,
						 	1'b1
						};
						commandCS <= 1'b1;
						draw_st <= DRAW_TOP_ACK;
					end
					
					DRAW_FOOD_ACK:
						if (!commandAck)
							draw_st <= WAIT;
						else
							commandCS <= 1'b0;
					
					DRAW_TOP: begin
						command <= 3'b101;
						data <= {
							24'b0,
							snake_x[0][4:0] + 5'd1,
							snake_y[0][3:0] + 4'd3,
						 	1'b1
						};
						commandCS <= 1'b1;
						draw_st <= DRAW_TOP_ACK;
					end
					
					DRAW_TOP_ACK:
						if (!commandAck)
							draw_st <= DRAW_BOTTOM;
						else
							commandCS <= 1'b0;
							
					DRAW_BOTTOM: begin
						command <= 3'b101;
						data <= {
							24'b0,
							snake_x[snake_len][4:0] + 5'd1,
							snake_y[snake_len][3:0] + 4'd3,
							1'b0
						};
						commandCS <= 1'b1;
						draw_st <= DRAW_BOTTOM_ACK;
					end
						
					DRAW_BOTTOM_ACK:
						if (!commandAck)
							draw_st <= WAIT;
						else
							commandCS <= 1'b0; 		
							
					DRAW_SCORE: begin
						command <= 3'b100;
						data <= {
							24'b0,
							2'b0,
							score,
							3'b000,
							7'd32
						};
						commandCS <= 1'b1;
						draw_st <= DRAW_SCORE_ACK;
					end
					
					DRAW_SCORE_ACK:
						if (!commandAck)
							draw_st <= WAIT;
						else
							commandCS <= 1'b0;
					
					MOVE_BODY: begin
						 if (move_idx > 0) begin
							  // Сдвигаем змейку
							  snake_x[move_idx] <= snake_x[move_idx-1];
							  snake_y[move_idx] <= snake_y[move_idx-1];
							  move_idx <= move_idx - 1'b1;
						 end else begin
							  draw_st <= MOVE_HEAD;
						 end
					end
				
					MOVE_HEAD: begin
						 snake_x[0] <= new_head_x;
						 snake_y[0] <= new_head_y;
						 move_pending <= 1'b0;
						 
						 draw_st <= DRAW_TOP;
					end
				
					CHECK_COLLISION: begin
						 if (collision_idx < snake_len && !collision_found) begin
							  if (future_x == snake_x[collision_idx] && future_y == snake_y[collision_idx]) begin
									collision_found <= 1'b1; //столкнулся с телом
							  end
							  collision_idx <= collision_idx + 1'b1;
						 end else begin
							  if (collision_found) begin
									game_over <= 1'b1; //столкновение есть, значит проиграли
							  end else begin
									collision_found <= 1'b0;
									draw_st <= MOVE_BODY; //коллизий нет, значит двигаем туловище
							  end
						 end
                end
				endcase
			
				//Управление с проверкой на 180 градусов
				if (btn_down && (snake_len == 1 || dir_y != 2'sb11)) begin 
                next_dir_x <= 2'sb00; next_dir_y <= 2'sb01; 
            end else if (btn_up && (snake_len == 1 || dir_y != 2'sb01)) begin 
                next_dir_x <= 2'sb00; next_dir_y <= 2'sb11; 
            end else if (btn_left && (snake_len == 1 || dir_x != 2'sb01)) begin 
                next_dir_x <= 2'sb11; next_dir_y <= 2'sb00; 
            end else if (btn_right && (snake_len == 1 || dir_x != 2'sb11)) begin 
                next_dir_x <= 2'sb01; next_dir_y <= 2'sb00; 
            end
		  
				if(game_tick) begin
				
					dir_x <= next_dir_x;
					dir_y <= next_dir_y;
					
					// Проверка столкновения (Стены и Хвоста)
					if ((next_dir_x == 2'sb11 && snake_x[0] == 0) || 
							(next_dir_x == 2'sb01 && snake_x[0] == 18) ||
							(next_dir_y == 2'sb11 && snake_y[0] == 0) || 
							(next_dir_y == 2'sb01 && snake_y[0] == 7)) 
					begin
							game_over <= 1'b1;
					end else begin
						  if (future_x == food_x && future_y == food_y) begin
								score <= score + 1'b1;
								if (snake_len < MAX_SNAKE) begin
									 snake_len <= snake_len + 1'b1;
								end else begin
									 game_over <= 1'b1;  //WIN
								end
								
								food_status <= STATUS_GENERATE;
								cand_x <= rng_value[3:0] > 18 ? 18 : rng_value[3:0];
								cand_y <= rng_value[6:4] > 7 ? 7 : rng_value[6:4];
								cells_checked <= '0;
								check_idx <= '0;
								is_occupied_reg <= 1'b0;
								draw_score <= 1'b1;
						  end
						  collision_idx <= 9'd1; //начинаем с первого туловища, не с головы!
						  collision_found <= 1'b0;
						  
						  //Движение туловища
						  new_head_x <= future_x;
						  new_head_y <= future_y;
						  move_idx <= snake_len;
						  move_pending <= 1'b1; //рассчитать новую координату для туловища
						  draw_st <= CHECK_COLLISION;
					end
			  end
				
			  if (food_status == INIT) begin
					food_status <= STATUS_IDLE;
					draw_food <= 1'b1;
			  end
					//Генерация еды по клоку
			  if (food_status == STATUS_GENERATE) begin
					// Проверяем, не занята ли ячейка
					if (check_idx < snake_len && !is_occupied_reg) begin
						if (cand_x == snake_x[check_idx] && cand_y == snake_y[check_idx]) begin
							is_occupied_reg <= 1'b1;
						end
						check_idx <= check_idx + 1'b1;
					end
					else begin
						if (!is_occupied_reg) begin
							food_x <= cand_x;
							food_y <= cand_y;
							draw_food <= 1'b1;
							food_status <= STATUS_IDLE;
						end else if (cells_checked < GRID_CELLS) begin
							//перегенерация еды, сдвигаем еду!
							if (cand_x < 18) begin
								cand_x <= cand_x + 1'b1;
							end else begin
								cand_x <= '0;
								cand_y <= (cand_y < 7) ? cand_y + 1'b1 : '0;
							end
							cells_checked <= cells_checked + 1'b1;
							check_idx <= '0;
							is_occupied_reg <= 1'b0;
						end else begin
							//Все ячейки заняты - победа!
							game_over <= 1'b1;
							food_status <= STATUS_IDLE;
						end
					end
				end
		  end
    end

    assign request_exit = 1'b0;

endmodule