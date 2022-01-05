
module alu_tester_module(alu_bfm bfm);
	import alu_pkg::*;


	function [3:0] CalculateCRC_4([67:0] Data, bit ok);
		reg [67:0] d;
		reg [3:0] c;
		reg [3:0] newcrc;
		if (ok) begin
			d = Data;
			c = '0;
			newcrc[0] = d[66] ^ d[64] ^ d[63] ^ d[60] ^ d[56] ^ d[55] ^ d[54] ^ d[53] ^ d[51] ^ d[49] ^ d[48] ^ d[45] ^ d[41] ^ d[40] ^ d[39] ^ d[38] ^ d[36] ^ d[34] ^ d[33] ^ d[30] ^ d[26] ^ d[25] ^ d[24] ^ d[23] ^ d[21] ^ d[19] ^ d[18] ^ d[15] ^ d[11] ^ d[10] ^ d[9] ^ d[8] ^ d[6] ^ d[4] ^ d[3] ^ d[0] ^ c[0] ^ c[2];
			newcrc[1] = d[67] ^ d[66] ^ d[65] ^ d[63] ^ d[61] ^ d[60] ^ d[57] ^ d[53] ^ d[52] ^ d[51] ^ d[50] ^ d[48] ^ d[46] ^ d[45] ^ d[42] ^ d[38] ^ d[37] ^ d[36] ^ d[35] ^ d[33] ^ d[31] ^ d[30] ^ d[27] ^ d[23] ^ d[22] ^ d[21] ^ d[20] ^ d[18] ^ d[16] ^ d[15] ^ d[12] ^ d[8] ^ d[7] ^ d[6] ^ d[5] ^ d[3] ^ d[1] ^ d[0] ^ c[1] ^ c[2] ^ c[3];
			newcrc[2] = d[67] ^ d[66] ^ d[64] ^ d[62] ^ d[61] ^ d[58] ^ d[54] ^ d[53] ^ d[52] ^ d[51] ^ d[49] ^ d[47] ^ d[46] ^ d[43] ^ d[39] ^ d[38] ^ d[37] ^ d[36] ^ d[34] ^ d[32] ^ d[31] ^ d[28] ^ d[24] ^ d[23] ^ d[22] ^ d[21] ^ d[19] ^ d[17] ^ d[16] ^ d[13] ^ d[9] ^ d[8] ^ d[7] ^ d[6] ^ d[4] ^ d[2] ^ d[1] ^ c[0] ^ c[2] ^ c[3];
			newcrc[3] = d[67] ^ d[65] ^ d[63] ^ d[62] ^ d[59] ^ d[55] ^ d[54] ^ d[53] ^ d[52] ^ d[50] ^ d[48] ^ d[47] ^ d[44] ^ d[40] ^ d[39] ^ d[38] ^ d[37] ^ d[35] ^ d[33] ^ d[32] ^ d[29] ^ d[25] ^ d[24] ^ d[23] ^ d[22] ^ d[20] ^ d[18] ^ d[17] ^ d[14] ^ d[10] ^ d[9] ^ d[8] ^ d[7] ^ d[5] ^ d[3] ^ d[2] ^ c[1] ^ c[3];
			CalculateCRC_4 = newcrc;
		end
		else
			CalculateCRC_4 = 4'($random);
	endfunction

	initial begin
		bit signed [31:0]   iA;
		bit signed [31:0]   iB;
		bit signed  [31:0]  result;
		bit         [3:0]   package_n;
		bit                 crc_ok;
		bit         [3:0]   CRC;
		bit         [3:0]   flags;
		bit ok;
		operation_t         op_set;

		bfm.reset_alu();
		repeat (30) begin : random_loop
			ok = std::randomize(op_set) with {op_set dist {and_op:=2, sub_op:=2,or_op:=2, add_op:=2, rst_op:=1, no_op:=1};};
			ok = std::randomize(iA) with {iA dist {'h00000000:=1, ['h000000001 : 'hFFFFFFFE]:/1, 'hFFFFFFFF:=1}; };
			ok = std::randomize(iB) with {iB dist {'h00000000:=1, ['h000000001 : 'hFFFFFFFE]:/1, 'hFFFFFFFF:=1}; };
			ok = std::randomize(package_n) with {package_n dist {8:=1,9:=98,10:=1 }; };
			ok = std::randomize(crc_ok )   with {crc_ok dist{1:=99, 0:=1};};
			CRC = CalculateCRC_4({iB,iA,1'b1,op_set}, crc_ok);

			bfm.send_op(iA,iB, op_set, package_n, CRC, crc_ok, flags, result );

		end : random_loop
	end // initial begin

endmodule : alu_tester_module





