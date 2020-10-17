/*****************************************************************************
Description:
DRAM for CGRA 
Memory of data
Author: Lin Youxu
*****************************************************************************/
`timescale 1ns/1ps

module dram_sim ( 	rst, clk,
					mem_en,
					rd_wr,
					addr,
					data_in,
					data_out,
					mem_valid);
parameter DATA_WDT = 64;
parameter DEPTH = 320000;
/*------------------------------------------------------------------------
				Ports
------------------------------------------------------------------------*/
input						rst;
input						clk;
input						mem_en;		//mem access enable: 1, enable; 0, disable
input						rd_wr;		//read/write select: 0, read; 1, write
input		[31:0]			addr;		//read/write address
input		[DATA_WDT-1:0]	data_in;	//write data into mem
output reg	[DATA_WDT-1:0]	data_out;	//read data from mem
output reg					mem_valid;
/*------------------------------------------------------------------------
				Internal Signal Declarations
------------------------------------------------------------------------*/
reg 	[DATA_WDT-1:0]		mem [DEPTH-1:0];	//mem body
integer i;

always @(posedge clk or negedge rst) begin
	if (~rst) begin
		$readmemh("memory.mem", mem);
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

always @(posedge clk or negedge rst) begin
	if(~rst) begin
		mem_valid <= 0;
	end
	else begin
		mem_valid <= mem_en;
	end
end

endmodule