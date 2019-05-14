const integer a=2<<2; // alpha parameter, number of bytes per block (in bytes)
const integer n=2<<8; // overall size of the memory (in bytes)
const integer d=6; // binary tree depth log(n/a), also represent the number of bits needed to describe block number
const integer K=3; // number of tuples per bucket (per node)

function [(8*a)-1:0] oread(input [d-1:0] block_number);
	memory_pos b_pos = oram.pos_map[block_number]; // get pos of input block
	if (b_pos.empty_n == 0) begin
		b_pos.pos = $urandom_range(d-2,0); // if block_number is not in pos map assign it to random leaf
	end



endfunction

function [(8*a)-1:0] owrite(input [d-1:0] block_number, input [(8*a)-1:0] w_value);




endfunction