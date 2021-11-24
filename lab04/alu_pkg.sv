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
package alu_pkg;
	typedef enum bit[2:0] {
		and_op                      = 3'b000,
		or_op                       = 3'b001,
		add_op                      = 3'b100,
		sub_op                      = 3'b101,
		rst_op                      = 3'b110,
		no_op                       = 3'b111
	} operation_t;


`include "tester.svh"
`include "coverage.svh"
`include "scoreboard.svh"
`include "testbench.svh"


endpackage : alu_pkg
