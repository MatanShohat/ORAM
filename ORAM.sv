const integer a=2<<2; // alpha parameter, number of bytes per block (in bytes)
const integer n=2<<8; // overall size of the memory (in bytes)
const integer d=6; // binary tree depth log(n/a), also represent the number of bits needed to describe block number
const integer K=3; // number of tuples per bucket (per node)

module oram_module(
	input [d:0] address, ;
	

	typedef struct memory_tuple {
		bit [d-2:0] pos; // the bt leaf which the tuple is associated with (word) , d-1 bits are needed (effectivly only d-1 bit word is valid (e.g., 0*(fd-1) is valid))
		bit [d-1:0] b; // the block number containing the word val (word), d bits are needed
		byte [4*a-1:0] val; // value of the give block (a words)
		bit empty_n; // tells if the tuple is valid, active low ( empty_n=0 - block is empty, empty_n=1 - block is full)
	} memory_tuple;

	typedef struct memory_bucket {
		memory_tuple bucket [K-1:0];	
	} memory_bucket;

	typedef struct oram_struct {
		memory_bucket oram_tree [(2<<d)-1:0]; // defining the binary tree holding the memory
		byte [(2<<d)-1:0][3:0] pos_map; // position map, block number(4 bytes (2^4 blocks) x pos(4 bytes)
	} oram_struct;

	initial begin
		oram_struct oram; // defining the oram
		$display ("oram module has been successfully created");
	end

endmodule