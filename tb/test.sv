class my_test extends uvm_test;
	`uvm_component_utils(my_test)
	
	my_env env;
	
	function new(string name = "my_test", uvm_component parent);
		super.new(name, parent);
	endfunction
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		env = my_env::type_id::create("env", this);
	endfunction
	
	task run_phase(uvm_phase phase);

		master_seq seq;
	
		phase.raise_objection(this);

		seq = master_seq::type_id::create("seq");
		if(!seq.randomize()) `uvm_fatal("TEST", "num tran rand failed")
		seq.print();
		seq.start(env.agent_in.seqr);




		phase.drop_objection(this);
	endtask

endclass
	
