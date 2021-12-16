class coverage extends uvm_subscriber #(command_transaction);
	`uvm_component_utils(coverage)

	protected bit         signed  [31:0]  A;
	protected bit         signed  [31:0]  B;
	protected bit                 [3:0]   package_n;
	protected bit                         crc_ok;
	protected bit                 [3:0]   flags;
	protected operation_t                op_set;

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
			bins others= {['h000000001 : 'h7FFFFFFE]};
			bins ones  = {-1};
		}

		b_leg: coverpoint B {
			bins zeros = {'h00000000};
			bins others= {['h000000001 : 'h7FFFFFFE]};
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
			bins D1_error_less = {8};
			bins D1_error_more = {10};
		}

		crc_leg: coverpoint crc_ok {
			bins D2_crc_error = {0};
		}

		ops_leg: coverpoint op_set {
			bins D3_error_ops = {no_op};
		}

	endgroup

	function new (string name, uvm_component parent);
		super.new(name, parent);
		error_cov               =   new();
		zeros_or_ones_on_ops    =   new();
		op_cov                  =   new();
		flag_cov                =   new();
	endfunction : new

	function void write(command_transaction t);
			A           = t.A;
			B           = t.B;
			op_set      = t.op;
			flags       = t.flags;
			crc_ok      = t.crc_ok;
			package_n   = t.package_n;
			error_cov.sample();
			zeros_or_ones_on_ops.sample();
			op_cov.sample();
			flag_cov.sample();
	endfunction : write

endclass