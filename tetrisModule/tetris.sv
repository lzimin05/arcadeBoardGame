`timescale 1ns / 1ps

module tetris #(
    parameter GRID_W = 10,
    parameter GRID_H = 11, 
    parameter SPEED_THRESHOLD = 25000000
)(
    input  logic clk,
    input  logic rst,
    input  logic run,
    input  logic btn_up,    
    input  logic btn_down,  
    input  logic btn_left,
    input  logic btn_right,
    input  logic commandAck,
    
    output logic game_over,
    output logic [11:0] score,
    
    output logic [2:0] command,
    output logic [31:0] data,
    output logic commandCS
);

    typedef enum logic [4:0] {
        S_IDLE, S_INIT_VIEW, S_INIT_ACK, S_INIT_SCORE, S_INIT_SCORE_ACK,
        S_NEW_PIECE, S_CHECK_SPAWN, S_PLAY, 
        S_CHECK_DOWN, S_CHECK_LEFT, S_CHECK_RIGHT, S_CHECK_ROT,
        
        S_ERASE_PREV_START, S_ERASE_PREV, S_ERASE_PREV_WAIT, S_ERASE_PREV_NEXT,
        S_DRAW_PIECE_START, S_DRAW_PIECE, S_DRAW_PIECE_WAIT, S_DRAW_PIECE_NEXT,
        S_DRAW_BOARD_START, S_DRAW_BOARD, S_DRAW_BOARD_WAIT, S_DRAW_BOARD_NEXT,
        
        S_LOCK, S_CHECK_LINES, S_UPDATE_SCORE, S_SCORE_ACK, S_GAMEOVER
    } state_t;
    state_t state;

    logic [GRID_W-1:0] land [0:GRID_H-1];
    logic signed [5:0] cur_x, cur_y;
    logic [2:0] cur_type;
    logic [1:0] cur_rot;
    
    logic signed [5:0] active_x [0:3], active_y [0:3];
    logic signed [5:0] prev_x [0:3], prev_y [0:3]; 
    
    logic game_tick;
    logic [15:0] rng_value;

    logic [4:0] draw_ptr_x;
    logic [3:0] draw_ptr_y;
    logic [2:0] piece_draw_idx;
    logic full_redraw; 

    logic up_reg, left_reg, right_reg, down_reg;
    wire up_pulse    = btn_up    && !up_reg;
    wire left_pulse  = btn_left  && !left_reg;
    wire right_pulse = btn_right && !right_reg;
    wire down_pulse  = btn_down  && !down_reg; 

    logic is_over_flag;
    logic found_line;
    logic [3:0] clear_index;

    always_ff @(posedge clk) begin
        up_reg <= btn_up; left_reg <= btn_left; 
        right_reg <= btn_right; down_reg <= btn_down;
    end

    logic tick_pending, left_pending, right_pending, up_pending, down_pending;

    clkDelay #(.WIDTH(25)) fallTimer (.clk(clk), .rst(rst), .threshold(SPEED_THRESHOLD), .clk_delay(game_tick));
    randomizer_lfsr #(.WIDTH(16)) rnd (.clk(clk), .rst(rst), .enable(state == S_NEW_PIECE), .value(rng_value));

    function void get_piece(input [2:0] t, input [1:0] r, input signed [5:0] px, input signed [5:0] py, output signed [5:0] ox[4], output signed [5:0] oy[4]);
        case (t)
            0: begin if (r[0]) begin ox='{px, px, px, px}; oy='{py-1, py, py+1, py+2}; end else begin ox='{px-1, px, px+1, px+2}; oy='{py, py, py, py}; end end
            1: begin ox='{px, px+1, px, px+1}; oy='{py, py, py+1, py+1}; end
            2: begin // T
                if(r==0)      begin ox='{px, px-1, px+1, px}; oy='{py, py, py, py+1}; end
                else if(r==1) begin ox='{px, px, px+1, px}; oy='{py, py-1, py, py+1}; end
                else if(r==2) begin ox='{px, px-1, px+1, px}; oy='{py, py, py, py-1}; end
                else          begin ox='{px, px, px-1, px};   oy='{py, py-1, py, py+1}; end
            end	
            3: begin
                if(r[0]) begin ox='{px, px, px+1, px+1}; oy='{py-1, py, py, py+1}; end
                else     begin ox='{px, px+1, px-1, px}; oy='{py, py+1, py, py+1}; end
            end
            4: begin
                if(r[0]) begin ox='{px+1, px+1, px, px}; oy='{py-1, py, py, py+1}; end
                else     begin ox='{px-1, px, px, px+1}; oy='{py, py+1, py, py+1}; end
            end
            5: begin
                if(r==0)      begin ox='{px, px, px-1, px}; oy='{py-1, py, py+1, py+1}; end
                else if(r==1) begin ox='{px-1, px-1, px, px+1}; oy='{py, py+1, py, py}; end
                else if(r==2) begin ox='{px, px, px+1, px}; oy='{py-1, py-1, py, py+1}; end
                else          begin ox='{px-1, px, px+1, px+1}; oy='{py, py, py, py-1}; end
            end
            6: begin
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

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE; game_over <= 0; score <= 12'h000; commandCS <= 0; full_redraw <= 1;
            tick_pending <= 0; left_pending <= 0; right_pending <= 0; up_pending <= 0; down_pending <= 0;
            for (int i=0; i<GRID_H; i++) land[i] <= '0;
            for (int i=0; i<4; i++) begin prev_x[i] <= '0; prev_y[i] <= -6'd1; end 
            cur_x <= 4; cur_y <= 0; cur_type <= 0; cur_rot <= 0;
        end else begin
            if (!run) begin
                state <= S_IDLE; game_over <= 0; score <= 12'h000; commandCS <= 0; full_redraw <= 1;
                tick_pending <= 0; left_pending <= 0; right_pending <= 0; up_pending <= 0; down_pending <= 0;
                for (int i=0; i<GRID_H; i++) land[i] <= '0;
                for (int i=0; i<4; i++) begin prev_x[i] <= '0; prev_y[i] <= -6'd1; end 
                cur_x <= 4; cur_y <= 0; cur_type <= 0; cur_rot <= 0;
            end else if (!game_over) begin
                
                if (game_tick) tick_pending <= 1;
                if (left_pulse) left_pending <= 1;
                if (right_pulse) right_pending <= 1; 
                if (up_pulse) up_pending <= 1;
                if (down_pulse) down_pending <= 1; 

                case (state)
                    S_IDLE: begin
                        state <= S_INIT_VIEW;
                    end
                    S_INIT_VIEW: begin
                        command <= 3'b000; data <= 32'd2; commandCS <= 1; state <= S_INIT_ACK;
                    end
                    S_INIT_ACK: if (!commandAck) begin commandCS <= 0; state <= S_INIT_SCORE; end
                    
                    S_INIT_SCORE: begin
                        command <= 3'b100;
                        data <= {10'b0, score, 3'b001, 7'd1}; 
                        commandCS <= 1;
                        state <= S_INIT_SCORE_ACK;
                    end
                    S_INIT_SCORE_ACK: if (!commandAck) begin commandCS <= 0; state <= S_NEW_PIECE; end

                    S_NEW_PIECE: begin
                        cur_type <= rng_value[2:0] % 7; cur_rot <= 0; cur_x <= 4; cur_y <= 0;
                        state <= S_CHECK_SPAWN; 
                    end

                    S_CHECK_SPAWN: begin
                        if (collision) state <= S_GAMEOVER;
                        else state <= full_redraw ? S_DRAW_BOARD_START : S_DRAW_PIECE_START;
                    end

                    S_PLAY: begin
                        for(int i=0; i<4; i++) begin prev_x[i] <= active_x[i]; prev_y[i] <= active_y[i]; end

                        if (tick_pending || down_pending) begin
                            tick_pending <= 0; down_pending <= 0;
                            cur_y <= cur_y + 1; state <= S_CHECK_DOWN;
                        end 
                        else if (left_pending) begin
                            left_pending <= 0; cur_x <= cur_x - 1; state <= S_CHECK_LEFT;
                        end
                        else if (right_pending) begin
                            right_pending <= 0; cur_x <= cur_x + 1; state <= S_CHECK_RIGHT;
                        end
                        else if (up_pending) begin
                            up_pending <= 0; cur_rot <= cur_rot + 1; state <= S_CHECK_ROT;
                        end
                    end

                    S_CHECK_DOWN: begin
                        if (collision) begin
                            cur_y <= cur_y - 1; state <= S_LOCK;
                        end else state <= S_ERASE_PREV_START;
                    end

                    S_CHECK_LEFT: begin
                        if (collision) begin cur_x <= cur_x + 1; state <= S_PLAY; end 
                        else state <= S_ERASE_PREV_START;
                    end

                    S_CHECK_RIGHT: begin
                        if (collision) begin cur_x <= cur_x - 1; state <= S_PLAY; end 
                        else state <= S_ERASE_PREV_START;
                    end

                    S_CHECK_ROT: begin
                        if (collision) begin cur_rot <= cur_rot - 1; state <= S_PLAY; end 
                        else state <= S_ERASE_PREV_START;
                    end

                    S_ERASE_PREV_START: begin piece_draw_idx <= 0; state <= S_ERASE_PREV; end
                    S_ERASE_PREV: begin
                        if (prev_y[piece_draw_idx] >= 0) begin 
                            command <= 3'b101;
                            data <= {22'b0, prev_x[piece_draw_idx][4:0] + 5'd6, prev_y[piece_draw_idx][3:0], 1'b0};
                            commandCS <= 1; state <= S_ERASE_PREV_WAIT;
                        end else state <= S_ERASE_PREV_NEXT;
                    end
                    S_ERASE_PREV_WAIT: if (!commandAck) begin commandCS <= 0; state <= S_ERASE_PREV_NEXT; end
                    S_ERASE_PREV_NEXT: begin
                        if (piece_draw_idx < 3) begin piece_draw_idx <= piece_draw_idx + 1; state <= S_ERASE_PREV; end
                        else state <= S_DRAW_PIECE_START;
                    end

                    S_DRAW_PIECE_START: begin piece_draw_idx <= 0; state <= S_DRAW_PIECE; end
                    S_DRAW_PIECE: begin
                        if (active_y[piece_draw_idx] >= 0) begin 
                            command <= 3'b101;
                            data <= {22'b0, active_x[piece_draw_idx][4:0] + 5'd6, active_y[piece_draw_idx][3:0], 1'b1};
                            commandCS <= 1; state <= S_DRAW_PIECE_WAIT;
                        end else state <= S_DRAW_PIECE_NEXT;
                    end
                    S_DRAW_PIECE_WAIT: if (!commandAck) begin commandCS <= 0; state <= S_DRAW_PIECE_NEXT; end
                    S_DRAW_PIECE_NEXT: begin
                        if (piece_draw_idx < 3) begin piece_draw_idx <= piece_draw_idx + 1; state <= S_DRAW_PIECE; end
                        else begin full_redraw <= 0; state <= S_PLAY; end 
                    end

                    S_DRAW_BOARD_START: begin draw_ptr_x <= 0; draw_ptr_y <= 0; state <= S_DRAW_BOARD; end
                    S_DRAW_BOARD: begin
                        command <= 3'b101;
                        data <= {22'b0, draw_ptr_x + 5'd6, draw_ptr_y, land[draw_ptr_y][draw_ptr_x]};
                        commandCS <= 1; state <= S_DRAW_BOARD_WAIT;
                    end
                    S_DRAW_BOARD_WAIT: if (!commandAck) begin commandCS <= 0; state <= S_DRAW_BOARD_NEXT; end
                    S_DRAW_BOARD_NEXT: begin
                        if (draw_ptr_x < GRID_W - 1) begin draw_ptr_x <= draw_ptr_x + 1; state <= S_DRAW_BOARD; end
                        else if (draw_ptr_y < GRID_H - 1) begin draw_ptr_x <= 0; draw_ptr_y <= draw_ptr_y + 1; state <= S_DRAW_BOARD; end
                        else state <= S_DRAW_PIECE_START; 
                    end

                    S_LOCK: begin
                        is_over_flag = 1'b0; 
                        for(int i=0; i<4; i++) begin
                            if(active_y[i] >= 0 && active_y[i] < GRID_H) begin
                                land[active_y[i]][active_x[i]] <= 1;
                            end else if (active_y[i] < 0) begin
                                is_over_flag = 1'b1; 
                            end
                        end
                        if (is_over_flag) state <= S_GAMEOVER;
                        else state <= S_CHECK_LINES;
                    end

                    S_CHECK_LINES: begin
                        found_line = 1'b0; 
                        clear_index = 4'd0;
                        
                        for (int i = GRID_H - 1; i >= 0; i--) begin
                            if (land[i] == {GRID_W{1'b1}} && !found_line) begin
                                found_line = 1'b1;
                                clear_index = i[3:0];
                            end
                        end
                        
                        if (found_line) begin
                            full_redraw <= 1'b1; 
                            for (int j = GRID_H - 1; j > 0; j--) begin
                                if (j <= clear_index) land[j] <= land[j-1];
                            end
                            land[0] <= {GRID_W{1'b0}}; 
                            
                            if (score[3:0] == 4'd9) begin
                                score[3:0] <= 4'd0;
                                if (score[7:4] == 4'd9) begin
                                    score[7:4] <= 4'd0;
                                    score[11:8] <= score[11:8] + 1'b1;
                                end else begin
                                    score[7:4] <= score[7:4] + 1'b1;
                                end
                            end else begin
                                score[3:0] <= score[3:0] + 1'b1;
                            end
                            state <= S_UPDATE_SCORE; 
                        end else begin
                            state <= S_NEW_PIECE; 
                        end
                    end

                    S_UPDATE_SCORE: begin
                        command <= 3'b100;
                        data <= {10'b0, score, 3'b001, 7'd1}; 
                        commandCS <= 1; state <= S_SCORE_ACK;
                    end
                    
                    S_SCORE_ACK: if (!commandAck) begin 
                        commandCS <= 0; 
                        state <= S_CHECK_LINES; 
                    end

                    S_GAMEOVER: begin
                         game_over <= 1; 
                         commandCS <= 0; 
                    end
                endcase
            end else begin
                game_over <= 1;
                commandCS <= 0;
            end
        end
    end
endmodule