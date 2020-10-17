/*****************************************************************************
Description:
L1 Cache for CGRA 
Memory of data
Author: Lin Youxu
*****************************************************************************/
`timescale 1ns/1ps

module mem_dat ( 	rst, clk,
					mem_en,
					rd_wr,
					addr,
					data_in,
					data_out,
					way_index);
parameter DATA_WDT = 64;
parameter LINE_SIZE = 512 / DATA_WDT;
parameter SET = `NUM_SET;	//cache set number
												
/*------------------------------------------------------------------------
				Ports
------------------------------------------------------------------------*/
input								rst;
input								clk;
input								mem_en;			//mem access enable: 1, enable; 0, disable
input								rd_wr;			//read/write select: 0, read; 1, write
input		[31 : 0]				addr;			//read/write address
input		[DATA_WDT-1 : 0]		data_in;		//write data into mem
output	reg [DATA_WDT-1 : 0]		data_out;		//read data from mem
input		[2 : 0]					way_index;		//which way is selected

wire 	[DATA_WDT*8-1 : 0]			data_out_0;
wire 	[DATA_WDT*8-1 : 0]			data_out_1;
wire 	[DATA_WDT*8-1 : 0]			data_out_2;
wire 	[DATA_WDT*8-1 : 0]			data_out_3;
wire 	[DATA_WDT*8-1 : 0]			data_out_4;
wire 	[DATA_WDT*8-1 : 0]			data_out_5;
wire 	[DATA_WDT*8-1 : 0]			data_out_6;
wire 	[DATA_WDT*8-1 : 0]			data_out_7;

reg 	[2 : 0]						way_index_reg;
reg 	[31 : 0]					addr_reg;

always @(posedge clk or negedge rst) begin
	if(~rst) begin
		way_index_reg <= 0;
		addr_reg <= 0;
	end
	else begin
		way_index_reg <= way_index;
		addr_reg <= addr;
	end
end

always @(*) begin
	if(DATA_WDT == 64) begin
		case (addr_reg[9:7])
			3'b000  : case (way_index_reg)
						3'd0 : data_out = data_out_0[63:0];
						3'd1 : data_out = data_out_0[127:64];
						3'd2 : data_out = data_out_0[191:128];
						3'd3 : data_out = data_out_0[255:192];
						3'd4 : data_out = data_out_0[319:256];
						3'd5 : data_out = data_out_0[383:320];
						3'd6 : data_out = data_out_0[447:384];
						3'd7 : data_out = data_out_0[511:448];
					 default : data_out = data_out_0[63:0];
					endcase
			3'b001  : case (way_index_reg)
						3'd0 : data_out = data_out_1[63:0];
						3'd1 : data_out = data_out_1[127:64];
						3'd2 : data_out = data_out_1[191:128];
						3'd3 : data_out = data_out_1[255:192];
						3'd4 : data_out = data_out_1[319:256];
						3'd5 : data_out = data_out_1[383:320];
						3'd6 : data_out = data_out_1[447:384];
						3'd7 : data_out = data_out_1[511:448];
					 default : data_out = data_out_1[63:0];
					endcase
			3'b010  : case (way_index_reg)
						3'd0 : data_out = data_out_2[63:0];
						3'd1 : data_out = data_out_2[127:64];
						3'd2 : data_out = data_out_2[191:128];
						3'd3 : data_out = data_out_2[255:192];
						3'd4 : data_out = data_out_2[319:256];
						3'd5 : data_out = data_out_2[383:320];
						3'd6 : data_out = data_out_2[447:384];
						3'd7 : data_out = data_out_2[511:448];
					 default : data_out = data_out_2[63:0];
					endcase
			3'b011  : case (way_index_reg)
						3'd0 : data_out = data_out_3[63:0];
						3'd1 : data_out = data_out_3[127:64];
						3'd2 : data_out = data_out_3[191:128];
						3'd3 : data_out = data_out_3[255:192];
						3'd4 : data_out = data_out_3[319:256];
						3'd5 : data_out = data_out_3[383:320];
						3'd6 : data_out = data_out_3[447:384];
						3'd7 : data_out = data_out_3[511:448];
					 default : data_out = data_out_3[63:0];
					endcase
			3'b100  : case (way_index_reg)
						3'd0 : data_out = data_out_4[63:0];
						3'd1 : data_out = data_out_4[127:64];
						3'd2 : data_out = data_out_4[191:128];
						3'd3 : data_out = data_out_4[255:192];
						3'd4 : data_out = data_out_4[319:256];
						3'd5 : data_out = data_out_4[383:320];
						3'd6 : data_out = data_out_4[447:384];
						3'd7 : data_out = data_out_4[511:448];
					 default : data_out = data_out_4[63:0];
					endcase
			3'b101  : case (way_index_reg)
						3'd0 : data_out = data_out_5[63:0];
						3'd1 : data_out = data_out_5[127:64];
						3'd2 : data_out = data_out_5[191:128];
						3'd3 : data_out = data_out_5[255:192];
						3'd4 : data_out = data_out_5[319:256];
						3'd5 : data_out = data_out_5[383:320];
						3'd6 : data_out = data_out_5[447:384];
						3'd7 : data_out = data_out_5[511:448];
					 default : data_out = data_out_5[63:0];
					endcase
			3'b110  : case (way_index_reg)
						3'd0 : data_out = data_out_6[63:0];
						3'd1 : data_out = data_out_6[127:64];
						3'd2 : data_out = data_out_6[191:128];
						3'd3 : data_out = data_out_6[255:192];
						3'd4 : data_out = data_out_6[319:256];
						3'd5 : data_out = data_out_6[383:320];
						3'd6 : data_out = data_out_6[447:384];
						3'd7 : data_out = data_out_6[511:448];
					 default : data_out = data_out_6[63:0];
					endcase
			3'b111  : case (way_index_reg)
						3'd0 : data_out = data_out_7[63:0];
						3'd1 : data_out = data_out_7[127:64];
						3'd2 : data_out = data_out_7[191:128];
						3'd3 : data_out = data_out_7[255:192];
						3'd4 : data_out = data_out_7[319:256];
						3'd5 : data_out = data_out_7[383:320];
						3'd6 : data_out = data_out_7[447:384];
						3'd7 : data_out = data_out_7[511:448];
					 default : data_out = data_out_7[63:0];
					endcase
			default : data_out = data_out_0[63:0];
		endcase
	end
	else begin
		case (addr_reg[7])
			1'b0  : case (way_index_reg)
						3'd0 : data_out = data_out_0[63:0];
						3'd1 : data_out = data_out_0[127:64];
						3'd2 : data_out = data_out_0[191:128];
						3'd3 : data_out = data_out_0[255:192];
						3'd4 : data_out = data_out_0[319:256];
						3'd5 : data_out = data_out_0[383:320];
						3'd6 : data_out = data_out_0[447:384];
						3'd7 : data_out = data_out_0[511:448];
					 default : data_out = data_out_0[63:0];
					endcase
			1'b1  : case (way_index_reg)
						3'd0 : data_out = data_out_1[63:0];
						3'd1 : data_out = data_out_1[127:64];
						3'd2 : data_out = data_out_1[191:128];
						3'd3 : data_out = data_out_1[255:192];
						3'd4 : data_out = data_out_1[319:256];
						3'd5 : data_out = data_out_1[383:320];
						3'd6 : data_out = data_out_1[447:384];
						3'd7 : data_out = data_out_1[511:448];
					 default : data_out = data_out_1[63:0];
					endcase
			default : data_out = data_out_0[63:0];
		endcase
	end
end

generate
	if (DATA_WDT == 64) begin
		genvar i;
		for(i = 0; i < 8; i = i + 1) begin: mem_dat_way
				rf_sp_128x64  mem_dat_0 (.Q(data_out_0[64*(i+1)-1:64*i]), .CLK(clk), .CEN( ~((way_index == i) && (addr[9:7] == 3'b000)) ), .WEN(~rd_wr), .A(addr[6:0]), .D(data_in), .EMA(3'b010), .EMAW(2'b00), .RET1N(1'b1));
				rf_sp_128x64  mem_dat_1 (.Q(data_out_1[64*(i+1)-1:64*i]), .CLK(clk), .CEN( ~((way_index == i) && (addr[9:7] == 3'b001)) ), .WEN(~rd_wr), .A(addr[6:0]), .D(data_in), .EMA(3'b010), .EMAW(2'b00), .RET1N(1'b1));
				rf_sp_128x64  mem_dat_2 (.Q(data_out_2[64*(i+1)-1:64*i]), .CLK(clk), .CEN( ~((way_index == i) && (addr[9:7] == 3'b010)) ), .WEN(~rd_wr), .A(addr[6:0]), .D(data_in), .EMA(3'b010), .EMAW(2'b00), .RET1N(1'b1));
				rf_sp_128x64  mem_dat_3 (.Q(data_out_3[64*(i+1)-1:64*i]), .CLK(clk), .CEN( ~((way_index == i) && (addr[9:7] == 3'b011)) ), .WEN(~rd_wr), .A(addr[6:0]), .D(data_in), .EMA(3'b010), .EMAW(2'b00), .RET1N(1'b1));
				rf_sp_128x64  mem_dat_4 (.Q(data_out_4[64*(i+1)-1:64*i]), .CLK(clk), .CEN( ~((way_index == i) && (addr[9:7] == 3'b100)) ), .WEN(~rd_wr), .A(addr[6:0]), .D(data_in), .EMA(3'b010), .EMAW(2'b00), .RET1N(1'b1));
				rf_sp_128x64  mem_dat_5 (.Q(data_out_5[64*(i+1)-1:64*i]), .CLK(clk), .CEN( ~((way_index == i) && (addr[9:7] == 3'b101)) ), .WEN(~rd_wr), .A(addr[6:0]), .D(data_in), .EMA(3'b010), .EMAW(2'b00), .RET1N(1'b1));
				rf_sp_128x64  mem_dat_6 (.Q(data_out_6[64*(i+1)-1:64*i]), .CLK(clk), .CEN( ~((way_index == i) && (addr[9:7] == 3'b110)) ), .WEN(~rd_wr), .A(addr[6:0]), .D(data_in), .EMA(3'b010), .EMAW(2'b00), .RET1N(1'b1));
				rf_sp_128x64  mem_dat_7 (.Q(data_out_7[64*(i+1)-1:64*i]), .CLK(clk), .CEN( ~((way_index == i) && (addr[9:7] == 3'b111)) ), .WEN(~rd_wr), .A(addr[6:0]), .D(data_in), .EMA(3'b010), .EMAW(2'b00), .RET1N(1'b1));
		end
	end
	else begin
		genvar i;
		for(i = 0; i < 8; i = i + 1) begin: mem_dat_way
				rf_sp_128x256  mem_dat_0 (.Q(data_out_0[256*(i+1)-1:256*i]), .CLK(clk), .CEN( ~((way_index == i) && (addr[7] == 1'b0)) ), .WEN(~rd_wr), .A(addr[6:0]), .D(data_in), .EMA(3'b010), .EMAW(2'b00), .RET1N(1'b1));
				rf_sp_128x256  mem_dat_1 (.Q(data_out_1[256*(i+1)-1:256*i]), .CLK(clk), .CEN( ~((way_index == i) && (addr[7] == 1'b1)) ), .WEN(~rd_wr), .A(addr[6:0]), .D(data_in), .EMA(3'b010), .EMAW(2'b00), .RET1N(1'b1));
		end
	end
endgenerate

endmodule
