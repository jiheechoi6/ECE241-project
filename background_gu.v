//gu for background needs a ram with img imf in datapath

module background_gu
	(
		frame,
		clk,						
		resetn,
		plot,
		
		colour_out,
		x_out,
		y_out,
		writeEn,
		done
	);
	input			frame;
	input			clk;
	input			resetn;
	input			plot;
	// Declare your inputs and outputs here
	output	[2:0]	colour_out;
	output	[8:0]	x_out;
	output	[7:0]	y_out;	
	output			writeEn;
	output			done;

	
	wire [8:0] x_increment;
	wire [7:0] y_increment;
	
	finite_state_machine f1(
		.plot(plot),
		.clk(clk),
		.resetn(resetn),
		.writeEn(writeEn),
		.x_increment(x_increment),
		.y_increment(y_increment),
		.done(done)
	);
	
	tl_data_path dp1(
		.frame(frame),
		.resetn(resetn),
		.clk(clk),
		.x_increment(x_increment),
		.y_increment(y_increment),
		
		.x_out(x_out),
		.y_out(y_out),
		.colour_out(colour_out)
	);
	
endmodule

module finite_state_machine(
		input plot,
		input clk,
		input resetn,
		output reg writeEn,
		output reg [8:0] x_increment,  //320
		output reg [7:0] y_increment,  //240
		output reg done
	);
	
	reg [4:0] current_state, next_state;
	
	reg [8:0] black_x_counter; // count to 160 pixel
 	reg [7:0] black_y_counter; // count to 120 pixel
	
	localparam 		S_RESET			= 5'd0,
					S_BLACK         = 5'd1,
					S_BLACK_X       = 5'd2,
					S_BLACK_Y       = 5'd3,
					S_DONE			= 5'd4;
					 
	
	always@(*)
    begin: state_table 
            case (current_state)
				S_RESET: next_state = plot ? S_BLACK : S_RESET;
				S_BLACK: next_state = (black_y_counter <= 8'd240) ? S_BLACK_X : S_DONE;
				S_BLACK_X: next_state = (black_x_counter <= 9'd320) ? S_BLACK : S_BLACK_Y;
				S_BLACK_Y: next_state = S_BLACK;
				S_DONE:	next_state = S_RESET;
				
            default:     next_state = S_RESET;
		endcase
    end // state_table
	 
	 
	
	always @(*)
    begin: enable_signals
        // By default make all our signals 0
		writeEn = 1'b0;
		x_increment = 9'b0;
		y_increment = 8'b0;
		done = 1'b0;
		
        case (current_state)
			S_BLACK: begin
				x_increment = black_x_counter;
				y_increment = black_y_counter;
			end
			S_BLACK_X : begin writeEn = 1'b1; end
			S_DONE : begin done = 1'b1; end
			
        endcase
    end 
	 
   always @(posedge clk)
   begin
      if(!resetn || (current_state == S_BLACK_Y) || (current_state == S_RESET))
	      black_x_counter <= 9'b0;
	  if (current_state == S_BLACK_X)
	      black_x_counter <= black_x_counter + 9'b1;
   end
   
   always @(posedge clk)
   begin
      if(!resetn || (current_state == S_RESET))
	      black_y_counter <= 8'b0;
	  if (current_state == S_BLACK_Y)
	      black_y_counter <= black_y_counter + 8'b1;
   end
   
    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state <= S_RESET;
        else
            current_state <= next_state;
    end // state_FFS
	
endmodule

module tl_data_path(
		input frame,
		input resetn,
		input clk,
	
		input [8:0] x_increment, // 320*240
		input [7:0] y_increment, // 320*240
		
		output reg [8:0] x_out,
		output reg [7:0] y_out,
		output [2:0] colour_out
	);
	
	reg [8:0] bg_offset;
	
	always@(posedge clk) begin
		if(frame)begin
			if(!resetn|(bg_offset==9'd91))
				bg_offset <= 9'd47;
			else
				bg_offset <= bg_offset + 9'd2;
		end
	end
	wire [17:0] address;
	assign address = bg_offset + x_increment + y_increment * 10'd640;
	background_image bi1(address,clk,3'b0,1'b0,colour_out);	
	
	
	always@(posedge clk) begin
		if(!resetn) begin
			x_out <= 9'b0;
			y_out <= 8'b0;
			//colour_out <= 3'b0;
		end
		else begin
				x_out <= x_increment;
				y_out <= y_increment;
			//	colour_out <= 3'b000; //set in to blk temp
		end
	end
endmodule
