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
class command_transaction extends uvm_transaction;
	`uvm_object_utils(command_transaction)

//------------------------------------------------------------------------------
// transaction variables
//------------------------------------------------------------------------------

	rand bit         signed  [31:0]  A;
	rand bit         signed  [31:0]  B;
	rand operation_t                 op;
	rand bit                 [3:0]   package_n;
	rand bit                         crc_ok;
	bit                      [3:0]   CRC;
	bit                      [3:0]   flags;

//------------------------------------------------------------------------------
// constraints
//------------------------------------------------------------------------------
//post_randomize
	constraint data {
		A dist {'h00000000:=1, ['h000000001 : 'hFFFFFFFE]:/1, 'hFFFFFFFF:=1};
		B dist {'h00000000:=1, ['h000000001 : 'hFFFFFFFE]:/1, 'hFFFFFFFF:=1};
		package_n   dist{8:=1,9:=98,10:=1};
		crc_ok      dist{1:=99, 0:=1};
	}

	function void post_randomize();
		flags = get_flags(B,A,op);
		CRC = CalculateCRC_4({B,A,1'b1,op}, crc_ok);
	endfunction

//------------------------------------------------------------------------------
// transaction functions: do_copy, clone_me, do_compare, convert2string
//------------------------------------------------------------------------------

	function void do_copy(uvm_object rhs);
		command_transaction copied_transaction_h;

		if(rhs == null)
			`uvm_fatal("COMMAND TRANSACTION", "Tried to copy from a null pointer")

		super.do_copy(rhs); // copy all parent class data

		if(!$cast(copied_transaction_h,rhs))
			`uvm_fatal("COMMAND TRANSACTION", "Tried to copy wrong type.")

		A  = copied_transaction_h.A;
		B  = copied_transaction_h.B;
		op = copied_transaction_h.op;
		package_n = copied_transaction_h.package_n;
		crc_ok  = copied_transaction_h.crc_ok;
		CRC  = copied_transaction_h.CRC;
		flags = copied_transaction_h.flags;

	endfunction : do_copy


	function command_transaction clone_me();

		command_transaction clone;
		uvm_object tmp;

		tmp = this.clone();
		$cast(clone, tmp);
		return clone;

	endfunction : clone_me


	function bit do_compare(uvm_object rhs, uvm_comparer comparer);

		command_transaction compared_transaction_h;
		bit same;

		if (rhs==null) `uvm_fatal("RANDOM TRANSACTION",
				"Tried to do comparison to a null pointer");

		if (!$cast(compared_transaction_h,rhs))
			same = 0;
		else
			same = super.do_compare(rhs, comparer) &&
			(compared_transaction_h.A == A) &&
			(compared_transaction_h.B == B) &&
			(compared_transaction_h.op == op) &&
			(compared_transaction_h.CRC == CRC) &&
			(compared_transaction_h.crc_ok == crc_ok) &&
			(compared_transaction_h.package_n == package_n);

		return same;

	endfunction : do_compare


	function string convert2string();
		string s;
		s = $sformatf("A: %h  B: %h op: %s Package number: %d  CRC: %b crc_ok: %b", A, B, op.name(), package_n, CRC, crc_ok);
		return s;
	endfunction : convert2string

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

	function new (string name = "");
		super.new(name);
	endfunction : new



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

endclass : command_transaction


