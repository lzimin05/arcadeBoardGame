module initModule(
	input logic rst,
	input logic clk,
	input logic cs,
	
	input logic cmdAck,
	output logic [7:0]cmdData,
	output logic cmdMode,
	output logic cmdEn,
	
	output logic ack
);
	enum {
		INIT, 
		NEW_COMMAND, 
		WAIT_ACK
	} state;

	logic [5:0][7:0] initCommands;
	logic [3:0]commandIndex;

	initial
		initCommands = {8'h0C, 8'h20, 8'h14, 8'h04, 8'hB8, 8'h21};
		
	always_ff@(posedge clk, posedge rst)
		if (rst) begin
			commandIndex <= 0;
			state <= INIT;
			cmdData <= 8'b0;
			cmdMode <= 1'b0;
			cmdEn <= 1'b1;
		end else
			unique case (state)
				INIT: if (cs) begin
					state <= NEW_COMMAND;
					commandIndex <= 0;
					cmdMode <= 0;
					ack <= 1;
				end
				NEW_COMMAND: begin
					cmdData <= initCommands[commandIndex];
					cmdEn <= 0;
					state <= WAIT_ACK;
				end
				WAIT_ACK: 
					if (!cmdAck) begin
						commandIndex <= commandIndex + 1'b1;
						state <= commandIndex < 5 ? NEW_COMMAND : INIT;
						ack <= commandIndex < 5 ? 1'b1 : 1'b0;
					end else
						cmdEn <= 1;
				
			endcase
endmodule
