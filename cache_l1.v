/*****************************************************************************
Description:
L1 Cache for CGRA 
8 way 128 set associated pipelined l1 cache
Replace Strategy：Pseudo LRU
Author: Lin Youxu
*****************************************************************************/
`include "cache_l1_define.v"
`timescale 1ns/10ps

module cache_l1
	#(
		parameter DATA_WDT  = 64,
		parameter LINE_SIZE = 512 / DATA_WDT
	)
	(
		input								clk, 					//时钟信号
		input								rst_n, 					//复位信号，低电平有效
		input								th_cgra_cache_flush, 	//Cache清空信号
		//Request
		input		[32 - 1 : 0]			agent_req_addr, 		//请求的地址
		input								agent_req_en, 			//请求使能信号，单周期脉冲
		input								agent_req_wr, 			//请求写入使能信号，对齐agent_req_en
		input		[DATA_WDT - 1 : 0]		agent_req_wr_data, 		//请求写入的数据，对齐agent_req_en
		output reg 							agent_req_done, 		//请求完成，与输出data的对齐
		output reg							agent_req_hit, 			//请求命中，单周期
		output reg							agent_req_miss, 		//请求缺失，单周期
		output reg							agent_req_block, 		//Cache阻塞，高电平期间所有请求无效
		output reg	[DATA_WDT - 1:0]		agent_req_data, 		//从Cache中读取的数据
		//To Memory
		input								mem_read_valid, 		//内存返回数据有效信号，与返回的数据对齐
		input		[DATA_WDT - 1 : 0]		mem_read_data, 			//缺失时Cache从内存读取的数据
		output reg							mem_req_en, 			//内存请求使能信号
		output 		[32 - 1 : 0]			mem_req_addr, 			//内存请求地址
		//Coherence Port
		input		[31 : 0]				i_coherence_addr_1, i_coherence_addr_2, i_coherence_addr_3, 		//输入请求失效的地址
		input 								i_coherence_valid_1, i_coherence_valid_2, i_coherence_valid_3, 		//输入请求失效的有效信号
		output reg							o_coherence_valid_1, o_coherence_valid_2, o_coherence_valid_3, 		//输出请求失效的有效信号
		input 								i_coherence_ack_1, i_coherence_ack_2, i_coherence_ack_3, 			//输入完成一致性应答信号
		output reg							o_coherence_ack_1, o_coherence_ack_2, o_coherence_ack_3, 			//输出完成一致性应答信号
		output reg 	[31 : 0]				o_coherence_addr 													//输出请求失效的地址
	);


//寄存器实现的LRU单元
reg  [6 : 0]						mem_lru				[127 : 0];
wire [6 : 0]						lru_data_out;
reg  [6 : 0]						lru_in_reg;
reg  [6 : 0]						lru_out_reg;



//输入信号的寄存器
reg  [32 -1 : 0]					agent_req_addr_reg;
reg  [32 -1 : 0]					agent_req_addr_reg_reg;
reg 								agent_req_en_reg;
reg 								agent_req_en_reg_reg;
reg 								agent_req_wr_reg;
reg 								agent_req_wr_reg_reg;
reg  [DATA_WDT - 1 : 0]				agent_req_wr_data_reg;
reg  [DATA_WDT - 1 : 0]				agent_req_wr_data_reg_reg;

//一致性相关信号
wire [32 - 1 : 0]					i_coherence_addr;
reg  [32 - 1 : 0]					i_coherence_addr_reg;
reg  [32 - 1 : 0]					i_coherence_addr_reg_reg;
wire 								i_coherence_valid;
reg  								i_coherence_valid_reg;
reg  								i_coherence_valid_reg_reg;


//状态机相关的状态信号
reg  [2 : 0]						current_state;
reg  [2 : 0]						next_state;

//判断命中或缺失的信号
integer 							i;
reg									cache_hit;
reg									cache_hit_reg;
reg 								cache_miss;
reg  [`NUM_WAY : 0]					cache_hit_tmp;
reg  [2:0] 							cache_hit_index;
reg  [2:0] 							cache_hit_index_reg;
reg  [2:0]							cache_hit_index_tmp	[`NUM_WAY : 0];
reg  [2:0]							way_index;
reg  [2:0]							way_index_reg;
reg  [2:0]							way_index_tmp		[`NUM_WAY : 0];
wire								req_hit;
reg									req_hit_reg;
reg									req_hit_reg_reg;
wire								coherence_hit;
reg									coherence_hit_reg;

wire [18 : 0]						tag_index;	//物理地址的标记位tag
wire [31 : 0]						set_index;
wire [31 : 0]						data_addr;
wire [31 : 0]						data_wr_addr;

//与存储单元相关的信号
wire 								valid_mem_en;
wire 								valid_rd_wr;
wire [31 : 0]						valid_addr;
wire [`NUM_WAY -1 : 0]				valid_data_in;
wire [`NUM_WAY -1 : 0]				valid_data_out;
wire [`NUM_WAY -1 : 0]				valid_out_w;
reg  [`NUM_WAY -1 : 0]				valid_out_reg;
reg  [`NUM_WAY -1 : 0]				valid_in_reg;

wire 								tag_mem_en;
wire 								tag_rd_wr;
wire [31 : 0]						tag_addr;
wire [`NUM_WAY*32 -1 : 0]			tag_data_in;
wire [`NUM_WAY*32 -1 : 0]			tag_data_out;
wire [32 -1 : 0]					tag_out_w 		[`NUM_WAY-1 : 0];
reg  [32 -1 : 0]					tag_out_reg		[`NUM_WAY-1 : 0];
reg  [32 -1 : 0]					tag_in_reg		[`NUM_WAY-1 : 0];

wire 								dat_mem_en;
wire 								dat_rd_wr;
wire [31 : 0]						dat_addr;
wire [DATA_WDT -1 : 0]				dat_data_in;
wire [DATA_WDT -1 : 0]				dat_data_out;
reg  [DATA_WDT -1 : 0]				dat_in_reg;

reg  [7 : 0]						reset_cnt;
reg  [2 : 0]						miss_valid_cnt;
reg  [2 : 0]						mem_req_addr_cnt;

//-----------------Input and Registers-------------------

//输入的使能信号agent_req_en，放入寄存器agent_req_en_reg
always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		agent_req_en_reg <= 0;
		agent_req_en_reg_reg <= 0;
	end
	else begin
		agent_req_en_reg_reg <= agent_req_en_reg;
		agent_req_en_reg <= agent_req_en;
	end
end

//输入的地址agent_req_addr，放入寄存器agent_req_addr_reg
always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		agent_req_addr_reg <= 0;
		agent_req_addr_reg_reg <= 0;
	end
	else begin
		agent_req_addr_reg_reg <= agent_req_addr_reg;
		if(agent_req_en)
			agent_req_addr_reg <= agent_req_addr;
		else
			agent_req_addr_reg <= agent_req_addr_reg;
	end
end

//输入的写使能信号agent_req_wr，放入寄存器agent_req_wr_reg
always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		agent_req_wr_reg <= 0;
		agent_req_wr_reg_reg <= 0;
	end
	else begin
		agent_req_wr_reg_reg <= agent_req_wr_reg;
		agent_req_wr_reg <= agent_req_wr;
	end
end

//写入的数据agent_req_wr_data，放入寄存器agent_req_wr_data_reg
always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		agent_req_wr_data_reg <= 0;
		agent_req_wr_data_reg_reg <= 0;
	end
	else begin
		agent_req_wr_data_reg_reg <= agent_req_wr_data_reg;
		if(agent_req_wr)
			agent_req_wr_data_reg <= agent_req_wr_data;
		else
			agent_req_wr_data_reg <= agent_req_wr_data_reg;
	end
end

//输入一致性失效地址i_coherence_addr，放入寄存器i_coherence_addr_reg
always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		i_coherence_addr_reg <= 0;
	end
	else begin
		i_coherence_addr_reg_reg <= i_coherence_addr_reg;
		if(i_coherence_valid)
			i_coherence_addr_reg <= i_coherence_addr;
		else
			i_coherence_addr_reg <= i_coherence_addr_reg;
	end
end

//输入一致性有效信号i_coherence_valid，放入寄存器i_coherence_valid_reg
always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		i_coherence_valid_reg <= 0;
		i_coherence_valid_reg_reg <= 0;
	end
	else begin
		i_coherence_valid_reg <= i_coherence_valid;
		i_coherence_valid_reg_reg <= i_coherence_valid_reg;
	end
end

//---------------------Output------------------------------

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		agent_req_miss <= 0;
	end
	else begin
		agent_req_miss <= current_state == `CACHE_WORK && agent_req_en_reg && cache_miss; //请求缺失，不是一致性的缺失
	end
end

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		agent_req_hit <= 0;
	end
	else begin
		agent_req_hit <= req_hit_reg_reg;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		agent_req_block <= 0;
	end
	else begin
		agent_req_block <= next_state == `CACHE_COHERENCE || next_state == `READ_MISS || next_state == `WRITE_MISS; //Cache阻塞
	end
end

//输出Cache中的数据
always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		agent_req_data <= 0;
		agent_req_done <= 0;
	end
	else if(req_hit_reg_reg) begin
		agent_req_done <= 1;
		agent_req_data <= dat_data_out;
	end
	else if((current_state == `READ_MISS) && mem_read_valid && (data_addr == data_wr_addr)) begin
		agent_req_data <= mem_read_data;
		agent_req_done <= 1;
	end
	else begin
		agent_req_data <= agent_req_data;
		agent_req_done <= 0;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		mem_req_en <= 0;
	end
	else if(mem_req_addr_cnt == LINE_SIZE - 1) begin
		mem_req_en <= 0;
	end
	else begin
		mem_req_en <= (next_state == `READ_MISS) || (next_state == `WRITE_MISS);
	end
end

assign mem_req_addr = (agent_req_addr_reg / 64 * LINE_SIZE) + mem_req_addr_cnt;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		mem_req_addr_cnt <= 0;
	end
	else if(mem_req_en) begin
		mem_req_addr_cnt <= mem_req_addr_cnt + 1;
	end
	else if(mem_req_addr_cnt == LINE_SIZE - 1) begin
		mem_req_addr_cnt <= 0;
	end
	else begin
		mem_req_addr_cnt <= mem_req_addr_cnt;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		o_coherence_valid_1 <= 0;
		o_coherence_valid_2 <= 0;
		o_coherence_valid_3 <= 0;
	end
	else begin
		if(agent_req_en && agent_req_wr) begin
			o_coherence_valid_1 <= 1;
			o_coherence_valid_2 <= 1;
			o_coherence_valid_3 <= 1;
		end
		else begin
			if(i_coherence_ack_1)
				o_coherence_valid_1 <= 0;
			else
				o_coherence_valid_1 <= o_coherence_valid_1;
			if(i_coherence_ack_2)
				o_coherence_valid_2 <= 0;
			else
				o_coherence_valid_2 <= o_coherence_valid_2;
			if(i_coherence_ack_3)
				o_coherence_valid_3 <= 0;
			else
				o_coherence_valid_3 <= o_coherence_valid_3;
		end
	end
end

always @(posedge clk or negedge rst_n)begin
	if(~rst_n) begin
		o_coherence_ack_1 <= 0;
		o_coherence_ack_2 <= 0;
		o_coherence_ack_3 <= 0;
	end
	else begin
		if(i_coherence_valid_1) begin
			o_coherence_ack_1 <= current_state == `CACHE_COHERENCE && next_state == `CACHE_IDLE;
			o_coherence_ack_2 <= 0;
			o_coherence_ack_3 <= 0;
		end
		else if(i_coherence_valid_2) begin
			o_coherence_ack_1 <= 0;
			o_coherence_ack_2 <= current_state == `CACHE_COHERENCE && next_state == `CACHE_IDLE;
			o_coherence_ack_3 <= 0;
		end
		else if(i_coherence_valid_3) begin
			o_coherence_ack_1 <= 0;
			o_coherence_ack_2 <= 0;
			o_coherence_ack_3 <= current_state == `CACHE_COHERENCE && next_state == `CACHE_IDLE;
		end
		else begin
			o_coherence_ack_1 <= 0;
			o_coherence_ack_2 <= 0;
			o_coherence_ack_3 <= 0;
		end
	end
end

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		o_coherence_addr <= 0;
	end
	else if(agent_req_en && agent_req_wr) begin
		o_coherence_addr <= agent_req_addr;
	end
	else begin
		o_coherence_addr <= o_coherence_addr;
	end
end
//---------------------Address assign-----------------------------------------
assign tag_index = agent_req_en_reg ? agent_req_addr_reg[32-1 : 32-19] : i_coherence_valid_reg ? i_coherence_addr_reg[32-1 : 32-19] : 0; //物理地址的标记位为高19位
assign set_index  = agent_req_en ? {25'b0, agent_req_addr[12:6]} : i_coherence_valid ? {25'b0, i_coherence_addr[12:6]} : 0; //物理地址的组号共7位，在第12~6位
assign data_addr  = agent_req_addr_reg_reg / (DATA_WDT/8) % (`NUM_SET*LINE_SIZE);
assign data_wr_addr = agent_req_addr_reg_reg[12:6] * LINE_SIZE + miss_valid_cnt;

assign i_coherence_valid = i_coherence_valid_1 || i_coherence_valid_2 || i_coherence_valid_3;
assign i_coherence_addr = i_coherence_valid_1 ? i_coherence_addr_1 : i_coherence_valid_2 ? i_coherence_addr_2 : i_coherence_valid_3 ? i_coherence_addr_3 : 0;

/*------------------------------------------------------------------------
						Miss or Hit Logic Start
------------------------------------------------------------------------*/
always @(*) begin
	if(agent_req_en_reg || (current_state == `CACHE_COHERENCE && i_coherence_valid_reg)) begin
		cache_hit_tmp[0] = 0;
		cache_hit_index_tmp[0] = 0;
		for(i = 0; i < `NUM_WAY; i = i + 1) begin
			if ((tag_index == tag_out_w[i][32-1 : 32-19]) && valid_data_out[i]) begin //tag标志位取高19位进行对比，valid为1，则命中
				cache_hit_tmp[i+1] = 1;
				cache_hit_index_tmp[i+1] = i;
			end
			else begin
				cache_hit_tmp[i+1] = 0;
				cache_hit_index_tmp[i+1] = cache_hit_index_tmp[i];
			end
		end
		cache_hit_index = cache_hit_index_tmp[`NUM_WAY]; //cache命中第cache_hit_index路的数据
		cache_hit = |cache_hit_tmp; //按位或，有一路命中则表示cache hit
		cache_miss = ~cache_hit; //cache缺失包括请求的缺失和一致性缺失
	end
	else begin
		cache_miss = 0;
		cache_hit = 0;
		cache_hit_index = 0;
		for(i = 0;i < `NUM_WAY + 1;i = i + 1) begin
			cache_hit_tmp[i] = 0;
			cache_hit_index_tmp[i] = 0;
		end
	end

	if(agent_req_en_reg_reg || (current_state == `CACHE_COHERENCE && i_coherence_valid_reg_reg)) begin
		if(~cache_hit_reg) begin //缺失
			way_index_tmp[0] = 0;
			if(&valid_out_reg) begin
				way_index = lru_out_reg[6] ?
							(lru_out_reg[5] ? (lru_out_reg[3] ? 7 : 6) : (lru_out_reg[2] ? 5 : 4)) :
							(lru_out_reg[4] ? (lru_out_reg[1] ? 3 : 2) : (lru_out_reg[0] ? 1 : 0));
			end
			else begin
				for(i = 0; i < `NUM_WAY; i = i + 1) begin
					if(~valid_out_reg[i]) way_index_tmp[i+1] = i;
					else 				  way_index_tmp[i+1] = way_index_tmp[i];
				end
				way_index = way_index_tmp[`NUM_WAY];
			end
		end
		else begin //命中
			for(i = 0;i < `NUM_WAY + 1;i = i + 1) begin
				way_index_tmp[i] = 0;
			end
			way_index = cache_hit_index_reg;
		end
	end
	else begin
		for(i = 0;i < `NUM_WAY + 1;i = i + 1) begin
			way_index_tmp[i] = 0;
		end
		way_index  = 0;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		way_index_reg <= 0;
	end
	else if(agent_req_en_reg_reg) begin
		way_index_reg <= way_index;
	end
	else begin
		way_index_reg <= way_index_reg;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		cache_hit_reg <= 0;
		cache_hit_index_reg <= 0;
	end
	else begin
		cache_hit_reg <= cache_hit;
		cache_hit_index_reg <= cache_hit_index;
	end
end

//请求命中，不是一致性的命中
assign req_hit = agent_req_en_reg && cache_hit;
always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		req_hit_reg <= 0;
		req_hit_reg_reg <= 0;
	end
	else begin
		req_hit_reg <= req_hit;
		req_hit_reg_reg <= req_hit_reg;
	end
end
//一致性命中，不是请求命中
assign coherence_hit = (current_state == `CACHE_COHERENCE) && cache_hit;
always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		coherence_hit_reg <= 0;
	end
	else begin
		coherence_hit_reg <= coherence_hit;
	end
end
/*------------------------------------------------------------------------
						Miss or Hit Logic End
------------------------------------------------------------------------*/


/*------------------------------------------------------------------------
						State Machine Start
------------------------------------------------------------------------*/
always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		current_state <= `CACHE_RESET;
	end
	else begin
		current_state <= next_state;
	end
end

//状态转换
always @(*) begin
	case (current_state)
		`CACHE_IDLE: begin
			if(agent_req_en)
				next_state = `CACHE_WORK;
			else if(i_coherence_valid)
				next_state = `CACHE_COHERENCE;
			else
				if(th_cgra_cache_flush) 
					next_state = `CACHE_RESET;
				else	
					next_state = `CACHE_IDLE;
		end

		`CACHE_WORK: begin
			if(cache_miss)
				if (agent_req_wr_reg)
					next_state = `WRITE_MISS;
				else
					next_state = `READ_MISS;
			else
				next_state = `CACHE_WORK;
		end

		`READ_MISS: begin
			if(miss_valid_cnt == LINE_SIZE - 1)
				next_state = `CACHE_IDLE;
			else
				next_state = `READ_MISS;
		end

		`WRITE_MISS: begin
			if(miss_valid_cnt == LINE_SIZE - 1)
				next_state = `CACHE_IDLE;
			else
				next_state = `WRITE_MISS;
		end

		`CACHE_RESET: begin
			if(reset_cnt == `NUM_SET - 1)
				next_state = `CACHE_IDLE;
			else
				next_state = `CACHE_RESET;
		end

		`CACHE_COHERENCE: begin
			if(i_coherence_valid_reg_reg) 
				next_state = `CACHE_IDLE;
			else if(cache_miss)
				next_state = `CACHE_IDLE;
			else
				next_state = `CACHE_COHERENCE;
		end

		default: begin
			next_state = `CACHE_IDLE;
		end
	endcase
end
/*------------------------------------------------------------------------
						State Machine End
------------------------------------------------------------------------*/


/*------------------------------------------------------------------------
						Memory Read or Write Start
------------------------------------------------------------------------*/
mem_valid
u_mem_valid(
	.rst				(rst_n),
	.clk				(clk),
	.mem_en				(valid_mem_en),
	.rd_wr				(valid_rd_wr),
	.addr				(valid_addr),
	.data_in			(valid_data_in),
	.data_out			(valid_data_out)
);

mem_tag
u_mem_tag(
	.rst				(rst_n),
	.clk				(clk),
	.mem_en				(tag_mem_en),
	.rd_wr				(tag_rd_wr),
	.addr				(tag_addr),
	.data_in			(tag_data_in),
	.data_out			(tag_data_out)
);

mem_dat
	#(
	.DATA_WDT	(DATA_WDT),
	.LINE_SIZE	(LINE_SIZE)
	)
u_mem_dat(
	.rst		(rst_n),
	.clk		(clk),
	.mem_en		(dat_mem_en),
	.rd_wr		(dat_rd_wr),
	.addr		(dat_addr),
	.data_in	(dat_data_in),
	.data_out	(dat_data_out),
	.way_index	(mem_read_valid ? way_index_reg : way_index)
);
//从存储单元中读出数据，放入对应的寄存器中
genvar k, j;
generate
	for(k = 0;k < `NUM_WAY; k = k + 1) begin: data_out_w
		assign tag_out_w[k] = tag_data_out[32*(k+1)-1 : 32* k];
		assign valid_out_w[k] = valid_data_out[k];
	end
	for(k = 0;k < `NUM_WAY;k = k + 1) begin: data_out_reg
		always @(posedge clk or negedge rst_n) begin
			if (~rst_n) begin
				tag_out_reg[k] <= 0;
				valid_out_reg[k] <= 0;
			end
			else begin
				tag_out_reg[k] <= tag_out_w[k];
				valid_out_reg[k] <= valid_out_w[k];
			end
		end
	end
endgenerate

//准备送入存储单元的数据
always @(*) begin
	if(agent_req_wr_reg_reg && req_hit_reg) begin //写命中
		for(i = 0; i < `NUM_WAY; i = i + 1) begin
			valid_in_reg[i] = 0;
		 	tag_in_reg[i] 	= 0;
		end
		dat_in_reg = agent_req_wr_data_reg_reg;
	end

	else if(coherence_hit_reg) begin //一致性命中
		for(i = 0; i < `NUM_WAY; i = i + 1) begin
			valid_in_reg[i] = (way_index == i) ? 0 : valid_out_reg[i];
			tag_in_reg[i] 	= 0;
		end
		dat_in_reg 	= 0;
	end

	else if(current_state == `READ_MISS || current_state == `WRITE_MISS) begin //缺失
		for(i = 0; i < `NUM_WAY; i = i + 1) begin
			valid_in_reg[i] = (way_index == i) ? 1 : valid_out_reg[i];
			tag_in_reg[i] 	= (way_index == i) ? agent_req_addr_reg_reg : tag_out_reg[i];
		end
		dat_in_reg 	= ((current_state == `WRITE_MISS) && mem_read_valid && (data_addr != data_wr_addr)) ? mem_read_data : agent_req_wr_data_reg_reg;
	end

	else begin
		for(i = 0; i < `NUM_WAY; i = i + 1) begin
			valid_in_reg[i] = 0;
		 	tag_in_reg[i] 	= 0;
		end
		dat_in_reg 	= 0;
	end
end

//存储器端口信号
//mem_valid端口信号
always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		reset_cnt <= 0;
	end 
	else begin
		if(current_state == `CACHE_RESET)
			if(reset_cnt != `NUM_SET)
				reset_cnt <= reset_cnt + 1;
			else
				reset_cnt <= 0;
		else
			reset_cnt <= 0;
	end
end
assign valid_mem_en = current_state == `CACHE_RESET || agent_req_en || i_coherence_valid || valid_rd_wr;
assign valid_rd_wr = current_state == `CACHE_RESET || coherence_hit_reg || agent_req_miss;
assign valid_addr = current_state == `CACHE_RESET ? reset_cnt : coherence_hit_reg ? {25'b0, i_coherence_addr_reg_reg[12:6]} : agent_req_miss ? {25'b0, agent_req_addr_reg_reg[12:6]} : set_index;
assign valid_data_in = current_state == `CACHE_RESET ? 0 : valid_in_reg;

//mem_tag端口信号
assign tag_mem_en = agent_req_en || i_coherence_valid || agent_req_miss;
assign tag_rd_wr  = agent_req_miss;
assign tag_addr   = agent_req_miss ? {25'b0, agent_req_addr_reg_reg[12:6]} : set_index;
generate
	for(k = 0; k < `NUM_WAY; k = k + 1) begin: data_in
		assign tag_data_in[32*(k+1)-1 : 32*k] = tag_in_reg[k];
	end
endgenerate

//mem_dat端口信号
always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		miss_valid_cnt <= 0;
	end
	else if(miss_valid_cnt == LINE_SIZE - 1) begin
		miss_valid_cnt <= 0;
	end
	else if(mem_read_valid) begin
		miss_valid_cnt <= miss_valid_cnt + 1;
	end
	else begin
		miss_valid_cnt <= miss_valid_cnt;
	end
end

assign dat_mem_en = (current_state == `CACHE_WORK && agent_req_en_reg_reg) || mem_read_valid;
assign dat_rd_wr  = (current_state == `CACHE_WORK && agent_req_en_reg_reg && agent_req_wr_reg_reg) || mem_read_valid;
assign dat_addr   = mem_read_valid ? (agent_req_addr_reg_reg[12:6] * LINE_SIZE + miss_valid_cnt) : (agent_req_addr_reg_reg / (DATA_WDT/8) % (`NUM_SET*LINE_SIZE));
assign dat_data_in = dat_in_reg;
/*------------------------------------------------------------------------
						Memory Read or Write End
------------------------------------------------------------------------*/

/*------------------------------------------------------------------------
						Pseudo LRU Replace Start
------------------------------------------------------------------------*/
assign lru_data_out = (agent_req_addr_reg[12:6] == agent_req_addr_reg_reg[12:6]) ? lru_in_reg : mem_lru[agent_req_addr_reg[12:6]]; //读写相同地址时，读的即为写的内容
always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		lru_out_reg <= 0;
	end
	else begin
		lru_out_reg <= lru_data_out;
	end
end

always @(*) begin
	case (way_index)
		3'd0 : begin lru_in_reg[6] = 1;
					 lru_in_reg[5] = lru_out_reg[5];
					 lru_in_reg[4] = 1;
					 lru_in_reg[3] = lru_out_reg[3];
					 lru_in_reg[2] = lru_out_reg[2];
					 lru_in_reg[1] = lru_out_reg[1];
					 lru_in_reg[0] = 1;
				end
		3'd1 : begin lru_in_reg[6] = 1;
					 lru_in_reg[5] = lru_out_reg[5];
					 lru_in_reg[4] = 1;
					 lru_in_reg[3] = lru_out_reg[3];
					 lru_in_reg[2] = lru_out_reg[2];
					 lru_in_reg[1] = lru_out_reg[1];
					 lru_in_reg[0] = 0;
				end
		3'd2 : begin lru_in_reg[6] = 1;
					 lru_in_reg[5] = lru_out_reg[5];
					 lru_in_reg[4] = 0;
					 lru_in_reg[3] = lru_out_reg[3];
					 lru_in_reg[2] = lru_out_reg[2];
					 lru_in_reg[1] = 1;
					 lru_in_reg[0] = lru_out_reg[0];
				end
		3'd3 : begin lru_in_reg[6] = 1;
					 lru_in_reg[5] = lru_out_reg[5];
					 lru_in_reg[4] = 0;
					 lru_in_reg[3] = lru_out_reg[3];
					 lru_in_reg[2] = lru_out_reg[2];
					 lru_in_reg[1] = 0;
					 lru_in_reg[0] = lru_out_reg[0];
				end
		3'd4 : begin lru_in_reg[6] = 0;
					 lru_in_reg[5] = 1;
					 lru_in_reg[4] = lru_out_reg[4];
					 lru_in_reg[3] = lru_out_reg[3];
					 lru_in_reg[2] = 1;
					 lru_in_reg[1] = lru_out_reg[1];
					 lru_in_reg[0] = lru_out_reg[0];
				end
		3'd5 : begin lru_in_reg[6] = 0;
					 lru_in_reg[5] = 1;
					 lru_in_reg[4] = lru_out_reg[4];
					 lru_in_reg[3] = lru_out_reg[3];
					 lru_in_reg[2] = 0;
					 lru_in_reg[1] = lru_out_reg[1];
					 lru_in_reg[0] = lru_out_reg[0];
				end
		3'd6 : begin lru_in_reg[6] = 0;
					 lru_in_reg[5] = 0;
					 lru_in_reg[4] = lru_out_reg[4];
					 lru_in_reg[3] = 1;
					 lru_in_reg[2] = lru_out_reg[2];
					 lru_in_reg[1] = lru_out_reg[1];
					 lru_in_reg[0] = lru_out_reg[0];
				end
		3'd7 : begin lru_in_reg[6] = 0;
					 lru_in_reg[5] = 0;
					 lru_in_reg[4] = lru_out_reg[4];
					 lru_in_reg[3] = 0;
					 lru_in_reg[2] = lru_out_reg[2];
					 lru_in_reg[1] = lru_out_reg[1];
					 lru_in_reg[0] = lru_out_reg[0];
				end
		default : begin lru_in_reg[6] = 0;
					 	lru_in_reg[5] = 0;
					 	lru_in_reg[4] = 0;
					 	lru_in_reg[3] = 0;
					 	lru_in_reg[2] = 0;
					 	lru_in_reg[1] = 0;
					 	lru_in_reg[0] = 0;
				end
	endcase
end

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		for (i = 0; i < 128; i = i + 1) begin
			mem_lru[i] <= 0;
		end
	end
	else if(agent_req_en_reg_reg) begin
		mem_lru[agent_req_addr_reg_reg[12:6]] <= lru_in_reg;
	end
	else begin
		for (i = 0; i < 128; i = i + 1) begin
			mem_lru[i] <= mem_lru[i];
		end
	end
end
/*------------------------------------------------------------------------
						Pseudo LRU Replace End
------------------------------------------------------------------------*/

endmodule