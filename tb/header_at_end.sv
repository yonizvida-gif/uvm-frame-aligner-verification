class seq_header_at_end extends uvm_sequence #(my_tran);

	`uvm_object_utils(seq_header_at_end)

	function new(string name = "seq_header_at_end");
		super.new(name);
	endfunction

	task body();
	
		req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind == ILLEGAL_HEADER; data.size() == 5; } ) `uvm_fatal("HEADER AT END","RAND1 FAILED")
		
		finish_item(req);
		
		repeat(3) begin
			req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind inside {HEADER_1, HEADER_2}; } ) `uvm_fatal("HEADER AT END","RAND2 FAILED")
		
			finish_item(req);
		end
		
		repeat(1) begin
			req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind == ILLEGAL_HEADER; header == 16'h1212; data.size() == 44; foreach(data[i]) {data[i] != 8'hAA; data[i] != 8'h55;} } ) `uvm_fatal("HEADER AT END","RAND3 FAILED")
		
			finish_item(req);
		end
		
		req = my_tran::type_id::create("req");
		start_item(req);

		if(!req.randomize() with { header_kind inside {HEADER_1, HEADER_2}; } ) `uvm_fatal("HEADER AT END","RAND4 FAILED")
		
		finish_item(req);

	endtask
	
	
endclass
