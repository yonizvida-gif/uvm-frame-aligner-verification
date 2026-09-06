class my_env extends uvm_env;
	
	`uvm_component_utils(my_env)
	
	
	my_agent_in agent_in;
	my_agent_out agent_out;
	my_scoreboard scor;
	my_cover cov;
	
	function new(string name = "my_env", uvm_component parent);
		super.new(name, parent);
	endfunction
	
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		
		agent_in = my_agent_in::type_id::create("agent_in", this);
		agent_out = my_agent_out::type_id::create("agent_out", this);
		scor = my_scoreboard::type_id::create("scor", this);
		cov = my_cover::type_id::create("cov", this);
		
	endfunction
	
	function void connect_phase(uvm_phase phase);
		
		agent_in.mon_in.ap.connect(scor.in_fifo.analysis_export);
		agent_in.mon_in.ap.connect(cov.in_fifo.analysis_export);

		agent_out.mon_out.ap.connect(scor.out_fifo.analysis_export);
		agent_out.mon_out.ap.connect(cov.out_fifo.analysis_export);
	endfunction


endclass
