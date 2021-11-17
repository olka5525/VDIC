/*
 Copyright 2013 Ray Salemi

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */
module scoreboard(alu_bfm bfm);
import alu_pkg::*;

string test_result = "PASSED";
//------------------------------------------------------------------------------
// calculate expected result
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// get error
//------------------------------------------------------------------------------
	function [5:0] get_error(
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
	function [3:0] get_flags(
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


	function [2:0] CalculateCRC_3;

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
	function logic [31:0] get_expected(
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

	function logic get_expected_33(
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
	always @(negedge bfm.clk) begin : scoreboard
		if(bfm.done) begin:verify_result
			bit                 [31:0]  expected;
			bit                 [3:0]   flags_expected;
			bit                 [2:0]   crc_expected;
			bit                 [5:0]   error_expected;
			automatic  string           test_result = "PASSED";

			bfm.done <= '0;
			if (bfm.correct) begin

				begin
					expected = get_expected( bfm.B,bfm.A, bfm.op_set);
					CHK_RESULT: assert(bfm.result === expected)
					else begin
						$display("Test FAILED for A=%0d B=%0d op_set=%0d",bfm.A, bfm.B, bfm.op_set);
						$display("Expected: %d  received: %d", expected, bfm.result);
						test_result = "FAILED";
					end

					flags_expected = get_flags( bfm.B,bfm.A, bfm.op_set);
					CHK_FLAG: assert(bfm.flags === flags_expected)
					else begin
						$display("Test FAILED for A=%0d B=%0d op_set=%0d", bfm.A, bfm.B, bfm.op_set);
						$display("Flags expected: %d  received: %d", flags_expected, bfm.flags);
						test_result = "FAILED";
					end

					crc_expected = CalculateCRC_3( {expected, 1'b0, flags_expected});
					CHK_CRC:  assert(bfm.crc_out === crc_expected)
					else begin
						$display("Test FAILED for A=%0d B=%0d op_set=%0d", bfm.A, bfm.B, bfm.op_set);
						$display("CRC expected: %d  received: %d", crc_expected, bfm.crc_out);
						test_result = "FAILED";
					end
				end
			end

			else begin //error
				error_expected = get_error(bfm.crc_ok, bfm.package_n, bfm.op_set);
				if          (bfm.error[0])
					CHK_ERROR_OP:  assert(error_expected[0] === bfm.error[0])
					else    begin
						$display("Test FAILED for A=%0d B=%0d op_set=%3b", bfm.A, bfm.B, bfm.op_set);
						$display("Error expected: %6b  received: %6b", error_expected, bfm.error);
						test_result = "FAILED";
					end

				else if     (bfm.error[1])
					CHK_ERROR_CRC: assert(error_expected[1] === bfm.error[1])
					else    begin
						$display("Test FAILED for A=%0d B=%0d op_set=%3b", bfm.A, bfm.B, bfm.op_set);
						$display("Error expected: %6b  received: %6b", error_expected, bfm.error);
						test_result = "FAILED";
					end

				else if     (bfm.error[2])
					CHK_ERROR_DATA: assert(error_expected[2] === bfm.error[2])
					else begin
						$display("Test FAILED for A=%0d B=%0d op_set=%3b", bfm.A, bfm.B, bfm.op_set);
						$display("Error expected: %6b  received: %6b", error_expected, bfm.error);
						test_result = "FAILED";
					end
				else test_result = "FAILED";
			end
		end
	end : scoreboard

//------------------------------------------------------------------------------
// Temporary. The scoreboard data will be later used.
	final begin : finish_of_the_test
		$display("Test %s.",test_result);
	end
//------------------------------------------------------------------------------

endmodule : scoreboard






