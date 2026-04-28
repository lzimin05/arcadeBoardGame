	module drawModule(
	input logic rst,
	input logic clk,
	input logic cs,
	
	input [19:0]pxl,
	input pxlEn,

	input logic cmdAck,
	output logic [7:0]cmdData,
	output logic cmdMode,
	output logic cmdEn,
	
	output logic ack
);
	enum {
		INIT, 
		NEW_COMMAND, 
		WAIT_ACK, 
		WAIT_X_ACK,
		WAIT_Y_ACK,
		NEXT_CMD
	} state;

	logic [7:0]MATRIX[83:0][5:0];
	logic UPDATED[83:0][5:0];
	
	logic [6:0]x;
	logic [2:0]y;
	
	logic skipPixel;
	
	logic [9:0]startPixel;
	logic [9:0]endPixel;
	logic waitEnd;
	
	always_ff@(posedge clk, posedge rst)
		if (rst) begin
			state <= INIT;
			cmdData <= 8'b0;
			cmdMode <= 1'b0;
			cmdEn <= 1'b1;
			x <= 0;
			y <= 0;
			skipPixel <= 1'b1;
			ack <= 1'b1;
			startPixel <= 10'b0000000000;
			endPixel <=   10'b1011010011;
			waitEnd <= 1'b0;
		end else begin
			if (!pxlEn) begin
				case (pxl[9:8])
					2'b00:
						MATRIX[pxl[19:13]][pxl[12:10]] <= pxl[7:0];
					2'b01:
						MATRIX[pxl[19:13]][pxl[12:10]] <= pxl[7:0] & MATRIX[pxl[19:13]][pxl[12:10]][7:0];
					default:
						MATRIX[pxl[19:13]][pxl[12:10]] <= pxl[7:0] | MATRIX[pxl[19:13]][pxl[12:10]][7:0];		
				endcase
				
				UPDATED[pxl[19:13]][pxl[12:10]] <= 1'b1;
				
				startPixel <= (startPixel > {pxl[12:10], pxl[19:13]} || !waitEnd) ? {pxl[12:10], pxl[19:13]} : startPixel;
				endPixel <= (endPixel < {pxl[12:10], pxl[19:13]} || !waitEnd) ? {pxl[12:10], pxl[19:13]} : endPixel;
				waitEnd <= 1'b1;
			end else 
				if (waitEnd) begin
					waitEnd <= 1'b0;
					skipPixel <= 1'b1;
					x <= startPixel[6:0];
					y <= startPixel[9:7];
					state <= NEW_COMMAND;
					ack <= 1'b1;
				end
					
			unique case (state)
				INIT: if (cs)
					state <= NEW_COMMAND;
				else
					ack <= 1'b1;
				
				NEW_COMMAND: begin
					if (!UPDATED[x][y]) begin
						state <= NEXT_CMD;
						skipPixel <= 1'b1;
					end else begin
						skipPixel <= 1'b0;
						if (!skipPixel) begin
							cmdData <= MATRIX[x][y];
							UPDATED[x][y] <= 1'b0;
							cmdEn <= 0;
							cmdMode <= 1'b1;
							state <= WAIT_ACK;
						end else begin
							cmdData <= 8'h80 | x;
							cmdEn <= 0;
							cmdMode <= 1'b0;
							state <= WAIT_X_ACK;
						end
					end
				end
				
				WAIT_X_ACK: begin
					if (!cmdAck) begin
						cmdData <= 8'h40 | y;
						cmdEn <= 0;
						cmdMode <= 1'b0;
						state <= WAIT_Y_ACK;
					end else
						cmdEn <= 1;
				end
				
				WAIT_Y_ACK: begin
					if (!cmdAck) begin
						cmdData <= MATRIX[x][y];
						cmdEn <= 0;
						cmdMode <= 1'b1;
						state <= WAIT_ACK;
					end else
						cmdEn <= 1;
				end
				
				WAIT_ACK: 
					if (!cmdAck) begin
						state <= NEXT_CMD;
					end else
						cmdEn <= 1;
						
				NEXT_CMD: begin
					x <= (x == 83) ? 0 : (x + 1'b1);
					y <= (x == 83) ? (y + 1) : y;
					state <= (x != endPixel[6:0] || y != endPixel[9:7]) ? NEW_COMMAND : INIT;
					ack <= (x != endPixel[6:0] || y != endPixel[9:7]) ? 1'b1 : 1'b0;
				end
			endcase
		end
endmodule
