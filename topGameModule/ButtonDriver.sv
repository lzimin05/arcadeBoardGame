module ButtonDriver(
	input logic clk,
	input logic rst,
	input logic in,
	output logic out
);
	enum { WAIT, PRESSED_BLOCK, WAIT_DEPRESSED, DEPRESSED_BLOCK } state;
	logic [24:0]timer;
	
	always_ff@(posedge clk, posedge rst)
		if (rst) begin
			state <= WAIT;
			timer <= 23'b0;
			out <= 1'b0;
		end else begin
			unique case (state)
				WAIT:
					if (in) begin
						state <= PRESSED_BLOCK;
						timer <= 25'b0;
					end
				PRESSED_BLOCK:
					if (timer == 1 << 8)
						state <= WAIT_DEPRESSED;
					else
						timer <= timer + 23'b1;
				WAIT_DEPRESSED:
					if (!in) begin
						state <= DEPRESSED_BLOCK;
						timer <= 25'b0;
						out <= 1'b1;
					end
				DEPRESSED_BLOCK:
					if (timer == 1 << 8)
						state <= WAIT;
					else begin
						timer <= timer + 23'b1;
						out <= 1'b0;
					end
			endcase
		end
endmodule