`timescale 1 ns / 1 ps
// ============================================================
// TESTBENCH: DO HIEU QUA TOI UU CLOCK GATING
// So sanh: picorv32.v (BASELINE) vs picorv32_cg.v (CG)
//
// Phuong phap do:
//   - Chay cung 1 chuong trinh tren 2 core song song
//   - Dem so chu ky RF clock bi gate (clk_cg_rf khong toggle)
//   - Dem so chu ky RF clock duoc mo (co ghi thanh ghi)
//   - So sanh ket qua RAM de chung minh chuc nang giong nhau
// ============================================================
module tb_cg_power;
	reg clk = 1; reg resetn = 0;
	always #5 clk = ~clk;

	// --- CORE BASELINE ---
	wire        trap_b, valid_b, instr_b; reg ready_b;
	wire [31:0] addr_b, wdata_b;  wire [3:0] wstrb_b;
	reg  [31:0] rdata_b;

	// --- CORE CG ---
	wire        trap_c, valid_c, instr_c; reg ready_c;
	wire [31:0] addr_c, wdata_c;  wire [3:0] wstrb_c;
	reg  [31:0] rdata_c;

	// Bo nho rieng biet cho moi core
	reg [31:0] mem_b [0:255];
	reg [31:0] mem_c [0:255];

	// ============================================================
	// Chuong trinh: Pha tron ALU + Memory + Branch
	// De tao du switching activity de do
	// ============================================================
	initial begin : init_mem
		integer i;

		// --- Khoi tao toan hang ---
		mem_b[0]  = 32'h00100093; // ADDI x1,x0,1     | x1=1
		mem_b[1]  = 32'h00200113; // ADDI x2,x0,2     | x2=2
		mem_b[2]  = 32'h00300193; // ADDI x3,x0,3     | x3=3
		mem_b[3]  = 32'h00400213; // ADDI x4,x0,4     | x4=4
		mem_b[4]  = 32'h00500293; // ADDI x5,x0,5     | x5=5

		// --- Cac phep tinh ALU (tao switching, CO ghi RF) ---
		mem_b[5]  = 32'h002081B3; // ADD  x3,x1,x2    | R-type -> ghi x3
		mem_b[6]  = 32'h40208233; // SUB  x4,x1,x2    | R-type -> ghi x4
		mem_b[7]  = 32'h0020F2B3; // AND  x5,x1,x2    | R-type -> ghi x5
		mem_b[8]  = 32'h0020E333; // OR   x6,x1,x2    | R-type -> ghi x6
		mem_b[9]  = 32'h0020C3B3; // XOR  x7,x1,x2    | R-type -> ghi x7

		// --- I-type (CO ghi RF) ---
		mem_b[10] = 32'h00F08513; // ADDI x10,x1,15   -> ghi x10
		mem_b[11] = 32'h0190A593; // SLTI x11,x1,25   -> ghi x11
		mem_b[12] = 32'h0FF0C693; // XORI x13,x1,255  -> ghi x13
		mem_b[13] = 32'h00F16713; // ORI  x14,x2,15   -> ghi x14
		mem_b[14] = 32'h00F0F793; // ANDI x15,x1,15   -> ghi x15

		// --- Store ket qua vao RAM (KHONG ghi RF -> CG chan clock) ---
		mem_b[15] = 32'h18302823; // SW x3, 0x190(x0) -> word[100]
		mem_b[16] = 32'h18402A23; // SW x4, 0x194(x0) -> word[101]
		mem_b[17] = 32'h18502C23; // SW x5, 0x198(x0) -> word[102]
		mem_b[18] = 32'h18602E23; // SW x6, 0x19C(x0) -> word[103]

		// --- Load lai (CO ghi RF) ---
		mem_b[19] = 32'h19002503; // LW x10, 0x190(x0) -> ghi x10
		mem_b[20] = 32'h19402583; // LW x11, 0x194(x0) -> ghi x11

		// --- Branch (KHONG ghi RF -> CG chan clock) ---
		mem_b[21] = 32'h00209463; // BNE x1,x2,+8
		mem_b[22] = 32'h00100293; // ADDI x5,x0,1 (bi bo qua)
		mem_b[23] = 32'h00200293; // ADDI x5,x0,2

		// --- Dung ---
		mem_b[24] = 32'h0000006F; // JAL x0,0 (vong lap vo tan)

		// Copy sang CG memory
		for (i=0; i<256; i=i+1)
			mem_c[i] = mem_b[i];
	end

	// Memory controller Baseline
	always @(posedge clk) begin
		ready_b <= 0;
		if (valid_b && !ready_b && addr_b < 1024) begin
			ready_b <= 1; rdata_b <= mem_b[addr_b>>2];
			if (wstrb_b[0]) mem_b[addr_b>>2][ 7: 0] <= wdata_b[ 7: 0];
			if (wstrb_b[1]) mem_b[addr_b>>2][15: 8] <= wdata_b[15: 8];
			if (wstrb_b[2]) mem_b[addr_b>>2][23:16] <= wdata_b[23:16];
			if (wstrb_b[3]) mem_b[addr_b>>2][31:24] <= wdata_b[31:24];
		end
	end

	// Memory controller CG
	always @(posedge clk) begin
		ready_c <= 0;
		if (valid_c && !ready_c && addr_c < 1024) begin
			ready_c <= 1; rdata_c <= mem_c[addr_c>>2];
			if (wstrb_c[0]) mem_c[addr_c>>2][ 7: 0] <= wdata_c[ 7: 0];
			if (wstrb_c[1]) mem_c[addr_c>>2][15: 8] <= wdata_c[15: 8];
			if (wstrb_c[2]) mem_c[addr_c>>2][23:16] <= wdata_c[23:16];
			if (wstrb_c[3]) mem_c[addr_c>>2][31:24] <= wdata_c[31:24];
		end
	end

	// Instantiate BASELINE
	picorv32 uut_b (
		.clk(clk), .resetn(resetn), .trap(trap_b),
		.mem_valid(valid_b), .mem_instr(instr_b), .mem_ready(ready_b),
		.mem_addr(addr_b),   .mem_wdata(wdata_b), .mem_wstrb(wstrb_b),
		.mem_rdata(rdata_b)
	);

	// Instantiate CG
	picorv32_cg uut_c (
		.clk(clk), .resetn(resetn), .trap(trap_c),
		.mem_valid(valid_c), .mem_instr(instr_c), .mem_ready(ready_c),
		.mem_addr(addr_c),   .mem_wdata(wdata_c), .mem_wstrb(wstrb_c),
		.mem_rdata(rdata_c)
	);

	// ============================================================
	// BO DEM CLOCK GATING ACTIVITY
	// Do so chu ky xung clock RF bi chan (clk_cg_rf = 0)
	// va so chu ky xung clock RF duoc mo (clk_cg_rf toggle)
	// ============================================================
	integer cycle_total    = 0;  // Tong so chu ky
	integer cycle_rf_write = 0;  // CG: chu ky RF duoc ghi (clock mo)
	integer cycle_rf_gated = 0;  // CG: chu ky RF bi chan clock (clock tat)
	integer mismatch       = 0;  // So chu ky 2 core khac nhau

	always @(posedge clk) begin
		if (resetn) begin
			cycle_total = cycle_total + 1;

			// Kiem tra tuong duong chuc nang
			if (valid_b === valid_c) begin
				if (valid_b && addr_b !== addr_c) begin
					mismatch = mismatch + 1;
					$display("[MISMATCH @%0t] addr: B=0x%h C=0x%h", $time, addr_b, addr_c);
				end
				if (valid_b && |wstrb_b && wdata_b !== wdata_c) begin
					mismatch = mismatch + 1;
					$display("[MISMATCH @%0t] wdata: B=0x%h C=0x%h", $time, wdata_b, wdata_c);
				end
			end

			// Dem chu ky theo trang thai Clock Gating cua RF
			// rf_cg_en = 1 -> clock duoc mo, RF dang ghi
			// rf_cg_en = 0 -> clock bi chan, RF ngu dong
			if (uut_c.rf_cg_en) begin
				cycle_rf_write = cycle_rf_write + 1;
			end else begin
				cycle_rf_gated = cycle_rf_gated + 1;
			end
		end
	end

	// ============================================================
	// KET QUA
	// ============================================================
	initial begin
		// Xuat file VCD de xem dang song va phuc vu Power Analysis (OpenLane)
		$dumpfile("tb_cg_power.vcd");
		$dumpvars(0, tb_cg_power);

		repeat (10) @(posedge clk); resetn <= 1;
		repeat (500) @(posedge clk);

		$display("");
		$display("=======================================================");
		$display("  TESTBENCH: DO HIEU QUA CLOCK GATING");
		$display("  So sanh: BASELINE vs CLOCK GATING (Register File)");
		$display("=======================================================");
		$display("");

		// Kiem tra chuc nang
		$display("--- [1] KIEM TRA CHUC NANG (Functional Check) ---");
		$display(trap_b ? "  [FAIL] Baseline bi TRAP!" : "  [OK] Baseline khong TRAP");
		$display(trap_c ? "  [FAIL] CG bi TRAP!" : "  [OK] CG khong TRAP");
		$display("  Ket qua RAM Baseline vs CG:");
		$display("  ADD  (word[100]): BASE=%0d | CG=%0d | %s",
			mem_b[100], mem_c[100], mem_b[100]===mem_c[100]?"MATCH":"MISMATCH!");
		$display("  SUB  (word[101]): BASE=%0d | CG=%0d | %s",
			mem_b[101], mem_c[101], mem_b[101]===mem_c[101]?"MATCH":"MISMATCH!");
		$display("  AND  (word[102]): BASE=%0d | CG=%0d | %s",
			mem_b[102], mem_c[102], mem_b[102]===mem_c[102]?"MATCH":"MISMATCH!");
		$display("  OR   (word[103]): BASE=%0d | CG=%0d | %s",
			mem_b[103], mem_c[103], mem_b[103]===mem_c[103]?"MATCH":"MISMATCH!");
		if (mismatch == 0)
			$display("  => HAI CORE CHO KET QUA GIONG HET (mismatch=0)");
		else
			$display("  => CANH BAO: %0d chu ky khac nhau!", mismatch);

		// Thong ke Clock Gating
		$display("");
		$display("--- [2] THONG KE CLOCK GATING ACTIVITY ---");
		$display("  Tong so chu ky chay         : %0d", cycle_total);
		$display("");
		$display("  Phan tich Clock cua Register File:");
		$display("  +--------------------------------------+----------+----------+");
		$display("  | Trang thai                           | BASELINE |    CG    |");
		$display("  +--------------------------------------+----------+----------+");
		$display("  | Chu ky RF clock TOGGLE (co ghi RF)   | %8d | %8d |",cycle_total,cycle_rf_write);
		$display("  | Chu ky RF clock BI CHAN (khong ghi)   |        0 | %8d |",cycle_rf_gated);
		$display("  +--------------------------------------+----------+----------+");
		$display("");
		$display("  Giai thich:");
		$display("  - BASELINE: Clock cap cho RF LIEN TUC moi chu ky (%0d toggle)", cycle_total);
		$display("              => 1024 Flip-Flop lien tuc nhan xung, gay ton dien!");
		$display("  - CG:       Clock chi cap cho RF khi can ghi (%0d toggle)", cycle_rf_write);
		$display("              => %0d chu ky RF duoc 'ngu dong', tiet kiem dien!", cycle_rf_gated);
		$display("");
		$display("  Ty le chu ky RF clock duoc chan:");
		if (cycle_total > 0)
			$display("  => %0d / %0d = %0d phan tram chu ky clock RF duoc tiet kiem",
				cycle_rf_gated, cycle_total, cycle_rf_gated * 100 / cycle_total);

		$display("");
		$display("--- [3] Y NGHIA CHO BACKEND ---");
		$display("  - BASELINE: 1024 FF x %0d toggle = %0d FF-toggle (lang phi)", cycle_total, 1024*cycle_total);
		$display("  - CG:       1024 FF x %0d toggle = %0d FF-toggle (toi uu)", cycle_rf_write, 1024*cycle_rf_write);
		$display("  - Giam: %0d FF-toggle => giam Dynamic Power tren Clock Tree", 1024*(cycle_total - cycle_rf_write));
		$display("");
		$display("  - File VCD cua testbench nay dung de chay Power Analysis");
		$display("    trong OpenSTA sau khi synthesis voi OpenLane");

		$display("");
		$display("=======================================================");
		$finish;
	end
endmodule
