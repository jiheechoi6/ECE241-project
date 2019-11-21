module prince_move (
	
	input go_up,
	input go_down,
	input clk,
	input frame,
	input resetn,
	output reg [7:0] y
	);
	
	localparam S_SATIONARY =3'd0,
			   S_MOVE_UP   =3'd1,
			   S_MOVE_DOWN =3'd2;
	
	reg [2:0]current_state, next_state;
	reg up_done, down_done;
		
	// next state logic
	always @(*) 
	begin
		case(current_state)
			S_SATIONARY: next_state = (go_up&&(y>8'd48)) ? S_MOVE_UP : ((go_down&&(y<8'd138)) ? S_MOVE_DOWN : S_SATIONARY);
			S_MOVE_UP: next_state = up_done ? S_SATIONARY : S_MOVE_UP;
			S_MOVE_DOWN : next_state = down_done ? S_SATIONARY : S_MOVE_DOWN;
			default: next_state = S_SATIONARY;
		endcase
	end
	
	
	//enable signals
	always@ (posedge clk) 
	begin
		if (!resetn) begin
			y <= 8'd120 - 8'b1;
			up_done <= 0;
			down_done <= 0;
		end 
		
		else 
		begin
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
