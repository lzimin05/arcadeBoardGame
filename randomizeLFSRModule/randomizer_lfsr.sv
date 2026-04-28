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
	logic [WIDTH-1:0] next_val;
	logic feedback;
	
	assign ready = 1'b1;
	
	always_comb begin
		feedback = lfsr_reg[WIDTH-1] ~^ lfsr_reg[WIDTH-3] ~^ lfsr_reg[WIDTH-4] ~^ lfsr_reg[WIDTH-6];
		next_val = {lfsr_reg[WIDTH-2:0], feedback};
		if (seed_in != 8'h00) begin
			next_val[7:0] = next_val[7:0] ^ seed_in;
		end
	end
	
	always_ff @(posedge clk or posedge rst) begin
		if(rst) begin
			lfsr_reg <= DEFAULT_SEED;
			value <= DEFAULT_SEED;
		end else if (enable) begin
			lfsr_reg <= next_val;
			value <= next_val;
		end
	end

endmodule