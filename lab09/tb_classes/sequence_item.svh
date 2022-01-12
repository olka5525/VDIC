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
class sequence_item extends uvm_sequence_item;

//  This macro is moved below the variables definition and expanded.
//    `uvm_object_utils(sequence_item)

//------------------------------------------------------------------------------
// sequence item variables
//------------------------------------------------------------------------------

	rand bit         signed  [31:0]  A;
	rand bit         signed  [31:0]  B;
	rand operation_t                 op;
	rand bit                 [3:0]   package_n;
	rand bit                         crc_ok;
	bit                      [3:0]   CRC;
	bit                      [3:0]   flags;

//------------------------------------------------------------------------------
// Macros providing copy, compare, pack, record, print functions.
// Individual functions can be enabled/disabled with the last
// `uvm_field_*() macro argument.
// Note: this is an expanded version of the `uvm_object_utils with additional
//       fields added. DVT has a dedicated editor for this (ctrl-space).
//------------------------------------------------------------------------------

	`uvm_object_utils_begin(sequence_item)
		`uvm_field_int(A, UVM_DEFAULT)
		`uvm_field_int(B, UVM_DEFAULT)
		`uvm_field_enum(operation_t, op, UVM_DEFAULT)
		`uvm_field_int(package_n, UVM_DEFAULT)
		`uvm_field_int(crc_ok, UVM_DEFAULT | UVM_UNSIGNED)
		`uvm_field_int(CRC, UVM_DEFAULT)
		`uvm_field_int(flags, UVM_DEFAULT)
	`uvm_object_utils_end

//------------------------------------------------------------------------------
// constraints
//------------------------------------------------------------------------------

	constraint data {
		A dist {'h00000000:=1, ['h000000001 : 'hFFFFFFFE]:/1, 'hFFFFFFFF:=1};
		B dist {'h00000000:=1, ['h000000001 : 'hFFFFFFFE]:/1, 'hFFFFFFFF:=1};
		package_n   dist{8:=1,9:=98,10:=1};
		crc_ok      dist{1:=99, 0:=1};
	}


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

	function new(string name = "sequence_item");
		super.new(name);
	endfunction : new

	function void post_randomize();
		flags = get_flags(B,A,op);
		CRC = CalculateCRC_4({B,A,1'b1,op}, crc_ok);
	endfunction



	protected function [3:0] CalculateCRC_4([67:0] Data, bit ok);
		reg [67:0] d;
		reg [3:0] c;
		reg [3:0] newcrc;
		if (ok) begin
			d = Data;
			c = '0;
			newcrc[0] = d[66] ^ d[64] ^ d[63] ^ d[60] ^ d[56] ^ d[55] ^ d[54] ^ d[53] ^ d[51] ^ d[49] ^ d[48] ^ d[45] ^ d[41] ^ d[40] ^ d[39] ^ d[38] ^ d[36] ^ d[34] ^ d[33] ^ d[30] ^ d[26] ^ d[25] ^ d[24] ^ d[23] ^ d[21] ^ d[19] ^ d[18] ^ d[15] ^ d[11] ^ d[10] ^ d[9] ^ d[8] ^ d[6] ^ d[4] ^ d[3] ^ d[0] ^ c[0] ^ c[2];
			newcrc[1] = d[67] ^ d[66] ^ d[65] ^ d[63] ^ d[61] ^ d[60] ^ d[57] ^ d[53] ^ d[52] ^ d[51] ^ d[50] ^ d[48] ^ d[46] ^ d[45] ^ d[42] ^ d[38] ^ d[37] ^ d[36] ^ d[35] ^ d[33] ^ d[31] ^ d[30] ^ d[27] ^ d[23] ^ d[22] ^ d[21] ^ d[20] ^ d[18] ^ d[16] ^ d[15] ^ d[12] ^ d[8] ^ d[7] ^ d[6] ^ d[5] ^ d[3] ^ d[1] ^ d[0] ^ c[1] ^ c[2] ^ c[3];
			newcrc[2] = d[67] ^ d[66] ^ d[64] ^ d[62] ^ d[61] ^ d[58] ^ d[54] ^ d[53] ^ d[52] ^ d[51] ^ d[49] ^ d[47] ^ d[46] ^ d[43] ^ d[39] ^ d[38] ^ d[37] ^ d[36] ^ d[34] ^ d[32] ^ d[31] ^ d[28] ^ d[24] ^ d[23] ^ d[22] ^ d[21] ^ d[19] ^ d[17] ^ d[16] ^ d[13] ^ d[9] ^ d[8] ^ d[7] ^ d[6] ^ d[4] ^ d[2] ^ d[1] ^ c[0] ^ c[2] ^ c[3];
			newcrc[3] = d[67] ^ d[65] ^ d[63] ^ d[62] ^ d[59] ^ d[55] ^ d[54] ^ d[53] ^ d[52] ^ d[50] ^ d[48] ^ d[47] ^ d[44] ^ d[40] ^ d[39] ^ d[38] ^ d[37] ^ d[35] ^ d[33] ^ d[32] ^ d[29] ^ d[25] ^ d[24] ^ d[23] ^ d[22] ^ d[20] ^ d[18] ^ d[17] ^ d[14] ^ d[10] ^ d[9] ^ d[8] ^ d[7] ^ d[5] ^ d[3] ^ d[2] ^ c[1] ^ c[3];
			CalculateCRC_4 = newcrc;
		end
		else
			CalculateCRC_4 = 4'($random);
	endfunction

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

	protected function logic get_expected_33(
			bit unsigned  [31:0] A,
			bit unsigned  [31:0] B,
			operation_t op
		);
		bit unsigned [32:0] ret;

		case(op)
			and_op : ret = A & B;
			add_op : ret = A + B;
			sub_op : ret = A - B;
			or_op : ret = A | B;

		endcase
		return(ret[32]);
	endfunction

endclass : sequence_item


