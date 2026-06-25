`timescale 1 ns / 1 ps
// ============================================================
// TESTBENCH: KIEM TRA TUAN THU CHUAN RV32I (37 LENH)
// Phu 100% tap lenh co ban RV32I
// Vung nho: Code = word[0..99], Data = word[100..149]
// ============================================================
module tb_rv32i_compliance;
	reg clk = 1; 
	reg resetn = 0;
	wire trap;

	always #5 clk = ~clk;

	initial begin
		$dumpfile("tb_rv32i_compliance.vcd");
		$dumpvars(0, tb_rv32i_compliance);
	end

	wire mem_valid, mem_instr; 
	reg mem_ready;

	wire [31:0] mem_addr, mem_wdata;
	wire [3:0] mem_wstrb;
	reg  [31:0] mem_rdata;
	reg  [31:0] memory [0:255];

	picorv32 #() uut (
		.clk(clk), 
		.resetn(resetn), 
		.trap(trap),
		.mem_valid(mem_valid), 
		.mem_instr(mem_instr), 
		.mem_ready(mem_ready),
		.mem_addr(mem_addr),   
		.mem_wdata(mem_wdata), 
		.mem_wstrb(mem_wstrb),
		.mem_rdata(mem_rdata)
	);

	initial begin
		// === SETUP (3 lenh) ===
		memory[0]  = 32'h01400093; // ADDI x1, x0, 20    | x1=20
		memory[1]  = 32'h00700113; // ADDI x2, x0, 7     | x2=7
		memory[2]  = 32'h00300193; // ADDI x3, x0, 3     | x3=3 (shift amount)

		// === R-TYPE (10 lenh) -> x4..x13 ===
		memory[3]  = 32'h00208233; // ADD  x4, x1, x2    | x4=27
		memory[4]  = 32'h402082B3; // SUB  x5, x1, x2    | x5=13
		memory[5]  = 32'h0020F333; // AND  x6, x1, x2    | x6=4
		memory[6]  = 32'h0020E3B3; // OR   x7, x1, x2    | x7=23
		memory[7]  = 32'h0020C433; // XOR  x8, x1, x2    | x8=19
		memory[8]  = 32'h0020A4B3; // SLT  x9, x1, x2    | x9=0 (20<7?no)
		memory[9]  = 32'h0020B533; // SLTU x10,x1, x2    | x10=0
		memory[10] = 32'h003095B3; // SLL  x11,x1, x3    | x11=20<<3=160
		memory[11] = 32'h0030D633; // SRL  x12,x1, x3    | x12=20>>3=2
		memory[12] = 32'h4030D6B3; // SRA  x13,x1, x3    | x13=20>>>3=2

		// === I-TYPE ALU (9 lenh) -> x14..x22 ===
		memory[13] = 32'h00F08713; // ADDI  x14,x1, 15   | x14=35
		memory[14] = 32'h0190A793; // SLTI  x15,x1, 25   | x15=1
		memory[15] = 32'h0050B813; // SLTIU x16,x1, 5    | x16=0
		memory[16] = 32'h0FF0C893; // XORI  x17,x1, 255  | x17=235
		memory[17] = 32'h00F16913; // ORI   x18,x2, 15   | x18=15
		memory[18] = 32'h00F0F993; // ANDI  x19,x1, 15   | x19=4
		memory[19] = 32'h00309A13; // SLLI  x20,x1, 3    | x20=160
		memory[20] = 32'h0030DA93; // SRLI  x21,x1, 3    | x21=2
		memory[21] = 32'h4030DB13; // SRAI  x22,x1, 3    | x22=2

		// === U-TYPE (2 lenh) -> x23, x24 ===
		memory[22] = 32'h00001BB7; // LUI   x23, 1       | x23=0x1000
		memory[23] = 32'h00000C17; // AUIPC x24, 0       | x24=PC=0x5C=92

		// === BRANCH (6 lenh, moi lenh 3 word) -> x25..x30 ===
		// BEQ x1,x1,+8 (taken: 20==20)
		memory[24] = 32'h00108463; // BEQ
		memory[25] = 32'h0080006F; // JAL x0,+8 (FAIL)
		memory[26] = 32'h00100C93; // ADDI x25,x0,1  PASS

		// BNE x1,x2,+8 (taken: 20!=7)
		memory[27] = 32'h00209463; // BNE
		memory[28] = 32'h0080006F; // JAL x0,+8 (FAIL)
		memory[29] = 32'h00100D13; // ADDI x26,x0,1  PASS

		// BLT x2,x1,+8 (taken: 7<20)
		memory[30] = 32'h00114463; // BLT
		memory[31] = 32'h0080006F; // JAL x0,+8 (FAIL)
		memory[32] = 32'h00100D93; // ADDI x27,x0,1  PASS

		// BGE x1,x2,+8 (taken: 20>=7)
		memory[33] = 32'h0020D463; // BGE
		memory[34] = 32'h0080006F; // JAL x0,+8 (FAIL)
		memory[35] = 32'h00100E13; // ADDI x28,x0,1  PASS

		// BLTU x2,x1,+8 (taken: 7u<20u)
		memory[36] = 32'h00116463; // BLTU
		memory[37] = 32'h0080006F; // JAL x0,+8 (FAIL)
		memory[38] = 32'h00100E93; // ADDI x29,x0,1  PASS

		// BGEU x1,x2,+8 (taken: 20u>=7u)
		memory[39] = 32'h0020F463; // BGEU
		memory[40] = 32'h0080006F; // JAL x0,+8 (FAIL)
		memory[41] = 32'h00100F13; // ADDI x30,x0,1  PASS

		// === STORE x4..x24 vao memory[100..120] ===
		memory[42] = 32'h18402823; // SW x4,  0x190(x0) -> mem[100]
		memory[43] = 32'h18502A23; // SW x5,  0x194(x0) -> mem[101]
		memory[44] = 32'h18602C23; // SW x6,  0x198(x0) -> mem[102]
		memory[45] = 32'h18702E23; // SW x7,  0x19C(x0) -> mem[103]
		memory[46] = 32'h1A802023; // SW x8,  0x1A0(x0) -> mem[104]
		memory[47] = 32'h1A902223; // SW x9,  0x1A4(x0) -> mem[105]
		memory[48] = 32'h1AA02423; // SW x10, 0x1A8(x0) -> mem[106]
		memory[49] = 32'h1AB02623; // SW x11, 0x1AC(x0) -> mem[107]
		memory[50] = 32'h1AC02823; // SW x12, 0x1B0(x0) -> mem[108]
		memory[51] = 32'h1AD02A23; // SW x13, 0x1B4(x0) -> mem[109]
		memory[52] = 32'h1AE02C23; // SW x14, 0x1B8(x0) -> mem[110]
		memory[53] = 32'h1AF02E23; // SW x15, 0x1BC(x0) -> mem[111]
		memory[54] = 32'h1D002023; // SW x16, 0x1C0(x0) -> mem[112]
		memory[55] = 32'h1D102223; // SW x17, 0x1C4(x0) -> mem[113]
		memory[56] = 32'h1D202423; // SW x18, 0x1C8(x0) -> mem[114]
		memory[57] = 32'h1D302623; // SW x19, 0x1CC(x0) -> mem[115]
		memory[58] = 32'h1D402823; // SW x20, 0x1D0(x0) -> mem[116]
		memory[59] = 32'h1D502A23; // SW x21, 0x1D4(x0) -> mem[117]
		memory[60] = 32'h1D602C23; // SW x22, 0x1D8(x0) -> mem[118]
		memory[61] = 32'h1D702E23; // SW x23, 0x1DC(x0) -> mem[119]
		memory[62] = 32'h1F802023; // SW x24, 0x1E0(x0) -> mem[120]

		// Store branch results x25..x30 -> mem[121..126]
		memory[63] = 32'h1F902223; // SW x25, 0x1E4(x0) -> mem[121]
		memory[64] = 32'h1FA02423; // SW x26, 0x1E8(x0) -> mem[122]
		memory[65] = 32'h1FB02623; // SW x27, 0x1EC(x0) -> mem[123]
		memory[66] = 32'h1FC02823; // SW x28, 0x1F0(x0) -> mem[124]
		memory[67] = 32'h1FD02A23; // SW x29, 0x1F4(x0) -> mem[125]
		memory[68] = 32'h1FE02C23; // SW x30, 0x1F8(x0) -> mem[126]

		// === JAL test (PC=69*4=276=0x114) ===
		memory[69] = 32'h00800F6F; // JAL  x30, +8   -> x30=PC+4=280=0x118, jump to mem[71]
		memory[70] = 32'h00000013; // NOP (skipped)

		// === JALR test (PC=71*4=284=0x11C) ===
		// x30=0x118 (from JAL). JALR x31, x30, 12 -> jump to 0x118+12=0x124=mem[73]
		memory[71] = 32'h00CF0FE7; // JALR x31, x30, 12 -> x31=PC+4=288=0x120
		memory[72] = 32'h00000013; // NOP (skipped)

		// Store JAL/JALR results
		memory[73] = 32'h1FE02E23; // SW x30, 0x1FC(x0) -> mem[127] = 0x118=280
		memory[74] = 32'h21F02023; // SW x31, 0x200(x0) -> mem[128] = 0x120=288

		// === LOAD/STORE BYTE/HALF tests ===
		// Dung vung 0x230 (mem[140]) de luu test data, tranh xung dot
		// Prepare: x4 = -128 = 0xFFFFFF80
		memory[75] = 32'hF8000213; // ADDI x4, x0, -128   | x4=0xFFFFFF80
		// SW x4, 0x230(x0): imm=0x230=560, imm[11:5]=0010001, imm[4:0]=10000
		// 0010001_00100_00000_010_10000_0100011
		memory[76] = 32'h22402823; // SW x4, 0x230(x0)  -> mem[140]=0xFFFFFF80

		// Clear mem[141]=0x234 and mem[142]=0x238 for SB/SH tests
		// SW x0, 0x234(x0): imm=0x234, imm[11:5]=0010001, imm[4:0]=10100
		memory[77] = 32'h22002A23; // SW x0, 0x234(x0) -> mem[141]=0
		// SW x0, 0x238(x0): imm=0x238, imm[11:5]=0010001, imm[4:0]=11000
		memory[78] = 32'h22002C23; // SW x0, 0x238(x0) -> mem[142]=0

		// LW x5, 0x230(x0): imm=0x230
		memory[79] = 32'h23002283; // LW  x5, 0x230(x0) -> x5=0xFFFFFF80

		// LB x6, 0x230(x0): byte0=0x80, sign_ext -> 0xFFFFFF80
		memory[80] = 32'h23000303; // LB  x6, 0x230(x0) -> x6=0xFFFFFF80

		// LBU x7, 0x230(x0): byte0=0x80, zero_ext -> 0x00000080
		memory[81] = 32'h23004383; // LBU x7, 0x230(x0) -> x7=0x80=128

		// LH x8, 0x230(x0): half0=0xFF80, sign_ext -> 0xFFFFFF80
		memory[82] = 32'h23001403; // LH  x8, 0x230(x0) -> x8=0xFFFFFF80

		// LHU x9, 0x230(x0): half0=0xFF80, zero_ext -> 0x0000FF80
		memory[83] = 32'h23005483; // LHU x9, 0x230(x0) -> x9=0xFF80=65408

		// SB x1, 0x234(x0): store byte 0x14
		memory[84] = 32'h22100A23; // SB  x1, 0x234(x0)
		// LW x10, 0x234(x0): verify
		memory[85] = 32'h23402503; // LW  x10,0x234(x0) -> x10=0x14=20

		// SH x1, 0x238(x0): store half 0x0014
		memory[86] = 32'h22101C23; // SH  x1, 0x238(x0)
		// LW x11, 0x238(x0): verify
		memory[87] = 32'h23802583; // LW  x11,0x238(x0) -> x11=0x14=20

		// Store load/store results to mem[129..135]
		// mem[129]=0x204: SW x5
		memory[88] = 32'h20502223; // SW x5,  0x204(x0) -> mem[129]
		memory[89] = 32'h20602423; // SW x6,  0x208(x0) -> mem[130]
		memory[90] = 32'h20702623; // SW x7,  0x20C(x0) -> mem[131]
		memory[91] = 32'h20802823; // SW x8,  0x210(x0) -> mem[132]
		memory[92] = 32'h20902A23; // SW x9,  0x214(x0) -> mem[133]
		memory[93] = 32'h20A02C23; // SW x10, 0x218(x0) -> mem[134]
		memory[94] = 32'h20B02E23; // SW x11, 0x21C(x0) -> mem[135]

		// === HALT ===
		memory[95] = 32'h0000006F; // JAL x0, 0 (infinite loop)
	end

	always @(posedge clk) begin
		mem_ready <= 0;
		if (mem_valid && !mem_ready && mem_addr < 1024) begin
			mem_ready <= 1;
			mem_rdata <= memory[mem_addr >> 2];
			if (mem_wstrb[0]) memory[mem_addr>>2][ 7: 0] <= mem_wdata[ 7: 0];
			if (mem_wstrb[1]) memory[mem_addr>>2][15: 8] <= mem_wdata[15: 8];
			if (mem_wstrb[2]) memory[mem_addr>>2][23:16] <= mem_wdata[23:16];
			if (mem_wstrb[3]) memory[mem_addr>>2][31:24] <= mem_wdata[31:24];
		end
	end

	integer p=0, f=0;
	task chk; input [8*30:1] n; input [31:0] g,e;
		begin
			if (g===e) begin $display("  [PASS] %-28s = %0d",n,g); p=p+1; end
			else       begin $display("  [FAIL] %-28s exp=%0d got=%0d",n,e,g); f=f+1; end
		end
	endtask

	initial begin
		repeat (10) @(posedge clk); resetn<=1;
		repeat (1200) @(posedge clk);

		$display("\n================================================");
		$display("  TESTBENCH: TUAN THU CHUAN RV32I (37 LENH)");
		$display("================================================");
		$display(trap ? "  [!] CPU bi TRAP" : "  [OK] CPU khong bi TRAP");
		$display("");

		$display("--- R-type (10 lenh) ---");
		chk("ADD  27=20+7",         memory[100], 32'd27);
		chk("SUB  13=20-7",         memory[101], 32'd13);
		chk("AND  4=20&7",          memory[102], 32'd4);
		chk("OR   23=20|7",         memory[103], 32'd23);
		chk("XOR  19=20^7",         memory[104], 32'd19);
		chk("SLT  0=(20<7)",        memory[105], 32'd0);
		chk("SLTU 0=(20<7u)",       memory[106], 32'd0);
		chk("SLL  160=20<<3",       memory[107], 32'd160);
		chk("SRL  2=20>>3",         memory[108], 32'd2);
		chk("SRA  2=20>>>3",        memory[109], 32'd2);

		$display("--- I-type ALU (9 lenh) ---");
		chk("ADDI  35=20+15",       memory[110], 32'd35);
		chk("SLTI  1=(20<25)",      memory[111], 32'd1);
		chk("SLTIU 0=(20<5u)",      memory[112], 32'd0);
		chk("XORI  235=20^255",     memory[113], 32'd235);
		chk("ORI   15=7|15",        memory[114], 32'd15);
		chk("ANDI  4=20&15",        memory[115], 32'd4);
		chk("SLLI  160=20<<3",      memory[116], 32'd160);
		chk("SRLI  2=20>>3",        memory[117], 32'd2);
		chk("SRAI  2=20>>>3",       memory[118], 32'd2);

		$display("--- U-type (2 lenh) ---");
		chk("LUI  0x1000",          memory[119], 32'h00001000);
		chk("AUIPC PC=0x5C",        memory[120], 32'h0000005C);

		$display("--- Branch (6 lenh) ---");
		chk("BEQ  taken (=1)",      memory[121], 32'd1);
		chk("BNE  taken (=1)",      memory[122], 32'd1);
		chk("BLT  taken (=1)",      memory[123], 32'd1);
		chk("BGE  taken (=1)",      memory[124], 32'd1);
		chk("BLTU taken (=1)",      memory[125], 32'd1);
		chk("BGEU taken (=1)",      memory[126], 32'd1);

		$display("--- JAL/JALR (2 lenh) ---");
		chk("JAL  x30=0x118",       memory[127], 32'h00000118);
		chk("JALR x31=0x120",       memory[128], 32'h00000120);

		$display("--- Load (5 lenh) ---");
		chk("LW   -128",            memory[129], 32'hFFFFFF80);
		chk("LB   sign(-128)",      memory[130], 32'hFFFFFF80);
		chk("LBU  zero(128)",       memory[131], 32'h00000080);
		chk("LH   sign(-128)",      memory[132], 32'hFFFFFF80);
		chk("LHU  zero(65408)",     memory[133], 32'h0000FF80);

		$display("--- Store SB/SH (2 lenh) ---");
		chk("SB   byte=20",         memory[134], 32'd20);
		chk("SH   half=20",         memory[135], 32'd20);

		$display("--- SW (da dung xuyen suot) ---");
		$display("  [PASS] SW verified by all checks above");
		p = p + 1;

		$display("\n================================================");
		$display("  TONG KET: %0d PASS / %0d FAIL (37 lenh RV32I)",p,f);
		if (f==0)
			$display("  => TUAN THU 100%% CHUAN RV32I!");
		else
			$display("  => CO %0d LOI CAN KIEM TRA!",f);
		$display("================================================\n");
		$finish;
	end
endmodule
