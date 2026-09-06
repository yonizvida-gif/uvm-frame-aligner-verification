class my_agent_out extends uvm_agent;

	`uvm_component_utils(my_agent_out)

	my_monitor_out mon_out;

	function new(string name = "my_agent_out", uvm_component parent);
		super.new(name, parent);
	endfunction
	
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		mon_out = my_monitor_out::type_id::create("mon_out", this);
	endfunction

endclass