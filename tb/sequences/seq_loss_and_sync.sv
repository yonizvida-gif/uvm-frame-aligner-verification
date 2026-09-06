class seq_loss_and_sync extends uvm_sequence #(my_tran);

	`uvm_object_utils(seq_loss_and_sync)

	function new(string name = "seq_loss_and_sync");
		super.new(name);
	endfunction

	task body();
	
		req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind == ILLEGAL_HEADER; } ) `uvm_fatal("LOSS AND SYNC","RAND1 FAILED")
		
		finish_item(req);
		
		repeat(4) begin
			req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind inside {HEADER_1, HEADER_2}; } ) `uvm_fatal("LOSS AND SYNC","RAND2 FAILED")
		
			finish_item(req);
		end
		
		repeat(4) begin
			req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind == ILLEGAL_HEADER; header == 16'h1212; data.size() == 10; data[9] == 8'h00; } } ) `uvm_fatal("LOSS AND SYNC","RAND3 FAILED")
		
			finish_item(req);
		end
		
		
		repeat(3) begin
			req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind inside {HEADER_1, HEADER_2}; } ) `uvm_fatal("LOSS AND SYNC","RAND4 FAILED")
		
			finish_item(req);
		end
	
	endtask
	
	
endclass
