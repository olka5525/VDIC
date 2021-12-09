                                                                                class scoreboard extends uvm_subscriber #(bit signed [31:0]);
	`uvm_component_utils(scoreboard)

	virtual alu_bfm bfm;
	uvm_tlm_analysis_fifo #(command_s) cmd_f;

	function new (string name, uvm_component parent);
		super.new(name, parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		cmd_f = new ("cmd_f", this);
	endfunction : build_phase

	protected function [5:0] get_error(
			bit                 crc_ok,
			int                 package_n,
			operation_t op_set
		);
		bit [5:0] error;
		bit signed [31:0] c;
		begin
			if (package_n != 9) begin
				error[2] = '1;
				error[5] = '1;
			end

			if (op_set == no_op ) begin
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
			operation_t op_set
		);
		bit [3:0] flag;
		bit signed [31:0] c;
		begin
			flag = 4'b0;
			case(op_set)

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
			if  (get_expected_33(A,B,op_set)==1)
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
			operation_t op_set
		);
		bit [31:0] ret;

		case(op_set)
			and_op : ret = A & B;
			add_op : ret = A + B;
			sub_op : ret = A - B;
			or_op : ret = A | B;

		endcase
		//$display("Ret: %s", op_set);
		return(ret);
	endfunction

	protected function logic get_expected_33(
			bit unsigned  [31:0] A,
			bit unsigned  [31:0] B,
			operation_t op_set
		);
		bit [32:0] ret;

		case(op_set)
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

	function void write(bit signed [31:0] t);
		bit signed [31:0] predicted_result;
		bit                 [31:0]  expected;
		bit                 [3:0]   flags_expected;
		bit                 [2:0]   crc_expected;
		bit                 [5:0]   error_expected;
		command_s cmd;
		cmd.A = 0;
		cmd.B = 0;
		cmd.op = no_op;
		cmd.package_n = 0;
		cmd.CRC = 0;
		cmd.crc_ok = 0;
		cmd.correct =1;

		if(cmd.done)begin
			cmd.done=0;
			if (cmd.correct) begin


				expected = get_expected(cmd.B,cmd.A, cmd.op);
				CHK_RESULT: assert(t === expected)
				else
					$error (
						"FAILED:  A=%0d B=%0d op_set=%s actual result: %d   expected: %d",
						cmd.A, cmd.B, cmd.op.name(), t, expected);

				flags_expected = get_flags(cmd.B,cmd.A, cmd.op);
				CHK_FLAG: assert(cmd.flags === flags_expected)
				else
					$error (
						"FAILED:  A=%0d B=%0d op_set=%s actual flags: %b   expected: %b",
						cmd.A, cmd.B, cmd.op.name(), cmd.flags, flags_expected);

				crc_expected = CalculateCRC_3( {expected, 1'b0, flags_expected});
				CHK_CRC:  assert(cmd.crc_out === crc_expected)
				else
					$error (
						"FAILED:  A=%0d B=%0d op_set=%s actual crc: %b   expected: %b",
						cmd.A, cmd.B, cmd.op.name(), cmd.crc_out, crc_expected);

			end

			else begin //error
				error_expected = get_error(cmd.crc_ok, cmd.package_n, cmd.op);
				if          (cmd.error[0])
					CHK_ERROR_OP:  assert(error_expected[0] === cmd.error[0])
					else
						$error (
							"FAILED:  A=%0d B=%0d op_set=%s actual error: %6b   expected: %6b",
							cmd.A, cmd.B, cmd.op.name(), cmd.error, error_expected);

				else if     (cmd.error[1])
					CHK_ERROR_CRC: assert(error_expected[1] === cmd.error[1])
					else
						$error (
							"FAILED:  A=%0d B=%0d op_set=%s actual error: %6b   expected: %6b",
							cmd.A, cmd.B, cmd.op.name(), cmd.error, error_expected);

				else if     (cmd.error[2])
					CHK_ERROR_DATA: assert(error_expected[2] === cmd.error[2])
					else
						$error (
							"FAILED:  A=%0d B=%0d op_set=%s actual error: %6b   expected: %6b",
							cmd.A, cmd.B, cmd.op.name(), cmd.error, error_expected);
			end
		end
	endfunction

endclass : scoreboard