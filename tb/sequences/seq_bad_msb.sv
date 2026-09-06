class seq_bad_msb extends uvm_sequence #(my_tran);

	`uvm_object_utils(seq_bad_msb)

	function new(string name = "seq_bad_msb");
		super.new(name);
	endfunction

	task body();
	
		req = my_tran::type_id::create("req");
		start_item(req);

		if(!req.randomize() with { header_kind == ILLEGAL_HEADER; data.size() == 5; } ) `uvm_fatal("BAD MSB","RAND1 FAILED")
		
		finish_item(req);
		//////////////////////////
		
		req = my_tran::type_id::create("req");
		start_item(req);

		if(!req.randomize() with { header_kind == ILLEGAL_HEADER; data.size() == 10; header == 16'hFFAA; } ) `uvm_fatal("BAD MSB","RAND2 FAILED")
		
		finish_item(req);
		//////////////////////////
		
		req = my_tran::type_id::create("req");
		start_item(req);
		
		if(!req.randomize() with { header_kind == ILLEGAL_HEADER; data.size() == 10; header == 16'hFF55; } ) `uvm_fatal("BAD MSB","RAND3 FAILED")
		
		finish_item(req);
		//////////////////////////
		
		repeat(3) begin
			req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind inside {HEADER_1, HEADER_2}; } ) `uvm_fatal("BAD MSB","RAND4 FAILED")
		
			finish_item(req);
		end
		//////////////////////////
		
		req = my_tran::type_id::create("req");
		start_item(req);

		if(!req.randomize() with { header_kind == ILLEGAL_HEADER; data.size() == 10; header == 16'hFF55; foreach(data[i]){data[i] != 8'hAA; data[i] != 8'h55; }} ) `uvm_fatal("BAD MSB","RAND5 FAILED")
		
		finish_item(req);
		//////////////////////////

		req = my_tran::type_id::create("req");
		start_item(req);

		if(!req.randomize() with { header_kind == ILLEGAL_HEADER; data.size() == 10; header == 16'hFFAA; foreach(data[i]){data[i] != 8'hAA; data[i] != 8'h55; }} ) `uvm_fatal("BAD MSB","RAND6 FAILED")
		
		finish_item(req);
		//////////////////////////
		
		req = my_tran::type_id::create("req");
		start_item(req);

		if(!req.randomize() with { header_kind == ILLEGAL_HEADER; data.size() == 10; header == 16'hFF55; foreach(data[i]){data[i] != 8'hAA; data[i] != 8'h55; }} ) `uvm_fatal("BAD MSB","RAND7 FAILED")
		
		finish_item(req);
		//////////////////////////
		
		req = my_tran::type_id::create("req");
		start_item(req);

		if(!req.randomize() with { header_kind == ILLEGAL_HEADER; data.size() == 10; header == 16'hFFAA; foreach(data[i]){data[i] != 8'hAA; data[i] != 8'h55; }} ) `uvm_fatal("BAD MSB","RAND8 FAILED")
		
		finish_item(req);
		//////////////////////////


		req = my_tran::type_id::create("req");
		start_item(req);

		if(!req.randomize() with { header_kind == ILLEGAL_HEADER; data.size() == 10; header == 16'h1212; foreach(data[i]){data[i] != 8'hAA; data[i] != 8'h55; }} ) `uvm_fatal("BAD MSB","RAND8 FAILED")
		
		finish_item(req);
		
	endtask
	
	
endclass
