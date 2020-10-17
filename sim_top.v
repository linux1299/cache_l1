/*****************************************************************************
Description:
Testbench for L1 Cache
Author: Li Cangyuan
*****************************************************************************/
//`include "cache_l1_define.v"
`timescale 1ns/10ps
module sim_top;

localparam DATA_WDT = 64;

logic 								clk;
logic 								rst_n;
logic 								th_cgra_cache_flush;

logic		[32 - 1 : 0]			agent_req_addr; 		//请求的地址
logic								agent_req_en; 			//请求使能信号，单周期脉冲
logic								agent_req_wr; 			//请求写入使能信号，对齐agent_req_en
logic		[DATA_WDT - 1 : 0]		agent_req_wr_data; 		//请求写入的数据，对齐agent_req_en
logic								agent_req_done; 		//请求完成，与输出data的对齐
logic								agent_req_hit; 			//请求命中，单周期
logic								agent_req_miss; 		//请求缺失，单周期
logic								agent_req_block; 		//Cache阻塞，高电平期间所有请求无效
logic		[DATA_WDT - 1:0]		agent_req_data; 		//从Cache中读取的数据

logic								mem_read_valid; 		//内存返回数据有效信号，与返回的数据对齐
logic		[DATA_WDT - 1 : 0]		mem_read_data; 			//缺失时Cache从内存读取的数据
logic								mem_req_en; 			//内存请求使能信号
logic		[32 - 1 : 0]			mem_req_addr; 			//内存请求地址

logic		[31 : 0]				i_coherence_addr_1, i_coherence_addr_2, i_coherence_addr_3; 		//输入请求失效的地址
logic								i_coherence_valid_1, i_coherence_valid_2, i_coherence_valid_3; 		//输入请求失效的有效信号
logic								o_coherence_valid_1, o_coherence_valid_2, o_coherence_valid_3; 		//输出请求失效的有效信号
logic								i_coherence_ack_1, i_coherence_ack_2, i_coherence_ack_3; 			//输入完成一致性应答信号
logic								o_coherence_ack_1, o_coherence_ack_2, o_coherence_ack_3; 			//输出完成一致性应答信号
logic		[31 : 0]				o_coherence_addr; 													//输出请求失效的地址

cache_l1 u_cache_l1(.clk(clk),
					.rst_n(rst_n),
					.th_cgra_cache_flush(0),
					.agent_req_addr(agent_req_addr),
					.agent_req_en(agent_req_en),
					.agent_req_wr(agent_req_wr),
					.agent_req_wr_data(agent_req_wr_data),
					.agent_req_done(agent_req_done),
					.agent_req_hit(agent_req_hit),
					.agent_req_miss(agent_req_miss),
					.agent_req_block(agent_req_block),
					.agent_req_data(agent_req_data),
					.mem_read_valid(mem_read_valid),
					.mem_read_data(mem_read_data),
					.mem_req_en(mem_req_en),
					.mem_req_addr(mem_req_addr),
					.i_coherence_addr_1(i_coherence_addr_1),
					.i_coherence_addr_2(i_coherence_addr_2),
					.i_coherence_addr_3(i_coherence_addr_3),
					.i_coherence_valid_1(i_coherence_valid_1),
					.i_coherence_valid_2(i_coherence_valid_2),
					.i_coherence_valid_3(i_coherence_valid_3),
					.o_coherence_valid_1(o_coherence_valid_1),
					.o_coherence_valid_2(o_coherence_valid_2),
					.o_coherence_valid_3(o_coherence_valid_3),
					.i_coherence_ack_1(i_coherence_ack_1),
					.i_coherence_ack_2(i_coherence_ack_2),
					.i_coherence_ack_3(i_coherence_ack_3),
					.o_coherence_ack_1(o_coherence_ack_1),
					.o_coherence_ack_2(o_coherence_ack_2),
					.o_coherence_ack_3(o_coherence_ack_3),
					.o_coherence_addr(o_coherence_addr)
					);

dram_sim u_dram_sim(.clk(clk),
					.rst(rst_n),
					.mem_en(mem_req_en),
					.rd_wr(0),
					.addr(mem_req_addr),
					.data_in(0),
					.data_out(mem_read_data),
					.mem_valid(mem_read_valid)
					);

initial begin
	clk = 0;
	rst_n = 1;
	i_coherence_addr_1 = 0; i_coherence_addr_2 = 0; i_coherence_addr_3 = 0;
	i_coherence_valid_1 = 0; i_coherence_valid_2 = 0; i_coherence_valid_3 = 0;
	i_coherence_ack_1 = 0; i_coherence_ack_2 = 0; i_coherence_ack_3 = 0;
	#3 rst_n = 0;
	#5 rst_n = 1;
	#2000 agent_req_addr = 32'd0;
	agent_req_en = 1;
	agent_req_wr = 1;
	agent_req_wr_data = 64'd1;

	#200 agent_req_addr = 32'd0;
	agent_req_en = 1;
	agent_req_wr = 0;
	agent_req_wr_data = 64'd1;
end



initial begin
	forever begin
		#5 clk = ~clk;
	end
end

endmodule