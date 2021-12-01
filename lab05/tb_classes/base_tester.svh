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
//`else
//class base_tester extends uvm_component;
//`endif
//`endif

	`uvm_component_utils(base_tester)

	virtual alu_bfm bfm;

	function new (string name, uvm_component parent);
		super.new(name, parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		if(!uvm_config_db #(virtual alu_bfm)::get(null, "*","bfm", bfm))
			$fatal(1,"Failed to get BFM");
	endfunction : build_phase

	pure virtual function operation_t get_op();

	pure virtual function bit [31:0] get_data();

	pure virtual function [3:0] CalculateCRC_4([67:0] Data);

	task run_phase(uvm_phase phase);
		bit         signed  [31:0]  iA;
		bit         signed  [31:0]  iB;
		bit                 [3:0]   package_n;
		bit                         crc_ok;
		operation_t                op_set;
		bit                 [9:0]   random_crc;
		bit                 [9:0]   random_num;
		bit         signed  [31:0]  result;
		bit                 [3:0]   CRC;

		phase.raise_objection(this);

		bfm.reset_alu();
		repeat (5000) begin : tester_main
			@(negedge bfm.clk);
			op_set = get_op();
			iA      = get_data();
			iB      = get_data();

			random_num = $urandom%10;
			case (random_num)
				1: package_n = 8;
				9:  package_n = 7;
				default:  package_n = 9;
			endcase

			CRC = CalculateCRC_4({{iB,iA},1'b1,op_set});

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

			bfm.send_op(iA, iB, op_set, package_n, CRC, crc_ok, result);
		end
		phase.drop_objection(this);
	endtask
endclass : base_tester
