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
module tester(alu_bfm bfm);
	import alu_pkg::*;

//---------------------------------
// Random data generation functions

	function operation_t get_op();
		bit [2:0] op_choice;
		op_choice = 3'($random);
		case (op_choice)
			3'b000 : return and_op;
			3'b001 : return  or_op;
			3'b100 : return add_op;
			3'b101 : return sub_op;
			3'b011 : return rst_op;
			3'b010 : return no_op;
			3'b111 : return no_op;
			3'b110 : return no_op;
		endcase // case (op_choice)
	endfunction : get_op

//---------------------------------
	function bit [31:0] get_data();
		bit [1:0] zero_ones;
		zero_ones = $random;
		if (zero_ones == 2'b00)
			return 32'h0;
		else if (zero_ones == 2'b11)
			return 32'hFFFFFFFF;
		else
			return $random;
	endfunction : get_data


//------------------------
// Tester main

	initial begin : tester

		bit         signed  [31:0]  iA;
		bit         signed  [31:0]  iB;
		bit                 [3:0]   package_n;
		bit                         crc_ok;
		bit                 [3:0]   flags;
		operation_t                op_set;
		bit                 [9:0]   random_crc;
		bit                 [9:0]   random_num;
		bit         signed  [31:0]  result;
		bit                 [3:0]   CRC;
		bit                 [2:0]   crc_out;
		bit                         done;


		bfm.reset_alu();
		repeat (10000) begin : tester_main
			@(negedge bfm.clk);
			op_set = get_op();
			iA      = get_data();
			iB      = get_data();

			random_num = $urandom%10;
			case (random_num)
				1: package_n = 8;
				9:  package_n = 7;
				default:  package_n = 9;
			endcase

			CRC = CalculateCRC_4({{iB,iA},1'b1,op_set});

			random_crc = $urandom%10;

			case (random_crc)
				1: begin
					CRC = 4'($random);
					crc_ok = 'b0;
				end
				9: begin
					CRC = 4'($random);
					crc_ok = 'b0;
				end
			endcase

			bfm.send_op(iA, iB, op_set, package_n, CRC, crc_ok, result);
			
		end
		$finish;

	end : tester

	function [3:0] CalculateCRC_4;

		input [67:0] Data;
		reg [67:0] d;
		reg [3:0] c;
		reg [3:0] newcrc;
		begin
			d = Data;
			c = '0;

			newcrc[0] = d[66] ^ d[64] ^ d[63] ^ d[60] ^ d[56] ^ d[55] ^ d[54] ^ d[53] ^ d[51] ^ d[49] ^ d[48] ^ d[45] ^ d[41] ^ d[40] ^ d[39] ^ d[38] ^ d[36] ^ d[34] ^ d[33] ^ d[30] ^ d[26] ^ d[25] ^ d[24] ^ d[23] ^ d[21] ^ d[19] ^ d[18] ^ d[15] ^ d[11] ^ d[10] ^ d[9] ^ d[8] ^ d[6] ^ d[4] ^ d[3] ^ d[0] ^ c[0] ^ c[2];
			newcrc[1] = d[67] ^ d[66] ^ d[65] ^ d[63] ^ d[61] ^ d[60] ^ d[57] ^ d[53] ^ d[52] ^ d[51] ^ d[50] ^ d[48] ^ d[46] ^ d[45] ^ d[42] ^ d[38] ^ d[37] ^ d[36] ^ d[35] ^ d[33] ^ d[31] ^ d[30] ^ d[27] ^ d[23] ^ d[22] ^ d[21] ^ d[20] ^ d[18] ^ d[16] ^ d[15] ^ d[12] ^ d[8] ^ d[7] ^ d[6] ^ d[5] ^ d[3] ^ d[1] ^ d[0] ^ c[1] ^ c[2] ^ c[3];
			newcrc[2] = d[67] ^ d[66] ^ d[64] ^ d[62] ^ d[61] ^ d[58] ^ d[54] ^ d[53] ^ d[52] ^ d[51] ^ d[49] ^ d[47] ^ d[46] ^ d[43] ^ d[39] ^ d[38] ^ d[37] ^ d[36] ^ d[34] ^ d[32] ^ d[31] ^ d[28] ^ d[24] ^ d[23] ^ d[22] ^ d[21] ^ d[19] ^ d[17] ^ d[16] ^ d[13] ^ d[9] ^ d[8] ^ d[7] ^ d[6] ^ d[4] ^ d[2] ^ d[1] ^ c[0] ^ c[2] ^ c[3];
			newcrc[3] = d[67] ^ d[65] ^ d[63] ^ d[62] ^ d[59] ^ d[55] ^ d[54] ^ d[53] ^ d[52] ^ d[50] ^ d[48] ^ d[47] ^ d[44] ^ d[40] ^ d[39] ^ d[38] ^ d[37] ^ d[35] ^ d[33] ^ d[32] ^ d[29] ^ d[25] ^ d[24] ^ d[23] ^ d[22] ^ d[20] ^ d[18] ^ d[17] ^ d[14] ^ d[10] ^ d[9] ^ d[8] ^ d[7] ^ d[5] ^ d[3] ^ d[2] ^ c[1] ^ c[3];
			CalculateCRC_4 = newcrc;
		end
	endfunction

endmodule