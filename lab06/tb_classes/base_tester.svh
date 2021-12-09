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
//`ifdef QUESTA
//virtual class base_tester extends uvm_component;
//`else
//`ifdef INCA
// irun requires abstract class when using virtual functions
// note: irun warns about the virtual class instantiation, this will be an
// error in future releases.
virtual class base_tester extends uvm_component;

	uvm_put_port #(command_s) command_port;

	function void build_phase(uvm_phase phase);
		command_port = new("command_port", this);
	endfunction : build_phase

	pure virtual protected function operation_t get_op();
	pure virtual protected function bit [31:0] get_data();
	pure virtual protected function [3:0] CalculateCRC_4([67:0] Data);



	task run_phase(uvm_phase phase);
      bit                 [9:0]   random_crc;
      bit                 [9:0]   random_num;

		command_s command;

		phase.raise_objection(this);
		command.op = rst_op;
		command_port.put(command);

		repeat ( 5000 ) begin : random_loop
			command.op = get_op();
			command.A      = get_data();
			command.B      = get_data();

			random_num = $urandom%10;
			case (random_num)
				1: command.package_n = 8;
				9:  command.package_n = 7;
				default:  command.package_n = 9;
			endcase

			command.CRC = CalculateCRC_4({{command.B,command.A},1'b1,command.op});
			command.crc_ok = 'b1;

			random_crc = $urandom%10;

			case (random_crc)
				1: begin
					command.CRC = 4'($random);
					command.crc_ok = 'b0;
				end
				9: begin
					command.CRC = 4'($random);
					command.crc_ok = 'b0;
				end
			endcase

			command_port.put(command);
		end : random_loop
		#500
		phase.drop_objection(this);
	endtask

	function new (string name, uvm_component parent);
		super.new(name, parent);
	endfunction : new
endclass : base_tester
