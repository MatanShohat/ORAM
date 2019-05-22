const integer a=2<<2; // alpha parameter, number of bytes per block (in bytes)
const integer n=2<<8; // overall size of the memory (in bytes)
const integer d=6; // binary tree depth log(n/a), also represent the number of bits needed to describe block number
const integer K=3; // number of tuples per bucket (per node)

import oram_function_package::*;

module oram_module(
	input [d-1:0] rw_block_number, // in both read and write operations, this input holds the requested address (block number)
	input [(8*a)-1:0] w_value, // only in write operation, this input holds the value which will be written to block number rw_block_number
	input rw_indicator, // indicates wheter it is a read or write operation (rw_indicator=0 - read, rw_indicator=1 - write)
	input input_ready, // indicates there are valid inputs on the line
	input clk, // core's clock
	input rst, // reset signal, active high
	output [(8*a)-1:0] r_value, // only in read operation, this output holds the value of block number rw_block_number
	output output_ready); // indicates there are valid outputs on the line
	
	typedef struct memory_pos {
		bit [d-2:0] pos; // the bt leaf which the tuple is associated with (word) , d-1 bits are needed (effectivly only d-1 bit word is valid (e.g., 0*(fd-1) is valid))
		bit empty_n; // tells if pos is valid, active low ( empty_n=0 - pos is not valid, empty_n=1 - pos is valid)
	} memory_pos;
	
	typedef struct memory_val {
		byte [a-1:0] val; // value of the given block (a bytes)
		bit empty_n; // tells if val is valid, active low ( empty_n=0 - val is not valid, empty_n=1 - val is valid)
	} memory_val;
	
	typedef struct memory_tuple {
		memory_pos b_pos;
		bit [d-1:0] b_number; // the block number containing the word val (word), d bits are needed
		memory_val b_val;
		bit empty_n; // tells if the tuple is valid, active low ( empty_n=0 - block is empty, empty_n=1 - block is full)
	} memory_tuple;

	typedef struct memory_bucket {
		memory_tuple bucket [K-1:0];	
	} memory_bucket;

	typedef struct oram_struct {
		memory_bucket oram_tree [(2<<d)-1:0]; // defining the binary tree holding the memory
		memory_pos pos_map [(2<<d)-1:0]; // position map, block number x pos
	} oram_struct;

	initial begin
		oram_struct oram; // defining the oram
		$display ("oram module has been successfully created");
	end
	
	always@(posedge clk iff (input_ready == 1 and rst == 0) or posedge rst) begin // enter only in posedge clk only if input is ready, asynchronous rst signal
		if (rst) begin // reset output signals
			r_value <= 0;
			output_ready <= 0;
		end else begin // input is ready, do operation
			if (rw_indicator == 0) begin // oread operation
				$display ("performing read operation on block number %h (hexadecimal)", rw_block_number);
				// implement oread
			end else begin // owrite operation
				$display ("performing write operation on block number %h (hexadecimal) with value %h (hexadecimal)", rw_block_number, w_value);
				// implement owrite
			end
		end
		
	end

endmodule