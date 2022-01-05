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
module top;
	import uvm_pkg::*;
	import alu_pkg::*;
//  `include "alu_macros.svh"
	`include "uvm_macros.svh"

	alu_bfm    class_bfm();
	mtm_Alu class_ALU (.clk(class_bfm.clk), .rst_n(class_bfm.rst_n), .sin(class_bfm.sin), .sout(class_bfm.sout));

//	alu_bfm_lab4    module_bfm();
	alu_bfm    module_bfm();
	mtm_Alu module_ALU (.clk(module_bfm.clk), .rst_n(module_bfm.rst_n), .sin(module_bfm.sin), .sout(module_bfm.sout));

// stimulus generator for module_dut
	alu_tester_module stim_module(module_bfm);

	initial begin

		uvm_config_db #(virtual alu_bfm)::set(null, "*", "class_bfm", class_bfm);
		uvm_config_db #(virtual alu_bfm)::set(null, "*", "module_bfm", module_bfm);
		run_test("dual_test");
	end

endmodule : top




