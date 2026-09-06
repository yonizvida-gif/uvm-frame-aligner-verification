class seq_bad_between_good extends uvm_sequence #(my_tran);

	`uvm_object_utils(seq_bad_between_good)

	function new(string name = "seq_bad_between_good");
		super.new(name);
	endfunction

	task body();
	
		req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind == ILLEGAL_HEADER; data.size() == 5; } ) `uvm_fatal("BAD BETWEEN GOOD","RAND1 FAILED")
		
		finish_item(req);
		
		repeat(2) begin
			req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind inside {HEADER_1, HEADER_2}; } ) `uvm_fatal("BAD BETWEEN GOOD","RAND2 FAILED")
		
			finish_item(req);
		end
		
		repeat(1) begin
			req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind == ILLEGAL_HEADER; header == 16'h1212; data.size() == 1; data[0] != 8'h55; data[0] != 8'hAA; } ) `uvm_fatal("BAD BETWEEN GOOD","RAND3 FAILED")
		
			finish_item(req);
		end
		
		repeat(3) begin
			req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind inside {HEADER_1, HEADER_2}; } ) `uvm_fatal("BAD BETWEEN GOOD"," RAND4 FAILED")
		
			finish_item(req);
		end
	
	endtask
	
	
endclass
