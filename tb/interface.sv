interface dut_if(input logic clk, reset);

	logic [7:0] rx_data;
	logic       frame_detect;
	logic [3:0] fr_byte_position;


	//Clocking Block 
    	clocking mon_cb @(posedge clk);
      		default input #1ns output #1ns;
      		input rx_data, fr_byte_position, frame_detect;  
   	 endclocking

	clocking drv_cb @(negedge clk);
      		default input #1ns output #1ns; 
		output rx_data;
    	endclocking
	
	modport dut_mp(
		input rx_data,
		output fr_byte_position, frame_detect
	);



	property reset_out;
		@(posedge clk) reset |-> (fr_byte_position == 4'd0) && (frame_detect == 1'b0);
	endproperty

	p1: assert property(reset_out);

	
	property legal_byte_position;
		@(posedge clk) disable iff(reset) fr_byte_position <= 4'd11;
	endproperty
	
	p2: assert property(legal_byte_position);

	

	sequence first_header;
		(!frame_detect && rx_data == 8'hAA  ##1 !frame_detect && rx_data == 8'hAF) or (!frame_detect && rx_data == 8'h55  ##1 !frame_detect && rx_data == 8'hBA);
	endsequence

	sequence header_seq;
		(!frame_detect && rx_data == 8'hAA && fr_byte_position == 4'd11 ##1 !frame_detect && rx_data == 8'hAF) or (!frame_detect && rx_data == 8'h55 && fr_byte_position == 4'd11 ##1 !frame_detect && 			rx_data == 8'hBA);
	endsequence
	
	sequence first_frame;
		first_header ##1 (!frame_detect)[*10];
	endsequence

	sequence seq_frame;
		header_seq ##1 (!frame_detect)[*10];
	endsequence
	
	sequence seq_3_legal_headers;
		first_frame ##1 seq_frame ##1 header_seq;
	endsequence
	
	
	property get_sync;
		@(posedge clk) disable iff(reset) seq_3_legal_headers |-> ##2 frame_detect;
	endproperty

	p3: assert property(get_sync)
	else $error("assert p3",$sformatf("at %0t",$time));



	sequence legal_header_in_sync;
		((frame_detect && rx_data == 8'hAA && fr_byte_position == 4'd11) ##1 (frame_detect && rx_data == 8'hAF)) or ((frame_detect && rx_data == 8'h55 && fr_byte_position == 4'd11) ##1 (frame_detect && 			rx_data == 8'hBA));
	endsequence

	sequence bad_msb_in_sync;
		((frame_detect && rx_data == 8'hAA  ##1 frame_detect && rx_data != 8'hAF) or (frame_detect && rx_data == 8'h55  ##1 frame_detect && rx_data != 8'hBA)) ##1 1'b1[*10];
	endsequence
	
	sequence bad_lsb_in_sync;
		(frame_detect && rx_data != 8'h55 && rx_data != 8'hAA) ##1 1'b1[*11];
	endsequence
	
	sequence bad_frame_in_sync;
		bad_lsb_in_sync or bad_msb_in_sync;
	endsequence
	
	sequence seq_4_bad_while_in_sync;
		legal_header_in_sync ##11 bad_frame_in_sync ##1 bad_frame_in_sync ##1 bad_frame_in_sync ##1 bad_frame_in_sync;
	endsequence
	
	property loss_sync_while_in_sync;
		@(posedge clk) disable iff(reset) seq_4_bad_while_in_sync |-> ##2 !frame_detect;
	endproperty
	
	p4: assert property(loss_sync_while_in_sync);
	

	
	sequence seq_4_bad_after_get_sync;
		seq_3_legal_headers ##11 bad_frame_in_sync ##1 bad_frame_in_sync ##1 bad_frame_in_sync ##1 bad_frame_in_sync;
	endsequence
	
	property loss_sync_after_get_sync;
		@(posedge clk) disable iff(reset) seq_4_bad_after_get_sync |-> ##2 !frame_detect;
	endproperty
	
	p5: assert property(loss_sync_after_get_sync);



	property byte_position_sync;
		@(posedge clk) disable iff(reset) legal_header_in_sync |->
        	(fr_byte_position == 4'd0)
		##1 (fr_byte_position == 4'd1)
		##1 (fr_byte_position == 4'd2)
		##1 (fr_byte_position == 4'd3)
		##1 (fr_byte_position == 4'd4)
		##1 (fr_byte_position == 4'd5)
		##1 (fr_byte_position == 4'd6)
		##1 (fr_byte_position == 4'd7)
		##1 (fr_byte_position == 4'd8)
		##1 (fr_byte_position == 4'd9)
		##1 (fr_byte_position == 4'd10)
		##1 (fr_byte_position == 4'd11);
	endproperty
	
	p6: assert property(byte_position_sync)
	else $error("assert p6",$sformatf("at %0t",$time));
	
	property byte_position_without_sync;
		@(posedge clk) disable iff(reset) header_seq |->
        	(fr_byte_position == 4'd0)
		##1 (fr_byte_position == 4'd1)
		##1 (fr_byte_position == 4'd2)
		##1 (fr_byte_position == 4'd3)
		##1 (fr_byte_position == 4'd4)
		##1 (fr_byte_position == 4'd5)
		##1 (fr_byte_position == 4'd6)
		##1 (fr_byte_position == 4'd7)
		##1 (fr_byte_position == 4'd8)
		##1 (fr_byte_position == 4'd9)
		##1 (fr_byte_position == 4'd10)
		##1 (fr_byte_position == 4'd11);
	endproperty

	p7: assert property(byte_position_without_sync)
	else $error("assert p7",$sformatf("at %0t",$time));



	sequence bad_lsb_in_next_frame;
		legal_header_in_sync ##11 (frame_detect && rx_data != 8'hAA && rx_data != 8'h55);
	endsequence
	
	sequence bad_msb_in_next_frame;
		legal_header_in_sync ##11 (((frame_detect && rx_data == 8'hAA) ##1 (frame_detect && rx_data != 8'hAF)) or ((frame_detect && rx_data == 8'h55) ##1 (frame_detect && rx_data != 8'hBA)));
	endsequence
	
	property bad_lsb_keeps_position_zero;
		@(posedge clk) disable iff(reset)
		bad_lsb_in_next_frame |-> (fr_byte_position == 4'd11) ##1 (fr_byte_position == 4'd0)[*11];
	endproperty

	p8: assert property(bad_lsb_keeps_position_zero);
	
	
	property bad_msb_keeps_position_zero;
		@(posedge clk) disable iff(reset)
		//bad_msb_in_next_frame |=> (fr_byte_position == 4'd1) ##1 (fr_byte_position == 4'd0)[*9]; 
		bad_msb_in_next_frame |-> (fr_byte_position == 4'd0) ##1 (fr_byte_position == 4'd0)[*10];
	endproperty

	p9: assert property(bad_msb_keeps_position_zero)
	else $error("assert p9",$sformatf("at %0t",$time));
	

	sequence overlap1;
		(!frame_detect && rx_data == 8'h55 && fr_byte_position == 4'd0) ##1 (!frame_detect && rx_data == 8'hAA) ##1 (!frame_detect && rx_data == 8'hAF);
	endsequence
	
	sequence overlap2;
		(!frame_detect && rx_data == 8'hAA && fr_byte_position == 4'd0) ##1 (!frame_detect && rx_data == 8'h55) ##1 (!frame_detect && rx_data == 8'hBA);
	endsequence
	
	sequence overlap;
		overlap1 or overlap2;
	endsequence
	
	property overlap_check;
		@(posedge clk) disable iff(reset)
		overlap |=> fr_byte_position == 4'd1;
	endproperty

	p10: assert property(overlap_check);



	property outputs_not_unknown;
		@(posedge clk) disable iff(reset) !$isunknown({frame_detect, fr_byte_position});
	endproperty

	p11: assert property(outputs_not_unknown);

endinterface
