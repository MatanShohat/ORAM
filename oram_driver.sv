`timescale 1ns/10ps

module oram_driver #(
	parameter INIT_FILE = "mem.hex",
	parameter ADDRESS_WIDTH = 4, // EE: in words, see line 15
	parameter BYTE_WIDTH = 8,
	parameter BYTES_PER_WORD = 4,
	parameter BYTES_PER_BLOCK = BYTES_PER_WORD,
	parameter MEMORY_SIZE=1<<(ADDRESS_WIDTH+$clog2(BYTES_PER_WORD)), // n parameter, overall size of the memory (in bytes) 
	parameter TREE_DEPTH=$clog2(MEMORY_SIZE/BYTES_PER_BLOCK) // binary tree depth log(MEMORY_SIZE/BYTES_PER_BLOCK), also represent the number of bits needed to describe block number
)(
	input logic clock,
	input logic reset,

	input logic  [ADDRESS_WIDTH-1:0]                  avs_data_address, // EE: address in word quantas, e.g.: 0x0 (first word), 0x1 (second word) ...
	input logic  [BYTES_PER_WORD-1:0]                 avs_data_byteenable,
	input logic                                       avs_data_read,
	output logic [BYTES_PER_WORD-1:0][BYTE_WIDTH-1:0] avs_data_readdata,
	input logic                                       avs_data_write,
	input logic [BYTES_PER_WORD-1:0][BYTE_WIDTH-1:0]  avs_data_writedata

);
	genvar i;	
	logic [TREE_DEPTH-1:0] rw_block_number;
	logic [(BYTE_WIDTH*BYTES_PER_WORD)-1:0] w_value;
	logic rw_indicator;
	logic input_ready;
	logic clk;
	logic rst;
	logic [(BYTE_WIDTH*BYTES_PER_WORD)-1:0] r_value;
	logic output_ready;
	

	assign clk = clock;
	assign rst = reset;
	assign rw_indicator = avs_data_write;
	assign input_ready = avs_data_read | avs_data_write;
	assign rw_block_number = avs_data_address[ADDRESS_WIDTH-1 -: TREE_DEPTH];
	for (i=0; i<BYTES_PER_WORD; i=i+1) begin
		assign w_value[i*BYTE_WIDTH +: BYTE_WIDTH] = avs_data_writedata[i];
		assign avs_data_readdata[i] = r_value[i*BYTE_WIDTH +: BYTE_WIDTH];
	end	

	oram_module oram(.*);	

endmodule
