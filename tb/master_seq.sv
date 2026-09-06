class master_seq extends uvm_sequence #(my_tran);
    	`uvm_object_utils(master_seq)
    
	seq_header_at_end           seq1;
	seq_3_bad_frame             seq2;
	seq_bad_between_good        seq3;
	seq_bad_msb                 seq4;
	seq_header_inside_payload   seq5;
	seq_overlap                 seq6;
	seq_loss_and_sync           seq7;
	seq_overlap_in_sync         seq8;
	seq_overlap_loss_sync       seq9;
	seq_header_inside_payload_2 seq10;
	seq_random_stress           seq11;

   	rand int seq_select;
	
    	rand int num_loops;
	
	bit check_one = 1'b0; //1'b1 for one simulation and 1'b0 for random simulation
	
    	constraint c_loops { if(check_one){
				num_loops == 1;
			}
			else{
				num_loops inside {[20000:40000]};
			}
	}

	constraint c_seq { seq_select inside {[0:10]}; }
	
   	function new(string name = "master_seq");
       		super.new(name);
    	endfunction

    	task body();
		
        	repeat(num_loops) begin
			
			if(!this.randomize(seq_select)) `uvm_fatal("MASTER_SEQ", "seq_select randomization failed")
			
			if(check_one) begin
				case(6)
				
					0: begin
						seq1 = seq_header_at_end::type_id::create("seq1");
						if(!seq1.randomize()) `uvm_fatal("TEST", "seq1 rand failed")
						seq1.start(m_sequencer);
					end
				
					1: begin
						seq2 = seq_3_bad_frame::type_id::create("seq2");
						if(!seq2.randomize()) `uvm_fatal("TEST", "seq2 rand failed")
						seq2.start(m_sequencer);
					end
				
					2: begin
						seq3 = seq_bad_between_good::type_id::create("seq3");
						if(!seq3.randomize()) `uvm_fatal("TEST", "seq3 rand failed")
						seq3.start(m_sequencer);
					end
				
					3: begin
						seq4 = seq_bad_msb::type_id::create("seq4");
						if(!seq4.randomize()) `uvm_fatal("TEST", "seq4 rand failed")
						seq4.start(m_sequencer);
					end
				
					4: begin
						seq5 = seq_header_inside_payload::type_id::create("seq5"); 
						if(!seq5.randomize()) `uvm_fatal("TEST", "seq5 rand failed")
						seq5.start(m_sequencer);
					end
				
					5: begin
						seq6 = seq_overlap::type_id::create("seq6");
						if(!seq6.randomize()) `uvm_fatal("TEST", "seq6 rand failed")
						seq6.start(m_sequencer);
					end
					
					6: begin
						seq7 = seq_loss_and_sync::type_id::create("seq7");
						if(!seq7.randomize()) `uvm_fatal("TEST", "seq7 rand failed")
						seq7.start(m_sequencer);
					end

					7: begin
						seq8 = seq_overlap_in_sync::type_id::create("seq8");
						if(!seq8.randomize()) `uvm_fatal("TEST", "seq8 rand failed")
						seq8.start(m_sequencer);
					end
					
					8: begin
						seq9 = seq_overlap_loss_sync::type_id::create("seq9");
						if(!seq9.randomize()) `uvm_fatal("TEST", "seq9 rand failed")
						seq9.start(m_sequencer);
					end

					9: begin
						seq10 = seq_header_inside_payload_2::type_id::create("seq10");
						if(!seq10.randomize()) `uvm_fatal("TEST", "seq10 rand failed")
						seq10.start(m_sequencer);
					end
					
					10: begin
						seq11 = seq_random_stress::type_id::create("seq11");
						if(!seq11.randomize()) `uvm_fatal("TEST", "seq11 rand failed")
						seq11.start(m_sequencer);
					end
				endcase
			end
			else begin
				case(seq_select)
				
					0: begin
						seq1 = seq_header_at_end::type_id::create("seq1");
						if(!seq1.randomize()) `uvm_fatal("TEST", "seq1 rand failed")
						seq1.start(m_sequencer);
					end
				
					1: begin
						seq2 = seq_3_bad_frame::type_id::create("seq2");
						if(!seq2.randomize()) `uvm_fatal("TEST", "seq2 rand failed")
						seq2.start(m_sequencer);
					end
				
					2: begin
						seq3 = seq_bad_between_good::type_id::create("seq3");
						if(!seq3.randomize()) `uvm_fatal("TEST", "seq3 rand failed")
						seq3.start(m_sequencer);
					end
				
					3: begin
						seq4 = seq_bad_msb::type_id::create("seq4");
						if(!seq4.randomize()) `uvm_fatal("TEST", "seq4 rand failed")
						seq4.start(m_sequencer);
					end
				
					4: begin
						seq5 = seq_header_inside_payload::type_id::create("seq5"); 
						if(!seq5.randomize()) `uvm_fatal("TEST", "seq5 rand failed")
						seq5.start(m_sequencer);
					end
				
					5: begin
						seq6 = seq_overlap::type_id::create("seq6");
						if(!seq6.randomize()) `uvm_fatal("TEST", "seq6 rand failed")
						seq6.start(m_sequencer);
					end
					
					6: begin
						seq7 = seq_loss_and_sync::type_id::create("seq7");
						if(!seq7.randomize()) `uvm_fatal("TEST", "seq7 rand failed")
						seq7.start(m_sequencer);
					end

					7: begin
						seq8 = seq_overlap_in_sync::type_id::create("seq8");
						if(!seq8.randomize()) `uvm_fatal("TEST", "seq8 rand failed")
						seq8.start(m_sequencer);
					end
					
					8: begin
						seq9 = seq_overlap_loss_sync::type_id::create("seq9");
						if(!seq9.randomize()) `uvm_fatal("TEST", "seq9 rand failed")
						seq9.start(m_sequencer);
					end
					
					9: begin
						seq10 = seq_header_inside_payload_2::type_id::create("seq10");
						if(!seq10.randomize()) `uvm_fatal("TEST", "seq10 rand failed")
						seq10.start(m_sequencer);
					end
					
					10: begin
						seq11 = seq_random_stress::type_id::create("seq11");
						if(!seq11.randomize()) `uvm_fatal("TEST", "seq11 rand failed")
						seq11.start(m_sequencer);
					end
				endcase
			
			
			end
        	end
    	endtask
endclass
