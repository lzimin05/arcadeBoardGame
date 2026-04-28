module SPI #(
	parameter DT = 255,
	parameter DEF = 128,
	parameter CLK = 127
)(
	input logic in_clk,
	input logic rst,
	input logic mode,
	input logic en,
	input logic [7:0]value,
	
	output logic clk,
	output logic ack,
	output logic ce,
	output logic dc,
	output logic din
);
	assign dc = mode;

	logic enabled;
	logic [7:0]cnt;
	logic [2:0]bitIndex;
	logic [7:0]data;
	
	logic [9:0]timer;
	logic timerEnabled;
	
	always_ff@(posedge in_clk) begin
		if (rst) begin
			cnt <= DEF;
			clk <= 1'b1;
		end else begin
			if ((cnt & CLK) == CLK)
				clk <= enabled ? (cnt == DT ? 1'b0 : 1'b1) : 1'b1;
				
			if (!enabled && cnt == DEF) begin
				cnt <= DEF;
			end else
				cnt <= cnt == DT ? 1'b0 : (cnt + 1'b1);
		end
	end
	
	always_ff@(posedge in_clk) begin
		if (rst) begin
			enabled <= 1'b0;
			ce <= 1'b1;
			bitIndex <= 1'b0;
			timer <= 0;
			timerEnabled <= 1'b0;
		end else begin
			if (!en) begin
				enabled <= 1;
				data <= value;
				bitIndex <= 1'b0;
				ce <= 1'b0;
			end else 
				ce <= ((enabled || cnt != CLK) && ce == 1'b0) ? 1'b0 : 1'b1;
			
			if (enabled && cnt == DT) begin
				din <= data[3'b111 - bitIndex];
				bitIndex <= bitIndex + 1'b1;
				enabled <= bitIndex == 7 ? 1'b0 : 1'b1;
			end
			
			if (!enabled && cnt == CLK) begin
				timerEnabled <= 1'b1;
				timer <= 0;
			end else begin
				if (timerEnabled)
					timer += 1'b1;
				if (timer == (1 << 9) && timerEnabled) begin
					timerEnabled <= 1'b0;
					ack <= 1'b0;
				end else
					ack <= 1'b1;
			end
		end
	end
endmodule