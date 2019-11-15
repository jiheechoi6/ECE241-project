
module control(input clk, resetn, plt_key, clear, go, 
		input [7:0] CounterX
		input [6:0] CounterY,
		input [5:0] counter_plt, 
		output reg ld_y, ld_clr, plot, enable_plt, enable_blk);
	
	reg [2:0] current_state, next_state;

	localparam S0 = 3'b0,
	S1= 3'b001,
	S1_WAIT = 3'b010,
	S2= 3'b011,
	DRAW= 3'b100,
	BLK= 3'b101;

	//next state logic
	always@(*)
	begin: state_table
		case(current_state)
			S0: begin
			if (go == 1'b1) next_state = S1;
			if (go ==1'b0) next_state = S0; 
			end
			S1: next_state = go ? S1: S1_WAIT;
			S1_WAIT: begin
				if (clear == 1'b1) next_state = BLK;
				if (plt_key == 1'b1) next_state = S2;
				else if (resetn == 1'b0) next_state = S1_WAIT;
			end
			S2: next_state = DRAW;
			DRAW: begin
				if (counter_plt <= 6'd15) next_state = DRAW;
				else next_state= S1_WAIT;
				end
			BLK : begin
				//next_state = (CounterX == 8'd160 & CounterY == 7'd120) ? S1_WAIT : BLK;
				if(CounterX != 8'd160 & CounterY != 7'd120) next_state = BLK;
				else next_state = S1_WAIT;
			end
			default: next_state= S1_WAIT;
		endcase
	end 

	//control signals
	always@(*)
	begin: enable_signals
	//reset all enable signals
	//ld_x =1'b0;
	ld_y = 1'b0;
	ld_clr= 1'b0; 
	plot = 1'b0; 
	enable_plt = 1'b0;
	enable_blk = 1'b0;
	
	case(current_state)
		//S1: ld_x = 1'b1;
		S2: begin
			ld_y= 1'b1;
			ld_clr= 1'b1;
		end
		DRAW: begin
			plot = 1'b1;
			enable_plt = 1'b1;
			ld_clr = 1'b1;
		end
		BLK: begin
			plot = 1'b1;
			enable_blk = 1'b1;
		end
	endcase
	end

	// current_state registers
    	always@(posedge clk)
    	begin: state_FFs
        	if(!resetn)
            		current_state <= S1_WAIT;
			else if (clear)
					current_state <= BLK;
        	else
            	current_state <= next_state;
    	end // state_FFS
	

endmodule 


module position (
	input go_up,
	input go_down,
	input clk,
	input frame,
	input resetn,
	output reg [7:0] y
	// output reg writeEn
	);
	
	localparam S_SATIONARY =3'd0,
			   S_MOVE_UP   =3'd1,
			   S_MOVE_DOWN =3'd2,
	
	reg [2:0] current_state, next_state;
	reg up_done, down_done;
		
	// next state logic
	always @(*) begin
		case(current_state)
			S_SATIONARY: next_state = (go_up&&(y>8'd48)) ? S_MOVE_UP : ((go_down&&(y<8'd138)) ? S_MOVE_DOWN : (grab ? S_HOOK_EXTENTION : S_SATIONARY));
			S_MOVE_UP: next_state = up_done ? S_SATIONARY : S_MOVE_UP;
			S_MOVE_DOWN : next_state = down_done ? S_SATIONARY : S_MOVE_DOWN;
			default: next_state = S_SATIONARY;
		endcase
	end
	
	
	//enable signals
	always@ (posedge clk) begin
		if (!resetn) begin
			y <= 8'd120 - 8'b1;
			up_done <= 0;
			down_done <= 0;
		end 
		
		else begin
			case(current_state)
				S_SATIONARY: 
				begin 
					up_done <= 0;
					down_done <= 0;
				end
				
				S_MOVE_UP: if(frame) 
				begin
					y <= y - 8'd2;
					up_done <= 1;
				end 
				
				S_MOVE_DOWN: if(frame) 
				begin 
					y <= y + 8'd2;
					down_done <= 1;
				end
				
			endcase
		
		end 
		
	end 
	
	// current_state registers
    always@(posedge clk)
    begin
        if(!resetn)
            current_state <= S_SATIONARY;
        else
            current_state <= next_state;
    end 
	
endmodule 
