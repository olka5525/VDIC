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
virtual class shape;
	protected real width=-1;
	protected real height=-1;

	pure virtual function real get_area();
	pure virtual function void print();

	function new(real w, real h);
		width = w;
		height = h;
	endfunction : new

endclass : shape


class rectangle extends shape;

	function real get_area();
		return width*height;
	endfunction

	function new(real w, real h);
		super.new(w,h);
	endfunction : new


	function void print();
		$display("Rectangle w=%g h=%g area=%g", width, height, get_area());
	endfunction

endclass

class triangle extends shape;

	function real get_area();
		return width*height/2;
	endfunction

	function new(real w, real h);
		super.new(w,h);
	endfunction : new

	function void print();
		$display("Triangle w=%g h=%g area=%g", width, height, get_area());
	endfunction

endclass

class square extends rectangle;

	function new(real w, real h);
		super.new(w,w);
	endfunction : new

	function void print();
		$display("Square w=%g area=%g", width, height, get_area());
	endfunction

endclass

class shape_reporter #(type T = shape);

	protected static T shape_storage[$];

	static function void add_shape(T new_shape);
		shape_storage.push_back(new_shape);
	endfunction

	static function void report_shape();
		real area = 0;
		foreach(shape_storage[i]) begin
			shape_storage[i].print();
			area = area + shape_storage[i].get_area();
		end
		$display("%g", area);

	endfunction : report_shape


endclass : shape_reporter

class shape_factory;

	static function shape make_shape(string shape_type,
			real w, real h);
		rectangle rectangle_h;
		triangle triangle_h;
		square square_h;
		case (shape_type)
			"rectangle" : begin
				rectangle_h = new(w, h);
				shape_reporter#(rectangle)::add_shape(rectangle_h);
				return rectangle_h;
			end

			"triangle" : begin
				triangle_h = new(w, h);
				shape_reporter#(triangle)::add_shape(triangle_h);
				return triangle_h;
			end

			"square" : begin
				square_h = new(w, h);
				shape_reporter#(square)::add_shape(square_h);
				return square_h;
			end

			default :
				$fatal (1, {"No such shape: ", shape_type});

		endcase // case (shape_type)

	endfunction : make_shape

endclass : shape_factory


module top;

	initial begin
		int file,code;
		string shape_s, w,l;
		$display("Start");
		file= $fopen("lab04part1_shapes.txt", "r");
		while(! $feof(file)==1) begin
			code = $fscanf(file, "%s %s %s", shape_s, w, l);
			if(code != -1) begin

			void'(shape_factory::make_shape(shape_s, w.atoreal(), l.atoreal()));

			end
		end
		shape_reporter#(rectangle)::report_shape();
		shape_reporter#(triangle)::report_shape();
		shape_reporter#(square)::report_shape();
	end

endmodule : top




