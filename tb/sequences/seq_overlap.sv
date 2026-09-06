class seq_overlap extends uvm_sequence #(my_tran);

	`uvm_object_utils(seq_overlap)
	
	function new(string name = "seq_overlap");
		super.new(name);
	endfunction

	task body();
	
		req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind == ILLEGAL_HEADER; data.size() == 2; } ) `uvm_fatal("OVERLAP WITHOUT SYNC","RAND1 FAILED")
		
		finish_item(req);
		
		repeat(1) begin
			req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind == ILLEGAL_HEADER; header == 16'hAA55; data[0] == 8'hAF; data.size() == 11; } ) `uvm_fatal("OVERLAP WITHOUT SYNC","RAND2 FAILED")
		
			finish_item(req);
		end
		
		repeat(1) begin
			req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind == ILLEGAL_HEADER; header == 16'h55AA; data[0] == 8'hBA; data.size() == 11; } ) `uvm_fatal("OVERLAP WITHOUT SYNC","RAND3 FAILED")
		
			finish_item(req);
		end

		repeat(3) begin
			req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind inside {HEADER_1, HEADER_2}; } ) `uvm_fatal("OVERLAP WITHOUT SYNC","RAND4 FAILED")
		
			finish_item(req);
		end
	
	endtask
	
	
endclass

