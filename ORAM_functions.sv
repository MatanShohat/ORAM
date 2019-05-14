const integer a=2<<2; // alpha parameter, number of bytes per block (in bytes)
const integer n=2<<8; // overall size of the memory (in bytes)
const integer d=6; // binary tree depth log(n/a), also represent the number of bits needed to describe block number
const integer K=3; // number of tuples per bucket (per node)

function memory_val oread_fetch(input [d-1:0] block_number);
	memory_val r_value;
	memory_pos b_pos = oram.pos_map[block_number]; // get pos of input block
	
	if (b_pos.empty_n == 0) begin // if block is not assigned to pos map
		b_pos.pos = $urandom_range((2<<(d-1))-1,0); // assign it to random leaf
		b_pos.empty_n = 1; // mark the assignment valid
		oram.pos_map[block_number] = b_pos; // write back to the oram data structure
	end
	
	integer i;
	integer j;
	bit current_bit;
	bit [d-1:0] current_block_number = 1; // remember the 1 offset
	
	memory_bucket current_bucket = oram.oram_tree[current_block_number - 1]; // check if root contains the required block
	memory_tuple current_tuple;
	for (j=0; j< (K-1); j=j+1) begin // go over root bucket
		current_tuple = current_bucket[j]; // for each tuple in bucket
		if (current_tuple.empty_n and current_tuple.b_pos.empty_n and current_tuple.b_pos.pos == b_pos.pos and current_tuple.b_number == block_number ) begin // if given tuple matches requested block number and block pos
			r_value = current_tuple.b_val; // return its value
			current_tuple.empty_n = 0; // remove the tuple
		end
	end
	
	for (i=0; i< (d-1); i=i+1) begin
		current_bit = b_pos.pos[i]; // get current bit from pos
		current_block_number = 2*current_block_number + current_bit; // advance down the tree
		current_bucket = oram.oram_tree[current_block_number - 1]; // get matched tree node
		for (j=0; j< (K-1); j=j+1) begin // go over current_bucket bucket
			current_tuple = current_bucket[j]; // for each tuple in bucket
			if (current_tuple.empty_n and current_tuple.b_pos.empty_n and current_tuple.b_pos.pos == b_pos.pos and current_tuple.b_number == block_number ) begin // if given tuple matches requested block number and block pos
				r_value = current_tuple.b_val; // return its value
				current_tuple.empty_n = 0; // remove the tuple
		end
	end
	
	return r_value;

endfunction

function memory_tuple oread_update_position_map(input [d-1:0] block_number, input memory_val block_val);
	memory_tuple new_block_tuple; // create new tuple
	new_block_tuple.b_val = block_val; // assign block val (return value from oread_fetch)
	new_block_tuple.b_pos.pos = $urandom_range((2<<(d-1))-1,0); // assign block_number to a new random leaf
	new_block_tuple.b_pos.empty_n = 1; // mark the assignment valid
	new_block_tuple.b_number = block_number; // assign block number
	new_block_tuple.empty_n = 1; // mark the assignment valid
	
	return new_block_tuple;
	
endfunction

function void oread_put_back(memory_tuple new_block_tuple);
	memory_bucket current_bucket = oram.oram_tree[0] // get root bucket
	memory_tuple current_tuple;
	for (j=0; j< (K-1); j=j+1) begin // go over bucket
		current_tuple = current_bucket[j]; // for each tuple in bucket
		if (current_tuple.empty_n == 0) begin // if empty tuple was found
			current_bucket[j] = new_block_tuple; // insert the new tuple
			return;
		end
	end
	
	$display ("overflow");
	
endfunction