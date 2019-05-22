const integer a=2<<2; // alpha parameter, number of bytes per block (in bytes)
const integer n=2<<8; // overall size of the memory (in bytes)
const integer d=6; // binary tree depth log(n/a), also represent the number of bits needed to describe block number
const integer K=3; // number of tuples per bucket (per node)

package oram_function_package;

function memory_val fetch(input [d-1:0] block_number);
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

function memory_tuple update_position_map(input [d-1:0] block_number, input memory_val block_val);
	memory_tuple new_block_tuple; // create new tuple
	new_block_tuple.b_val = block_val; // assign block val (return value from oread_fetch)
	new_block_tuple.b_pos.pos = $urandom_range((2<<(d-1))-1,0); // assign block_number to a new random leaf
	new_block_tuple.b_pos.empty_n = 1; // mark the assignment valid
	new_block_tuple.b_number = block_number; // assign block number
	new_block_tuple.empty_n = 1; // mark the assignment valid
	
	return new_block_tuple;
	
endfunction

function void put_back(memory_tuple new_block_tuple);
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
	
	return;
	
endfunction

// this task pushes one node (in level depth) one level lower down the tree with respect to pos
task push_down_one_node_one_level;
	input [d-2:0] pos; // indicates where to go
	input depth; // indicates which node try to push
	bit current_bit;
	bit [d-1:0] current_block_number = 1; // remember the 1 offset
	integer i;
	integer j;
	integer k;
	
	// get to the node which we try to push
	for (i=0; i< (depth - 1); i=i+1) begin
		current_bit = pos[i]; // get current bit from pos
		current_block_number = current_block_number<<1 + current_bit; // advance down the tree
	end
	
	memory_bucket higher_bucket = oram.oram_tree[current_block_number - 1]; // bucket which contains the tuples from the up level which want to be pushed down
	current_block_number = current_block_number<<1 + pos[i]; // go down the tree one bit 
	memory_bucket lower_bucket = oram.oram_tree[current_block_number - 1]; // bucket which contains the tuples from the down level
	memory_tuple current_tuple;
	memory_tuple current_lower_tuple;
	
	for (j=0; j< (K-1); j=j+1) begin // go over higher bucket
		current_higher_tuple = higher_bucket[j]; // for each tuple in bucket
		if (not (current_higher_tuple.empty_n and current_higher_tuple.b_pos.empty_n))  begin
			continue;
		end else if (current_higher_tuple.empty_n and current_higher_tuple.b_pos.empty_n and current_higher_tuple.b_pos.pos[depth - 1] != pos[depth - 1]) begin
			continue;
		end else begin // tuple's pos still in path, try to push it down one level
			for (k=0; k< (K-1); k=k+1) begin // go over lower bucket
				current_lower_tuple = lower_bucket[k]; // for each tuple in bucket
				if not (current_lower_tuple.empty_n and current_lower_tuple.b_pos.empty_n) begin // if it is empty
					lower_bucket[k] = current_higher_tuple; // push the higher tuple down to the empty spot
					current_higher_tuple.empty_n = 0; 
					higher_bucket[j] = current_higher_tuple; // assign it as invalid in higher bucket
					break;
				end
			end
		end
	end
	oram.oram_tree[current_block_number - 1] = lower_bucket; // update oram lower node
	current_block_number = (current_block_number - pos[i])>>1; // go back up the tree
	oram.oram_tree[current_block_number - 1] = higher_bucket; // update oram higher node
	
endtask

task flush;

	bit [d-2:0] pos_star = $urandom_range((2<<(d-1))-1,0); // choose a random leaf
	integer i;
	integer j;
	for (i=d-1; i>0; i=i-1) begin // start from the depth of leafs - 1 and go up
		for (j=i; i<d; j=j+1) begin // try to push down the ith level node down to the leaf if possibole
			push_down_one_node_one_level(pos_star, j); // push down iteration
		end
	end
	
endtask

endpackage : oram_function_package