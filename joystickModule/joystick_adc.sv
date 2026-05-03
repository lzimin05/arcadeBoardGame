`timescale 1ns / 1ps

module joystick_adc (
    input logic         	   CLOCK_50,
    input logic         	   RESET,
   //output logic [7:0]  LED,
    output logic    		   ADC_CS_N,
    output logic       		   ADC_SCLK,
	output logic       	 	   ADC_SADDR,
	input  logic         	   ADC_SDAT,
	output logic    [7:0]	   UP,
	output logic	[7:0]	   DOWN,
	output logic	[7:0]	   LEFT,
	output logic	[7:0]	   RIGHT
);

	// генерация клоков ~2 MHz с фазовым сдвигом
	logic [4:0] clk_div;
	logic sclk_2m, sclk_2m_n;
	
	always_ff @(posedge CLOCK_50 or negedge RESET) begin
		if (!RESET) begin 
			clk_div   <= 5'd0;
			sclk_2m   <= 1'b1; 
			sclk_2m_n <= 1'b0; 
		end
		else if (clk_div == 5'd12) begin 
			clk_div   <=  5'd0; 
			sclk_2m   <= ~sclk_2m; 
			sclk_2m_n <= ~sclk_2m_n; 
		end
		else clk_div <= clk_div + 1'b1;
	end
	
	assign ADC_CS_N  = ~RESET;
    assign ADC_SCLK  = sclk_2m;
    assign ADC_SADDR = din_bit;

	 
    logic [3:0]  cnt, m_cont;
    logic [11:0] adc_buf;
	 
	logic [11:0] vr_x, vr_y;
	logic [7:0]  up, down, left, right;

    logic din_bit;

    // раздельные флаги для команды и данных
    logic ch_cmd;   // канал для следующей команды (отправляем на DIN)
    logic ch_data;  // канал для текущих данных (принимаем с DOUT)

    // счётчик битов фрейма
    always_ff @(posedge sclk_2m or negedge RESET) begin
        if (!RESET) 	cnt <= 4'd0;
        else			cnt <= cnt + 1'b1;
    end

    // зеркальный счётчик для чтения
    always_ff @(posedge sclk_2m_n or negedge RESET) begin
        if (!RESET) 	m_cont <= 4'd0;
        else 			m_cont <= cnt;
    end

    // переключение канала для команды (после полного фрейма)
    always_ff @(posedge sclk_2m or negedge RESET) begin
        if 		 (!RESET) 		 ch_cmd <= 1'b0;     // начинаем с IN0 (канал 0)
        else if (cnt == 4'd15) ch_cmd <= ~ch_cmd;  // переключаем для следующей конвертации
    end

    // Формирование DIN: биты [5:3] = ADD2 ADD1 ADD0
    // IN0: 000, IN1: 001
    always_ff @(posedge sclk_2m_n or negedge RESET) begin
        if (!RESET)  din_bit <= 1'b0;
        else unique case (cnt)
            4'd2:    din_bit <= 1'b0;
            4'd3:    din_bit <= 1'b0;
            4'd4:    din_bit <= ch_cmd;
            default: din_bit <= 1'b0;
        endcase
    end

    // приём DOUT
    always @(posedge sclk_2m or negedge RESET) begin
        if (!RESET) begin
            adc_buf <= 12'd0;
            vr_x 	  <= 12'd0;
            vr_y    <= 12'd0;
            ch_data <= 1'b0;
        end else begin
            unique case (m_cont)
                4'd4:  adc_buf[11] <= ADC_SDAT;
                4'd5:  adc_buf[10] <= ADC_SDAT;
                4'd6:  adc_buf[9]  <= ADC_SDAT;
                4'd7:  adc_buf[8]  <= ADC_SDAT;
                4'd8:  adc_buf[7]  <= ADC_SDAT;
                4'd9:  adc_buf[6]  <= ADC_SDAT;
                4'd10: adc_buf[5]  <= ADC_SDAT;
                4'd11: adc_buf[4]  <= ADC_SDAT;
                4'd12: adc_buf[3]  <= ADC_SDAT;
                4'd13: adc_buf[2]  <= ADC_SDAT;
                4'd14: adc_buf[1]  <= ADC_SDAT;
                4'd15: adc_buf[0]  <= ADC_SDAT;
            endcase

            if (cnt == 4'd15) begin
                if (ch_data == 1'b0) begin
                    vr_x <= adc_buf[11:0];
						  if (vr_x > 12'h810) begin
								left  <= vr_x[10:3];
								right <= 8'b0;
						  end 
						  else if (~vr_x > 12'h810) begin
								right <= ~vr_x[10:3];
								left  <= 8'b0;
						  end 
						  else begin
								right <= 8'b0;
								left  <= 8'b0;
						  end
                end 
					 else begin
                    vr_y <= adc_buf[11:0];
						  if (vr_y > 12'h810) begin
								down <= vr_y[10:3];
								up   <= 8'b0;
						  end 
						  else if (~vr_y > 12'h810) begin
								up   <= ~vr_y[10:3];
								down <= 8'b0;
						  end 
						  else begin
								up   <= 8'b0;
								down <= 8'b0;
						  end
					 end

                ch_data <= ~ch_data;
            end
        end
    end
	 
	assign UP    = up;
	assign DOWN  = down;
	assign LEFT  = left;
	assign RIGHT = right;

endmodule