`timescale 1ns / 1ps

module tetris #(
    parameter GRID_W = 10,
    parameter GRID_H = 20,
    parameter SPEED_THRESHOLD = 25000000
)(
    input  logic clk,
    input  logic rst,
    input  logic run,
    input  logic btn_up,    // Поворот
    input  logic btn_down,  // Ускорение
    input  logic btn_left,
    input  logic btn_right,
    output logic game_over,
    output logic [15:0] score,
    
    // Интерфейс для видеокарты 
    output logic [GRID_W-1:0] land [0:GRID_H-1],
	 
    output logic [3:0] active_x [0:3],
    output logic [4:0] active_y [0:3]
);

    typedef enum logic [2:0] {
        S_IDLE,
        S_NEW_PIECE,
        S_MOVE,
        S_FALL,
        S_LOCK,
        S_CLEAR_LINE
    } state_t;
    state_t state;
	 
    logic game_tick;
    logic [15:0] rng_value;
    logic [2:0]  curr_type; // Тип тетрамино (0-6)
    logic [1:0]  curr_rot;  // Поворот (0-3)
    logic signed [4:0] piece_x; 
    logic signed [5:0] piece_y; 

    // Модуль задержки
    clkDelay #(.WIDTH(25)) fallTimer (
        .clk(clk), 
        .rst(rst), 
        .threshold(SPEED_THRESHOLD), 
        .clk_delay(game_tick) 
    );

    // Рандомайзер для выбора новой фигуры
    randomizer_lfsr #(.WIDTH(16)) rnd (
        .clk(clk), 
        .rst(rst), 
        .enable(state == S_NEW_PIECE), 
        .value(rng_value), 
        .ready()
    );

    // фигуры
    always_comb begin
        case (curr_type)
            0: begin // I-фигура
                if (curr_rot[0]) begin
                    active_x[0] = piece_x;   active_y[0] = piece_y - 1;
                    active_x[1] = piece_x;   active_y[1] = piece_y;
                    active_x[2] = piece_x;   active_y[2] = piece_y + 1;
                    active_x[3] = piece_x;   active_y[3] = piece_y + 2;
                end else begin
                    active_x[0] = piece_x - 1; active_y[0] = piece_y;
                    active_x[1] = piece_x;     active_y[1] = piece_y;
                    active_x[2] = piece_x + 1; active_y[2] = piece_y;
                    active_x[3] = piece_x + 2; active_y[3] = piece_y;
                end
            end
            1: begin // O-фигура (Квадрат)
                active_x[0] = piece_x;     active_y[0] = piece_y;
                active_x[1] = piece_x + 1; active_y[1] = piece_y;
                active_x[2] = piece_x;     active_y[2] = piece_y + 1;
                active_x[3] = piece_x + 1; active_y[3] = piece_y + 1;
            end
            // Добавить T, S, Z, J, L
            default: begin
                for(int i=0; i<4; i++) begin active_x[i] = 0; active_y[i] = 0; end
            end
        endcase
    end

    // -Коллизия
    logic collision;
    always_comb begin
        collision = 1'b0;
        for (int i = 0; i < 4; i++) begin
            // Стенки и дно
            if (active_x[i] < 0 || active_x[i] >= GRID_W || active_y[i] >= GRID_H)
                collision = 1'b1;
            // Проверка с уже упавшими блоками
            else if (active_y[i] >= 0 && land[active_y[i]][active_x[i]])
                collision = 1'b1;
        end
    end

    // Джойстик
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            game_over <= 0;
            score <= 0;
            for (int i=0; i<GRID_H; i++) land[i] <= '0;
        end else if (run) begin
            case (state)
                S_IDLE: state <= S_NEW_PIECE;

                S_NEW_PIECE: begin
                    curr_type <= rng_value[2:0] % 7;
                    curr_rot  <= 0;
                    piece_x   <= GRID_W / 2 - 1;
                    piece_y   <= 0;
                    state     <= S_MOVE;
                    if (collision) game_over <= 1'b1;
                end

                S_MOVE: begin
                    // Здесь обрабатываем кнопки btn_left, btn_right, btn_up
                    // (Нужно сохранять старые координаты, пробовать новые, 
                    // если есть коллизия — откатывать назад)
                    if (game_tick || (btn_down)) state <= S_FALL;
                end

                S_FALL: begin
                    // piece_y <= piece_y + 1;
                    // Если collision -> state <= S_LOCK
                end
                
                // дописать...
            endcase
        end
    end

endmodule