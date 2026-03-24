`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.03.2026 16:45:47
// Design Name: 
// Module Name: top_game_tb
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

module top_game_tb();
    // Параметры симуляции
    localparam GRID_WIDTH  = 16;
    localparam GRID_HEIGHT = 16;
    localparam ADDR_W      = $clog2(GRID_WIDTH);
    localparam ADDR_H      = $clog2(GRID_HEIGHT);
    localparam CLK_PERIOD  = 10; 
    localparam TEST_SPEED  = 40;

    logic clk = 0;
    logic reset;
    logic button_up    = 0;
    logic button_down  = 0;
    logic button_left  = 0;
    logic button_right = 0;
    logic button_select = 0;
    logic button_home   = 0;
    
    logic [1:0] system_status;
    logic [7:0] current_score;
    logic [8:0] snake_length;
    logic [ADDR_W-1:0] food_pos_x, food_pos_y;
    logic [ADDR_W-1:0] snake_x_array [0:255];
    logic [ADDR_H-1:0] snake_y_array [0:255];

    logic debug_snake_run;
    logic debug_snake_tick;
    logic debug_snake_game_over;
    logic [1:0] debug_menu_selection;

    assign debug_snake_run       = dut.run_snake;
    assign debug_snake_tick      = dut.snake_inst.game_tick;
    assign debug_snake_game_over = dut.snake_inst.game_over; 
    assign debug_menu_selection  = dut.menu_inst.selected_game;

    // Инстанс игрового модуля
    top_game #(
        .SNAKE_GRID_W(GRID_WIDTH),
        .SNAKE_GRID_H(GRID_HEIGHT),
        .SNAKE_SPEED (TEST_SPEED)
    ) dut (
        .clk(clk),
        .rst(reset),
        .btn_up(button_up),
        .btn_down(button_down),
        .btn_left(button_left),
        .btn_right(button_right),
        .btn_selected(button_select),
        .btn_home(button_home),
        .system_status(system_status),
        .score(current_score),
        .snake_len(snake_length),
        .food_x(food_pos_x),
        .food_y(food_pos_y),
        .snake_x(snake_x_array),
        .snake_y(snake_y_array)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    initial begin
        $display("--- СТАРТ СИМУЛЯЦИИ ---");
        reset = 1;
        #(CLK_PERIOD * 10);
        reset = 0;
        #(CLK_PERIOD * 10);

        $display("[%0t] МЕНЮ: Листаем вниз/вверх...", $time);
        button_down = 1; #(CLK_PERIOD * 5); button_down = 0;
        #(CLK_PERIOD * 100);
        
        button_up = 1;   #(CLK_PERIOD * 5); button_up = 0;
        #(CLK_PERIOD * 100);

        $display("[%0t] МЕНЮ: Выбираем Змейку...", $time);
        button_select = 1; #(CLK_PERIOD * 5); button_select = 0;

        wait(system_status == 2'b01);
        $display("[%0t] ИГРА: Запущена. Голова в (%d, %d)", $time, snake_x_array[0], snake_y_array[0]);

        $display("[%0t] ИГРА: Идем к еде в (%d, %d)...", $time, food_pos_x, food_pos_y);
        while (current_score == 0) begin
            @(posedge clk);
            if (food_pos_y > snake_y_array[0])      begin button_up = 0; button_down = 1; end
            else if (food_pos_y < snake_y_array[0]) begin button_up = 1; button_down = 0; end
            else                                    begin button_up = 0; button_down = 0; end
            
            if (food_pos_x > snake_x_array[0])      begin button_right = 1; button_left = 0; end
            else if (food_pos_x < snake_x_array[0]) begin button_right = 0; button_left = 1; end
            else                                    begin button_right = 0; button_left = 0; end
        end
        $display("[%0t] СОБЫТИЕ: Еда съедена! Счет: %d", $time, current_score);

        $display("[%0t] ИГРА: Круг почета по полю...", $time);
        button_up = 1; button_down = 0; button_left = 0; button_right = 0;
        repeat (5) @(posedge debug_snake_tick);
        
        button_up = 0; button_right = 1;
        repeat (5) @(posedge debug_snake_tick);
        
        button_right = 0; button_down = 1;
        repeat (5) @(posedge debug_snake_tick);

        $display("[%0t] ИГРА: Направляем змейку в стену для завершения...", $time);
        button_down = 0; button_left = 1; // Зажали влево до упора
        
        wait(debug_snake_game_over == 1'b1);
        $display("[%0t] СОБЫТИЕ: Змейка погибла (Game Over)!", $time);
        button_left = 0;

        // 5. Возврат в меню
        #(CLK_PERIOD * 100);
        $display("[%0t] МЕНЮ: Возврат на главный экран...", $time);
        button_home = 1; #(CLK_PERIOD * 5); button_home = 0;
        
        wait(system_status == 2'b00);
        $display("[%0t] СТАТУС: В меню. Симуляция успешно завершена.", $time);

        #(CLK_PERIOD * 100);
        $finish;
    end

endmodule