class seq_overlap_loss_sync extends uvm_sequence #(my_tran);

	`uvm_object_utils(seq_overlap_loss_sync)

	function new(string name = "seq_overlap_loss_sync");
		super.new(name);
	endfunction

	task body();
	
		req = my_tran::type_id::create("req");
		start_item(req);

		if(!req.randomize() with { header_kind == ILLEGAL_HEADER; } ) `uvm_fatal("OVERLAP LOSS SYNC","RAND1 FAILED")
		
		finish_item(req);
		
		repeat(3) begin
			req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind inside {HEADER_1, HEADER_2}; } ) `uvm_fatal("OVERLAP LOSS SYNC","RAND2 FAILED")
		
			finish_item(req);
		end
		
		
		repeat(3) begin
			req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind == ILLEGAL_HEADER; header == 16'h1212; data.size() == 10; data[9] == 8'h00; foreach(data[i]){data[i] != 8'hAA; data[i] != 8'h55;} }) `uvm_fatal("OVERLAP LOSS SYNC","RAND3 FAILED")
		
			finish_item(req);
		end

		repeat(1) begin
			req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind == ILLEGAL_HEADER; header == 16'hFFFF; data.size() == 10; data[9] == 8'h55; foreach(data[i]){if(i != 9){data[i] != 8'hAA; data[i] != 8'h55; }} }) `uvm_fatal("OVERLAP LOSS SYNC","RAND4 FAILED")
		
			finish_item(req);
		end
		
		repeat(1) begin
			req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind ==  HEADER_1; } ) `uvm_fatal("OVERLAP LOSS SYNC","RAND5 FAILED")
		
			finish_item(req);
		end
		
		repeat(3) begin
			req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind inside {HEADER_1, HEADER_2}; } ) `uvm_fatal("OVERLAP LOSS SYNC","RAND6 FAILED")
		
			finish_item(req);
		end
		
		repeat(3) begin
			req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind == ILLEGAL_HEADER; header == 16'h1212; data.size() == 10; data[9] == 8'h00; foreach(data[i]){data[i] != 8'hAA; data[i] != 8'h55;} }) `uvm_fatal("OVERLAP LOSS SYNC","RAND7 FAILED")
		
			finish_item(req);
		end

		repeat(1) begin
			req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind == ILLEGAL_HEADER; header == 16'hFFFF; data.size() == 10; data[9] == 8'hAA; foreach(data[i]){if(i != 9){data[i] != 8'hAA; data[i] != 8'h55; }}}) `uvm_fatal("OVERLAP LOSS SYNC","RAND8 FAILED")
		
			finish_item(req);
		end
		
		repeat(1) begin
			req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind ==  HEADER_2; } ) `uvm_fatal("OVERLAP LOSS SYNC","RAND9 FAILED")
		
			finish_item(req);
		end
		
		repeat(4) begin
			req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind inside {HEADER_1, HEADER_2}; } ) `uvm_fatal("OVERLAP LOSS SYNC","RAND10 FAILED")
		
			finish_item(req);
		end
	
	endtask
	
	
endclass
