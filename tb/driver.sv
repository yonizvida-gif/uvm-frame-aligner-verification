class my_driver extends uvm_driver #(my_tran);

	`uvm_component_utils(my_driver)	
	
	function new(string name = "my_driver", uvm_component parent);
		super.new(name, parent);
	endfunction
	
	virtual dut_if dut_vif;

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		
		if( !uvm_config_db#(virtual dut_if)::get(this, "", "dut_vif", dut_vif) )
		`uvm_error("","uvm_config_db::get failed");
	endfunction

	task run_phase(uvm_phase phase);
		@(dut_vif.drv_cb);
		wait(dut_vif.reset == 1'b0);

		forever begin
			
			seq_item_port.get_next_item(req);
			
			@(dut_vif.drv_cb);
			dut_vif.drv_cb.rx_data <= req.header[7:0];
			
			@(dut_vif.drv_cb);
			dut_vif.drv_cb.rx_data <= req.header[15:8];
			
			foreach (req.data[i]) begin
				@(dut_vif.drv_cb);
				dut_vif.drv_cb.rx_data <= req.data[i];
			end
			
			seq_item_port.item_done();
			
		end

	endtask
endclass