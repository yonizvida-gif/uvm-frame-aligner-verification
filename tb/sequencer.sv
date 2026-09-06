class my_seqr extends uvm_sequencer #(my_tran);
	`uvm_component_utils(my_seqr)
	
	function new(string name = "my_seqr", uvm_component parent);
		super.new(name,parent);
	endfunction	
	
	
endclass