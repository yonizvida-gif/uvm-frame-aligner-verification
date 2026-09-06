//--------------------------------------------------------------
//--------------------------------------------------------------
//  Frame aligner block . Implementation of the frame aligner
//  Algorithm.
//  Author: Ilan Rachmanov   


module frame_aligner(clk, rx_data , reset , fr_byte_position , frame_detect) ;

   output [3:0]  fr_byte_position; // byte position in a legal frame
   output frame_detect;            // frame alignment indication

   input  clk;
   input  [7:0] rx_data;
   input  reset;


   reg [3:0] fr_byte_position;
   reg [1:0] legal_frame_counter;
   reg [5:0] na_byte_counter;
   reg 	     frame_detect;
   reg [7:0] header_lsb_samp;
   
   // FSM control triggers
   reg 	     fr_byte_position_rst;
   reg 	     na_byte_count_inc, na_byte_count_rst;
   reg 	     legal_frame_counter_rst , legal_frame_counter_inc;

   
   typedef enum reg [1:0] {FR_IDLE = 2'b00,
			   FR_HLSB = 2'b01,
			   FR_HMSB = 2'b10,
			   FR_DATA = 2'b11
			   } frame_aligner_state_e;
   
   frame_aligner_state_e current_state , next_state;

   wire   header_msb_valid , header_lsb_valid;

   //--------------------------------------------------------------
   //--------------------------------------------------------------
   // Frame Aligner state machine
   
   always @ (posedge clk or  posedge reset)
     begin
	if (reset)
	  current_state <= FR_IDLE;
	else
	  current_state <= next_state;
     end

       
   
   always @ (*)
     begin
	fr_byte_position_rst = 1'b0;
	na_byte_count_inc = 1'b0;
	na_byte_count_rst = 1'b0;
	legal_frame_counter_rst = 1'b0;
	legal_frame_counter_inc = 1'b0;

	case(current_state)
	  FR_IDLE:
	    begin
	       if(header_lsb_valid)
		 begin
		    fr_byte_position_rst = 1'b1;
		    na_byte_count_inc = 1'b1;
		    next_state = FR_HLSB;
		 end
	       else
		 begin
		    legal_frame_counter_rst = 1'b1;
		    fr_byte_position_rst = 1'b1;
		    na_byte_count_inc = 1'b1;
		    next_state = FR_IDLE;
		 end
	    end
	  FR_HLSB:
	    begin
	    /*if(header_lsb_valid) //added by YonatanR
		 begin
		    fr_byte_position_rst = 1'b1;
		    na_byte_count_inc = 1'b1;
		    next_state = FR_HLSB;
		 end		//Added by YonatanR */
		/*else*/ if(header_msb_valid) //added else YonatanR
		 begin
		    legal_frame_counter_inc = 1'b1;
		    next_state = FR_HMSB;
		 end
	       else
		 begin
			//fr_byte_position_rst = 1'b1; //added by YonatanR
		    legal_frame_counter_rst = 1'b1;
		    na_byte_count_inc = 1'b1;
		    next_state = FR_IDLE;
		 end
	    end
	  FR_HMSB:
	    begin
			//na_byte_count_rst = 1'b1; //added by YonatanR
	       next_state = FR_DATA;
	    end
	  FR_DATA:
	    begin
	       if(fr_byte_position == 8'd10)
		 begin
		    na_byte_count_rst = 1'b1;
		    next_state = FR_IDLE;
		 end
	       else
		 next_state = FR_DATA;
	    end
	endcase
	  
     end
   
   //--------------------------------------------------------------
   //--------------------------------------------------------------
	
   // The code below searches the header pattern and send indications to the FSM to advance to FR_HLSB and FR_HMSB states
   // first the lsb pattern is sampled . in case the msb pattern matches , the FSM will advance to FR_HMSB
   assign header_lsb_valid = (rx_data == 8'haa) || (rx_data == 8'h55);
   
     always @ (posedge clk or  posedge reset)
       begin
	  if (reset)
	    header_lsb_samp <= 8'h0; 
	  else if (header_lsb_valid)
	    header_lsb_samp <= rx_data;
       end

   /// expected lsb header pattern:
   wire [7:0] expected_header_msb = (header_lsb_samp == 8'haa) ? 8'haf : ( (header_lsb_samp == 8'h55) ? 8'hba : 8'h00); // 00 is illegal since header_lsb_samp can be only 55 or aa
   
   assign header_msb_valid = (expected_header_msb == rx_data);
   
   //--------------------------------------------------------------
   //--------------------------------------------------------------
   
   // The code below is implementation of the legal frame counter ,  byte position  . and not aligned byte counter which accepts triggeres from the FSM


   //  fr_byte_position increments by default , reset is controlled by the fsm
   always @ (posedge clk or  posedge reset)
     begin
	if (reset)
	  fr_byte_position <= 4'h0;
	else if (fr_byte_position_rst)
	  fr_byte_position <= 4'h0;
	else
	  fr_byte_position <= fr_byte_position + 1'b1;
     end

   // frame counter for legal frames
   always @ (posedge clk or  posedge reset)
     begin
	if (reset)
	  legal_frame_counter <= 2'h0;
	else if (legal_frame_counter_rst)
	  legal_frame_counter <= 2'h0;
	else if (legal_frame_counter_inc)
	  legal_frame_counter <= legal_frame_counter + 1'b1 ;
	
     end
   
   // na_byte_counter is counting the illegal frames . in case there are 48 continues bytes witout header frame_detect will set low
     always @ (posedge clk or  posedge reset)
       begin
	  if (reset) 
	    na_byte_counter <= 6'h0;
	  else if (na_byte_count_rst)
	    na_byte_counter <= 6'h0;
	  else if (na_byte_count_inc)
	    na_byte_counter <= na_byte_counter + 1'b1;
       end
   
   always @ (posedge clk or  posedge reset)
     begin
	if (reset)
	  frame_detect <= 1'b0;
	else if(legal_frame_counter == 2'h3)
	  frame_detect <= 1'b1;
	else if(na_byte_counter == 6'd47) //&& next_state != 2) //&& next state condition added by YonatanR
	  frame_detect <= 1'b0;
     end


   //--------------------------------------------------------------
   //--------------------------------------------------------------
   
   
endmodule
