typedef enum bit[1:0] {HEADER_1, HEADER_2, ILLEGAL_HEADER} header_kind_e;

class my_tran extends uvm_sequence_item;

	`uvm_object_utils_begin(my_tran)
        	`uvm_field_enum(header_kind_e, header_kind, UVM_DEFAULT)
       		`uvm_field_array_int(data, UVM_DEFAULT)
		`uvm_field_int(header, UVM_DEFAULT)
    	`uvm_object_utils_end
	
	localparam DATA_WIDTH = 8;
	

	
	localparam header1 = 16'hAFAA;
	localparam header2 = 16'hBA55;
	
	function new(string name = "my_tran");
		super.new(name);
	endfunction
	
	rand header_kind_e header_kind;

	logic frame_detect;
	logic [3:0] fr_byte_position;
	

	
	rand logic [DATA_WIDTH-1:0] data[];
	rand logic [2*DATA_WIDTH -1:0] header;
	

	
	constraint header_dist {
        header_kind dist {
           	HEADER_1       := 15,
           	HEADER_2       := 15,
            ILLEGAL_HEADER := 70
        };
    }
	
	constraint header_match {
		
		if (header_kind == HEADER_1) {
			header == header1; 
			data.size() == 10;
		}
		else if (header_kind == HEADER_2) {
			header == header2; 
			data.size() == 10;
		}
		
		else {
			data.size() inside {[1:50]}; // 1:50
			//data.size() == 10; // 1:50
		/*
			foreach(data[i]){
				data[i] != header1[7:0];
				data[i] != header1[15:8];
				data[i] != header2[7:0];
				data[i] != header2[15:8];
			}
		*/
			header != header1;
			header != header2;
		}
		
		
	}
	
endclass
