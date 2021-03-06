`timescale 1ns/10ps
package oram_functions_pkg;
	//Constants decleration
	parameter BYTE_WIDTH = 8;
	parameter BYTES_PER_BLOCK=1<<2; // alpha parameter, number of bytes per block (in bytes)
	parameter MEMORY_SIZE=1<<16; // n parameter, overall size of the memory (in bytes)
	parameter TREE_DEPTH=$clog2(MEMORY_SIZE/BYTES_PER_BLOCK); // binary tree depth log(MEMORY_SIZE/BYTES_PER_BLOCK), also represent the number of bits needed to describe block number
	parameter K=3; // number of tuples per bucket (per node)

	//TypeDefs declaration
	typedef struct {
		logic [TREE_DEPTH-2:0] pos; // the bt leaf which the tuple is associated with (word) , TREE_DEPTH-1 bits are needed (effectivly only TREE_DEPTH-1 bit word is valid (e.g., 0*(fd-1) is valid))
		bit empty_n; // tells if pos is valid, active low ( empty_n=0 - pos is not valid, empty_n=1 - pos is valid)
	} memory_pos;

	typedef struct {
		bit [(BYTE_WIDTH*BYTES_PER_BLOCK)-1:0] val; // value of the given block (a bytes)
		bit empty_n; // tells if val is valid, active low ( empty_n=0 - val is not valid, empty_n=1 - val is valid)
	} memory_val;

	typedef struct {
		memory_pos b_pos;
		bit [TREE_DEPTH-1:0] b_number; // the block number containing the word val (word), TREE_DEPTH bits are needed
		memory_val b_val;
		bit empty_n; // tells if the tuple is valid, active low ( empty_n=0 - block is empty, empty_n=1 - block is full)
	} memory_tuple;

    typedef struct {
		memory_tuple bucket [K-1:0];
	} memory_bucket;

    typedef struct {
		memory_bucket oram_tree [(1<<TREE_DEPTH)-1:0]; // defining the binary tree holding the memory
		memory_pos pos_map [(1<<TREE_DEPTH)-1:0]; // position map, block number x pos
	} oram_struct;

  function automatic void init_memory(ref oram_struct oram);
		foreach(oram.pos_map[i]) begin
			oram.pos_map[i].pos = '0;
			oram.pos_map[i].empty_n = '0;
		end
		foreach(oram.oram_tree[i]) begin
			foreach(oram.oram_tree[i].bucket[j]) begin
				oram.oram_tree[i].bucket[j].b_pos.pos = '0;
				oram.oram_tree[i].bucket[j].b_pos.empty_n = '0;
				oram.oram_tree[i].bucket[j].b_number = '0;
				oram.oram_tree[i].bucket[j].b_val.val = '0;
				oram.oram_tree[i].bucket[j].b_val.empty_n = '0;
				oram.oram_tree[i].bucket[j].empty_n = '0;
			end
		end
	endfunction

	function automatic memory_val fetch(ref oram_struct oram, input [TREE_DEPTH-1:0] block_number);
		memory_val r_value;
		memory_pos b_pos;
		bit current_bit;
		bit [TREE_DEPTH-1:0] current_bucket_number;
		memory_bucket current_bucket;
		memory_tuple current_tuple;
		integer i;
		integer j;

		//$display("Fetch start with block number %p", block_number);
		b_pos = oram.pos_map[block_number]; // get pos of input block

		if (b_pos.empty_n == 0) begin // if block is not assigned to pos map
			//$display("pos is empty");
			b_pos.pos = $urandom_range((2<<(TREE_DEPTH-1))-1,0); // assign it to random leaf
			b_pos.empty_n = 1; // mark the assignment valid
			oram.pos_map[block_number] = b_pos; // write back to the oram data structure
		end

		current_bucket_number = 1; // remember the 1 offset
		current_bucket = oram.oram_tree[current_bucket_number - 1]; // check if root contains the required block

		for (j=0; j < K; j=j+1) begin // go over root bucket
			//$display("Going over the root bucket");
			current_tuple = current_bucket.bucket[j]; // for each tuple in bucket
			if (current_tuple.empty_n && current_tuple.b_pos.empty_n && current_tuple.b_pos.pos == b_pos.pos && current_tuple.b_number == block_number ) begin // if given tuple matches requested block number and block pos
				r_value = current_tuple.b_val; // return its value
				oram.oram_tree[current_bucket_number - 1].bucket[j].empty_n = 0; // remove the tuple
			end
		end

		for (i=0; i< (TREE_DEPTH-1); i=i+1) begin
			//$display("Search the tree");
			current_bit = b_pos.pos[i]; // get current bit from pos
			current_bucket_number = 2*current_bucket_number + current_bit; // advance down the tree
			current_bucket = oram.oram_tree[current_bucket_number - 1]; // get matched tree node
			for (int j=0; j< K; j=j+1) begin // go over current_bucket bucket
				current_tuple = current_bucket.bucket[j]; // for each tuple in bucket
				if (current_tuple.empty_n && current_tuple.b_pos.empty_n && current_tuple.b_pos.pos == b_pos.pos && current_tuple.b_number == block_number ) begin // if given tuple matches requested block number and block pos
					r_value = current_tuple.b_val; // return its value
					oram.oram_tree[current_bucket_number - 1].bucket[j].empty_n = 0; // remove the tuple
					//$display("removed block number %p", block_number);
				end
			end
		end
		//$display("Fetch is done");
		return r_value;

	endfunction

	function memory_tuple update_position_map(input [TREE_DEPTH-1:0] block_number, input memory_val block_val);
		memory_tuple new_block_tuple; // create new tuple
		//$display("update_position_map Start");
		new_block_tuple.b_val = block_val; // assign block val (return value from oread_fetch)
		new_block_tuple.b_pos.pos = $urandom_range((1<<(TREE_DEPTH-1))-1,0); // assign block_number to a new random leaf
		//$display("new pos: %d, to block: %p", new_block_tuple.b_pos.pos, block_number);
		new_block_tuple.b_pos.empty_n = 1; // mark the assignment valid
		new_block_tuple.b_number = block_number; // assign block number
		new_block_tuple.empty_n = 1; // mark the assignment valid
		//$display("update_position_map End");
		return new_block_tuple;
	endfunction

	function automatic void put_back(ref oram_struct oram, input memory_tuple new_block_tuple);
		memory_tuple current_tuple;
		integer j;
		//$display("put_back Start");
	
		for (j=0; j<K; j=j+1) begin // go over bucket
			//$display("go over the bucket in spot %d", j);
			current_tuple = oram.oram_tree[0].bucket[j]; // for each tuple in bucket
			if (current_tuple.empty_n == 0) begin // if empty tuple was found
				oram.oram_tree[0].bucket[j] = new_block_tuple; // insert the new tuple to tree
				oram.pos_map[new_block_tuple.b_number] = new_block_tuple.b_pos; //insert to pos map

				//$display("put_back End");
				return;
			end
		end
		$display ("overflow");
		//print_oram(oram);
		$stop;
		return;
	endfunction

	task automatic print_oram;
        ref oram_struct oram;
		integer i;
		// print the memoet map
		$display("memory map:");
		for (i=0 ; i< (1<<TREE_DEPTH)-1 ; i++) begin
			if (oram.pos_map[i].empty_n == 0) begin
				$write("X ");
			end else begin
				$write("%d ", oram.pos_map[i].pos);
			end
		end

		// print the tree
		$display("");
		$display("oram_tree:");
		print_oram_tree(oram,1);
	endtask

	task automatic print_oram_tree;
		ref oram_struct oram;
		input integer node;
		integer i;
		//check we are not done yet
		if(node > 1<<TREE_DEPTH ) begin
			$display("");
			return;
		end
		if (node == 2 || node == 4 || node == 8 || node == 16 || node == 32) begin
			$display("");
        end
        //$display("The bucket in the %d node",node);
		// print the bucket
		$write("|");
        for (i = 0; i<K; i++) begin
			//if (node == 1)
			//	$display("aaaaa: %d", oram.oram_tree[node-1].bucket[i].empty_n);
			if (oram.oram_tree[node-1].bucket[i].empty_n == 0) begin
				$write("X ");
            end else begin
				$write("(%p,%p,%p) ",oram.oram_tree[node-1].bucket[i].b_pos.pos,oram.oram_tree[node-1].bucket[i].b_number,oram.oram_tree[node-1].bucket[i].b_val.val);
			end
		end
		$write("|");
		//left
		print_oram_tree(oram,node+1);
		//right
		//print_oram_tree(oram,node*2+1);
	endtask

	// this task pushes one node (in level depth) one level lower down the tree with respect to pos
	task automatic push_down_one_node_one_level;
		ref oram_struct oram; //
		input [TREE_DEPTH-2:0] pos; // indicates where to go
		input integer depth; // indicates which node try to push
		bit current_bit;
		bit [TREE_DEPTH-1:0] current_bucket_number;
		integer i;
		integer j;
		integer kk;

		memory_bucket higher_bucket;
		memory_bucket lower_bucket;
		memory_tuple current_tuple;
		memory_tuple current_lower_tuple;
		memory_tuple current_higher_tuple;


		current_bucket_number = 1; // remember the 1 offset

		//$display("Leaf Push_Down Start");

		// get to the node which we try to push
		for (i=0; i < (depth - 1); i=i+1) begin
			//$display("de|");
			//$display("Depth: %d. Find The node Iter: %d", depth, i);
			current_bit = pos[i]; // get current bit from pos
			current_bucket_number = current_bucket_number<<1; // advance down the tree
			current_bucket_number[0] = current_bit; // advance down the tree
		end
		//$display("Found");

		higher_bucket = oram.oram_tree[current_bucket_number - 1]; // bucket which contains the tuples from the up level which want to be pushed down
		current_bit = pos[depth - 1]; // get current bit from pos
		current_bucket_number = current_bucket_number<<1; // advance down the tree
		current_bucket_number[0] = current_bit; // advance down the tree
		lower_bucket = oram.oram_tree[current_bucket_number - 1]; // bucket which contains the tuples from the down level

		for (j=0; j< K; j=j+1) begin // go over higher bucket
			//$display("Go over higher buckets");
			current_higher_tuple = higher_bucket.bucket[j]; // for each tuple in bucket
			if (current_higher_tuple.empty_n == 0)  begin
				continue;
			end else if (current_higher_tuple.b_pos.pos[depth - 1] != pos[depth - 1]) begin
				continue;
			end else begin // tuple's pos still in path, try to push it down one level
				for (kk=0; kk< K; kk=kk+1) begin // go over lower bucket
					//$display("j = %d, k = %d",j,kk);
					current_lower_tuple = lower_bucket.bucket[kk]; // for each tuple in bucket
					if (current_lower_tuple.empty_n == 0) begin // if it is empty
						lower_bucket.bucket[kk] = current_higher_tuple; // push the higher tuple down to the empty spot
						current_higher_tuple.empty_n = 0;
						higher_bucket.bucket[j] = current_higher_tuple; // assign it as invalid in higher bucket
						break;
					end
				end
			end
		end

		oram.oram_tree[current_bucket_number - 1] = lower_bucket; // update oram lower node
		current_bucket_number = current_bucket_number>>1; // go back up the tree
		oram.oram_tree[current_bucket_number - 1] = higher_bucket; // update oram higher node
		//$display("Leaf Push_Down End");
	endtask

	task automatic flush;
		ref oram_struct oram;
		bit [TREE_DEPTH-2:0] pos_star;
		integer i;
		integer j;
		//$display("Flush Start");
		pos_star = $urandom_range((1<<(TREE_DEPTH-1))-1,0); // choose a random leaf
		$display("Flush Begin with Pos: %d",pos_star);
		for (i=TREE_DEPTH-1; i>0; i=i-1) begin // start from the depth of leafs - 1 and go up
			for (j=i; j<TREE_DEPTH; j=j+1) begin // try to push down the ith level node down to the leaf if possibole
				//$display("FLUSH iter: TREE_DEPTH=%d, i= %d, j= %d",TREE_DEPTH,i,j);
				push_down_one_node_one_level(oram, pos_star, j); // push down iteration
			end
		end
		//$display("Flush End");

	endtask

endpackage
