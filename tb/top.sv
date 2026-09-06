module top;
	import uvm_pkg::*;
	import tb_pkg::*;
	
	bit clk,reset;
	
	dut_if vif(.clk(clk), .reset(reset));
	
	frame_aligner d1(
		.clk(clk),
		.reset(reset),
		.rx_data(vif.rx_data),
		.fr_byte_position (vif.fr_byte_position),
		.frame_detect(vif.frame_detect)
	);

	//clock generator
	initial begin 
        clk = 0;
        forever 
			#10 clk = ~clk;
    end
    
	
	initial begin
	
		uvm_config_db #(virtual dut_if)::set(null, "*", "dut_vif" , vif);
		run_test(" ");
		
	end
	
	initial begin
		reset = 1'b1;
		repeat(4) @(negedge clk);
		reset = 1'b0;		
	end

endmodule

