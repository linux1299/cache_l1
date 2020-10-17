//`define _REG_ARRAY_
`define	NUM_WAY  			4'd8
`define NUM_SET  			128

//cache state machine
`define CACHE_IDLE			0
`define CACHE_WORK			1
`define READ_MISS			2
`define WRITE_MISS			3
`define CACHE_RESET			4
`define CACHE_COHERENCE		5