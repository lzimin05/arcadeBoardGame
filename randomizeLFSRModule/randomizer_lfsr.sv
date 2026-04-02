`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.03.2026 14:30:10
// Design Name: 
// Module Name: randomizer_lfsr
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


module randomizer_lfsr #(
    parameter WIDTH = 16,                    // Разрядность числа
    parameter DEFAULT_SEED = 16'hACE1        // Зерно по умолчанию
)(
    input  logic clk,
    input  logic rst,
    input  logic enable,                      // Запрос нового числа
    input  logic [7:0] seed_in,               // Внешнее зерно (опционально)
    output logic [WIDTH-1:0] value,           // Случайное число
    output logic ready                        // Готовность
);

    logic [WIDTH-1:0] lfsr_reg;
    assign ready = 1'b1;
    
    // Блок приколистов
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            lfsr_reg <= DEFAULT_SEED;
            value <= DEFAULT_SEED;
        end else if (enable) begin
            // следующий шаг LFSR
            logic [WIDTH-1:0] next_lfsr;
            next_lfsr = {lfsr_reg[WIDTH-2:0], lfsr_reg[WIDTH-1] ~^ lfsr_reg[WIDTH-3] ~^ lfsr_reg[WIDTH-4] ~^ lfsr_reg[WIDTH-6]};
            
            // работа с зерном
            if (seed_in != 8'h00) begin
                next_lfsr[7:0] = next_lfsr[7:0] ^ seed_in;
            end
            
            lfsr_reg <= next_lfsr;
            value <= next_lfsr;
        end
    end
    
endmodule