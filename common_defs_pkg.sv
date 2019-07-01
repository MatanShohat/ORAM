`timescale 1ns/10ps
package common_defs_pkg;
	
	// Adress width constants declerations
	parameter BYTE_WIDTH = 8;
	parameter BYTES_PER_WORD = 4;
	parameter INST_MEM_ADDR_WIDTH = 12; 
	parameter DATA_MEM_ADDR_WIDTH = 12;
	

	// Oram constants declerations	
	parameter ALPHA = BYTES_PER_WORD;
	parameter N = (1<<DATA_MEM_ADDR_WIDTH)*BYTES_PER_WORD;
	parameter TREE_DEPTH = $clog2(N/ALPHA); // also represent the number of bits needed to describe block number
	parameter K = 3; // number of tuples per bucket (per node)

endpackage