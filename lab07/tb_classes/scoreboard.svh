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
	protected function [5:0] get_error(
			bit                 crc_ok,
			int                 package_n,
			operation_t op
		);
		bit [5:0] error;
		bit signed [31:0] c;
		begin
			if (package_n != 9) begin
				error[2] = '1;
				error[5] = '1;
			end

			if (op == no_op ) begin
				error[0] = '1;
				error[3] = '1;
			end

			if (!crc_ok) begin
				error[1] = '1;
				error[4] = '1;
			end


			return(error);
		end


	endfunction

//------------------------------------------------------------------------------
// get flags
//------------------------------------------------------------------------------
	protected function [3:0] get_flags(
			bit signed [31:0] A,
			bit signed  [31:0] B,
			operation_t op
		);
		bit [3:0] flag;
		bit signed [31:0] c;
		begin
			flag = 4'b0;
			case(op)

				and_op :c = A & B;
				add_op :begin
					c = A + B;
					if ((!A[31] && !B[31] && c[31]) || (A[31] && B[31] &&  !c[31]))
						flag[2] = 1;
				end
				sub_op :begin
					c = A - B;
					if ((!A[31] && B[31] && c[31]) || (A[31] && !B[31] &&  !c[31]))
						flag[2] = 1;
				end
				or_op : c = A | B;

			endcase

			if (c == 0) //zero
				flag[1] = 1;
			if (c[31] == 1)
				flag[0] = 1;
			if  (get_expected_33(A,B,op)==1)
				flag[3]  = 1;

			return(flag);
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
// calculate expected result
//------------------------------------------------------------------------------
	protected function logic [31:0] get_expected(
			bit signed [31:0] A,
			bit signed  [31:0] B,
			operation_t op
		);
		 //bit [31:0] ret;

		case(op)
			and_op : return (A & B);
			add_op : return (A + B);
			sub_op : return (A - B);
			or_op :  return (A | B);

		endcase
		//$display("Ret: %s", op_set);
		//return(ret);
	endfunction

	protected function logic get_expected_33(
			bit unsigned  [31:0] A,
			bit unsigned  [31:0] B,
			operation_t op
		);
		bit [32:0] ret;

		case(op)
			and_op : ret = A & B;
			add_op : ret = A + B;
			sub_op : ret = A - B;
			or_op : ret = A | B;

		endcase
		return(ret[32]);
	endfunction

//------------------------------------------------------------------------------
// scoreboard
//------------------------------------------------------------------------------

	function void write(result_transaction t);
//      bit signed [31:0] predicted_result;
//      bit                 [31:0]  expected;
//      bit                 [3:0]   flags_expected;
//      bit                 [2:0]   crc_expected;
//      bit                 [5:0]   error_expected;

		string data_str;
		command_transaction cmd;
		result_transaction predicted;
		//result_transaction predicted;

		do
			if (!cmd_f.try_get(cmd))
				$fatal(1, "Missing command in self checker");
		while ((cmd.op == no_op) || (cmd.op == rst_op));

		//predicted = predict_result(cmd);

			 predicted = new("predicted");

			if (t.correct) begin
				predicted.result = get_expected(cmd.B,cmd.A, cmd.op);
				predicted.flags = get_flags(cmd.B,cmd.A, cmd.op);
				predicted.crc_out = CalculateCRC_3( {predicted.result, 1'b0, predicted.flags});

				data_str  = { cmd.convert2string(),
					" ==>  Actual " , t.convert2string(),
					"/Predicted ",predicted.convert2string()};

				if (!predicted.compare(t)) begin
					`uvm_error("SELF CHECKER", {"FAIL: ",data_str})
					tr = TEST_FAILED;
				end
				else
					`uvm_info ("SELF CHECKER", {"PASS: ", data_str}, UVM_HIGH)

//              predicted.result = get_expected(cmd.B,cmd.A, cmd.op);
//              CHK_RESULT: assert(predicted.result === t.result)
//              else
//                  $error (
//                      "FAILED:  A=%0d B=%0d op_set=%s actual result: %d   expected: %d",
//                      cmd.A, cmd.B, cmd.op.name(), t.result, predicted.result);
//
//              predicted.flags = get_flags(cmd.B,cmd.A, cmd.op);
//              CHK_FLAG: assert(t.flags === predicted.flags)
//              else
//                  $error (
//                      "FAILED:  A=%0d B=%0d op_set=%s actual flags: %b   expected: %b",
//                      cmd.A, cmd.B, cmd.op.name(), t.flags, predicted.flags);
//
//              predicted.crc_out = CalculateCRC_3( {predicted.result, 1'b0, predicted.flags});
//              CHK_CRC:  assert(t.crc_out === predicted.crc_out)
//              else
//                  $error (
//                      "FAILED:  A=%0d B=%0d op_set=%s actual crc: %b   expected: %b",
//                      cmd.A, cmd.B, cmd.op.name(), t.crc_out, predicted.crc_out);

			end

			else begin //error
				predicted.error = get_error(cmd.crc_ok, cmd.package_n, cmd.op);

				data_str  = { cmd.convert2string(),
					" ==>  Actual " , t.convert2string(),
					"/Predicted ",predicted.convert2string()};

				if (!predicted.compare(t)) begin
					`uvm_error("SELF CHECKER", {"FAIL: ",data_str})
					tr = TEST_FAILED;
//              if          (t.error[0])
//                  CHK_ERROR_OP:  assert(predicted.error[0] === t.error[0])
//                  else
//                      $error (
//                          "FAILED:  A=%0d B=%0d op_set=%s actual error: %6b   expected: %6b",
//                          cmd.A, cmd.B, cmd.op.name(), t.error, predicted.error);
//
//              else if     (t.error[1])
//                  CHK_ERROR_CRC: assert(predicted.error[1] === t.error[1])
//                  else
//                      $error (
//                          "FAILED:  A=%0d B=%0d op_set=%s actual error: %6b   expected: %6b",
//                          cmd.A, cmd.B, cmd.op.name(), t.error, predicted.error);
//
//              else if     (t.error[2])
//                  CHK_ERROR_DATA: assert(predicted.error[2] === t.error[2])
//                  else
//                      $error (
//                          "FAILED:  A=%0d B=%0d op_set=%s actual error: %6b   expected: %6b",
//                          cmd.A, cmd.B, cmd.op.name(), t.error, predicted.error);
				end
		end
	endfunction

endclass : scoreboard