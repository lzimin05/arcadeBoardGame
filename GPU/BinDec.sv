module BinDec(
	input logic [9:0]in,
	output logic [11:0]out
);
	always_comb begin
		logic [5:0]out_1;
		logic [4:0]out_2;
		logic [3:0]out_3;
		
		out_1 = (in[0] ? 6'd1 : 6'd0) + (in[1] ? 6'd2 : 6'd0) + (in[2] ? 6'd4 : 6'd0) + (in[3] ? 6'd8 : 6'd0) + (in[4] ? 6'd6 : 6'd0) +
			(in[5] ? 6'd2 : 6'd0) + (in[6] ? 6'd4 : 6'd0) + (in[7] ? 6'd8 : 6'd0) + (in[8] ? 6'd6 : 6'd0) + (in[9] ? 6'd2 : 6'd0);
		
		out_2 = (in[4] ? 5'd1 : 5'd0) + (in[5] ? 5'd3 : 5'd0) + (in[6] ? 5'd6 : 5'd0) + (in[7] ? 5'd2 : 5'd0) + (in[8] ? 5'd5 : 5'd0) + 
			(in[9] ? 5'd1 : 5'd0);
			
		out_3 = (in[7] ? 4'd1 : 4'd0) + (in[8] ? 4'd2 : 4'd0) + (in[9] ? 4'd5 : 4'd0);
		
		out_2 += out_1 >= 6'd40
			? 5'd4
			: (
				out_1 >= 6'd30
					? 5'd3
					: (
						out_1 >= 6'd20
							? 5'd2
							: (
								out_1 >= 5'd10
									? 5'd1
									: 5'd0
							)
					)
			);
		
		out_1 = out_1 >= 6'd40
			? (out_1 - 6'd40)
			: (
				out_1 >= 6'd30
					? (out_1 - 6'd30)
					: (
						out_1 >= 6'd20
							? (out_1 - 6'd20)
							: (
								out_1 >= 6'd10
									? (out_1 - 6'd10)
									: out_1
							)
					)
			);
			
		out_3 += out_2 >= 5'd10 ? 4'd1 : 4'd0;
		
		out_2 = out_2 >= 5'd10 ? (out_2 - 5'd10) : out_2;
		
		out = { out_3, out_2[3:0], out_1[3:0] };
	end
endmodule