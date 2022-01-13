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
class minmax_sequence extends uvm_sequence #(sequence_item);
	`uvm_object_utils(minmax_sequence)

//------------------------------------------------------------------------------
// local variables
//------------------------------------------------------------------------------

	sequence_item req;

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

	function new(string name = "minmax_sequence");
		super.new(name);
	endfunction : new

//------------------------------------------------------------------------------
// the sequence body
//------------------------------------------------------------------------------

	task body();
		`uvm_info("SEQ_MINMAX","",UVM_MEDIUM)
		`uvm_do_with(req, {op == rst_op;})

		repeat (10) begin

			`uvm_rand_send_with(req, {A dist {'h00000000:=1, ['h000000001 : 'hFFFFFFFE]:/1, 'hFFFFFFFF:=1}; B dist {'h00000000:=1, ['h000000001 : 'hFFFFFFFE]:/1, 'hFFFFFFFF:=1};})
		end
	endtask : body


endclass : minmax_sequence











