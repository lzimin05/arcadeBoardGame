module GPU(
	input logic rst,
	input logic clk,
	
	input logic [2:0]command,
	input logic [31:0]data,
	input logic commandCS,
	output logic commandAck,
	
	output logic screenRst,
	output logic screenClk,
	output logic screenCE,
	output logic screenDC,
	output logic screenDIn
);
	enum { 
		RESET_LOW, 
		RESET_HIGH, 
		INIT, ACK_INIT,
		WAIT_COMMAND, ACK_COMMAND,
		RUN_MODE
	} state;
	
	logic [23:0]resetCounter;

	logic [13:0]SCREEN;
	logic ACK;
	logic GPU_ACK;
	
	logic [13:0]INIT_WIRES = 0;
	logic INIT_CS;
	logic INIT_ACK;
	
	logic [13:0]DRAW_WIRES;
	logic DRAW_CS;
	logic DRAW_ACK;
	
	logic CTRL_CS;
	logic CTRL_ACK;
	
	logic [19:0]pxlCommand;
	logic pxlCommandEn;
	
	assign screenClk = SCREEN[0];
	assign screenCE = SCREEN[1];
	assign screenDC = SCREEN[2];
	assign screenDIn = SCREEN[3];

	SPI SPIController (
		.rst(rst),
		.in_clk(clk),
		
		.en(SCREEN[4]),
		.value(SCREEN[12:5]),
		.ack(ACK),
		.mode(SCREEN[13]),
		
		.clk(SCREEN[0]),
		.ce(SCREEN[1]),
		.dc(SCREEN[2]),
		.din(SCREEN[3])
	);
	
	initModule init (
		.rst(rst),
		.clk(clk),
		.cs(INIT_CS),
		
		.cmdAck(ACK),
		.cmdData(INIT_WIRES[12:5]),
		.cmdMode(INIT_WIRES[13]),
		.cmdEn(INIT_WIRES[4]),
		
		.ack(INIT_ACK)
	);
	
	drawModule draw1 (
		.rst(rst),
		.clk(clk),
		.cs(DRAW_CS),
		
		.pxl(pxlCommand),
		.pxlEn(pxlCommandEn),
		
		.cmdAck(ACK),
		.cmdData(DRAW_WIRES[12:5]),
		.cmdMode(DRAW_WIRES[13]),
		.cmdEn(DRAW_WIRES[4]),
		
		.ack(DRAW_ACK)
	);
	
	GPUControlDevice Device (
		.rst(rst),
		.clk(clk),
		.cs(CTRL_CS),
		
		.commandCS(commandCS),
		.command(command),
		.data(data),
		.pxlAck(DRAW_ACK),
		
		.pxlCommand(pxlCommand),
		.pxlCommandEn(pxlCommandEn),
		.commandAck(CTRL_ACK)
	);
		
	always_ff@(posedge clk, posedge rst)
		if (rst) begin
			state <= RESET_LOW;
			resetCounter <= 0;
		end else begin
			case (state)
				RESET_LOW:
					if (resetCounter == (1 << 8)) begin
						state <= RESET_HIGH;
						resetCounter <= 1'b0;
					end else begin
						screenRst <= 0;
						resetCounter <= resetCounter + 1'b1;
					end
						
				RESET_HIGH:
					if (resetCounter == (1 << 8)) begin
						state <= INIT;
						resetCounter <= 1'b0;
					end else begin
						screenRst <= 1;
						resetCounter <= resetCounter + 1'b1;
					end
				
				INIT: begin
					INIT_CS <= 1'b1;
					state <= ACK_INIT;
				end
				
				ACK_INIT:
					if (!INIT_ACK)
						state <= ACK_COMMAND;
					else
						INIT_CS <= 1'b0;
				
				WAIT_COMMAND: begin
					DRAW_CS <= 1'b1;
					state <= ACK_COMMAND;
				end
				
				ACK_COMMAND: begin
					DRAW_CS <= 1'b0;
					if (!DRAW_ACK) begin
						CTRL_CS <= 1'b1;
						state <= RUN_MODE;
						GPU_ACK <= 1'b0;
					end
				end
				
				RUN_MODE:
					GPU_ACK <= 1'b1;
			endcase
		end
		
		always_comb begin
			SCREEN[13:4] = INIT_WIRES[13:4];
			if (state == WAIT_COMMAND || state == ACK_COMMAND || state == RUN_MODE)
				SCREEN[13:4] = DRAW_WIRES[13:4];
		end
		
		assign commandAck = CTRL_ACK;
	
endmodule
