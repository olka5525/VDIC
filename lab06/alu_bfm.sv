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
	bit                         start;

	bit         signed  [31:0]  result;
	bit                 [3:0]   package_n;
	bit                 [3:0]   flags;
	bit                 [2:0]   crc_out;
	bit                         done;
	bit                 [3:0]   CRC;
	bit                         crc_ok;
	bit                 [5:0]   error;
	bit                         correct;
	operation_t                 op_set;

	//assign op = op_set;

//------------------------------------------------------------------------------
// reset task
//------------------------------------------------------------------------------
	task reset_alu();
	`ifdef DEBUG
		$display("%0t DEBUG: reset_alu", $time);
	`endif
		start = 1'b0;
		rst_n = 1'b0;
		sin = '1;
		@(negedge clk);
		rst_n = 1'b1;
	endtask

	task send_op(input bit signed [31:0] iA, input bit signed [31:0] iB, input operation_t iop, input bit [3:0] ipackage_n,input bit [3:0] iCRC,input bit icrc_ok,
			bit signed [31:0] result);

		op_set = iop;
		A      = iA;
		B      = iB;
		package_n = ipackage_n;
		CRC     = iCRC;
		crc_ok = icrc_ok;

		BA = {B,A};

		start = 1'b1;
		@(posedge clk);
		@(posedge clk);
		case(op_set)
			
			rst_op: begin
				reset_alu();
			end
			no_op: begin
				@(negedge clk);
				start = 1'b0;
			end
			default: begin
				start = 1'b0;
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
						result[31-(8*i)-:8] = out[52-(11*i)-:8];
					end
					flags = out[7:4];
					crc_out = out[3:1];
					correct = '1;
				end
				else begin
					error = out[51:46];
					correct = '0;
				end
				@(negedge clk);
				@(negedge clk);
				done ='1;
			end
		endcase
	endtask : send_op


	command_monitor command_monitor_h;


	always @(posedge clk) begin : op_monitor
		static bit in_command = 0;
		command_s command;
		if (start) begin : start_high
			if (!in_command) begin : new_command
				command.A   <= A;
				command.B   <= B;
				command.op  <= op_set;
				command.package_n   <= package_n;
				command.CRC <= CRC;
				command.crc_ok      <= crc_ok;
				command.done <= done;
				command.correct <= correct;
				command.flags <= flags;
				command.error <= error;

				command_monitor_h.write_to_monitor(command);
				in_command = (command.op != no_op);
			end : new_command
		end : start_high
		else // start low
			in_command = 0;
	end : op_monitor

	always @(negedge rst_n) begin : rst_monitor
		command_s command;
		command.op <= rst_op;
		if (command_monitor_h != null) //guard against VCS time 0 negedge
			command_monitor_h.write_to_monitor(command);
	end : rst_monitor

	result_monitor result_monitor_h;

	initial begin : result_monitor_thread
		forever begin
			@(posedge clk) ;
			if (done)  begin
				result_monitor_h.write_to_monitor(result);
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


endinterface : alu_bfm


