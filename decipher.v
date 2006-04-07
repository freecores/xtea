module decipher(clock, reset, data_in1, data_in2, key_in, data_out1, data_out2, all_done);

parameter s0 = 4'd0, s1 = 4'd1, s2 = 4'd2, s3 = 4'd3, s4 = 4'd4, s5 = 4'd5, s6 = 4'd6, s7 = 4'd7, s8 = 4'd8, s9 = 4'd9, s14 = 4'd14, s15 = 4'd15;

input clock, reset;
input[31:0] data_in1, data_in2;
input[127:0] key_in;
output[31:0] data_out1, data_out2;
output all_done;

wire clock, reset;
wire[31:0] data_in1, data_in2;
wire[127:0] key_in;
reg all_done, while_flag;
reg[1:0] selectslice;
reg[3:0] state;
reg[7:0] x;
reg[31:0] data_out1, data_out2, sum, workunit1, workunit2, delta;

always @(posedge clock or posedge reset)
begin
	if (reset)
		state = s0;
	else begin
		case (state)
			s0: state = s1;
			s1: state = s2;
			s2: state = s15;
			s15: state = while_flag ? s3 : s14;
			s3: state = s4;
			s4: state = s5;
			s5: state = s6;
			s6: state = s7;
			s7: state = s2;
			s14: state = s8;
			s8: state = s9;
			s9: state = s9;
			default: state = 4'bxxxx;
		endcase
	end
end

always @(posedge clock or posedge reset)
begin
	if (reset) begin
		data_out1 = 32'h00000000;
		data_out2 = 32'h00000000;
		x = 8'b00000000;
		sum = 32'h00000000;
		while_flag = 1'b0;
		workunit1 = 32'h00000000;
		workunit2 = 32'h00000000;
		selectslice = 1'b0;
		all_done = 1'b0;
		delta = 32'h00000000;
	end
	else begin
		case (state)
			s1: begin
			    workunit1 = data_in1;
			    workunit2 = data_in2;
			    delta = 32'h9E3779B9;
			    sum = 32'hc6ef3720;
			    end
			s2: if (x < 8'd32) while_flag = 1'b1; else while_flag = 1'b0;
			s15: begin
			    //do nothing
			    end
			s3: selectslice = (sum >> 32'd11 & 32'd3);
			s4: case (selectslice)
				2'b00: workunit2 = workunit2 - (((workunit1 << 4 ^ workunit1 >> 5) + workunit1) ^ (sum + key_in[127:96]));
				2'b01: workunit2 = workunit2 - (((workunit1 << 4 ^ workunit1 >> 5) + workunit1) ^ (sum + key_in[95:64]));
				2'b10: workunit2 = workunit2 - (((workunit1 << 4 ^ workunit1 >> 5) + workunit1) ^ (sum + key_in[63:32]));
				2'b11: workunit2 = workunit2 - (((workunit1 << 4 ^ workunit1 >> 5) + workunit1) ^ (sum + key_in[31:0]));
				default: workunit2 = 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
			    endcase
			s5: sum = sum - delta;
			s6: selectslice = (sum & 32'd3);
			s7: begin
			    case (selectslice)
				2'b00: workunit1 = workunit1 - (((workunit2 << 4 ^ workunit2 >> 5) + workunit2) ^ (sum + key_in[127:96]));
				2'b01: workunit1 = workunit1 - (((workunit2 << 4 ^ workunit2 >> 5) + workunit2) ^ (sum + key_in[95:64]));
				2'b10: workunit1 = workunit1 - (((workunit2 << 4 ^ workunit2 >> 5) + workunit2) ^ (sum + key_in[63:32]));
			  2'b11: workunit1 = workunit1 - (((workunit2 << 4 ^ workunit2 >> 5) + workunit2) ^ (sum + key_in[31:0]));
				default: workunit1 = 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
			    endcase
			    x = x + 1'b1;
			    end
			 s14: begin
			       //do nothing
			       end
			 s8: begin
			     data_out1 = workunit1;
			     data_out2 = workunit2;
			     end
			 s9: all_done = 1'b1;
			 default: begin
			     data_out1 = 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
			     data_out2 = 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
			     end
		 endcase
	end
end

endmodule