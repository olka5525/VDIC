
module top;

//------------------------------------------------------------------------------
// type and variable definitions
//------------------------------------------------------------------------------

	typedef enum bit[2:0] {and_op = 3'b000,
		or_op                    = 3'b001,
		add_op                   = 3'b100,
		sub_op                   = 3'b101,
		not_used0                = 3'b011,
		not_used1                = 3'b010,
		not_used2                = 3'b111,
		not_used3                = 3'b110
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

	bit                 [31:0]  expected;
	bit                 [3:0]   flags_expected;
	bit                 [2:0]   crc_expected;
	bit         signed  [31:0]  result;

	bit                 [4:0]   package_n;

	bit                 [3:0]   flags;
	bit                 [2:0]   crc_out;
	bit                 [3:0]   CRC;

	bit                         crc_ok;
	bit                 [5:0]   error;
	bit                 [5:0]   error_expected;

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
		op_choice = $random;
		case (op_choice)
			3'b000 : return and_op;
			3'b001 : return  or_op;
			3'b100 : return add_op;
			3'b101 : return sub_op;
			3'b011 : return not_used0;
			3'b010 : return not_used1;
			3'b111 : return not_used2;
			3'b110 : return not_used3;
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
		@(negedge clk);
		sin =1'b1;
		repeat (5) begin : tester_main
			@(negedge clk);
			op_set = get_op();
			A      = get_data();
			B      = get_data();

			random_num = $urandom%10;
			case (random_num)
				1: package_n = 5;
				9:  package_n = 6;
				default:  package_n = 9;
			endcase

			//package_n = 9;
			BA = {B,A};
			out = '0;
			crc_ok = 1'b1;
			CRC = CalculateCRC_4({BA,1'b1,op_set});

			random_crc = $urandom%10;

			case (random_crc)
				1: begin
					CRC = 4'($random);//8;
					crc_ok = 'b0;
				end
				9: begin
					CRC = 4'($random);//$random%5+4;
					crc_ok = 'b0;
				end

			endcase


			for (int i=0; i<package_n; i++) begin
				in[98-(11*i)-:11]= {2'b00, BA[63-(8*i)-:8], 1'b1};
			end
			in[10:0] = {3'b010, op_set, CRC, 1'b1};

			//for (int i=98; i<=99-package_n*11; i--) begin
//			for (int i=98; i>=0; i--) begin
//				@(negedge clk);
//				sin=in[i];
//			end
			package_n =8;
			for (int i=0; i<11*package_n; i++) begin
				@(negedge clk);
				
				sin=in[98-i];
				$display("i = %0d", i);
			end
			$display("for end");
			@(negedge sout);

			for (int i=0; i<55; i++) begin
				@(negedge clk);
				out[54-i]= sout;
			end

			@(negedge clk);

			if (out[54:53] == 'b00) begin //correct

				for (int i=0; i<4; i++) begin
					result[31-(8*i)-:8] = out [52-(11*i)-:8];
				end
				flags = out[7:4];
				crc_out = out[3:1];

				begin
					expected = get_expected( B,A, op_set);
					assert(result === expected)
					else begin
						$display("Test FAILED for A=%0d B=%0d op_set=%0d", A, B, op_set);
						$display("Expected: %d  received: %d", expected, result);
						test_result = "FAILED";
					end



					flags_expected = get_flags( B,A, op_set);
					assert(flags === flags_expected)
					else begin
						$display("Test FAILED for A=%0d B=%0d op_set=%0d", A, B, op_set);
						$display("Flags expected: %d  received: %d", flags_expected, flags);
						test_result = "FAILED";
					end


					crc_expected = CalculateCRC_3( {expected, 1'b0, flags_expected});
					assert(crc_out === crc_expected)
					else begin
						$display("Test FAILED for A=%0d B=%0d op_set=%0d", B, A, op_set);
						$display("CRC expected: %d  received: %d", crc_expected, crc_out);
						test_result = "FAILED";
					end


				end
			end
			else begin //error


				error = out[51:46];

				error_expected = get_error(crc_ok, package_n, op_set);
				if          (error[0])
					assert(error_expected[0] === error[0])
					else    begin
						$display("Test FAILED for A=%0d B=%0d op_set=%3b", B, A, op_set);
						$display("Error expected: %6b  received: %6b", error_expected, error);
						test_result = "FAILED";
					end
				else if     (error[1])
					assert(error_expected[1] === error[1])
					else    begin
						$display("Test FAILED for A=%0d B=%0d op_set=%3b", B, A, op_set);
						$display("Error expected: %6b  received: %6b", error_expected, error);
						test_result = "FAILED";
					end
				else if     (error[2])
					assert(error_expected[2] === error[2])
					else begin
						$display("Test FAILED for A=%0d B=%0d op_set=%3b", B, A, op_set);
						$display("Error expected: %6b  received: %6b", error_expected, error);
						test_result = "FAILED";
					end
				else test_result = "FAILED";


			end


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
		//start   = 1'b0;
		rst_n = 1'b0;
		sin =1'b1;
		@(negedge clk);
		rst_n = 1'b1;
	endtask

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
			if (package_n != 8) begin
				error[1] = '1;
				error[4] = '1;
			end

			if (op_set == not_used0 || op_set == not_used1 || op_set == not_used2 || op_set == not_used3) begin
				error[2] = '1;
				error[5] = '1;
			end

			if (!crc_ok) begin
				error[0] = '1;
				error[3] = '1;
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