import oramPkg::*;

module oram_module(
	input [d-1:0] rw_block_number, // in both read and write operations, this input holds the requested address (block number)
	input [(8*a)-1:0] w_value, // only in write operation, this input holds the value which will be written to block number rw_block_number
	input rw_indicator, // indicates wheter it is a read or write operation (rw_indicator=0 - read, rw_indicator=1 - write)
	input input_ready, // indicates there are valid inputs on the line
	input clk, // core's clock
	input rst, // reset signal, active high
	output logic [(8*a)-1:0] r_value, // only in read operation, this output holds the value of block number rw_block_number
	output logic output_ready); // indicates there are valid outputs on the line

	//wire read_value;
	oram_struct oram;
	memory_val read_val;
	memory_tuple new_tuple;

	initial begin
		init_memory(oram);
		$display ("oram module has been successfully created");
	end

	always@(posedge clk iff (input_ready == 1 && rst == 0) or posedge rst) begin // enter only in posedge clk only if input is ready, asynchronous rst signal

		if (rst) begin // reset output signals
			r_value <= 0;
			output_ready <= 0;
		end else begin // input is ready, do operation
      output_ready <= 0;
			if (rw_indicator == 0) begin // oread operation
				$display ("performing read operation on block number %h (hexadecimal)", rw_block_number);
				read_val = fetch(oram, rw_block_number);
				new_tuple = update_position_map(rw_block_number, read_val);
				put_back(oram, new_tuple);
				flush(oram);
                r_value <= read_val.val;
                output_ready <= 1;
			end else begin // owrite operation
				$display ("performing write operation on block number %h (hexadecimal) with value %h (hexadecimal)", rw_block_number, w_value);
				read_val = fetch(oram, rw_block_number);
				read_val.val = w_value;
				new_tuple = update_position_map(rw_block_number, read_val);
				put_back(oram, new_tuple);
				flush(oram);
                output_ready <= 1;
                $display ("performing write operation on block number %h (hexadecimal) with value %h (hexadecimal) is DONE!", rw_block_number, w_value);
			end

		end

	end

endmodule
