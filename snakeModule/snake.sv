`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.03.2026 13:54:04
// Design Name: 
// Module Name: snake
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

module snake #(
    parameter GRID_W = 16,
    parameter GRID_H = 16,
    parameter SPEED_THRESHOLD = 25000000,
    parameter ADDR_W = $clog2(GRID_W),
    parameter ADDR_H = $clog2(GRID_H)
)(
    input  logic clk,
    input  logic rst,
    input  logic run,
    input  logic btn_up,
    input  logic btn_down,
    input  logic btn_left,
    input  logic btn_right,
    output logic request_exit,
    output logic game_over,
    output logic [7:0] score,
    output logic [8:0] snake_len,
    output logic [ADDR_W-1:0] snake_x [0:255],
    output logic [ADDR_H-1:0] snake_y [0:255],
    output logic [ADDR_W-1:0] food_x,
    output logic [ADDR_H-1:0] food_y
);
    localparam GRID_CELLS = GRID_W * GRID_H;
    localparam MAX_SNAKE = GRID_CELLS;
    
    logic game_tick;
    logic signed [1:0] dir_x, dir_y;
    logic signed [1:0] next_dir_x, next_dir_y;
    logic [15:0] rng_value;
    
    logic [ADDR_W-1:0] future_x;
    logic [ADDR_H-1:0] future_y;

    logic [ADDR_W-1:0] cand_x;
    logic [ADDR_H-1:0] cand_y;
    logic found_empty;
    logic is_occupied;

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
            game_over  <= 1'b0;
            score      <= '0;
            snake_len  <= 9'd1;
            snake_x[0] <= GRID_W / 2;
            snake_y[0] <= GRID_H / 2;
            food_x     <= GRID_W - 3;
            food_y     <= GRID_H / 2;
            dir_x      <= 2'sb01;
            dir_y      <= 2'sb00;
            next_dir_x <= 2'sb01;
            next_dir_y <= 2'sb00;
        end else if (run && game_tick && !game_over) begin
            dir_x <= next_dir_x;
            dir_y <= next_dir_y;
            
            // Проверка столкновения (Стены и Хвоста)
            if ((next_dir_x == 2'sb11 && snake_x[0] == 0) || 
                (next_dir_x == 2'sb01 && snake_x[0] == GRID_W - 1) ||
                (next_dir_y == 2'sb11 && snake_y[0] == 0) || 
                (next_dir_y == 2'sb01 && snake_y[0] == GRID_H - 1)) 
            begin
                game_over <= 1'b1;
            end

            for (int i = 1; i < GRID_CELLS; i++) begin
                if (i < snake_len) begin
                    if (future_x == snake_x[i] && future_y == snake_y[i])
                        game_over <= 1'b1;
                end
            end
            
            // ЕДА
            if (!game_over) begin
                if (future_x == food_x && future_y == food_y) begin
                    score <= score + 1'b1;
                    if (snake_len < MAX_SNAKE) snake_len <= snake_len + 1'b1;
                    
                    cand_x = rng_value[ADDR_W-1:0] % GRID_W;
                    cand_y = rng_value[ADDR_H+3:4] % GRID_H;
                    found_empty = 1'b0;

                    for (int offset = 0; offset < GRID_CELLS; offset++) begin
                        if (!found_empty) begin
                            is_occupied = 1'b0;
                            for (int i = 0; i < MAX_SNAKE; i++) begin
                                if (i < snake_len) begin
                                    if (cand_x == snake_x[i] && cand_y == snake_y[i])
                                        is_occupied = 1'b1; // ячейка занята
                                end
                            end
                            
                            if (!is_occupied) begin
                                food_x <= cand_x;
                                food_y <= cand_y;
                                found_empty = 1'b1;
                            end else begin
                                if (cand_x < GRID_W - 1) cand_x++;
                                else begin
                                    cand_x = '0;
                                    cand_y = (cand_y < GRID_H - 1) ? cand_y + 1'b1 : '0;
                                end
                            end
                        end
                    end
                end
                //Движение туловища
                for (int i = snake_len-1; i > 0; i--) begin
                    snake_x[i] <= snake_x[i-1];
                    snake_y[i] <= snake_y[i-1];
                end
                snake_x[0] <= future_x;
                snake_y[0] <= future_y;
            end
        end
    end

    // Управление (с проверкой на 180)
    always_ff @(posedge clk) begin
        if (run && !game_over) begin
            if (btn_up && (snake_len == 1 || dir_y != 2'sb11)) begin 
                next_dir_x <= 2'sb00; 
                next_dir_y <= 2'sb01; 
            end else if (btn_down && (snake_len == 1 || dir_y != 2'sb01)) begin 
                next_dir_x <= 2'sb00; 
                next_dir_y <= 2'sb11; 
            end else if (btn_left && (snake_len == 1 || dir_x != 2'sb01)) begin 
                next_dir_x <= 2'sb11; 
                next_dir_y <= 2'sb00; 
            end else if (btn_right && (snake_len == 1 || dir_x != 2'sb11)) begin 
                next_dir_x <= 2'sb01; 
                next_dir_y <= 2'sb00; 
            end
        end
    end

    assign request_exit = 1'b0;

endmodule
