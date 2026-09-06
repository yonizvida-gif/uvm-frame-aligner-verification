class seq_overlap_in_sync extends uvm_sequence #(my_tran);

	`uvm_object_utils(seq_overlap_in_sync)

	function new(string name = "seq_overlap_in_sync");
		super.new(name);
	endfunction

	task body();
	
		req = my_tran::type_id::create("req");
		start_item(req);

		if(!req.randomize() with { header_kind == ILLEGAL_HEADER; } ) `uvm_fatal("OVERLAP IN SYNC","RAND1 FAILED")
		
		finish_item(req);
		
		repeat(3) begin
			req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind inside {HEADER_1, HEADER_2}; } ) `uvm_fatal("OVERLAP IN SYNC","RAND2 FAILED")
		
			finish_item(req);
		end
		
		
		repeat(1) begin
			req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind == ILLEGAL_HEADER; header == 16'h1212; data.size() == 10; data[9] == 8'h55; foreach(data[i]){if(i != 9){data[i] != 8'hAA; data[i] != 8'h55; }} } ) `uvm_fatal("OVERLAP IN SYNC","RAND3 FAILED")
		
			finish_item(req);
		end
		
		repeat(1) begin
			req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind == HEADER_1; data.size() == 10; data[9] == 8'hAA; foreach(data[i]){if(i != 9){data[i] != 8'h55; data[i] != 8'hAA; }} } ) `uvm_fatal("OVERLAP IN SYNC","RAND4 FAILED")
		
			finish_item(req);
		end
		
		repeat(1) begin
			req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind == HEADER_2; data.size() == 10; foreach(data[i]){data[i] != 8'h55; data[i] != 8'hAA; } } ) `uvm_fatal("OVERLAP IN SYNC","RAND5 FAILED")
		
			finish_item(req);
		end
		
		repeat(4) begin
			req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind inside {HEADER_1, HEADER_2}; foreach(data[i]){data[i] != 8'h55; data[i] != 8'hAA; } } ) `uvm_fatal("OVERLAP IN SYNC","RAND6 FAILED")
		
			finish_item(req);
		end
	
	endtask
	
	
endclass
