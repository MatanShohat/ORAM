import oramPkg::*;

module oram_tb;
	timeunit 1ns;

	reg clk = 0;
	reg [(8*a)-1:0] read_val;
	reg [(8*a)-1:0] write_val;
	reg output_ready;
	reg rst, rw_indicator, input_ready;
	reg [d-1:0] block_num;
	reg pass;
	


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
	
	
	/*
	initial begin

		
	end
	*/
	

  	// Test stimulus
	initial
	begin
		$display ("Start test");
		rst = 1;
		#50;
		rst = 0;
		// write process
		rw_indicator = 1;
		//for(int i=0;i<2^d;i++) begin
			write_val = 2;
			block_num = 1;
			input_ready = 1;
			wait (output_ready == 1'b1);
            
		//end
        
        #5
		// read process
		rw_indicator = 0;
		pass = 1;
		//for(int i=0;i<2^d;i++) begin
			block_num = 1;
            rst = 1;
            #10;
            rst = 0;
            #10
			wait (output_ready == 1'b1);
			if ( read_val != 2 )
				pass = 0;
		//end
        
		$display ("Test done");
        #100;
        $stop;
	end

endmodule

