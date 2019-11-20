// top module
module Project
	(
		CLOCK_50,						//	On Board 50 MHz
		KEY,
		SW,
		HEX0,
		HEX1,
		HEX2,
		HEX3,
		// Your inputs and outputs here
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);
	output [6:0] HEX0, HEX1, HEX2, HEX3;
	input			CLOCK_50;				//	50 MHz
	input	[3:0]	KEY;
	input	[9:0]	SW;
	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire resetn;
	reg go_up, go_down;
	reg go_up_buf, go_down_buf;
	reg restart;
	assign resetn = KEY[0] && !restart;
	
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.

	reg [2:0] colour;
	reg [8:0] x;
	reg [7:0] y;
	
	wire [1:0]	writeEn; 
	reg writeEn_vga;
	
	reg [10:0]	plot=1'b1; 
	wire [10:0] done;
	wire clk;
	wire frame; // empty for now
	
	DelayCounter dc(.clock(CLOCK_50), .reset_n(resetn), .maxcount(28'd833334), .enable(frame)); //60 fps
	
	assign clk = CLOCK_50;
	
	always@(posedge clk) begin
		go_up_buf <= ~KEY[3];
		go_down_buf <= ~KEY[2];
		
	end 
	
	always@(posedge clk) begin
		go_up <= go_up_buf;
		go_down <=go_down_buf;
	end
	
	//==========================================================
	wire [7:0] blitz_y;
	wire [7:0] plot_y_p;
	wire [8:0] plot_x_p;
	wire [2:0] colour_p;

	prince_move 	motion(go_up, go_down, clk, frame, resetn, blitz_y);
	prince_gu		p_gu(clk, blitz_y, resetn, plot[0], colour_p, plot_x_p, plot_y_p, writeEn[0], done[0]);

	
	// *background_gu  
	wire [8:0] plot_x_bg;
	wire [7:0] plot_y_bg;	
	wire [2:0] colour_bg ;
	background_gu bg_gu(frame,clk,resetn,plot[1],colour_bg,plot_x_bg,plot_y_bg,writeEn[1],done[1]);
	
	// *FSM
	reg [4:0] current_state, next_state;
	localparam  S_PLOT_WAIT	     		= 5'd0, 
				S_PLOT_BG	     		= 5'd1, 
				S_PLOT_BLITZ     		= 5'd2,

//			
//				
	always@(*)
   begin: state_table 
           case (current_state)
				S_PLOT_WAIT: next_state = (swap) ? S_PLOT_BG : S_PLOT_WAIT;
				S_PLOT_BG:	 next_state = done[1] ? S_PLOT_BLITZ : S_PLOT_BG;		
				S_PLOT_BLITZ: next_state = done[0] ? S_PLOT_WAIT : S_PLOT_BLITZ;
            default:     next_state = S_PLOT_WAIT;
		endcase
    end // state_table
	
	always@(*)
   begin
	plot = 19'b0;
			case (current_state)				
				S_PLOT_BG:	plot[10]=1'b1;
				S_PLOT_BLITZ: 	plot[0]=1'b1;
				default: plot = 19'b0;
			endcase
   end 

// current_state registers
    always@(posedge clk)
    begin
		if(SW[0] == 0)
		    current_state <= S_PLOT_WAIT;
        else
            current_state <= next_state;
    end 


	always@(posedge clk)
    begin
			case (current_state)
				S_PLOT_BG:	    	begin x=plot_x_bg; y=plot_y_bg; colour=colour_bg; writeEn_vga=writeEn[10];		end
				S_PLOT_BLITZ:   	begin x=plot_x_b;  y=plot_y_b;  colour=colour_b;  writeEn_vga=writeEn[0];  		end			
			endcase
    end 
	
	wire swap;
	
	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter_2buffers VGA(
			.frame(frame),
			.swap(swap),
			.resetn(KEY[0]),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn_vga),
			 //Signals for the DAC to drive the monitor. 
			.VGA_R(VGA_R), 
 			.VGA_G(VGA_G), 
 			.VGA_B(VGA_B), 
			.VGA_HS(VGA_HS), 
			.VGA_VS(VGA_VS), 
			.VGA_BLANK(VGA_BLANK_N), 
			.VGA_SYNC(VGA_SYNC_N), 
			.VGA_CLK(VGA_CLK));  	
			
 	defparam VGA.RESOLUTION = "160x120"; 
 	defparam VGA.MONOCHROME = "FALSE"; 
 	defparam VGA.BITS_PER_COLOUR_CHANNEL = 1; 
	defparam VGA.BACKGROUND_IMAGE = "background.mif"; 

	
	// Put your code here. Your code should produce signals x,y,colour and writeEn
	// for the VGA controller, in addition to any other functionality your design may require.
	
endmodule


//=====================================Delay counter======================================
module DelayCounter(clock, reset_n, maxcount, enable);
	input clock, reset_n;
	input [27:0] maxcount;
	output enable;
	reg [27:0] count;
	
	assign enable = (count == 0) ? (1'b1) : (1'b0);
		
	always @ (posedge clock, negedge reset_n)
	begin
		if (!reset_n)
			count <= 0;
		else if (count == (maxcount-28'b1))
			count <= 0;
		else
			count <= count + 1'b1;
	end

endmodule
