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
class tester extends uvm_component;
	`uvm_component_utils (tester)

//------------------------------------------------------------------------------
// local variables
//------------------------------------------------------------------------------

	uvm_put_port #(command_transaction) command_port;

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

	function new (string name, uvm_component parent);
		super.new(name, parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		command_port = new("command_port", this);
	endfunction : build_phase

//------------------------------------------------------------------------------
// run phase
//------------------------------------------------------------------------------

	task run_phase(uvm_phase phase);
//      bit                 [9:0]   random_crc;
//      bit                 [9:0]   random_num;

		command_transaction command;

		phase.raise_objection(this);

		command    = new("command");
		command.op = rst_op;
		command_port.put(command);

		command    = command_transaction::type_id::create("command");

		repeat ( 500 ) begin : random_loop
			assert(command.randomize());
			command_port.put(command);
		end
		
		command.op = rst_op;
		command_port.put(command);

		#500
		phase.drop_objection(this);
	endtask

endclass :tester
