module GPUControlDevice(
	input logic clk,
	input logic rst,
	input logic cs,
	
	input logic commandCS,
	input logic [2:0]command,
	input logic [31:0]data,
	input logic pxlAck,
	
	output logic [19:0]pxlCommand,
	output logic pxlCommandEn,
	output logic commandAck
);
	enum {
		WAIT_COMMAND,
		WAIT_NUMBER_SHOW,
		SEND_COMMAND,
		WAIT_ACK
	} state;
	
	logic [19:0]pxlCommands[48:0];
	logic [6:0]pxlCommandIndex; 
	
	logic clearEn;
	logic [1:0]clearMode;
	logic [6:0]clearX;
	logic [2:0]clearY;
	
	logic [11:0]numbers[199:0];
	
	logic [9:0]numberForShow;
	logic [9:0]numberForShowPosition;
	logic [11:0]realNumbers;
	logic [19:0]realNumbersCommands[14:0];
	
	logic [7:0]counter;

	NumberProvider np1 (
		.in(realNumbers[11:8]),
		.positionX(numberForShowPosition[6:0] + 7'd0),
		.positionY(numberForShowPosition[9:7]),
		.out(realNumbersCommands[4:0])
	);
	
	NumberProvider np2 (
		.in(realNumbers[7:4]),
		.positionX(numberForShowPosition[6:0] + 7'd6),
		.positionY(numberForShowPosition[9:7]),
		.out(realNumbersCommands[9:5])
	);
	
	NumberProvider np3 (
		.in(realNumbers[3:0]),
		.positionX(numberForShowPosition[6:0] + 7'd12),
		.positionY(numberForShowPosition[9:7]),
		.out(realNumbersCommands[14:10])
	);
	
	always_ff@(posedge clk, posedge rst)
		if (rst) begin
			state <= WAIT_COMMAND;
			commandAck <= 1'b1;
			clearEn <= 1'b0;
			clearMode <= 2'b00;
			realNumbers <= 12'b0;
		end else
			unique case (state)
				WAIT_COMMAND: begin
					commandAck <= 1'b1;
					if (commandCS) begin
						if (command != 3'b100)
							state <= SEND_COMMAND;
						else
							state <= WAIT_NUMBER_SHOW;
							
						if (command == 3'b000) begin
							clearEn <= 1'b1;
							clearX <= 7'b0;
							clearY <= 3'b0;
							clearMode <= data[1:0];
						end
						if (command == 3'b001) begin
							clearEn <= 1'b0;
							pxlCommandIndex <= 6'd31;
							pxlCommands[0] <= {7'b0000000 + data[6:0], data[9:7], 10'b0000000001};
							pxlCommands[1] <= {7'b0000001 + data[6:0], data[9:7], 10'b0000000001};
							pxlCommands[2] <= {7'b0000010 + data[6:0], data[9:7], 10'b0001111111};
							pxlCommands[3] <= {7'b0000011 + data[6:0], data[9:7], 10'b0000000001};
							pxlCommands[4] <= {7'b0000100 + data[6:0], data[9:7], 10'b0000000001};
							pxlCommands[5] <= {7'b0000110 + data[6:0], data[9:7], 10'b0001111111};
							pxlCommands[6] <= {7'b0000111 + data[6:0], data[9:7], 10'b0001001001};
							pxlCommands[7] <= {7'b0001000 + data[6:0], data[9:7], 10'b0001001001};
							pxlCommands[8] <= {7'b0001001 + data[6:0], data[9:7], 10'b0001001001};
							pxlCommands[9] <= {7'b0001010 + data[6:0], data[9:7], 10'b0001001001};
							pxlCommands[10] <= {7'b0001011 + data[6:0], data[9:7], 10'b0001101011};
							pxlCommands[11] <= {7'b0001101 + data[6:0], data[9:7], 10'b0000000001};
							pxlCommands[12] <= {7'b0001110 + data[6:0], data[9:7], 10'b0000000001};
							pxlCommands[13] <= {7'b0001111 + data[6:0], data[9:7], 10'b0001111111};
							pxlCommands[14] <= {7'b0010000 + data[6:0], data[9:7], 10'b0000000001};
							pxlCommands[15] <= {7'b0010001 + data[6:0], data[9:7], 10'b0000000001};
							pxlCommands[16] <= {7'b0010011 + data[6:0], data[9:7], 10'b0001111111};
							pxlCommands[17] <= {7'b0010100 + data[6:0], data[9:7], 10'b0000001001};
							pxlCommands[18] <= {7'b0010101 + data[6:0], data[9:7], 10'b0000001001};
							pxlCommands[19] <= {7'b0010110 + data[6:0], data[9:7], 10'b0000001001};
							pxlCommands[20] <= {7'b0010111 + data[6:0], data[9:7], 10'b0000001001};
							pxlCommands[21] <= {7'b0011000 + data[6:0], data[9:7], 10'b0000001111};
							pxlCommands[22] <= {7'b0011010 + data[6:0], data[9:7], 10'b0001111111};
							pxlCommands[23] <= {7'b0011011 + data[6:0], data[9:7], 10'b0000100000};
							pxlCommands[24] <= {7'b0011100 + data[6:0], data[9:7], 10'b0000010000};
							pxlCommands[25] <= {7'b0011101 + data[6:0], data[9:7], 10'b0000001000};
							pxlCommands[26] <= {7'b0011110 + data[6:0], data[9:7], 10'b0000000100};
							pxlCommands[27] <= {7'b0011111 + data[6:0], data[9:7], 10'b0001111111};
							pxlCommands[28] <= {7'b0100001 + data[6:0], data[9:7], 10'b0001111111};
							pxlCommands[29] <= {7'b0100010 + data[6:0], data[9:7], 10'b0001000001};
							pxlCommands[30] <= {7'b0100011 + data[6:0], data[9:7], 10'b0001000001};
							pxlCommands[31] <= {7'b0100100 + data[6:0], data[9:7], 10'b0001000001};
						end
						if (command == 3'b010) begin
							clearEn <= 1'b0;
							pxlCommandIndex <= 6'd31;
							pxlCommands[0] <= {7'b0000000 + data[6:0], data[9:7], 10'b0001001001};
							pxlCommands[1] <= {7'b0000001 + data[6:0], data[9:7], 10'b0001001001};
							pxlCommands[2] <= {7'b0000010 + data[6:0], data[9:7], 10'b0001001001};
							pxlCommands[3] <= {7'b0000011 + data[6:0], data[9:7], 10'b0001001001};
							pxlCommands[4] <= {7'b0000100 + data[6:0], data[9:7], 10'b0001010101};
							pxlCommands[5] <= {7'b0000101 + data[6:0], data[9:7], 10'b0001100011};
							pxlCommands[6] <= {7'b0000111 + data[6:0], data[9:7], 10'b0001111111};
							pxlCommands[7] <= {7'b0001000 + data[6:0], data[9:7], 10'b0000000010};
							pxlCommands[8] <= {7'b0001001 + data[6:0], data[9:7], 10'b0000000100};
							pxlCommands[9] <= {7'b0001010 + data[6:0], data[9:7], 10'b0000000100};
							pxlCommands[10] <= {7'b0001011 + data[6:0], data[9:7], 10'b0000000010};
							pxlCommands[11] <= {7'b0001100 + data[6:0], data[9:7], 10'b0001111111};
							pxlCommands[12] <= {7'b0001110 + data[6:0], data[9:7], 10'b0001111111};
							pxlCommands[13] <= {7'b0001111 + data[6:0], data[9:7], 10'b0001001001};
							pxlCommands[14] <= {7'b0010000 + data[6:0], data[9:7], 10'b0001001001};
							pxlCommands[15] <= {7'b0010001 + data[6:0], data[9:7], 10'b0001001001};
							pxlCommands[16] <= {7'b0010010 + data[6:0], data[9:7], 10'b0001001001};
							pxlCommands[17] <= {7'b0010100 + data[6:0], data[9:7], 10'b0001111100};
							pxlCommands[18] <= {7'b0010101 + data[6:0], data[9:7], 10'b0000100001};
							pxlCommands[19] <= {7'b0010110 + data[6:0], data[9:7], 10'b0000010001};
							pxlCommands[20] <= {7'b0010111 + data[6:0], data[9:7], 10'b0000001001};
							pxlCommands[21] <= {7'b0011000 + data[6:0], data[9:7], 10'b0001111100};
							pxlCommands[22] <= {7'b0011010 + data[6:0], data[9:7], 10'b0001111111};
							pxlCommands[23] <= {7'b0011011 + data[6:0], data[9:7], 10'b0000001000};
							pxlCommands[24] <= {7'b0011100 + data[6:0], data[9:7], 10'b0000010100};
							pxlCommands[25] <= {7'b0011101 + data[6:0], data[9:7], 10'b0000100010};
							pxlCommands[26] <= {7'b0011110 + data[6:0], data[9:7], 10'b0001000001};
							pxlCommands[27] <= {7'b0100000 + data[6:0], data[9:7], 10'b0001111000};
							pxlCommands[28] <= {7'b0100001 + data[6:0], data[9:7], 10'b0000010110};
							pxlCommands[29] <= {7'b0100010 + data[6:0], data[9:7], 10'b0000010001};
							pxlCommands[30] <= {7'b0100011 + data[6:0], data[9:7], 10'b0000010110};
							pxlCommands[31] <= {7'b0100100 + data[6:0], data[9:7], 10'b0001111000};
						end
						if (command == 3'b011) begin
							clearEn <= 1'b0;
							pxlCommandIndex <= 3'd6;
							if (data[10]) begin
								pxlCommands[0] <= {7'b0000000 + data[6:0], data[9:7], 10'b0000001000};
								pxlCommands[1] <= {7'b0000001 + data[6:0], data[9:7], 10'b0000001000};
								pxlCommands[2] <= {7'b0000010 + data[6:0], data[9:7], 10'b0000001000};
								pxlCommands[3] <= {7'b0000011 + data[6:0], data[9:7], 10'b0000001000};
								pxlCommands[4] <= {7'b0000100 + data[6:0], data[9:7], 10'b0000101010};
								pxlCommands[5] <= {7'b0000101 + data[6:0], data[9:7], 10'b0000011100};
								pxlCommands[6] <= {7'b0000110 + data[6:0], data[9:7], 10'b0000001000};
							end else begin
								pxlCommands[0] <= {7'b0000000 + data[6:0], data[9:7], 10'b0000000000};
								pxlCommands[1] <= {7'b0000001 + data[6:0], data[9:7], 10'b0000000000};
								pxlCommands[2] <= {7'b0000010 + data[6:0], data[9:7], 10'b0000000000};
								pxlCommands[3] <= {7'b0000011 + data[6:0], data[9:7], 10'b0000000000};
								pxlCommands[4] <= {7'b0000100 + data[6:0], data[9:7], 10'b0000000000};
								pxlCommands[5] <= {7'b0000101 + data[6:0], data[9:7], 10'b0000000000};
								pxlCommands[6] <= {7'b0000110 + data[6:0], data[9:7], 10'b0000000000};
							end
						end
						if (command == 3'b100) begin
							clearEn <= 1'b0;
							realNumbers <= data[21:10];
							numberForShowPosition <= data[9:0];
						end
						if (command == 3'b101) begin
							clearEn <= 1'b0;
							pxlCommandIndex <= 3'd4;
							pxlCommands[0] <= {
								7'b0000000 + {data[9:5], 2'b00}, 
								data[4:2], 
								data[0] 
									? (!data[1] ? 10'b1000001111 : 10'b1011110000)
									: (!data[1] ? 10'b0111110000 : 10'b0100001111)
							};
							pxlCommands[1] <= {
								7'b0000001 + {data[9:5], 2'b00}, 
								data[4:2], 
								data[0] 
									? (!data[1] ? 10'b1000001111 : 10'b1011110000)
									: (!data[1] ? 10'b0111110000 : 10'b0100001111)
									
							};
							pxlCommands[2] <= {
								7'b0000010 + {data[9:5], 2'b00}, 
								data[4:2], 
								data[0] 
									? (!data[1] ? 10'b1000001111 : 10'b1011110000)
									: (!data[1] ? 10'b0111110000 : 10'b0100001111)
									
							};
							pxlCommands[3] <= {
								7'b0000011 + {data[9:5], 2'b00}, 
								data[4:2], 
								data[0] 
									? (!data[1] ? 10'b1000001111 : 10'b1011110000)
									: (!data[1] ? 10'b0111110000 : 10'b0100001111)
									
							};
						end
						if (command == 3'b110) begin
							clearEn <= 1'b0;
							pxlCommandIndex <= 6'd39;
							pxlCommands[0] <= {7'b0000000 + data[6:0], data[9:7], 10'b0001111111};
							pxlCommands[1] <= {7'b0000001 + data[6:0], data[9:7], 10'b0001000001};
							pxlCommands[2] <= {7'b0000010 + data[6:0], data[9:7], 10'b0001001001};
							pxlCommands[3] <= {7'b0000011 + data[6:0], data[9:7], 10'b0001001001};
							pxlCommands[4] <= {7'b0000100 + data[6:0], data[9:7], 10'b0001111001};
							pxlCommands[5] <= {7'b0000110 + data[6:0], data[9:7], 10'b0001110000};
							pxlCommands[6] <= {7'b0000111 + data[6:0], data[9:7], 10'b0000011100};
							pxlCommands[7] <= {7'b0001000 + data[6:0], data[9:7], 10'b0000010011};
							pxlCommands[8] <= {7'b0001001 + data[6:0], data[9:7], 10'b0000011100};
							pxlCommands[9] <= {7'b0001010 + data[6:0], data[9:7], 10'b0001110000};
							pxlCommands[10] <= {7'b0001100 + data[6:0], data[9:7], 10'b0001111111};
							pxlCommands[11] <= {7'b0001101 + data[6:0], data[9:7], 10'b0000000010};
							pxlCommands[12] <= {7'b0001110 + data[6:0], data[9:7], 10'b0000000100};
							pxlCommands[13] <= {7'b0001111 + data[6:0], data[9:7], 10'b0000000010};
							pxlCommands[14] <= {7'b0010000 + data[6:0], data[9:7], 10'b0001111111};
							pxlCommands[15] <= {7'b0010010 + data[6:0], data[9:7], 10'b0001111111};
							pxlCommands[16] <= {7'b0010011 + data[6:0], data[9:7], 10'b0001001001};
							pxlCommands[17] <= {7'b0010100 + data[6:0], data[9:7], 10'b0001001001};
							pxlCommands[18] <= {7'b0010101 + data[6:0], data[9:7], 10'b0001001001};
							pxlCommands[19] <= {7'b0010110 + data[6:0], data[9:7], 10'b0001001001};
							pxlCommands[20] <= {7'b0011010 + data[6:0], data[9:7], 10'b0001111111};
							pxlCommands[21] <= {7'b0011011 + data[6:0], data[9:7], 10'b0001000001};
							pxlCommands[22] <= {7'b0011100 + data[6:0], data[9:7], 10'b0001000001};
							pxlCommands[23] <= {7'b0011101 + data[6:0], data[9:7], 10'b0001000001};
							pxlCommands[24] <= {7'b0011110 + data[6:0], data[9:7], 10'b0001111111};
							pxlCommands[25] <= {7'b0100000 + data[6:0], data[9:7], 10'b0000000111};
							pxlCommands[26] <= {7'b0100001 + data[6:0], data[9:7], 10'b0000111000};
							pxlCommands[27] <= {7'b0100010 + data[6:0], data[9:7], 10'b0001000000};
							pxlCommands[28] <= {7'b0100011 + data[6:0], data[9:7], 10'b0000111000};
							pxlCommands[29] <= {7'b0100100 + data[6:0], data[9:7], 10'b0000000111};
							pxlCommands[30] <= {7'b0100110 + data[6:0], data[9:7], 10'b0001111111};
							pxlCommands[31] <= {7'b0100111 + data[6:0], data[9:7], 10'b0001001001};
							pxlCommands[32] <= {7'b0101000 + data[6:0], data[9:7], 10'b0001001001};
							pxlCommands[33] <= {7'b0101001 + data[6:0], data[9:7], 10'b0001001001};
							pxlCommands[34] <= {7'b0101010 + data[6:0], data[9:7], 10'b0001001001};
							pxlCommands[35] <= {7'b0101100 + data[6:0], data[9:7], 10'b0001111111};
							pxlCommands[36] <= {7'b0101101 + data[6:0], data[9:7], 10'b0000011001};
							pxlCommands[37] <= {7'b0101110 + data[6:0], data[9:7], 10'b0000101001};
							pxlCommands[38] <= {7'b0101111 + data[6:0], data[9:7], 10'b0000101001};
							pxlCommands[39] <= {7'b0110000 + data[6:0], data[9:7], 10'b0001001111};
						end
						
						if (command == 3'b111) begin
							clearEn <= 1'b0;
							pxlCommandIndex <= 6'd44;
							pxlCommands[0] <= {7'b0000000 + data[6:0], data[9:7], 10'b0001111111};
							pxlCommands[1] <= {7'b0000001 + data[6:0], data[9:7], 10'b0001000001};
							pxlCommands[2] <= {7'b0000010 + data[6:0], data[9:7], 10'b0001000001};
							pxlCommands[3] <= {7'b0000011 + data[6:0], data[9:7], 10'b0001000001};
							pxlCommands[4] <= {7'b0000100 + data[6:0], data[9:7], 10'b0001000001};
							pxlCommands[5] <= {7'b0000110 + data[6:0], data[9:7], 10'b0001111111};
							pxlCommands[6] <= {7'b0000111 + data[6:0], data[9:7], 10'b0001000001};
							pxlCommands[7] <= {7'b0001000 + data[6:0], data[9:7], 10'b0001000001};
							pxlCommands[8] <= {7'b0001001 + data[6:0], data[9:7], 10'b0001000001};
							pxlCommands[9] <= {7'b0001010 + data[6:0], data[9:7], 10'b0001111111};
							pxlCommands[10] <= {7'b0001100 + data[6:0], data[9:7], 10'b0001111111};
							pxlCommands[11] <= {7'b0001101 + data[6:0], data[9:7], 10'b0000000010};
							pxlCommands[12] <= {7'b0001110 + data[6:0], data[9:7], 10'b0000001100};
							pxlCommands[13] <= {7'b0001111 + data[6:0], data[9:7], 10'b0000010000};
							pxlCommands[14] <= {7'b0010000 + data[6:0], data[9:7], 10'b0001111111};
							pxlCommands[15] <= {7'b0010010 + data[6:0], data[9:7], 10'b0000000001};
							pxlCommands[16] <= {7'b0010011 + data[6:0], data[9:7], 10'b0000000001};
							pxlCommands[17] <= {7'b0010100 + data[6:0], data[9:7], 10'b0001111111};
							pxlCommands[18] <= {7'b0010101 + data[6:0], data[9:7], 10'b0000000001};
							pxlCommands[19] <= {7'b0010110 + data[6:0], data[9:7], 10'b0000000001};
							pxlCommands[20] <= {7'b0011000 + data[6:0], data[9:7], 10'b0001000001};
							pxlCommands[21] <= {7'b0011001 + data[6:0], data[9:7], 10'b0001000001};
							pxlCommands[22] <= {7'b0011010 + data[6:0], data[9:7], 10'b0001111111};
							pxlCommands[23] <= {7'b0011011 + data[6:0], data[9:7], 10'b0001000001};
							pxlCommands[24] <= {7'b0011100 + data[6:0], data[9:7], 10'b0001000001};
							pxlCommands[25] <= {7'b0011110 + data[6:0], data[9:7], 10'b0001111111};
							pxlCommands[26] <= {7'b0011111 + data[6:0], data[9:7], 10'b0000000010};
							pxlCommands[27] <= {7'b0100000 + data[6:0], data[9:7], 10'b0000001100};
							pxlCommands[28] <= {7'b0100001 + data[6:0], data[9:7], 10'b0000010000};
							pxlCommands[29] <= {7'b0100010 + data[6:0], data[9:7], 10'b0001111111};
							pxlCommands[30] <= {7'b0100100 + data[6:0], data[9:7], 10'b0001111111};
							pxlCommands[31] <= {7'b0100101 + data[6:0], data[9:7], 10'b0000100000};
							pxlCommands[32] <= {7'b0100110 + data[6:0], data[9:7], 10'b0000011000};
							pxlCommands[33] <= {7'b0100111 + data[6:0], data[9:7], 10'b0000000100};
							pxlCommands[34] <= {7'b0101000 + data[6:0], data[9:7], 10'b0001111111};
							pxlCommands[35] <= {7'b0101010 + data[6:0], data[9:7], 10'b0001111111};
							pxlCommands[36] <= {7'b0101011 + data[6:0], data[9:7], 10'b0001001001};
							pxlCommands[37] <= {7'b0101100 + data[6:0], data[9:7], 10'b0001001001};
							pxlCommands[38] <= {7'b0101101 + data[6:0], data[9:7], 10'b0001001001};
							pxlCommands[39] <= {7'b0101110 + data[6:0], data[9:7], 10'b0001001001};
							pxlCommands[40] <= {7'b0110000 + data[6:0], data[9:7], 10'b0000000011};
							pxlCommands[41] <= {7'b0110001 + data[6:0], data[9:7], 10'b0000000001};
							pxlCommands[42] <= {7'b0110010 + data[6:0], data[9:7], 10'b0001010001};
							pxlCommands[43] <= {7'b0110011 + data[6:0], data[9:7], 10'b0000001001};
							pxlCommands[44] <= {7'b0110100 + data[6:0], data[9:7], 10'b0000000111};
						end
					end
				end
				SEND_COMMAND:
					if (clearEn) begin
						if (clearMode == 2'b01) begin
							pxlCommand <= {
								clearX, 
								clearY, 
								2'b00, 
								(clearY > 0 && (clearX < 3 || clearX > 80)) 
									? 8'd255
									: (clearY == 1
										? 8'b00000111
										: (clearY == 5
											? 8'b11100000
											: 8'b0
										)
									)
							};
						end else if (clearMode == 2'b10) begin
							pxlCommand <= {
								clearX, 
								clearY,
								2'b00, 
							((clearX >= 21 && clearX <= 23) || (clearX >= 64 && clearX <= 66))
    ? 8'b11111111
    : (
        ((clearY == 5) && (clearX >= 21 && clearX <= 66)) 
            ? 8'b11110000
            : 8'b0
    )
							};
						end else
							pxlCommand <= {
								clearX, 
								clearY, 
								2'b00, 
								8'd0
							};
						pxlCommandEn <= 1'b0;
						clearX <= clearX == 83 ? 7'b0 : (clearX + 7'b1);
						clearY <= clearX == 83 ? (clearY + 3'b1) : clearY;
						if (clearX == 83 && clearY == 5)
							if (clearMode == 2'b01) begin
								clearEn <= 1'b0;
								pxlCommandIndex <= 5'd25;
								pxlCommands[0] <= {7'b0000000 + (clearMode == 2'b01 ? 7'b0 : 7'b0), (clearMode == 2'b01 ? 3'b0 : 3'b0), 10'b0001101111};
								pxlCommands[1] <= {7'b0000001 + (clearMode == 2'b01 ? 7'b0 : 7'b0), (clearMode == 2'b01 ? 3'b0 : 3'b0), 10'b0001001001};
								pxlCommands[2] <= {7'b0000010 + (clearMode == 2'b01 ? 7'b0 : 7'b0), (clearMode == 2'b01 ? 3'b0 : 3'b0), 10'b0001001001};
								pxlCommands[3] <= {7'b0000011 + (clearMode == 2'b01 ? 7'b0 : 7'b0), (clearMode == 2'b01 ? 3'b0 : 3'b0), 10'b0001001001};
								pxlCommands[4] <= {7'b0000100 + (clearMode == 2'b01 ? 7'b0 : 7'b0), (clearMode == 2'b01 ? 3'b0 : 3'b0), 10'b0001111011};
								pxlCommands[5] <= {7'b0000110 + (clearMode == 2'b01 ? 7'b0 : 7'b0), (clearMode == 2'b01 ? 3'b0 : 3'b0), 10'b0001111111};
								pxlCommands[6] <= {7'b0000111 + (clearMode == 2'b01 ? 7'b0 : 7'b0), (clearMode == 2'b01 ? 3'b0 : 3'b0), 10'b0001000001};
								pxlCommands[7] <= {7'b0001000 + (clearMode == 2'b01 ? 7'b0 : 7'b0), (clearMode == 2'b01 ? 3'b0 : 3'b0), 10'b0001000001};
								pxlCommands[8] <= {7'b0001001 + (clearMode == 2'b01 ? 7'b0 : 7'b0), (clearMode == 2'b01 ? 3'b0 : 3'b0), 10'b0001000001};
								pxlCommands[9] <= {7'b0001010 + (clearMode == 2'b01 ? 7'b0 : 7'b0), (clearMode == 2'b01 ? 3'b0 : 3'b0), 10'b0001000001};
								pxlCommands[10] <= {7'b0001100 + (clearMode == 2'b01 ? 7'b0 : 7'b0), (clearMode == 2'b01 ? 3'b0 : 3'b0), 10'b0001111111};
								pxlCommands[11] <= {7'b0001101 + (clearMode == 2'b01 ? 7'b0 : 7'b0), (clearMode == 2'b01 ? 3'b0 : 3'b0), 10'b0001000001};
								pxlCommands[12] <= {7'b0001110 + (clearMode == 2'b01 ? 7'b0 : 7'b0), (clearMode == 2'b01 ? 3'b0 : 3'b0), 10'b0001000001};
								pxlCommands[13] <= {7'b0001111 + (clearMode == 2'b01 ? 7'b0 : 7'b0), (clearMode == 2'b01 ? 3'b0 : 3'b0), 10'b0001000001};
								pxlCommands[14] <= {7'b0010000 + (clearMode == 2'b01 ? 7'b0 : 7'b0), (clearMode == 2'b01 ? 3'b0 : 3'b0), 10'b0001111111};
								pxlCommands[15] <= {7'b0010010 + (clearMode == 2'b01 ? 7'b0 : 7'b0), (clearMode == 2'b01 ? 3'b0 : 3'b0), 10'b0001111111};
								pxlCommands[16] <= {7'b0010011 + (clearMode == 2'b01 ? 7'b0 : 7'b0), (clearMode == 2'b01 ? 3'b0 : 3'b0), 10'b0000011001};
								pxlCommands[17] <= {7'b0010100 + (clearMode == 2'b01 ? 7'b0 : 7'b0), (clearMode == 2'b01 ? 3'b0 : 3'b0), 10'b0000101001};
								pxlCommands[18] <= {7'b0010101 + (clearMode == 2'b01 ? 7'b0 : 7'b0), (clearMode == 2'b01 ? 3'b0 : 3'b0), 10'b0000101001};
								pxlCommands[19] <= {7'b0010110 + (clearMode == 2'b01 ? 7'b0 : 7'b0), (clearMode == 2'b01 ? 3'b0 : 3'b0), 10'b0001001111};
								pxlCommands[20] <= {7'b0011000 + (clearMode == 2'b01 ? 7'b0 : 7'b0), (clearMode == 2'b01 ? 3'b0 : 3'b0), 10'b0001111111};
								pxlCommands[21] <= {7'b0011001 + (clearMode == 2'b01 ? 7'b0 : 7'b0), (clearMode == 2'b01 ? 3'b0 : 3'b0), 10'b0001001001};
								pxlCommands[22] <= {7'b0011010 + (clearMode == 2'b01 ? 7'b0 : 7'b0), (clearMode == 2'b01 ? 3'b0 : 3'b0), 10'b0001001001};
								pxlCommands[23] <= {7'b0011011 + (clearMode == 2'b01 ? 7'b0 : 7'b0), (clearMode == 2'b01 ? 3'b0 : 3'b0), 10'b0001001001};
								pxlCommands[24] <= {7'b0011100 + (clearMode == 2'b01 ? 7'b0 : 7'b0), (clearMode == 2'b01 ? 3'b0 : 3'b0), 10'b0001001001};
								pxlCommands[25] <= {7'b0011110 + (clearMode == 2'b01 ? 7'b0 : 7'b0), (clearMode == 2'b01 ? 3'b0 : 3'b0), 10'b0000100100};
							end else
								state <= WAIT_ACK;
					end else begin
						pxlCommand <= pxlCommands[pxlCommandIndex];
						pxlCommandIndex <= pxlCommandIndex - 1;
						pxlCommandEn <= 1'b0;
						if (pxlCommandIndex == 0)
							state <= WAIT_ACK;
					end
				WAIT_NUMBER_SHOW: begin
					if (counter == 7'd90) begin
						pxlCommandIndex <= 6'd14;
						
						pxlCommands[0] <= realNumbersCommands[0];
						pxlCommands[1] <= realNumbersCommands[1];
						pxlCommands[2] <= realNumbersCommands[2];
						pxlCommands[3] <= realNumbersCommands[3];
						pxlCommands[4] <= realNumbersCommands[4];
						
						pxlCommands[5] <= realNumbersCommands[5];
						pxlCommands[6] <= realNumbersCommands[6];
						pxlCommands[7] <= realNumbersCommands[7];
						pxlCommands[8] <= realNumbersCommands[8];
						pxlCommands[9] <= realNumbersCommands[9];
						
						pxlCommands[10] <= realNumbersCommands[10];
						pxlCommands[11] <= realNumbersCommands[11];
						pxlCommands[12] <= realNumbersCommands[12];
						pxlCommands[13] <= realNumbersCommands[13];
						pxlCommands[14] <= realNumbersCommands[14];
						
						state <= SEND_COMMAND;
					end else 
						counter <= counter + 1;
				end
				WAIT_ACK: begin
					pxlCommandEn <= 1'b1;
					if (!pxlAck) begin
						state <= WAIT_COMMAND;
						commandAck <= 1'b0;
					end
				end
			endcase
endmodule