class my_agent_in extends uvm_agent;

	`uvm_component_utils(my_agent_in)

	
	my_driver drv;
	my_seqr seqr;
	my_monitor_in mon_in;

	function new(string name = "my_agent_in", uvm_component parent);
		super.new(name, parent);
	endfunction
	
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		if(is_active == UVM_ACTIVE) begin
			drv = my_driver::type_id::create("drv", this);
			seqr = my_seqr::type_id::create("seqr", this);
		end

		mon_in = my_monitor_in::type_id::create("mon_in", this);
	endfunction


	function void connect_phase(uvm_phase phase);
		if(is_active == UVM_ACTIVE) begin
			drv.seq_item_port.connect(seqr.seq_item_export);
		end
	endfunction
endclass
