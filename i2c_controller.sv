module i2c_master(		input		logic i_clk,
                        input		logic i_nrst,
                        input		logic [7:0]i_data_write,
                        input		logic [6:0]i_addr, 
                        input		logic i_start,
                        input		logic i_read_or_write,
                        input		logic [2:0]i_word_cnt,
                        inout		tri o_scl,
                        inout		tri o_sda
								);
								
typedef enum logic [3:0] {	        IDLE,
									START1,
									START2,
									START3,
									TRANS1,
									TRANS2,
									TRANS3,
									RD_ACK1,
									RD_ACK2,
									RD_ACK3,
									STOP1,
									STOP2,
									STOP3} state_type;
	
//=================================================================================================
//=================================================================================================
//  Signal declarations
//=================================================================================================
//=================================================================================================
state_type current_state;
state_type next_state;


logic [2:0]current_word_cntr, next_word_cntr;
logic current_ack, next_ack;
logic [3:0]current_bit_cntr, next_bit_cntr;
logic current_addr_or_data, next_addr_or_data; //used as select line for mux
logic current_buff1_wr_en, next_buff1_wr_en;
logic current_cnt_wr_en, next_cnt_wr_en;
logic current_shift_wr_en, next_shift_wr_en;

logic sda_int;
logic scl_int;
logic [7:0]shift_out_reg; 		//register to hold byte to be shifted out, it load from the output of addr_or_data mux
logic [2:0]word_cnt_reg;		//register to hold the number of bytes to be shifted out
logic [7:0]data_out_buffer;	//register to hold the data to be sent to i2c slave
logic [7:0]addr_cmd_buffer;	//register to hold the address and command to i2c slave
logic [7:0]addr_or_data_mux;	//output of mux the choose between data or address





//=================================================================================================
//=================================================================================================
// 				                    			 Structural coding
//=================================================================================================
//=================================================================================================

assign o_sda = sda_int ? 1'bz : 1'b0;
assign o_scl = scl_int ? 1'bz : 1'b0;


assign addr_or_data_mux = current_addr_or_data	? data_out_buffer : addr_cmd_buffer;

//===========================================================
//update data buffer with data to be shift out
//===========================================================
always_ff @(posedge i_clk, negedge i_nrst)
begin
	if(!i_nrst)
		data_out_buffer <= 8'b0;
	else if(current_buff1_wr_en)
		data_out_buffer <= i_data_write;
	else
		data_out_buffer <= data_out_buffer;
end

//===========================================================
//update addr/cmd buffer with address and command to be shift out
//===========================================================
always_ff @(posedge i_clk, negedge i_nrst)
begin
	if(!i_nrst)
		addr_cmd_buffer <= 8'b0;
	else if(current_buff1_wr_en)
		addr_cmd_buffer <= {i_addr,i_read_or_write};
	else
		addr_cmd_buffer <= addr_cmd_buffer;
end

//===========================================================
//update word count buffer with number of bytes to be shift out
//===========================================================
always_ff @(posedge i_clk, negedge i_nrst)
begin
	if(!i_nrst)
		word_cnt_reg <= 3'b0;
	else if(current_cnt_wr_en)
		word_cnt_reg <= i_word_cnt;
	else
		word_cnt_reg <= word_cnt_reg;
end

//===========================================================
//update the shift_out_reg with either address or byt
//===========================================================
always_ff @(posedge i_clk, negedge i_nrst)
begin
	if(!i_nrst)
		shift_out_reg <= 8'b0;
	else if(current_shift_wr_en)
		shift_out_reg <= addr_or_data_mux;
	else
		shift_out_reg <= shift_out_reg;
end

//===========================================================
//state register
//===========================================================
always_ff @(posedge i_clk, negedge i_nrst)
begin
	if(!i_nrst)
		current_state <= IDLE;
	else
		current_state <= next_state;
end

//===========================================================
//Update word counter register
//===========================================================
always_ff @(posedge i_clk, negedge i_nrst)
begin
	if(!i_nrst)
		current_word_cntr <= 3'b000;
	else
		current_word_cntr <= next_word_cntr;
end


//===========================================================
//Update wether dealing with sending address or data register
//===========================================================
always_ff @(posedge i_clk, negedge i_nrst)
begin
	if(!i_nrst)
		current_addr_or_data <= 1'b0; //select line resets to 8'b{addr,rd/wr};
	else
		current_addr_or_data <= next_addr_or_data;
end

//===========================================================
//Update value of current_ack flag register
//===========================================================
always_ff @(posedge i_clk, negedge i_nrst)
begin
	if(!i_nrst)
		current_ack <= 1'b1;
	else
		current_ack <= next_ack;
end

//===========================================================
//Update value of current_bit_cntr counter register
//===========================================================
always_ff @(posedge i_clk, negedge i_nrst)
begin
	if(!i_nrst)
		current_bit_cntr <= 4'b1000;
	else
		current_bit_cntr <= next_bit_cntr;
end

//===========================================================
//Update value of current_buff1_wr_en register
//===========================================================
always_ff @(posedge i_clk, negedge i_nrst)
begin
	if(!i_nrst)
		current_buff1_wr_en <= 1'b0;
	else
		current_buff1_wr_en <= next_buff1_wr_en;
end

//===========================================================
//Update value of current_cnt_wr_en register
//===========================================================
always_ff @(posedge i_clk, negedge i_nrst)
begin
	if(!i_nrst)
		current_cnt_wr_en <= 1'b0;
	else
		current_cnt_wr_en <= next_cnt_wr_en;
end

//===========================================================
//Update value of current_buff1_wr_en register
//===========================================================
always_ff @(posedge i_clk, negedge i_nrst)
begin
	if(!i_nrst)
		current_shift_wr_en <= 1'b0;
	else
		current_shift_wr_en <= next_shift_wr_en;
end


//===========================================================
//next_state logic and update registers and flags
//===========================================================
always_comb
begin
	next_word_cntr     = current_word_cntr;
	next_ack           = current_ack;
	next_bit_cntr      = current_bit_cntr;
	next_addr_or_data  = current_addr_or_data;
	next_buff1_wr_en   = current_buff1_wr_en;
	next_cnt_wr_en     = current_cnt_wr_en;
	next_shift_wr_en   = current_shift_wr_en;
    next_state          = current_state;
//============================================================
	case(current_state)
		IDLE:
		begin	
			next_word_cntr 	    = 3'b0;		//reset current word being shifted out
			next_ack			= 1'b1;		//reset acknowledge
			next_bit_cntr		= 4'b1000;	//reset the bit pointer to MSb
			next_addr_or_data   = 1'b0;		//reset flag to send addr before data
			next_buff1_wr_en	= 1'b0;		//reset write enable to 0 to update {address,cmd} and data.
			next_cnt_wr_en		= 1'b0;		//reset write enable to 0 to update count of bytes to be shifted out
			next_shift_wr_en	= 1'b0;		//reset write enable to 0 to update the register of bits to be shifted out	
			if(i_start)
				next_state 		= START1;
			else
				next_state		= IDLE;
		end
//============================================================		
		START1:
		begin
			next_buff1_wr_en	= 1'b1;     //record {address,cmd} and data
			next_cnt_wr_en		= 1'b1;      //record number of bytes to be shifted out
			next_state			= START2;
		end
//============================================================		
		START2:
		begin
			next_buff1_wr_en	= 1'b0;
			next_cnt_wr_en		= 1'b0;
			next_shift_wr_en	= 1'b1;     //put {address,cmd} on the tx_shifter
			next_state			= START3;
		end
//============================================================	
		START3:
		begin
			next_shift_wr_en	= 1'b0;
			next_state			= TRANS1;
		end
//============================================================	
		TRANS1:
		begin
			
			next_ack			= 1'b1;
			next_state			= TRANS2;
		end
//============================================================		
		TRANS2:
		begin
			next_state			= TRANS3;
		end
//============================================================		
		TRANS3:
		begin
			next_bit_cntr		= current_bit_cntr - 1'b1;
			if(current_bit_cntr == 4'b0001)
				next_state 		= RD_ACK1;
			else
				next_state		= TRANS1;
		end
//============================================================		
		RD_ACK1:
		begin
			next_bit_cntr		= 4'b1000;
			if(current_ack == 1'b1)
				next_state		= RD_ACK2;
			else
				next_state		= TRANS1;
		end
//============================================================		
		RD_ACK2:
		begin
			next_addr_or_data	= 1'b1;
			next_word_cntr		= current_word_cntr + 1'b1;
			next_state			= RD_ACK3;
		end
//============================================================		
		RD_ACK3:
		begin
			next_ack				= o_sda;
			next_shift_wr_en	= 1'b1;
			if(current_word_cntr < word_cnt_reg)
				next_state		= STOP1;
			else
				next_state		= RD_ACK1;
		end
//============================================================		
		STOP1:
		begin
			next_state			= STOP2;
		end
//============================================================		
		STOP2:
		begin
			next_state			= STOP3;
		end
//============================================================		
		STOP3:
		begin
			next_state			= IDLE;
		end
//============================================================		
	endcase
end	


//===========================================================
//next_state logic and update registers and flags
//===========================================================
always_comb
begin
    sda_int = 1'b1;
    scl_int = 1'b1;
//============================================================
	case(current_state)
		IDLE:
		begin
			sda_int = 1'b1;
			scl_int = 1'b1;
		end
//============================================================		
		START1:
		begin
			sda_int = 1'b0;
			scl_int = 1'b1;
		end
//============================================================		
		START2:
		begin
			sda_int = 1'b0;
			scl_int = 1'b0;
		end
//============================================================		
		START3:
		begin
			sda_int = 1'b0;
			scl_int = 1'b0;
		end
//============================================================		
		TRANS1:
		begin
			sda_int = shift_out_reg[current_bit_cntr - 1'b1];
			scl_int = 1'b0;
		end
//============================================================		
		TRANS2:
		begin
			sda_int = shift_out_reg[current_bit_cntr - 1'b1];
			scl_int = 1'b1;
		end
//============================================================		
		TRANS3:
		begin
			sda_int = shift_out_reg[current_bit_cntr - 1'b1];
			scl_int = 1'b0;
		end
//============================================================		
		RD_ACK1:
		begin
			sda_int = 1'b1;
			scl_int = 1'b0;
		end
//============================================================		
		RD_ACK2:
		begin
			sda_int = 1'b1;
			scl_int = 1'b1;
		end
//============================================================		
		RD_ACK3:
		begin
			sda_int = 1'b1;
			scl_int = 1'b1;
		end
//============================================================		
		STOP1:
		begin
			sda_int = 1'b0;
			scl_int = 1'b0;
		end
//============================================================		
		STOP2:
		begin
			sda_int = 1'b0;
			scl_int = 1'b1;
		end
//============================================================		
		STOP3:
		begin
			sda_int = 1'b1;
			scl_int = 1'b1;
		end
//============================================================		
	endcase
	
end


endmodule
		