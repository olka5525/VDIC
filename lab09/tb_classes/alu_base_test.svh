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
virtual class alu_base_test extends uvm_test;
    // The class will never be instantiated, does not need
    // `uvm_component_utils() macro

//------------------------------------------------------------------------------
// local variables
//------------------------------------------------------------------------------

    local env env_h;
    protected sequencer sequencer_h;

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

    function new (string name, uvm_component parent);
        super.new(name,parent);
    endfunction : new
    
//------------------------------------------------------------------------------
// build phase
//------------------------------------------------------------------------------

    function void build_phase(uvm_phase phase);
        env_h = env::type_id::create("env_h",this);
    endfunction : build_phase
    
//------------------------------------------------------------------------------
// end-of-elaboration phase
//------------------------------------------------------------------------------

    function void end_of_elaboration_phase(uvm_phase phase);
        sequencer_h = env_h.sequencer_h;
    endfunction : end_of_elaboration_phase
    
//------------------------------------------------------------------------------
// start-of-simulation phase
//------------------------------------------------------------------------------

    function void start_of_simulation();
        super.start_of_simulation();
        uvm_top.print_topology();
    endfunction : start_of_simulation

endclass
