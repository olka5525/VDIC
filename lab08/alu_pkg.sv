
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
 `timescale 1ns/1ps
package alu_pkg;
	import uvm_pkg::*;
	`include "uvm_macros.svh"

	typedef enum bit[2:0] {
		and_op  = 3'b000,
		or_op   = 3'b001,
		add_op  = 3'b100,
		sub_op  = 3'b101,
		rst_op  = 3'b110,
		no_op   = 3'b111
	} operation_t;

	// terminal print colors
	typedef enum {
		COLOR_BOLD_BLACK_ON_GREEN,
		COLOR_BOLD_BLACK_ON_RED,
		COLOR_BOLD_BLACK_ON_YELLOW,
		COLOR_BOLD_BLUE_ON_WHITE,
		COLOR_BLUE_ON_WHITE,
		COLOR_DEFAULT
	} print_color;

//------------------------------------------------------------------------------
// package functions
//------------------------------------------------------------------------------

	// used to modify the color of the text printed on the terminal

	function void set_print_color ( print_color c );
		string ctl;
		case(c)
			COLOR_BOLD_BLACK_ON_GREEN : ctl  = "\033\[1;30m\033\[102m";
			COLOR_BOLD_BLACK_ON_RED : ctl    = "\033\[1;30m\033\[101m";
			COLOR_BOLD_BLACK_ON_YELLOW : ctl = "\033\[1;30m\033\[103m";
			COLOR_BOLD_BLUE_ON_WHITE : ctl   = "\033\[1;34m\033\[107m";
			COLOR_BLUE_ON_WHITE : ctl        = "\033\[0;34m\033\[107m";
			COLOR_DEFAULT : ctl              = "\033\[0m\n";
			default : begin
				$error("set_print_color: bad argument");
				ctl                          = "";
			end
		endcase
		$write(ctl);
	endfunction


`include "command_transaction.svh"
`include "minmax_transaction.svh"
`include "result_transaction.svh"

`include "coverage.svh"
`include "scoreboard.svh"
`include "tester.svh"

`include "driver.svh"

`include "command_monitor.svh"
`include "result_monitor.svh"
`include "env.svh"

`include "random_test.svh"
`include "minmax_test.svh"

endpackage : alu_pkg
