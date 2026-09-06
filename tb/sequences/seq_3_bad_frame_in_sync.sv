class seq_3_bad_frame extends uvm_sequence #(my_tran);

	`uvm_object_utils(seq_3_bad_frame)

	function new(string name = "seq_3_bad_frame");
		super.new(name);
	endfunction

	task body();
	
		req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind == ILLEGAL_HEADER; data.size() == 5; } ) `uvm_fatal("3 BAD FRAME","RAND1 FAILED")
		
		finish_item(req);
		
		repeat(4) begin
			req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind == HEADER_1; } ) `uvm_fatal("3 BAD FRAME","RAND2 FAILED")
		
			finish_item(req);
		end
		
		repeat(3) begin
			req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind == ILLEGAL_HEADER; header == 16'h1212; data.size() == 10; foreach(data[i]){ data[i] != 8'hAA; data[i] !=  8'hAF; data[i] != 8'h55; data[i] !=  8'hBA; } }) `uvm_fatal("3 BAD FRAME","RAND3 FAILED")
		
			finish_item(req);
		end
		

		
		repeat(1) begin
			req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind == HEADER_1; } ) `uvm_fatal("3 BAD FRAME","RAND4 FAILED")
		
			finish_item(req);
		end
		
		repeat(3) begin
			req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind == ILLEGAL_HEADER; header == 16'h1212; data.size() == 10; foreach(data[i]){ data[i] != 8'hAA; data[i] !=  8'hAF; data[i] != 8'h55; data[i] !=  8'hBA; } }) `uvm_fatal("3 BAD FRAME","RAND5 FAILED")
		
			finish_item(req);
		end
		
		repeat(2) begin
			req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind == HEADER_2; } ) `uvm_fatal("3 BAD FRAME","RAND6 FAILED")
		
			finish_item(req);
		end
	
	endtask
	
	
endclass
