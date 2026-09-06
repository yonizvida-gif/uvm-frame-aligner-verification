class my_scoreboard extends uvm_scoreboard;
    	`uvm_component_utils(my_scoreboard)

   	uvm_tlm_analysis_fifo #(my_tran) in_fifo;
    	uvm_tlm_analysis_fifo #(my_tran) out_fifo;

	localparam header1_LSB = 8'hAA;
	localparam header1_MSB = 8'hAF;
	
	localparam header2_LSB = 8'h55;
	localparam header2_MSB = 8'hBA;

	logic [3:0] exp_byte_position;
	logic  exp_frame_detect;
	
	
	int error;
	int sample_count;
	
	logic [7:0] prev_rx_data;
	
	bit valid_lsb;
	int payload;
	logic [1:0] good_frame;

	int bad_bytes;
	bit flag;
	bit delay;
	bit bad_frame;


    function new(string name = "my_scoreboard", uvm_component parent);
        super.new(name, parent);
		
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
		
	in_fifo  = new("in_fifo", this);
        out_fifo = new("out_fifo", this);
    endfunction

	
	task run_phase(uvm_phase phase);
		
		my_tran tr_in;
		my_tran tr_out;

		error = 0;
		sample_count = 0;

		reset_ref_model();
		
		forever begin

			in_fifo.get(tr_in);
			out_fifo.get(tr_out);
			
			sample_count++;
			
			//if(tr_in.data.size() != 1) begin
				//`uvm_fatal("SCB_INPUT", $sformatf("Expected 1 input byte, got %0d bytes", tr_in.data.size()))
			//end
			
			check_output(tr_out);

			ref_model_step(tr_in.data[0]);
			
		end

	endtask
	
	function void reset_ref_model();

		exp_byte_position = 4'd0;
		exp_frame_detect  = 1'b0;
		
		payload = 0;
		valid_lsb = 0;
		prev_rx_data = 8'h00;
		good_frame = 2'b00;
		bad_bytes = 0;
		bad_frame = 1'b0;
		delay = 1'b0;
		flag = 1'b0;

	endfunction	
	
	function void check_output(my_tran actual);

		if(actual.fr_byte_position !== exp_byte_position) begin
			error++;
			
			`uvm_error("SCB_POS",
				$sformatf("SAMPLE=%0d | BYTE_POSITION MISMATCH | EXP=%0d ACT=%0d | DET=%0b | good=%0d bad=%0d payload=%0d valid_lsb=%0b bad_frame=%0b",
					sample_count,
					exp_byte_position,
					actual.fr_byte_position,
					exp_frame_detect,
					good_frame,
					bad_bytes,
					payload,
					valid_lsb,
					bad_frame
				)
			)

		end
	
	    if(actual.frame_detect !== exp_frame_detect) begin
			error++;
			`uvm_error("SCB_DETECT",
				$sformatf("SAMPLE=%0d | FRAME_DETECT MISMATCH | EXP=%0b ACT=%0b | POS_EXP=%0d POS_ACT=%0d | good=%0d bad=%0d payload=%0d delay=%0b",
					sample_count,
					exp_frame_detect,
					actual.frame_detect,
					exp_byte_position,
					actual.fr_byte_position,
					good_frame,
					bad_bytes,
					payload,
					delay
            )
        )

		end
		
		
		
		
	endfunction
	
	
	
	
	function void ref_model_step(logic [7:0] rx_data);
	
		if(delay) begin
			exp_frame_detect = 1'b0;
			exp_byte_position = 4'd0;
			delay = 1'b0;
			payload   = 0;
			bad_frame = 0;
			bad_bytes = 0;
			good_frame = 0;
			flag = 0;
			 valid_lsb = 1'b0;
		end
			
			
		if(payload > 0) begin
				
				
			
				
			if(payload == 10 && flag) begin
				flag = 1'b0;
				if(good_frame < 2'b11) begin
					good_frame++;
				end
				if(good_frame == 2'b11) begin
					exp_frame_detect = 1'b1;
				end
			end
									
			if(bad_frame) begin
				bad_bytes++;
				exp_byte_position = 4'h0;
			end
			else
				exp_byte_position++;
				
			if(payload == 1) begin
				bad_frame = 1'b0;
			end
			
			if(bad_bytes == 48) begin
				bad_bytes = 0;
				delay = 1'b1;
				bad_frame = 1'b0;
			end	
				
			payload--;
			
		end
		else begin
			if(!exp_frame_detect) begin
				if(!valid_lsb && rx_data != 8'hAA && rx_data != 8'h55) begin
					good_frame = 2'b00;
				end
				
				if(valid_lsb && prev_rx_data == 8'hAA) begin
					if(rx_data == 8'hAF) begin
						payload = 10;
						exp_byte_position++;
						valid_lsb = 1'b0;
						flag = 1'b1;
					end	
					else begin
						good_frame = 2'b00;
					end
			
				end
				else if(valid_lsb && prev_rx_data == 8'h55) begin
					if(rx_data == 8'hBA) begin
						valid_lsb = 1'b0;
						exp_byte_position++;
						payload = 10;
						flag = 1'b1;
					end
					else begin
						good_frame = 2'b00;
					end
				end
				
				
				
				if(rx_data == 8'hAA) begin
					valid_lsb = 1'b1;
					exp_byte_position = 4'h0;
				end
				else if(rx_data == 8'h55) begin
					valid_lsb = 1'b1;
					exp_byte_position = 4'h0;
				end
				else begin
					valid_lsb = 1'b0;
					if(!flag)
						exp_byte_position = 4'h0;
				end
			end
			else begin // in sync
				
				if(valid_lsb && prev_rx_data == 8'hAA) begin
					if(rx_data == 8'hAF) begin
						payload = 10;
						valid_lsb = 1'b0;
						exp_byte_position++;
						bad_bytes = 0;
						bad_frame = 1'b0;
						flag = 1'b1;
					end	
					else begin
						good_frame = 0;
						payload = 10;
						exp_byte_position = 4'h0;
						bad_frame = 1'b1;
						bad_bytes+=2;
						valid_lsb = 1'b0;
					end
			
				end
				else if(valid_lsb && prev_rx_data == 8'h55) begin
					if(rx_data == 8'hBA) begin
						valid_lsb = 1'b0;
						payload = 10;
						exp_byte_position++;
						bad_bytes = 0;
						bad_frame = 1'b0;
						flag = 1'b1;

					end
					else begin
						good_frame = 0;
						payload = 10;
						exp_byte_position = 4'h0;
						bad_frame = 1'b1;
						bad_bytes+=2;
						valid_lsb = 1'b0;
					end
				end
				else if(rx_data == 8'hAA) begin
					valid_lsb = 1'b1;
					exp_byte_position = 4'h0;
				end
				else if(rx_data == 8'h55) begin
					valid_lsb = 1'b1;
					exp_byte_position = 4'h0;
				end
				else begin
					bad_bytes++;
					valid_lsb = 1'b0;
					payload = 11;
					exp_byte_position = 4'h0;
					bad_frame = 1'b1;
					good_frame = 0;
				end
			end
				
			
		end
		
			prev_rx_data = rx_data;
	
	endfunction
	
	
	

	
	function void report_phase(uvm_phase phase);
		super.report_phase(phase);

		`uvm_info("SCB_SUMMARY",$sformatf("Checked %0d samples, errors = %0d",sample_count, error), UVM_LOW)
	endfunction
endclass
