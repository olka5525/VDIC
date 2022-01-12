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
class minmax_test extends alu_base_test;
    `uvm_component_utils(minmax_test)

//------------------------------------------------------------------------------
// local variables
//------------------------------------------------------------------------------
   
   local minmax_sequence minmax_seq;

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
   
   function new (string name, uvm_component parent);
      super.new(name,parent);
   endfunction : new
   
//------------------------------------------------------------------------------
// run_phase
//------------------------------------------------------------------------------
   
   task run_phase(uvm_phase phase);
      minmax_seq = new("minmax_seq");
      phase.raise_objection(this);
      minmax_seq.start(sequencer_h); // the sequence gets the sequencer by its own
      phase.drop_objection(this);
   endtask : run_phase


endclass

