module NumberProvider(
	input logic [3:0]in,
	input logic [6:0]positionX,
	input logic [2:0]positionY,
	output logic [19:0]out[4:0]
);
	always_comb
		case (in)
			4'd1: begin
				out[0] <= {7'b0000000 + positionX, positionY, 10'b0001000100};
				out[1] <= {7'b0000001 + positionX, positionY, 10'b0001000010};
				out[2] <= {7'b0000010 + positionX, positionY, 10'b0001111111};
				out[3] <= {7'b0000011 + positionX, positionY, 10'b0001000000};
				out[4] <= {7'b0000100 + positionX, positionY, 10'b0001000000};
			end
			
			4'd2: begin
				out[0] <= {7'b0000000 + positionX, positionY, 10'b0001111001};
				out[1] <= {7'b0000001 + positionX, positionY, 10'b0001001001};
				out[2] <= {7'b0000010 + positionX, positionY, 10'b0001001001};
				out[3] <= {7'b0000011 + positionX, positionY, 10'b0001001001};
				out[4] <= {7'b0000100 + positionX, positionY, 10'b0001001111};
			end
			
			4'd3: begin
				out[0] <= {7'b0000000 + positionX, positionY, 10'b0001001001};
				out[1] <= {7'b0000001 + positionX, positionY, 10'b0001001001};
				out[2] <= {7'b0000010 + positionX, positionY, 10'b0001001001};
				out[3] <= {7'b0000011 + positionX, positionY, 10'b0001001001};
				out[4] <= {7'b0000100 + positionX, positionY, 10'b0001111111};
			end
			
			4'd4: begin
				out[0] <= {7'b0000000 + positionX, positionY, 10'b0000001111};
				out[1] <= {7'b0000001 + positionX, positionY, 10'b0000001000};
				out[2] <= {7'b0000010 + positionX, positionY, 10'b0000001000};
				out[3] <= {7'b0000011 + positionX, positionY, 10'b0000001000};
				out[4] <= {7'b0000100 + positionX, positionY, 10'b0001111111};
			end
			
			4'd5: begin
				out[0] <= {7'b0000000 + positionX, positionY, 10'b0001001111};
				out[1] <= {7'b0000001 + positionX, positionY, 10'b0001001001};
				out[2] <= {7'b0000010 + positionX, positionY, 10'b0001001001};
				out[3] <= {7'b0000011 + positionX, positionY, 10'b0001001001};
				out[4] <= {7'b0000100 + positionX, positionY, 10'b0001111001};
			end
			
			4'd6: begin
				out[0] <= {7'b0000000 + positionX, positionY, 10'b0001111111};
				out[1] <= {7'b0000001 + positionX, positionY, 10'b0001001001};
				out[2] <= {7'b0000010 + positionX, positionY, 10'b0001001001};
				out[3] <= {7'b0000011 + positionX, positionY, 10'b0001001001};
				out[4] <= {7'b0000100 + positionX, positionY, 10'b0001111001};
			end
			
			4'd7: begin
				out[0] <= {7'b0000000 + positionX, positionY, 10'b0000000011};
				out[1] <= {7'b0000001 + positionX, positionY, 10'b0000000001};
				out[2] <= {7'b0000010 + positionX, positionY, 10'b0000001001};
				out[3] <= {7'b0000011 + positionX, positionY, 10'b0001111111};
				out[4] <= {7'b0000100 + positionX, positionY, 10'b0000001000};
			end
			
			4'd8: begin
				out[0] <= {7'b0000000 + positionX, positionY, 10'b0001110111};
				out[1] <= {7'b0000001 + positionX, positionY, 10'b0001001001};
				out[2] <= {7'b0000010 + positionX, positionY, 10'b0001001001};
				out[3] <= {7'b0000011 + positionX, positionY, 10'b0001001001};
				out[4] <= {7'b0000100 + positionX, positionY, 10'b0001110111};
			end
			
			4'd9: begin
				out[0] <= {7'b0000000 + positionX, positionY, 10'b0001001111};
				out[1] <= {7'b0000001 + positionX, positionY, 10'b0001001001};
				out[2] <= {7'b0000010 + positionX, positionY, 10'b0001001001};
				out[3] <= {7'b0000011 + positionX, positionY, 10'b0001001001};
				out[4] <= {7'b0000100 + positionX, positionY, 10'b0001111111};
			end
			
			default: begin
				out[0] <= {7'b0000000 + positionX, positionY, 10'b0000111110};
				out[1] <= {7'b0000001 + positionX, positionY, 10'b0001010001};
				out[2] <= {7'b0000010 + positionX, positionY, 10'b0001001001};
				out[3] <= {7'b0000011 + positionX, positionY, 10'b0001000101};
				out[4] <= {7'b0000100 + positionX, positionY, 10'b0000111110};
			end
		endcase
endmodule