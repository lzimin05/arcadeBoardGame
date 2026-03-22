module clkDelay #(
	parameter WIDTH = 8 //кол-во бит для счетчика
)(
	input logic clk,
	input logic rst,
	input logic [WIDTH-1:0] threshold, //порог срабатывания
	output logic clk_delay
);
	var logic [WIDTH-1:0] counter = 0;
	
	always_ff @(posedge clk or posedge rst) begin
		if(rst) begin
			counter <= 0;
			clk_delay <= 0;
		end else begin
			if (counter >= threshold) begin
				counter <= 0;
				clk_delay <= 1; //импульс
			end else begin
				counter <= counter + 1;
				clk_delay <= 0;
			end
		end
	end 
endmodule