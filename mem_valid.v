/*****************************************************************************
Description:
L1 Data Cache for CGRA 
8 way 128 set associated cache
Author: Li Cangyuan
*****************************************************************************/
`timescale 1ns/1ps

//`include "cache_define.v"

module mem_valid ( rst, clk, mem_en, rd_wr, addr, data_in, data_out);

												
/*------------------------------------------------------------------------
					Ports
------------------------------------------------------------------------*/
input									rst;
input									clk;
input									mem_en;			//mem access enable: 1, enable; 0, disable
input									rd_wr;			//read/write select: 0, read; 1, write
input	[31:0]							addr;			//read/write address
input	[`NUM_WAY - 1:0]				data_in;		//write data into mem
output	[`NUM_WAY - 1:0]				data_out;		//read data from mem

`ifdef _REG_ARRAY_

icache_l1_mem #(.DEPTH(`NUM_SET), .WIDTH(`NUM_WAY)) mem_valid ( rst, clk, mem_en, rd_wr, addr, data_in, data_out);

`else

rf_sp_128x8 mem_valid_0 (.Q(data_out), .CLK(clk), .CEN(~mem_en), .WEN(~rd_wr), .A(addr[6:0]), .D(data_in), .EMA(3'b010), .EMAW(2'b00), .RET1N(1'b1));

`endif

endmodule

