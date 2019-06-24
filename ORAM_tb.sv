`timescale 1ns/10ps
import oramPkg::*;

module oram_tb;
	timeunit 1ns;

	logic clk = 0;
	logic [(BYTE_WIDTH*BYTES_PER_BLOCK)-1:0] read_val;
	logic [(BYTE_WIDTH*BYTES_PER_BLOCK)-1:0] write_val;
	logic output_ready;
	logic rst, rw_indicator, input_ready;
	logic [TREE_DEPTH-1:0] block_num;
	logic pass;
	


	oram_module oram(
	block_num,
	write_val,
	rw_indicator,
	input_ready,
	clk,
	rst,
	read_val,
	output_ready);	

	// Clock generator
	always
	begin
		#5 clk = 1;
		#5 clk = 0;
	end
	

	// Test stimulus
	initial
	begin
		$display ("Start test");
		rst = 1;
		#50;
		rst = 0;
		// write process
		rw_indicator = 1;
		//for(int i=0;i<(1<<TREE_DEPTH);i++) begin
			write_val = 2;
			block_num = 1;
			input_ready = 1;
			wait (output_ready == 1'b1);
            rst = 1;
			#10;
			rst = 0;
        	rw_indicator = 1;
			write_val = 10;
			block_num = 3;
			input_ready = 1;
			wait (output_ready == 1'b1);
		//end
        
		#5
		// read process
		rw_indicator = 0;
		pass = 1;
		//for(int i=0;i<(1<<TREE_DEPTH);i++) begin
			block_num = 1;
			rst = 1;
			#10;
			rst = 0;
			#10
			wait (output_ready == 1'b1);
			if ( read_val != 2 )
				pass = 0;
		//end
        #5;
		$display ("Test done");
        $stop;
		#100;
		
	end

endmodule

