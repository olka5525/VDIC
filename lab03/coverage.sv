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
module coverage(alu_bfm bfm);
	import alu_pkg::*;

	bit         signed  [31:0]  A;
	bit         signed  [31:0]  B;
	bit                 [3:0]   package_n;
	bit                         crc_ok;
	bit                 [3:0]   flags;
	operation_t                op_set;


	//------------------------------------------------------------------------------
// Coverage block
//------------------------------------------------------------------------------

// Covergroup checking the op codes and theri sequences
	covergroup op_cov;

		option.name = "cg_op_cov";

		coverpoint op_set {
			// #A1 test all operations
			bins A1_single_cycle[] = {[and_op : no_op]};

			// #A2 test all operations after reset
			bins A2_rst_opn[]      = (rst_op => [and_op:sub_op]);

			// #A3 test reset after all operations
			bins A3_opn_rst[]      = ([and_op:sub_op] => rst_op);

			// #A6 two operations in row
			bins A4_twoops[]       = ([and_op:sub_op] [* 2]);

		// bins manymult = (mul_op [* 3:5]);
		}

	endgroup

// Covergroup checking for min and max arguments of the ALU
	covergroup zeros_or_ones_on_ops;

		option.name = "cg_zeros_or_ones_on_ops";

		all_ops : coverpoint op_set {
			ignore_bins null_ops = {rst_op, no_op};
		}

		a_leg: coverpoint A {
			bins zeros = {'h00000000};
			bins others= {['h000000001:'h7FFFFFFF]};
			bins ones  = {-1};
		}

		b_leg: coverpoint B {
			bins zeros = {'h00000000};
			bins others= {['h000000001:'h7FFFFFFF]};
			bins ones  = {-1};
		}

		B_op_00_FF: cross a_leg, b_leg, all_ops {

			// #B1 simulate all zero input for all the operations

			bins B1_add_00          = binsof (all_ops) intersect {add_op} &&
			(binsof (a_leg.zeros) || binsof (b_leg.zeros));

			bins B1_and_00          = binsof (all_ops) intersect {and_op} &&
			(binsof (a_leg.zeros) || binsof (b_leg.zeros));

			bins B1_or_00          = binsof (all_ops) intersect {or_op} &&
			(binsof (a_leg.zeros) || binsof (b_leg.zeros));

			bins B1_sub_00          = binsof (all_ops) intersect {sub_op} &&
			(binsof (a_leg.zeros) || binsof (b_leg.zeros));

			// #B2 simulate all one input for all the operations

			bins B2_add_FF          = binsof (all_ops) intersect {add_op} &&
			(binsof (a_leg.ones) || binsof (b_leg.ones));

			bins B2_and_FF          = binsof (all_ops) intersect {and_op} &&
			(binsof (a_leg.ones) || binsof (b_leg.ones));

			bins B2_or_FF          = binsof (all_ops) intersect {or_op} &&
			(binsof (a_leg.ones) || binsof (b_leg.ones));

			bins B2_sub_FF          = binsof (all_ops) intersect {sub_op} &&
			(binsof (a_leg.ones) || binsof (b_leg.ones));

			bins B2_sub_max         = binsof (all_ops) intersect {sub_op} &&
			(binsof (a_leg.ones) && binsof (b_leg.ones));

			// #B3 simulate all one input A and B for all the operations

			bins B3_add_FF          = binsof (all_ops) intersect {add_op} &&
			(binsof (a_leg.ones) && binsof (b_leg.ones));

			bins B3_and_FF          = binsof (all_ops) intersect {and_op} &&
			(binsof (a_leg.ones) && binsof (b_leg.ones));

			bins B3_or_FF          = binsof (all_ops) intersect {or_op} &&
			(binsof (a_leg.ones) && binsof (b_leg.ones));

			bins B3_sub_FF          = binsof (all_ops) intersect {sub_op} &&
			(binsof (a_leg.ones) && binsof (b_leg.ones));

			// #B4 simulate all zero input A and B for all the operations

			bins B4_add_00          = binsof (all_ops) intersect {add_op} &&
			(binsof (a_leg.zeros) && binsof (b_leg.zeros));

			bins B4_and_00         = binsof (all_ops) intersect {and_op} &&
			(binsof (a_leg.zeros) && binsof (b_leg.zeros));

			bins B4_or_00         = binsof (all_ops) intersect {or_op} &&
			(binsof (a_leg.zeros) && binsof (b_leg.zeros));

			bins B4_sub_00         = binsof (all_ops) intersect {sub_op} &&
			(binsof (a_leg.zeros) && binsof (b_leg.zeros));




			ignore_bins others_only =
			binsof(a_leg.others) && binsof(b_leg.others);
		}

	endgroup

//Covergoup for flags

	covergroup flag_cov;

		option.name = "cg_flags_cov";

		all_ops : coverpoint op_set {
			ignore_bins null_ops = {rst_op,no_op};
		}


		flag_leg : coverpoint flags {
			bins carry = {'b1000};
			bins overflow = {'b0100};
			bins zero = {'b0010};
			bins negative = {'b0001};
			bins rest = {'b1100, 'b1010, 'b1001, 'b0110, 'b0101};
		}

		Flags: cross flag_leg, all_ops{

			// #C1 simulate carry flag

			bins C1_carry_add          = binsof (all_ops) intersect {add_op} &&
			(binsof (flag_leg.carry));

			bins C1_carry_sub          = binsof (all_ops) intersect {sub_op} &&
			(binsof (flag_leg.carry));

			// #C2 simulate overflow flag

			bins C2_overflow_add          = binsof (all_ops) intersect {add_op} &&
			(binsof (flag_leg.overflow));

			bins C2_overflow_sub          = binsof (all_ops) intersect {sub_op} &&
			(binsof (flag_leg.overflow));

			// #C3 simulate zero flag

			bins C3_zero_add          = binsof (all_ops) intersect {add_op} &&
			(binsof (flag_leg.zero));

			bins C3_zero_sub          = binsof (all_ops) intersect {sub_op} &&
			(binsof (flag_leg.zero));

			bins C3_zero_and          = binsof (all_ops) intersect {and_op} &&
			(binsof (flag_leg.zero));

			bins C3_zero_or          = binsof (all_ops) intersect {or_op} &&
			(binsof (flag_leg.zero));

			// #C4 simulate negative flag

			bins C4_negative_add          = binsof (all_ops) intersect {add_op} &&
			(binsof (flag_leg.negative));

			bins C4_negative_sub          = binsof (all_ops) intersect {sub_op} &&
			(binsof (flag_leg.negative));

			bins C4_negative_and          = binsof (all_ops) intersect {and_op} &&
			(binsof (flag_leg.negative));

			bins C4_negative_or          = binsof (all_ops) intersect {or_op} &&
			(binsof (flag_leg.negative));


			ignore_bins or_overflow = binsof (all_ops) intersect {or_op} &&
			(binsof (flag_leg.overflow));
			ignore_bins and_overflow = binsof (all_ops) intersect {and_op} &&
			(binsof (flag_leg.overflow));
			ignore_bins or_carry = binsof (all_ops) intersect {or_op} &&
			(binsof (flag_leg.carry));
			ignore_bins and_carry = binsof (all_ops) intersect {and_op} &&
			(binsof (flag_leg.carry));
		}

	endgroup

	covergroup error_cov;
		option.name = "cg_errors";

		data_leg: coverpoint package_n{
			bins D1_error_less = {7};
			bins D1_error_more = {9};
		}

		crc_leg: coverpoint crc_ok {
			bins D2_crc_error = {0};
		}

		ops_leg: coverpoint op_set {
			bins D3_error_ops = {no_op};
		}

	endgroup


	op_cov                      oc;
	zeros_or_ones_on_ops        c_00_FF;
	error_cov                   ec;
	flag_cov                    fc;

	initial begin : coverage
		oc      = new();
		c_00_FF = new();
		ec      = new();
		fc      = new();

		forever begin : sample_cov
			@(posedge bfm.clk);
			A      		= bfm.A;
			B      		= bfm.B;
			op_set 		= bfm.op_set;
			flags  		= bfm.flags;
			crc_ok 		= bfm.crc_ok;
			package_n 	= bfm.package_n;
			oc.sample();
			c_00_FF.sample();
			ec.sample();
			fc.sample();
		end
	end : coverage



endmodule : coverage





