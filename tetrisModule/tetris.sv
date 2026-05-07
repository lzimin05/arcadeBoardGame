`timescale 1ns / 1ps

module tetris #(
    parameter GRID_W = 10,
    parameter GRID_H = 12, 
    parameter SPEED_THRESHOLD = 25000000
)(
    input  logic clk,
    input  logic rst,
    input  logic run,
    input  logic btn_up,    // Поворот
    input  logic btn_down,  // Ускорение
    input  logic btn_left,
    input  logic btn_right,
    input  logic commandAck,
    
    output logic game_over,
    output logic [11:0] score,
    
    // Маска для видеокарты
    output logic [119:0] tetris_mask,
    // Команды для обновления Score
    output logic [2:0] command,
    output logic [31:0] data,
    output logic commandCS
);

    typedef enum logic [3:0] {
        S_IDLE, S_INIT_VIEW, S_INIT_ACK, S_NEW_PIECE, S_PLAY, 
        S_DRAW_START, S_DRAW_LOOP, S_DRAW_WAIT,
        S_LOCK, S_CHECK_LINES, S_UPDATE_SCORE, S_SCORE_ACK, S_GAMEOVER
    } state_t;
    state_t state;

    logic [GRID_W-1:0] land [0:GRID_H-1];
    logic signed [5:0] cur_x, cur_y;
    logic [2:0] cur_type;
    logic [1:0] cur_rot;
    
    logic signed [5:0] active_x [0:3], active_y [0:3];
    logic game_tick;
    logic [15:0] rng_value;

    logic [4:0] draw_ptr_x;
    logic [3:0] draw_ptr_y;

    logic up_reg, left_reg, right_reg;
    wire up_pulse    = btn_up    && !up_reg;
    wire left_pulse  = btn_left  && !left_reg;
    wire right_pulse = btn_right && !right_reg;

    always_ff @(posedge clk) begin
        up_reg <= btn_up; left_reg <= btn_left; right_reg <= btn_right;
    end

    clkDelay #(.WIDTH(25)) fallTimer (.clk(clk), .rst(rst), .threshold(SPEED_THRESHOLD), .clk_delay(game_tick));
    randomizer_lfsr #(.WIDTH(16)) rnd (.clk(clk), .rst(rst), .enable(state == S_NEW_PIECE), .value(rng_value));

function void get_piece(input [2:0] t, input [1:0] r, input signed [5:0] px, input signed [5:0] py, output signed [5:0] ox[4], output signed [5:0] oy[4]);
        case (t)
            0: begin // I (полоска)
                if (r[0]) begin ox='{px, px, px, px}; oy='{py-1, py, py+1, py+2}; end
                else      begin ox='{px-1, px, px+1, px+2}; oy='{py, py, py, py}; end
            end
            1: begin // O (квадрат)
                ox='{px, px+1, px, px+1}; oy='{py, py, py+1, py+1};
            end
            2: begin // T
                if(r==0)      begin ox='{px, px-1, px+1, px}; oy='{py, py, py, py+1}; end
                else if(r==1) begin ox='{px, px, px+1, px}; oy='{py, py-1, py, py+1}; end
                else if(r==2) begin ox='{px, px-1, px+1, px}; oy='{py, py, py, py-1}; end
                else          begin ox='{px, px-1, px, px};   oy='{py, py-1, py, py+1}; end
            end
            3: begin // S
                if(r[0]) begin ox='{px, px, px+1, px+1}; oy='{py-1, py, py, py+1}; end
                else     begin ox='{px, px+1, px-1, px}; oy='{py, py+1, py, py+1}; end
            end
            4: begin // Z
                if(r[0]) begin ox='{px+1, px+1, px, px}; oy='{py-1, py, py, py+1}; end
                else     begin ox='{px-1, px, px, px+1}; oy='{py, py+1, py, py+1}; end
            end
            5: begin // J
                if(r==0)      begin ox='{px, px, px-1, px}; oy='{py-1, py, py+1, py+1}; end
                else if(r==1) begin ox='{px-1, px-1, px, px+1}; oy='{py, py+1, py, py}; end
                else if(r==2) begin ox='{px, px, px+1, px}; oy='{py-1, py-1, py, py+1}; end
                else          begin ox='{px-1, px, px+1, px+1}; oy='{py, py, py, py-1}; end
            end
            6: begin // L
                if(r==0)      begin ox='{px, px, px+1, px}; oy='{py-1, py, py+1, py+1}; end
                else if(r==1) begin ox='{px-1, px, px+1, px-1}; oy='{py, py, py, py-1}; end
                else if(r==2) begin ox='{px, px-1, px, px}; oy='{py-1, py-1, py, py+1}; end
                else          begin ox='{px+1, px+1, px, px-1}; oy='{py, py-1, py, py}; end
            end
            default: begin ox='{px, px+1, px, px+1}; oy='{py, py, py+1, py+1}; end
        endcase
    endfunction

    always_comb get_piece(cur_type, cur_rot, cur_x, cur_y, active_x, active_y);

    logic collision;
    always_comb begin
        collision = 1'b0;
        for (int i = 0; i < 4; i++) begin
            if (active_x[i] < 0 || active_x[i] >= GRID_W || active_y[i] >= GRID_H) collision = 1'b1;
            else if (active_y[i] >= 0 && land[active_y[i]][active_x[i]]) collision = 1'b1;
        end
    end

    // маска
    always_comb begin
        tetris_mask = '0;
        for (int y = 0; y < GRID_H; y++) begin
            for (int x = 0; x < GRID_W; x++) begin
                if (land[y][x]) tetris_mask[y*GRID_W + x] = 1'b1;
            end
        end
        for (int i = 0; i < 4; i++) begin
            if (active_y[i] >= 0 && active_y[i] < GRID_H && active_x[i] >= 0 && active_x[i] < GRID_W)
                tetris_mask[active_y[i]*GRID_W + active_x[i]] = 1'b1;
        end
    end

    logic cell_active;
    always_comb begin
        cell_active = 0;
        for(int i=0; i<4; i++) if(active_x[i] == draw_ptr_x && active_y[i] == draw_ptr_y) cell_active = 1;
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE; game_over <= 0; score <= 12'h000; commandCS <= 0;
            for (int i=0; i<GRID_H; i++) land[i] <= '0;
        end else if (run) begin
            case (state)
                S_IDLE: begin
                    state <= S_INIT_VIEW;
                end

                S_INIT_VIEW: begin
                    command <= 3'b000;
                    data <= 32'd2; 
                    commandCS <= 1;
                    state <= S_INIT_ACK;
                end

                S_INIT_ACK: if (!commandAck) begin commandCS <= 0; state <= S_NEW_PIECE; end

                S_NEW_PIECE: begin
                    cur_type <= rng_value[2:0] % 7; cur_rot <= 0; cur_x <= 4; cur_y <= 0;
                    if (collision) state <= S_GAMEOVER;
                    else state <= S_DRAW_START;
                end

                S_PLAY: begin
                    // падение
                    if (game_tick || btn_down) begin
                        cur_y <= cur_y + 1;
                        if (collision) begin
                            cur_y <= cur_y - 1; // Откат
                            state <= S_LOCK;
                        end else state <= S_DRAW_START;
                    end 
                    // влево
                    else if (left_pulse) begin
                        cur_x <= cur_x - 1;
                        if (collision) cur_x <= cur_x + 1; // Откат
                        else state <= S_DRAW_START;
                    end
                    // вправо
                    else if (right_pulse) begin
                        cur_x <= cur_x + 1;
                        if (collision) cur_x <= cur_x - 1; // Откат
                        else state <= S_DRAW_START;
                    end
                    // Поворот
                    else if (up_pulse) begin
                        cur_rot <= cur_rot + 1;
                        if (collision) cur_rot <= cur_rot - 1; // Откат
                        else state <= S_DRAW_START;
                    end
                end

                S_DRAW_START: begin draw_ptr_x <= 0; draw_ptr_y <= 0; state <= S_DRAW_LOOP; end

                S_DRAW_LOOP: begin
                    command <= 3'b101;
                    data <= {22'b0, draw_ptr_x + 5'd4, draw_ptr_y, (land[draw_ptr_y][draw_ptr_x] || cell_active)};
                    commandCS <= 1;
                    state <= S_DRAW_WAIT;
                end

                S_DRAW_WAIT: if (!commandAck) begin
                    commandCS <= 0;
                    if (draw_ptr_x < GRID_W - 1) begin draw_ptr_x <= draw_ptr_x + 1; state <= S_DRAW_LOOP; end
                    else if (draw_ptr_y < GRID_H - 1) begin draw_ptr_x <= 0; draw_ptr_y <= draw_ptr_y + 1; state <= S_DRAW_LOOP; end
                    else state <= S_PLAY;
                end

                S_LOCK: begin
                    for(int i=0; i<4; i++) 
                        if(active_y[i] >= 0 && active_y[i] < GRID_H) land[active_y[i]][active_x[i]] <= 1;
                    state <= S_CHECK_LINES;
                end

                S_CHECK_LINES: begin
                    logic [3:0] lines_cleared = 0;
                    for(int i=0; i<GRID_H; i++) begin
                        if (land[i] == {GRID_W{1'b1}}) begin
                            lines_cleared++;
                            for (int j=i; j>0; j--) land[j] <= land[j-1];
                            land[0] <= '0;
                        end
                    end
                    if (lines_cleared > 0) begin
                        if (score[7:4] + lines_cleared >= 10) begin	
                            score[7:4] <= score[7:4] + lines_cleared - 4'd10;
                            score[11:8] <= score[11:8] + 4'd1;
                        end else begin
                            score[7:4] <= score[7:4] + lines_cleared;
                        end
                        state <= S_UPDATE_SCORE;
                    end else state <= S_NEW_PIECE;
                end

                S_UPDATE_SCORE: begin
                    command <= 3'b100;
                    data <= {10'b0, score, 10'b010_10000}; 
                    commandCS <= 1;
                    state <= S_SCORE_ACK;
                end

                S_SCORE_ACK: if (!commandAck) begin commandCS <= 0; state <= S_NEW_PIECE; end

                S_GAMEOVER: game_over <= 1;
            endcase
        end
    end
endmodule