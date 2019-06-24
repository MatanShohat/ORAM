`timescale 1ns/10ps

module oram_driver #(
    parameter INIT_FILE = "mem.hex",
    parameter ADDRESS_WIDTH = 12, // n= 1 << ADDRESS_WIDTH
    parameter BYTE_WIDTH = 8,
    parameter BYTES_PER_WORD = 4, // BYTES_PER_WORD
    parameter BYTES_PER_BLOCK = BYTES_PER_WORD
)(
    input logic clock,
    input logic reset,

    input logic  [ADDRESS_WIDTH-1:0]                  avs_a_address,
    input logic  [BYTES_PER_WORD-1:0]                 avs_a_byteenable,
    input logic                                       avs_a_read,
    output logic [BYTES_PER_WORD-1:0][BYTE_WIDTH-1:0] avs_a_readdata,
    input logic                                       avs_a_write,
    input logic [BYTES_PER_WORD-1:0][BYTE_WIDTH-1:0] avs_a_writedata

);

  // model the RAM with an array of 2D arrays, each representing one word
	logic [d-1:0] rw_block_number;
	logic [(BYTE_WIDTH*BYTES_PER_WORD)-1:0] w_value;
	logic rw_indicator;
	logic input_ready;
	logic clk;
	logic rst;
	logic [(BYTE_WIDTH*BYTES_PER_WORD)-1:0] r_value;
	logic output_ready;

	logic [BYTES_PER_WORD-1:0][BYTE_WIDTH-1:0] memory [1 << ADDRESS_WIDTH];
	initial $readmemh(INIT_FILE, memory);

  assign clk = clock;
  assign rst = reset;
  assign rw_indicator = avs_a_write;
  assign input_ready = avs_a_read | avs_a_write;




endmodule
