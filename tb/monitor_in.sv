class my_monitor_in extends uvm_monitor;

	`uvm_component_utils(my_monitor_in)	
	
	function new(string name = "my_monitor_in", uvm_component parent);
		super.new(name, parent);
	endfunction
	
	virtual dut_if dut_vif;
	
	uvm_analysis_port #(my_tran) ap;

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		ap = new("ap", this);

		if( !uvm_config_db#(virtual dut_if)::get(this, "", "dut_vif", dut_vif) )
		`uvm_error("","uvm_config_db::get failed");
	endfunction

	task run_phase(uvm_phase phase);
		my_tran tr;
		@(dut_vif.mon_cb);
		wait(dut_vif.reset == 1'b0);
		
		forever begin
			
			tr = my_tran::type_id::create("tr");
			tr.data = new[1];
			@(dut_vif.mon_cb);	
			
			if(!dut_vif.reset) begin
				tr.data[0] = dut_vif.mon_cb.rx_data;
				ap.write(tr);
			end
			
		end

	endtask
endclass