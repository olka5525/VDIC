class scoreboard extends uvm_subscriber #(result_transaction);
	`uvm_component_utils(scoreboard)

//------------------------------------------------------------------------------
// local typedefs
//------------------------------------------------------------------------------

	typedef enum bit {
		TEST_PASSED,
		TEST_FAILED
	} test_result;

//------------------------------------------------------------------------------
// local variables
//------------------------------------------------------------------------------

	virtual alu_bfm bfm;
	uvm_tlm_analysis_fifo #(command_transaction) cmd_f;

	protected test_result tr = TEST_PASSED; // the result of the current test

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

	function new (string name, uvm_component parent);
		super.new(name, parent);
	endfunction : new

//------------------------------------------------------------------------------
// print the PASSED/FAILED in color
//------------------------------------------------------------------------------
	protected function void print_test_result (test_result r);
		if(tr == TEST_PASSED) begin
			set_print_color(COLOR_BOLD_BLACK_ON_GREEN);
			$write ("-----------------------------------\n");
			$write ("----------- Test PASSED -----------\n");
			$write ("-----------------------------------");
			set_print_color(COLOR_DEFAULT);
			$write ("\n");
		end
		else begin
			set_print_color(COLOR_BOLD_BLACK_ON_RED);
			$write ("-----------------------------------\n");
			$write ("----------- Test FAILED -----------\n");
			$write ("-----------------------------------");
			set_print_color(COLOR_DEFAULT);
			$write ("\n");
		end
	endfunction

//------------------------------------------------------------------------------
// build phase
//------------------------------------------------------------------------------

	function void build_phase(uvm_phase phase);
		cmd_f = new ("cmd_f", this);
	endfunction : build_phase

//------------------------------------------------------------------------------
// function to calculate the expected ALU result
//------------------------------------------------------------------------------
	protected function [5:0] get_error(bit crc_ok,int package_n,operation_t op);
		bit [5:0] error;
		begin
			if (package_n != 9) begin
				error[2] = '1;
				error[5] = '1;
				return error;
			end
			if (!crc_ok) begin
				error[1] = '1;
				error[4] = '1;
				return error;
			end
			if (op == no_op ) begin
				error[0] = '1;
				error[3] = '1;
				return error;
			end
		end
	endfunction

	protected function [2:0] CalculateCRC_3;

		input [36:0] Data;
		reg [36:0] d;
		reg [2:0] c;
		reg [2:0] newcrc;
		begin
			d = Data;
			c = '0;

			newcrc[0] = d[35] ^ d[32] ^ d[31] ^ d[30] ^ d[28] ^ d[25] ^ d[24] ^ d[23] ^ d[21] ^ d[18] ^ d[17] ^ d[16] ^ d[14] ^ d[11] ^ d[10] ^ d[9] ^ d[7] ^ d[4] ^ d[3] ^ d[2] ^ d[0] ^ c[1];
			newcrc[1] = d[36] ^ d[35] ^ d[33] ^ d[30] ^ d[29] ^ d[28] ^ d[26] ^ d[23] ^ d[22] ^ d[21] ^ d[19] ^ d[16] ^ d[15] ^ d[14] ^ d[12] ^ d[9] ^ d[8] ^ d[7] ^ d[5] ^ d[2] ^ d[1] ^ d[0] ^ c[1] ^ c[2];
			newcrc[2] = d[36] ^ d[34] ^ d[31] ^ d[30] ^ d[29] ^ d[27] ^ d[24] ^ d[23] ^ d[22] ^ d[20] ^ d[17] ^ d[16] ^ d[15] ^ d[13] ^ d[10] ^ d[9] ^ d[8] ^ d[6] ^ d[3] ^ d[2] ^ d[1] ^ c[0] ^ c[2];
			CalculateCRC_3 = newcrc;
		end
	endfunction

///------------------------------------------------------------------------------
// calculate predicted result
//------------------------------------------------------------------------------
	protected function logic [31:0] get_expected(
			bit signed [31:0] A,
			bit signed  [31:0] B,
			operation_t op
		);
		case(op)
			and_op : return (A & B);
			add_op : return (A + B);
			sub_op : return (A - B);
			or_op :  return (A | B);
		endcase
	endfunction


///------------------------------------------------------------------------------
// calculate expected result
//------------------------------------------------------------------------------
	protected function result_transaction predict_result(command_transaction cmd);
		result_transaction predicted;
		predicted = new("predicted");

		predicted.error = get_error(cmd.crc_ok, cmd.package_n, cmd.op);

		if(cmd.crc_ok==1'b1 && cmd.package_n==9 && cmd.op!=no_op) begin
			predicted.result = get_expected(cmd.B,cmd.A, cmd.op);
			predicted.flags = cmd.flags;
			predicted.crc_out = CalculateCRC_3( {predicted.result, 1'b0, predicted.flags});
		end
		else begin
			predicted.result = '0;
			predicted.flags = '0;
			predicted.crc_out = '0;
		end
		return predicted;

	endfunction


//------------------------------------------------------------------------------
// scoreboard
//------------------------------------------------------------------------------

	function void write(result_transaction t);
		string data_str;
		command_transaction cmd;
		result_transaction predicted;

		do
			if (!cmd_f.try_get(cmd))
				$fatal(1, "Missing command in self checker");
		while (cmd.op == rst_op);

		predicted = predict_result(cmd);

		data_str  = { cmd.convert2string(),
			" ==>  Actual " , t.convert2string(),
			"/Predicted ",predicted.convert2string()};

		if (!predicted.compare(t)) begin
			`uvm_error("SELF CHECKER", {"FAIL: ",data_str})
			tr = TEST_FAILED;
		end
		else
			`uvm_info ("SELF CHECKER", {"PASS: ", data_str}, UVM_HIGH)

	endfunction

endclass : scoreboard