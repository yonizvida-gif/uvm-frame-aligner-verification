//--------------------------------------------------------------
// Frame Aligner - Reference RTL
// Behavior matched to the UVM scoreboard reference model
//--------------------------------------------------------------

module frame_aligner (
    input  logic       clk,
    input  logic [7:0] rx_data,
    input  logic       reset,

    output logic [3:0] fr_byte_position,
    output logic       frame_detect
);

    localparam logic [7:0] HEADER1_LSB = 8'hAA;
    localparam logic [7:0] HEADER1_MSB = 8'hAF;

    localparam logic [7:0] HEADER2_LSB = 8'h55;
    localparam logic [7:0] HEADER2_MSB = 8'hBA;


    //----------------------------------------------------------
    // Internal state
    //----------------------------------------------------------

    logic [7:0] prev_rx_data;
    logic       valid_lsb;

    logic [3:0] payload;
    logic [1:0] good_frame;
    logic [5:0] bad_bytes;

    logic bad_frame;
    logic delay;
    logic flag;


    //----------------------------------------------------------
    // Next-state signals
    //----------------------------------------------------------

    logic [3:0] fr_byte_position_d;
    logic       frame_detect_d;

    logic [7:0] prev_rx_data_d;
    logic       valid_lsb_d;

    logic [3:0] payload_d;
    logic [1:0] good_frame_d;
    logic [5:0] bad_bytes_d;

    logic bad_frame_d;
    logic delay_d;
    logic flag_d;


    //----------------------------------------------------------
    // Reference-model combinational logic
    //----------------------------------------------------------

    always_comb begin

        //------------------------------------------------------
        // Hold current values by default
        //------------------------------------------------------

        fr_byte_position_d = fr_byte_position;
        frame_detect_d     = frame_detect;

        prev_rx_data_d     = prev_rx_data;
        valid_lsb_d        = valid_lsb;

        payload_d          = payload;
        good_frame_d       = good_frame;
        bad_bytes_d        = bad_bytes;

        bad_frame_d        = bad_frame;
        delay_d            = delay;
        flag_d             = flag;


        //------------------------------------------------------
        // Delayed loss of synchronization
        //------------------------------------------------------

        if (delay_d) begin

            frame_detect_d     = 1'b0;
            fr_byte_position_d = 4'd0;

            delay_d            = 1'b0;
            payload_d          = 4'd0;

            bad_frame_d        = 1'b0;
            bad_bytes_d        = 6'd0;

            good_frame_d       = 2'd0;

            flag_d             = 1'b0;
            valid_lsb_d        = 1'b0;

        end


        //------------------------------------------------------
        // Inside payload / remaining bytes of a frame
        //------------------------------------------------------

        if (payload_d > 0) begin


            //--------------------------------------------------
            // First payload byte after a legal header
            //--------------------------------------------------

            if ((payload_d == 4'd10) && flag_d) begin

                flag_d = 1'b0;

                if (good_frame_d < 2'd3)
                    good_frame_d = good_frame_d + 2'd1;

                //------------------------------------------------
                // Three consecutive legal frames -> synchronization
                //------------------------------------------------

                if (good_frame_d == 2'd3)
                    frame_detect_d = 1'b1;

            end


            //--------------------------------------------------
            // Bad frame:
            // ignore all bytes until frame boundary
            //--------------------------------------------------

            if (bad_frame_d) begin

                bad_bytes_d = bad_bytes_d + 6'd1;

                fr_byte_position_d = 4'd0;

            end

            //--------------------------------------------------
            // Legal frame
            //--------------------------------------------------

            else begin

                fr_byte_position_d =
                    fr_byte_position_d + 4'd1;

            end


            //--------------------------------------------------
            // Last byte of bad frame
            //--------------------------------------------------

            if (payload_d == 4'd1)
                bad_frame_d = 1'b0;


            //--------------------------------------------------
            // 48 consecutive bad bytes = four bad frames
            //--------------------------------------------------

            if (bad_bytes_d == 6'd48) begin

                bad_bytes_d = 6'd0;

                //------------------------------------------------
                // Do NOT lower frame_detect immediately.
                // Scoreboard expects delayed loss.
                //------------------------------------------------

                delay_d = 1'b1;

                bad_frame_d = 1'b0;

            end


            payload_d = payload_d - 4'd1;

        end


        //------------------------------------------------------
        // Not inside payload
        //------------------------------------------------------

        else begin

            //--------------------------------------------------
            // SEARCH MODE - not synchronized
            //--------------------------------------------------

            if (!frame_detect_d) begin


                //------------------------------------------------
                // Garbage byte breaks consecutive-good count
                //------------------------------------------------

                if (!valid_lsb_d &&
                    rx_data != HEADER1_LSB &&
                    rx_data != HEADER2_LSB) begin

                    good_frame_d = 2'd0;

                end


                //------------------------------------------------
                // Previous byte was AA
                //------------------------------------------------

                if (valid_lsb_d &&
                    prev_rx_data == HEADER1_LSB) begin

                    if (rx_data == HEADER1_MSB) begin

                        payload_d = 4'd10;

                        fr_byte_position_d =
                            fr_byte_position_d + 4'd1;

                        valid_lsb_d = 1'b0;

                        flag_d = 1'b1;

                    end

                    else begin

                        good_frame_d = 2'd0;

                    end

                end


                //------------------------------------------------
                // Previous byte was 55
                //------------------------------------------------

                else if (valid_lsb_d &&
                         prev_rx_data == HEADER2_LSB) begin

                    if (rx_data == HEADER2_MSB) begin

                        valid_lsb_d = 1'b0;

                        fr_byte_position_d =
                            fr_byte_position_d + 4'd1;

                        payload_d = 4'd10;

                        flag_d = 1'b1;

                    end

                    else begin

                        good_frame_d = 2'd0;

                    end

                end


                //------------------------------------------------
                // Current byte can immediately become next LSB.
                //
                // This preserves overlap:
                //
                // 55 AA AF
                //    AA AF
                //
                // AA 55 BA
                //    55 BA
                //------------------------------------------------

                if (rx_data == HEADER1_LSB) begin

                    valid_lsb_d = 1'b1;

                    fr_byte_position_d = 4'd0;

                end

                else if (rx_data == HEADER2_LSB) begin

                    valid_lsb_d = 1'b1;

                    fr_byte_position_d = 4'd0;

                end

                else begin

                    valid_lsb_d = 1'b0;

                    if (!flag_d)
                        fr_byte_position_d = 4'd0;

                end

            end


            //--------------------------------------------------
            // SYNCHRONIZED
            //--------------------------------------------------

            else begin


                //------------------------------------------------
                // Candidate Header1
                //------------------------------------------------

                if (valid_lsb_d &&
                    prev_rx_data == HEADER1_LSB) begin


                    //------------------------------------------------
                    // AA AF - legal header
                    //------------------------------------------------

                    if (rx_data == HEADER1_MSB) begin

                        payload_d = 4'd10;

                        valid_lsb_d = 1'b0;

                        fr_byte_position_d =
                            fr_byte_position_d + 4'd1;

                        //------------------------------------------------
                        // Legal frame resets bad-frame streak
                        //------------------------------------------------

                        bad_bytes_d = 6'd0;

                        bad_frame_d = 1'b0;

                        flag_d = 1'b1;

                    end


                    //------------------------------------------------
                    // AA + wrong MSB
                    //------------------------------------------------

                    else begin

                        good_frame_d = 2'd0;

                        payload_d = 4'd10;

                        fr_byte_position_d = 4'd0;

                        bad_frame_d = 1'b1;

                        //------------------------------------------------
                        // LSB + MSB already consumed
                        //------------------------------------------------

                        bad_bytes_d =
                            bad_bytes_d + 6'd2;

                        valid_lsb_d = 1'b0;

                    end

                end


                //------------------------------------------------
                // Candidate Header2
                //------------------------------------------------

                else if (valid_lsb_d &&
                         prev_rx_data == HEADER2_LSB) begin


                    //------------------------------------------------
                    // 55 BA - legal header
                    //------------------------------------------------

                    if (rx_data == HEADER2_MSB) begin

                        valid_lsb_d = 1'b0;

                        payload_d = 4'd10;

                        fr_byte_position_d =
                            fr_byte_position_d + 4'd1;

                        bad_bytes_d = 6'd0;

                        bad_frame_d = 1'b0;

                        flag_d = 1'b1;

                    end


                    //------------------------------------------------
                    // 55 + wrong MSB
                    //------------------------------------------------

                    else begin

                        good_frame_d = 2'd0;

                        payload_d = 4'd10;

                        fr_byte_position_d = 4'd0;

                        bad_frame_d = 1'b1;

                        bad_bytes_d =
                            bad_bytes_d + 6'd2;

                        valid_lsb_d = 1'b0;

                    end

                end


                //------------------------------------------------
                // Current byte is candidate LSB
                //------------------------------------------------

                else if (rx_data == HEADER1_LSB) begin

                    valid_lsb_d = 1'b1;

                    fr_byte_position_d = 4'd0;

                end

                else if (rx_data == HEADER2_LSB) begin

                    valid_lsb_d = 1'b1;

                    fr_byte_position_d = 4'd0;

                end


                //------------------------------------------------
                // Bad LSB
                //------------------------------------------------

                else begin

                    bad_bytes_d =
                        bad_bytes_d + 6'd1;

                    valid_lsb_d = 1'b0;

                    //------------------------------------------------
                    // Current byte + 11 remaining bytes
                    //------------------------------------------------

                    payload_d = 4'd11;

                    fr_byte_position_d = 4'd0;

                    bad_frame_d = 1'b1;

                    good_frame_d = 2'd0;

                end

            end

        end


        //------------------------------------------------------
        // Remember current RX byte
        //------------------------------------------------------

        prev_rx_data_d = rx_data;

    end


    //----------------------------------------------------------
    // Registers
    //----------------------------------------------------------

    always_ff @(posedge clk or posedge reset) begin

        if (reset) begin

            fr_byte_position <= 4'd0;
            frame_detect     <= 1'b0;

            prev_rx_data     <= 8'h00;

            valid_lsb        <= 1'b0;

            payload          <= 4'd0;

            good_frame       <= 2'd0;

            bad_bytes        <= 6'd0;

            bad_frame        <= 1'b0;

            delay            <= 1'b0;

            flag             <= 1'b0;

        end

        else begin

            //--------------------------------------------------
            // IMPORTANT:
            // No additional output-register stage here.
            //--------------------------------------------------

            fr_byte_position <= fr_byte_position_d;
            frame_detect     <= frame_detect_d;

            prev_rx_data     <= prev_rx_data_d;

            valid_lsb        <= valid_lsb_d;

            payload          <= payload_d;

            good_frame       <= good_frame_d;

            bad_bytes        <= bad_bytes_d;

            bad_frame        <= bad_frame_d;

            delay            <= delay_d;

            flag             <= flag_d;

        end

    end

endmodule//--------------------------------------------------------------
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
