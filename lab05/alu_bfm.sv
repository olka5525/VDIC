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
interface alu_bfm;
	import alu_pkg::*;

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
	bit                         done='0;
	bit                 [3:0]   CRC;
	bit                         crc_ok;
	bit                 [5:0]   error;
	bit                         correct='0;

	operation_t        op_set;


	assign op = op_set;

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



	task send_op(input bit [31:0] iA, input bit [31:0] iB, input operation_t iop, input bit [3:0] ipackage_n, bit [3:0] iCRC, bit icrc_ok,
			output bit signed [31:0] iresult);

		op_set = iop;
		A      = iA;
		B      = iB;
		package_n = ipackage_n;
		CRC     = iCRC;
		crc_ok = icrc_ok;

		BA = {B,A};

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
	endtask : send_op
endinterface : alu_bfm


