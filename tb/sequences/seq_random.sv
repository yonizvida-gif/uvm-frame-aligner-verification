class seq_random_stress extends uvm_sequence #(my_tran);

    `uvm_object_utils(seq_random_stress)

    rand int num_tran;

    function new(string name = "seq_random_stress");
        super.new(name);
    endfunction

    constraint c_num { num_tran inside {[20000:50000]}; }

    task body();

	//repeat(num_tran) begin

            req = my_tran::type_id::create("req");
               
            start_item(req);

            if(!req.randomize())`uvm_fatal("RANDOM SEQ", "Transaction randomization failed")

            finish_item(req);

        //end

    endtask

endclass
