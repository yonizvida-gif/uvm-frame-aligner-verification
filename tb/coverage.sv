class my_cover extends uvm_component;
	`uvm_component_utils(my_cover)
	
	uvm_tlm_analysis_fifo #(my_tran) in_fifo;
    	uvm_tlm_analysis_fifo #(my_tran) out_fifo;
	
	function new(string name = "my_cover", uvm_component parent);
		super.new(name, parent);

		cg = new(); 
		cg_bad_tran = new();
		cg_good_tran = new();
		cg_sync_tran = new();
	endfunction
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);	
		
		in_fifo  = new("in_fifo", this);
        	out_fifo = new("out_fifo", this);
	endfunction

	logic frame_detect, prev_frame_detect;
	logic [3:0] byte_position, prev_byte_position;
	logic [7:0] rx_data, prev_rx_data;
	
	int good_frame;
	int bad_frame;
	bit good_header;
	bit bad_header;
	bit wait_msb;
	bit frame_header;
	int payload;
	bit good_frame_event;


	covergroup cg;

		cp_detect: coverpoint frame_detect{
			bins no_sync = {0};
			bins sync    = {1};
		}
		
		cp_detect_tr: coverpoint frame_detect{
			bins sync             = (0 => 1);
			bins loss_sync        = (1 => 0);
			bins sync_one_frame   = (1[*12]);
			bins sync_four_frames = (1[*48]);
		}

		cp_data: coverpoint rx_data{
			bins header1_lsb = {8'hAA};
			bins header1_msb = {8'hAF};
			bins header2_lsb = {8'h55};
			bins header2_msb = {8'hBA};
			bins other = default;
		}
		
		data_sync: cross cp_detect,cp_data;
		
		
		cp_byte_position: coverpoint byte_position{
			bins valid[] = {[0:11]};
			illegal_bins invalid = {[12:15]};
		}
		
		detect_position: cross cp_detect, cp_byte_position;
		
		cp_sync_frame: coverpoint byte_position iff(frame_detect){
			bins full_frame = (0 => 1 => 2 => 3 => 4 => 5 => 6 => 7 => 8 => 9 => 10 => 11);
		}
		
		header_tran: coverpoint rx_data{
			bins header1   = (8'hAA => 8'hAF);
			bins header2   = (8'h55 => 8'hBA);
		}
		
		header_at_frame_start: coverpoint {prev_rx_data, rx_data}  iff(byte_position == 4'd0 && prev_byte_position == 4'd11){
			bins header1 = {16'hAAAF};
			bins header2 = {16'h55BA};
		}
		
		double_lsb: coverpoint rx_data{
			bins lsb_12 = (8'hAA => 8'h55);
			bins lsb_21 = (8'h55 => 8'hAA);
		}
		
		overlap: coverpoint rx_data {
			bins header1_overlap = (8'h55 => 8'hAA => 8'hAF);
			bins header2_overlap = (8'hAA => 8'h55 => 8'hBA);
		}
		
		overlap_before: coverpoint rx_data iff(!frame_detect) {
			bins header1_overlap = (8'h55 => 8'hAA => 8'hAF);
			bins header2_overlap = (8'hAA => 8'h55 => 8'hBA);
		}
		
		
		lsb_in_payload: coverpoint rx_data iff(frame_detect == 1'b1 && byte_position > 4'd0 && byte_position < 4'd11){
			bins lsb1 = {8'hAA};
			bins lsb2 = {8'h55};
		}
		
		header_in_payload: coverpoint {prev_rx_data, rx_data} iff(frame_detect == 1'b1 && byte_position > 4'd1 && byte_position < 4'd11){
			bins header1 = {16'hAAAF};
			bins header2 = {16'h55BA};
		}
		
		header_check_1: coverpoint rx_data iff(frame_detect == 1'b1 && prev_byte_position == 4'd11 && byte_position == 4'd0 && prev_rx_data == 8'hAA){
			bins good_msb = {8'hAF};
			bins bad_msb  = default;
		}
		
		header_check_2: coverpoint rx_data iff(frame_detect == 1'b1 && prev_byte_position == 4'd11 && byte_position == 4'd0 && prev_rx_data == 8'h55) {
			bins good_msb = {8'hBA};
			bins bad_msb  = default;
		}
		
		cp_good_frame: coverpoint good_frame iff(good_header){
			bins frame1 = {1};
			bins frame2 = {2};
			bins frame3 = {3};
		}
		
		cp_bad_frame: coverpoint bad_frame iff(bad_header && frame_detect){
			bins bad_frame1 = {1};
			bins bad_frame2 = {2};
			bins bad_frame3 = {3};
			bins bad_frame4 = {4};
		}
		
			
	endgroup
	
	covergroup cg_bad_tran;
		cp_bad_frame_tran: coverpoint bad_frame{
			bins bad_frame1 = (1 => 2 => 3 => 4);
			bins bad_frame2 = (1 => 2 => 3 => 0 => 1 => 2 => 3 => 4);
			bins bad_frame3 = (1 => 2 => 0 => 1 => 2 => 3 => 4);
			bins bad_frame4 = (1 => 2 => 3 => 0 => 1 => 2 => 3);
		}
	endgroup
	
	
	covergroup cg_good_tran;
		cp_good_frame_tran: coverpoint good_frame{
			bins good_frame1 = (1 => 2 => 3);
			bins good_frame2 = (1 => 2 => 0 => 1 => 2 => 3);
			bins good_frame3 = (1 => 0 => 1 => 2 => 3);
		}
	endgroup
	
	
	covergroup cg_sync_tran;
		cp_sync_loss: coverpoint frame_detect {
			bins loss = (1 => 0);
			bins reacquire = (1 => 0 => 1);
			bins reacquire_twice = (1 => 0 => 1 => 0 => 1);
		}
	endgroup
	
	task run_phase(uvm_phase phase);
		my_tran tr_in;
		my_tran tr_out;
		
		prev_rx_data       = 8'h00;
		prev_byte_position = 4'd0;
		prev_frame_detect = 1'b0;
		
		good_header = 1'b0;
		good_frame  = 0;
		bad_frame = 0;
		payload = 0;
		wait_msb = 1'b0;
		bad_header = 1'b0;
		frame_header = 1'b0;
		good_frame_event = 1'b0;
		
		forever begin
			in_fifo.get(tr_in);
			out_fifo.get(tr_out);
			
			rx_data       = tr_in.data[0];
			frame_detect  = tr_out.frame_detect;
			byte_position = tr_out.fr_byte_position;

			good_header = 1'b0;
			bad_header = 1'b0;
			frame_header = 1'b0;
			good_frame_event = 1'b0;
			
			if((prev_byte_position == 4'd11 && byte_position == 4'd0) || (prev_byte_position == 4'd0  && byte_position == 4'd0)) begin
				if(!frame_detect) begin
					
					if({rx_data, prev_rx_data} == 16'hAFAA || {rx_data, prev_rx_data} == 16'hBA55) begin

						good_header = 1'b1;
						
						
						if(good_frame < 3) begin
							good_frame++;
							good_frame_event = 1'b1;
						end
						if(good_frame == 3) begin
							payload = 9;
						end

					end
					else begin
						if(good_frame > 0) begin
							good_frame = 0;
							good_frame_event = 1'b1;
						end
					end
				end
			end
			
			
			if(frame_detect) begin
				good_frame = 0;
				if(payload > 0) begin
					payload--;
				end
				else if(wait_msb) begin
					frame_header = 1'b1;
					wait_msb = 0;
					if((prev_rx_data == 8'hAA && rx_data == 8'hAF) || (prev_rx_data == 8'h55 && rx_data == 8'hBA)) begin
						bad_frame = 0;
					end
					else begin
						bad_frame++;
						bad_header = 1'b1;
					end
					payload = 10;
				end
				else begin
					if(rx_data == 8'hAA || rx_data == 8'h55) begin
						wait_msb = 1;
					end
					else begin
						bad_frame++;
						bad_header = 1'b1;
						payload = 11;
						frame_header = 1'b1;
					end	
				end

			end
			else begin
				bad_frame = 0;
				wait_msb = 0;
			end
			
			cg.sample();
			
			if(frame_header) begin
				cg_bad_tran.sample();
			end
			
			if(good_frame_event) begin
				cg_good_tran.sample();
			end
			
			if(frame_detect != prev_frame_detect) begin
				cg_sync_tran.sample();
			end
			prev_frame_detect = frame_detect;
			prev_rx_data = rx_data;
			prev_byte_position = byte_position;
		
		end
	
	endtask

endclass
