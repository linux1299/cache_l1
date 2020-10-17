/*****************************************************************************
Description:
L1 Data Cache for CGRA 
8 way 128 set associated cache
Author: Lin Youxu
*****************************************************************************/
`timescale 1ns/1ps

`include "cache_l1_define.v"

module mem_tag (rst, clk, mem_en, rd_wr, addr, data_in, data_out);

												
/*------------------------------------------------------------------------
					Ports
------------------------------------------------------------------------*/
input								rst;
input								clk;
input								mem_en;			//mem access enable: 1, enable; 0, disable
input								rd_wr;			//read/write select: 0, read; 1, write
input	[31:0]						addr;			//read/write address
input	[32*`NUM_WAY - 1:0]			data_in;		//write data into mem
output	[32*`NUM_WAY - 1:0]			data_out;		//read data from mem

reg 	[31:0]						addr_reg;
wire	[32*`NUM_WAY - 1:0]			data_0;
wire	[32*`NUM_WAY - 1:0]			data_1;

always @(posedge clk or negedge rst) begin
	if(~rst) begin
		addr_reg <= 0;
	end
	else begin
		addr_reg <= addr;
	end
end

genvar i;
generate
for(i = 0; i < `NUM_WAY; i = i + 1)
	begin: mem_tag
		rf_sp_64x32 mem_tag_0 (.Q(data_0[32*(i+1)-1:32*i]), .CLK(clk), .CEN(~(mem_en && ~addr[6])), .WEN(~rd_wr), .A(addr[5:0]), .D(data_in[32*(i+1)-1:32*i]), .EMA(3'b010), .EMAW(2'b00), .RET1N(1'b1));
		rf_sp_64x32 mem_tag_1 (.Q(data_1[32*(i+1)-1:32*i]), .CLK(clk), .CEN(~(mem_en &&  addr[6])), .WEN(~rd_wr), .A(addr[5:0]), .D(data_in[32*(i+1)-1:32*i]), .EMA(3'b010), .EMAW(2'b00), .RET1N(1'b1));
	end
endgenerate
assign data_out = addr_reg[6] ? data_1 : data_0;

endmodule