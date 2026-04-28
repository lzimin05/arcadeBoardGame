`timescale 1ns / 1ps

module tetris #(
    parameter GRID_W = 10,
    parameter GRID_H = 12, 
    parameter X_OFFSET = 5, 
    parameter SPEED_THRESHOLD = 25000000
)(
    input  logic clk,
    input  logic rst,
    input  logic run,
    input  logic btn_up,    //Поворот
    input  logic btn_down,  //Ускорение
    input  logic btn_left,
    input  logic btn_right,
    input  logic commandAck,
    
    output logic game_over,
    output logic [15:0] score,
    
    output logic [2:0] command,
    output logic [31:0] data,
    output logic commandCS
);

    typedef enum logic [3:0] {
        S_IDLE, S_NEW_PIECE, S_WAIT_INPUT, S_MOVE, S_FALL, 
        S_LOCK, S_CHECK_LINES, S_GAME_OVER,
        S_DRAW_FULL_START, S_DRAW_FULL_LOOP, S_DRAW_WAIT_ACK,
        S_DRAW_NEW_PIECE
    } state_t;
    
    state_t state;

    logic [GRID_W-1:0] land [0:GRID_H-1];
    logic signed [5:0] cur_x, cur_y;
    logic [2:0] cur_type;
    logic [1:0] cur_rot;
    
    logic signed [5:0] active_x [0:3], active_y [0:3];

    logic game_tick;
    logic [15:0] rng_value;
    
    logic up_reg, left_reg, right_reg;
    wire up_pulse    = btn_up    && !up_reg;
    wire left_pulse  = btn_left  && !left_reg;
    wire right_pulse = btn_right && !right_reg;

    always_ff @(posedge clk) begin
        up_reg <= btn_up;
        left_reg <= btn_left;
        right_reg <= btn_right;
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
                else          begin ox='{px, px, px-1, px}; oy='{py, py-1, py, py+1}; end
            end
            3: begin // S
                if(r[0]) begin ox='{px, px, px+1, px+1}; oy='{py-1, py, py, py+1}; end
                else     begin ox='{px, px+1, px-1, px}; oy='{py, py, py+1, py+1}; end
            end
            4: begin // Z
                if(r[0]) begin ox='{px+1, px+1, px, px}; oy='{py-1, py, py, py+1}; end
                else     begin ox='{px-1, px, px, px+1}; oy='{py, py, py+1, py+1}; end
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
                else if(r==2) begin ox='{px, px, px-1, px}; oy='{py-1, py-1, py, py+1}; end
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
            if (active_x[i] < 0 || active_x[i] >= GRID_W || active_y[i] >= GRID_H)
                collision = 1'b1;
            else if (active_y[i] >= 0 && land[active_y[i]][active_x[i]])
                collision = 1'b1;
        end
    end

    logic [4:0] draw_ptr_x;
    logic [3:0] draw_ptr_y;

    logic cell_is_active;
    always_comb begin
        cell_is_active = 1'b0;
        for(int i=0; i<4; i++)
            if(active_x[i] == draw_ptr_x && active_y[i] == draw_ptr_y) cell_is_active = 1'b1;
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            game_over <= 0;
            score <= 0;
            commandCS <= 0;
            for (int i=0; i<GRID_H; i++) land[i] <= '0;
        end else if (run) begin
            case (state)
                S_IDLE: begin
                    command <= 3'b000; 
                    data <= 0;
                    commandCS <= 1;
                    if (!commandAck) begin commandCS <= 0; state <= S_NEW_PIECE; end
                end

                S_NEW_PIECE: begin
                    cur_type <= rng_value[2:0] % 7; 
                    cur_rot  <= 0;
                    cur_x    <= GRID_W / 2 - 1;
                    cur_y    <= 0;
                    state    <= S_DRAW_NEW_PIECE;
                    if (collision) game_over <= 1;
                end

                S_DRAW_FULL_START: begin
                    draw_ptr_x <= 0;
                    draw_ptr_y <= 0;
                    state <= S_DRAW_FULL_LOOP;
                end

                S_DRAW_FULL_LOOP: begin
                    command <= 3'b101;
                    data <= {22'b0, draw_ptr_x + X_OFFSET[4:0], draw_ptr_y, (land[draw_ptr_y][draw_ptr_x] || cell_is_active)};
                    commandCS <= 1;
                    state <= S_DRAW_WAIT_ACK;
                end

                S_DRAW_WAIT_ACK: begin
                    if (!commandAck) begin
                        commandCS <= 0;
                        if (draw_ptr_x < GRID_W - 1) begin
                            draw_ptr_x <= draw_ptr_x + 1;
                            state <= S_DRAW_FULL_LOOP;
                        end else if (draw_ptr_y < GRID_H - 1) begin
                            draw_ptr_x <= 0;
                            draw_ptr_y <= draw_ptr_y + 1;
                            state <= S_DRAW_FULL_LOOP;
                        end else begin
                            state <= S_WAIT_INPUT;
                        end
                    end
                end

                S_WAIT_INPUT: begin
                    if (game_tick || (btn_down)) state <= S_FALL;
                    else if (left_pulse) begin
                        cur_x <= cur_x - 1;
                        if (collision) cur_x <= cur_x + 1;
                        else state <= S_DRAW_FULL_START;
                    end
                    else if (right_pulse) begin
                        cur_x <= cur_x + 1;
                        if (collision) cur_x <= cur_x - 1;
                        else state <= S_DRAW_FULL_START;
                    end
                    else if (up_pulse) begin
                        cur_rot <= cur_rot + 1;
                        if (collision) cur_rot <= cur_rot - 1;
                        else state <= S_DRAW_FULL_START;
                    end
                end

                S_FALL: begin
                    cur_y <= cur_y + 1;
                    if (collision) begin
                        cur_y <= cur_y - 1;
                        state <= S_LOCK;
                    end else begin
                        state <= S_DRAW_FULL_START;
                    end
                end

                S_LOCK: begin
                    for(int i=0; i<4; i++) 
                        if(active_y[i] >= 0) land[active_y[i]][active_x[i]] <= 1;
                    state <= S_CHECK_LINES;
                end

                S_CHECK_LINES: begin
                    for(int i=0; i<GRID_H; i++) begin
                        if (land[i] == {GRID_W{1'b1}}) begin
                            score <= score + 10;
                            for (int j=i; j>0; j--) land[j] <= land[j-1];
                            land[0] <= '0;
                        end
                    end
                    state <= S_NEW_PIECE;
                end
                
                S_DRAW_NEW_PIECE: state <= S_DRAW_FULL_START; 

            endcase
        end
    end
endmodule