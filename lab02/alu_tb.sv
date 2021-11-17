
module top;

//------------------------------------------------------------------------------
// type and variable definitions

//------------------------------------------------------------------------------
	typedef enum bit[2:0] {
		and_op                      = 3'b000,
		or_op                       = 3'b001,
		add_op                      = 3'b100,
		sub_op                      = 3'b101,
		rst_op                      = 3'b110,
		no_op                       = 3'b111
	} operation_t;

	bit         signed  [31:0]  A;
	bit         signed  [31:0]  B;
	bit                 [63:0]  BA;
	bit                         clk;
	bit                         rst_n;
	bit                         sin;
	logic                       sout;
	bit                 [98:0]  in;
	logic               [54:0]  out;

	bit         signed  [31:0]  result;
	bit                 [3:0]   package_n;
	bit                 [3:0]   flags;
	bit                 [2:0]   crc_out;
	bit                 [3:0]   CRC;

	bit                         crc_ok;
	bit                 [5:0]   error;
	bit                         done='0;
	bit                         correct='0;
	bit                 [9:0]   random_crc;
	bit                 [9:0]   random_num;



	operation_t        op_set;

	//assign op = op_set;

	string             test_result = "PASSED";

//------------------------------------------------------------------------------
// DUT instantiation
//------------------------------------------------------------------------------

	mtm_Alu ALU (.clk(clk), .rst_n(rst_n), .sin(sin), .sout(sout));


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
			bins others= {['h000000001:'hFFFFFFFE]};
			bins ones  = {-1};
		}

		b_leg: coverpoint B {
			bins zeros = {'h00000000};
			bins others= {['h000000001:'hFFFFFFFE]};
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
			@(posedge clk);
			oc.sample();
			c_00_FF.sample();
			ec.sample();
			fc.sample();
		end
	end : coverage


//------------------------------------------------------------------------------
// Clock generator
//------------------------------------------------------------------------------

	initial begin : clk_gen
		clk = 0;
		forever begin : clk_frv
			#10;
			clk = ~clk;
		end
	end

//------------------------------------------------------------------------------
// Tester
//------------------------------------------------------------------------------

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
		reset_alu();
		repeat (1000) begin : tester_main
			@(negedge clk);
			op_set = get_op();
			A      = get_data();
			B      = get_data();

			random_num = $urandom%10;
			case (random_num)
				1: package_n = 8;
				9:  package_n = 7;
				default:  package_n = 9;
			endcase

			BA = {B,A};
			out = '0;
			result = '0;
			crc_ok = 1'b1;
			CRC = CalculateCRC_4({BA,1'b1,op_set});

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


			case(op_set==rst_op)
				1: begin
					reset_alu();
				end
				0:begin
					
					for (int i=0; i<package_n; i++) begin
						in[98-(11*i)-:11]= {2'b00, BA[63-(8*i)-:8], 1'b1};
					end
					in[10:0] = {3'b010, op_set, CRC, 1'b1};

					for (int i=0; i<11*(package_n-1); i++) begin
						@(negedge clk);

						sin=in[98-i];
					end
					for (int i=0; i<11; i++) begin
						@(negedge clk);

						sin=in[10-i];
					end

					@(negedge sout);
					for (int i=0; i<11; i++) begin
						@(negedge clk);
						out[54-i]= sout;
					end
					if (out[54:53] == 'b00) begin
						for (int i=11; i<55; i++) begin
							@(negedge clk);
							out[54-i]= sout;
						end

						@(negedge clk);

						for (int i=0; i<4; i++) begin
							result[31-(8*i)-:8] = out [52-(11*i)-:8];
						end
						flags = out[7:4];
						crc_out = out[3:1];
						correct = '1;
					end
					else begin
						error = out[51:46];
						correct = '0;
					end
					done ='1;
				end


			endcase
			if($get_coverage() == 100) break;
		end
		$display("Passed");
		$finish;

	end : tester
//------------------------------------------------------------------------------
// reset task
//------------------------------------------------------------------------------
	task reset_alu();
	`ifdef DEBUG
		$display("%0t DEBUG: reset_alu", $time);
	`endif
		rst_n = 1'b0;
		sin =1'b1;
		@(negedge clk);
		rst_n = 1'b1;
	endtask

//------------------------------------------------------------------------------
// scoreboard
//------------------------------------------------------------------------------
	always @(negedge clk) begin : scoreboard
		if(done) begin:verify_result
			bit                 [31:0]  expected;
			bit                 [3:0]   flags_expected;
			bit                 [2:0]   crc_expected;

			bit                 [5:0]   error_expected;
			automatic  string           test_result = "PASSED";

			done <= '0;
			if (correct) begin

				begin
					expected = get_expected( B,A, op_set);
					CHK_RESULT: assert(result === expected)
					else begin
						$display("Test FAILED for A=%0d B=%0d op_set=%0d", A, B, op_set);
						$display("Expected: %d  received: %d", expected, result);
						test_result = "FAILED";
					end

					flags_expected = get_flags( B,A, op_set);
					CHK_FLAG: assert(flags === flags_expected)
					else begin
						$display("Test FAILED for A=%0d B=%0d op_set=%0d", A, B, op_set);
						$display("Flags expected: %d  received: %d", flags_expected, flags);
						test_result = "FAILED";
					end

					crc_expected = CalculateCRC_3( {expected, 1'b0, flags_expected});
					CHK_CRC:  assert(crc_out === crc_expected)
					else begin
						$display("Test FAILED for A=%0d B=%0d op_set=%0d", B, A, op_set);
						$display("CRC expected: %d  received: %d", crc_expected, crc_out);
						test_result = "FAILED";
					end
				end
			end

			else begin //error
				error_expected = get_error(crc_ok, package_n, op_set);
				if          (error[0])
					CHK_ERROR_OP:  assert(error_expected[0] === error[0])
					else    begin
						$display("Test FAILED for A=%0d B=%0d op_set=%3b", B, A, op_set);
						$display("Error expected: %6b  received: %6b", error_expected, error);
						test_result = "FAILED";
					end

				else if     (error[1])
					CHK_ERROR_CRC: assert(error_expected[1] === error[1])
					else    begin
						$display("Test FAILED for A=%0d B=%0d op_set=%3b", B, A, op_set);
						$display("Error expected: %6b  received: %6b", error_expected, error);
						test_result = "FAILED";
					end

				else if     (error[2])
					CHK_ERROR_DATA: assert(error_expected[2] === error[2])
					else begin
						$display("Test FAILED for A=%0d B=%0d op_set=%3b", B, A, op_set);
						$display("Error expected: %6b  received: %6b", error_expected, error);
						test_result = "FAILED";
					end
				else test_result = "FAILED";
			end
		end
	end : scoreboard

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
// Temporary. The scoreboard data will be later used.
	final begin : finish_of_the_test
		$display("Test %s.",test_result);
	end
//------------------------------------------------------------------------------
endmodule : top
