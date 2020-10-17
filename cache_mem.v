
`timescale 1ns/1ps

//`include "icache_define.v"

module icache_l1_mem ( rst, clk, mem_en, rd_wr, addr, data_in, data_out);

parameter DEPTH=16;			//mem depth
parameter WIDTH=16;			//mem width
parameter ADDR_WIDTH=32;	//mem width
												
/*------------------------------------------------------------------------
					Ports
------------------------------------------------------------------------*/
input						rst;
input						clk;
input						mem_en;		//mem access enable: 1, enable; 0, disable
input						rd_wr;		//read/write select: 0, read; 1, write
input	[ADDR_WIDTH - 1:0]	addr;		//read/write address
input	[WIDTH-1:0]			data_in;	//write data into mem
output 	[WIDTH-1:0]			data_out;	//read data from mem
reg 	[WIDTH-1:0]			data_out;

/*------------------------------------------------------------------------
				Internal Signal Declarations
------------------------------------------------------------------------*/
reg 	[WIDTH-1:0]			mem [DEPTH-1:0];	//mem body
integer i;

always @(posedge clk or negedge rst) begin
	if (~rst) begin
		for(i=0;i<DEPTH;i=i+1) begin
			mem[i] <= 0;
		end
	end
	else if (mem_en && rd_wr) begin //write
		mem[addr] <= data_in;
	end
end

always @(posedge clk or negedge rst) begin
	if (~rst) begin
		data_out <= 0;
	end
	else if (mem_en && ~rd_wr) begin //read
		data_out <= mem[addr];
	end
end

endmodule
