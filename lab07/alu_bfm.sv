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
import alu_pkg::*;

interface alu_bfm;


	bit         signed  [31:0]  A;
	bit         signed  [31:0]  B;
	bit                 [63:0]  BA;
	bit                         clk;
	bit                         rst_n;
	bit                         sin;
	logic                       sout;
	bit                         start='0;

	bit         signed  [31:0]  result;
	bit                 [3:0]   package_n;
	bit                 [3:0]   flags;
	bit                 [3:0]   flags_out;
	bit                 [2:0]   crc_out;
	bit                         done;
	bit                         crc_ok;
	bit                 [5:0]   error;
	operation_t                 op_set;

	command_monitor             command_monitor_h;
	result_monitor              result_monitor_h;

//------------------------------------------------------------------------------
// reset task
//------------------------------------------------------------------------------
	task reset_alu();
	`ifdef DEBUG
		$display("%0t DEBUG: reset_alu", $time);
	`endif
		start = 1'b0;
		rst_n = 1'b0;
		sin = 1'b1;
		@(negedge clk);
		rst_n = 1'b1;
	endtask

	task send_op(input bit signed [31:0] iA,
			input bit signed [31:0] iB,
			input operation_t iop,
			input bit [3:0] ipackage_n,
			input bit icrc_ok);

		bit signed  [31:0]  iresult;
		bit                 [98:0]  in;
		logic               [54:0]  out;
		bit                 [3:0]   CRC;

		op_set = iop;
		A      = iA;
		B      = iB;
		package_n = ipackage_n;
		crc_ok = icrc_ok;
		CRC     =  CalculateCRC_4({B,A,1'b1,op_set}, crc_ok);
		flags = get_flags(B,A,op_set);

		BA = {B,A};
		start = 1'b1;
		case(op_set)

			rst_op: begin
				reset_alu();
			end
			default: begin
				@(posedge clk);
				start = 1'b0;
				for (int i=0; i<package_n; i++) begin
					in[98-(11*i)-:11]= {2'b00, BA[63-(8*i)-:8], 1'b1};
				end
				in[10:0] = {3'b010, op_set, CRC, 1'b1};

				if (package_n>9) begin
					for (int i=0; i<00; i++) begin
						@(negedge clk);
						sin=in[98-i];
					end
				end
				else begin
					for (int i=0; i<11*(package_n-1); i++) begin
						@(negedge clk);
						sin=in[98-i];
					end
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
						iresult[31-(8*i)-:8] = out[52-(11*i)-:8];
					end
					flags_out = out[7:4];
					crc_out = out[3:1];
					result=iresult;
					error = '0;
				end
				else begin
					error = out[51:46];
					flags_out='0;
					crc_out=0;
					result = '0;
				end
				done ='1;
			end
		endcase
	endtask : send_op

	always @(posedge clk) begin : op_monitor
		static bit in_command = 0;
		command_transaction command;
		if (start) begin : start_high
			if (!in_command) begin : new_command
				command_monitor_h.write_to_monitor(A,B,op_set,package_n, crc_ok, flags);
				in_command = (op_set != no_op);
			end : new_command
		end : start_high
		else // start low
			in_command = 0;
	end : op_monitor

	always @(negedge rst_n) begin : rst_monitor
		command_transaction command;
		if (command_monitor_h != null) //guard against VCS time 0 negedge
			command_monitor_h.write_to_monitor(32'($random),32'($random),rst_op,8,1,0);
	end : rst_monitor

	initial begin : result_monitor_thread
		forever begin
			@(posedge clk) ;
			if (done)  begin
				result_monitor_h.write_to_monitor(flags_out,crc_out,error,result);
				done = '0;
			//@(negedge done);
			end
		end
	end : result_monitor_thread


	initial begin
		clk = 0;
		forever begin
			#10;
			clk = ~clk;
		end
	end

	function [3:0] CalculateCRC_4([67:0] Data, bit ok);
		reg [67:0] d;
		reg [3:0] c;
		reg [3:0] newcrc;

		d = Data;
		c = '0;
		newcrc[0] = d[66] ^ d[64] ^ d[63] ^ d[60] ^ d[56] ^ d[55] ^ d[54] ^ d[53] ^ d[51] ^ d[49] ^ d[48] ^ d[45] ^ d[41] ^ d[40] ^ d[39] ^ d[38] ^ d[36] ^ d[34] ^ d[33] ^ d[30] ^ d[26] ^ d[25] ^ d[24] ^ d[23] ^ d[21] ^ d[19] ^ d[18] ^ d[15] ^ d[11] ^ d[10] ^ d[9] ^ d[8] ^ d[6] ^ d[4] ^ d[3] ^ d[0] ^ c[0] ^ c[2];
		newcrc[1] = d[67] ^ d[66] ^ d[65] ^ d[63] ^ d[61] ^ d[60] ^ d[57] ^ d[53] ^ d[52] ^ d[51] ^ d[50] ^ d[48] ^ d[46] ^ d[45] ^ d[42] ^ d[38] ^ d[37] ^ d[36] ^ d[35] ^ d[33] ^ d[31] ^ d[30] ^ d[27] ^ d[23] ^ d[22] ^ d[21] ^ d[20] ^ d[18] ^ d[16] ^ d[15] ^ d[12] ^ d[8] ^ d[7] ^ d[6] ^ d[5] ^ d[3] ^ d[1] ^ d[0] ^ c[1] ^ c[2] ^ c[3];
		newcrc[2] = d[67] ^ d[66] ^ d[64] ^ d[62] ^ d[61] ^ d[58] ^ d[54] ^ d[53] ^ d[52] ^ d[51] ^ d[49] ^ d[47] ^ d[46] ^ d[43] ^ d[39] ^ d[38] ^ d[37] ^ d[36] ^ d[34] ^ d[32] ^ d[31] ^ d[28] ^ d[24] ^ d[23] ^ d[22] ^ d[21] ^ d[19] ^ d[17] ^ d[16] ^ d[13] ^ d[9] ^ d[8] ^ d[7] ^ d[6] ^ d[4] ^ d[2] ^ d[1] ^ c[0] ^ c[2] ^ c[3];
		newcrc[3] = d[67] ^ d[65] ^ d[63] ^ d[62] ^ d[59] ^ d[55] ^ d[54] ^ d[53] ^ d[52] ^ d[50] ^ d[48] ^ d[47] ^ d[44] ^ d[40] ^ d[39] ^ d[38] ^ d[37] ^ d[35] ^ d[33] ^ d[32] ^ d[29] ^ d[25] ^ d[24] ^ d[23] ^ d[22] ^ d[20] ^ d[18] ^ d[17] ^ d[14] ^ d[10] ^ d[9] ^ d[8] ^ d[7] ^ d[5] ^ d[3] ^ d[2] ^ c[1] ^ c[3];
		CalculateCRC_4 = newcrc;
		if (~ok) begin
			CalculateCRC_4 = ~CalculateCRC_4;
		end
	endfunction

	function [3:0] get_flags(bit signed [31:0] A,bit signed  [31:0] B,operation_t op);
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

	function logic get_expected_33(
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

endinterface : alu_bfm


