class seq_header_inside_payload extends uvm_sequence #(my_tran);

	`uvm_object_utils(seq_header_inside_payload)

	function new(string name = "seq_header_inside_payload");
		super.new(name);
	endfunction

	task body();
	
		req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind == ILLEGAL_HEADER; header == 16'h1212; data.size() == 5; } ) `uvm_fatal("HEADER IN PAYLOAD","RAND1 FAILED")
		
		finish_item(req);
		
		repeat(3) begin
			req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind inside {HEADER_1, HEADER_2}; } ) `uvm_fatal("HEADER IN PAYLOAD","RAND2 FAILED")
		
			finish_item(req);
		end
		
		repeat(1) begin
			req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind == ILLEGAL_HEADER; header == 16'h1212; data.size() == 10; data[5] == 8'hAA; data[6] ==  8'hAF; data[9] == 8'h00; }) `uvm_fatal("HEADER IN PAYLOAD","RAND3 FAILED")
		
			finish_item(req);
		end
		
		req = my_tran::type_id::create("req");
		start_item(req);

		if(!req.randomize() with { header_kind inside {HEADER_1, HEADER_2}; } ) `uvm_fatal("HEADER IN PAYLOAD","RAND4 FAILED")
		
		finish_item(req);
		
		repeat(1) begin
			req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind == ILLEGAL_HEADER; header == 16'h1212; data.size() == 10; data[5] == 8'h55; data[6] ==  8'hBA; data[9] == 8'h00; }) `uvm_fatal("HEADER IN PAYLOAD","RAND5 FAILED")
		
			finish_item(req);
		end

		repeat(1) begin
			req = my_tran::type_id::create("req");
			start_item(req);

			if(!req.randomize() with { header_kind == ILLEGAL_HEADER; header == 16'h1212; data.size() == 36; data[9] == 8'h00; data[21] == 8'h00; data[33] == 8'h00; }) `uvm_fatal("HEADER IN PAYLOAD","RAND6 FAILED")
		
			finish_item(req);
		end


	
	endtask
	
	
endclass
