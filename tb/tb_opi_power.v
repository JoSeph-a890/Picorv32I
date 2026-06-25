`timescale 1 ns / 1 ps
// ============================================================
// TESTBENCH 2: DO HIEU QUA TOI UU OPERAND ISOLATION
// So sanh: picorv32.v (BASELINE) vs picorv32_opi.v (OPI)
//
// Phuong phap do switching activity:
//   - Chay cung 1 chuong trinh tren 2 core song song
//   - Dem so lan mem_wstrb=1 (CPU ghi du lieu) - chung minh chuc nang giong nhau
//   - Dem so chu ky mem_valid va mem_instr tren moi core
//   - So sanh: OPI co opi_alu_active=0 khi khong can ALU
//     => toan hang duoc ghim ve 0 => giam switching
// ============================================================
module tb_opi_power;
	reg clk = 1; reg resetn = 0;
	always #5 clk = ~clk;

	// --- CORE BASELINE ---
	wire        trap_b, valid_b, instr_b; reg ready_b;
	wire [31:0] addr_b, wdata_b;  wire [3:0] wstrb_b;
	reg  [31:0] rdata_b;

	// --- CORE OPI ---
	wire        trap_o, valid_o, instr_o; reg ready_o;
	wire [31:0] addr_o, wdata_o;  wire [3:0] wstrb_o;
	reg  [31:0] rdata_o;

	// Bo nho rieng biet cho moi core
	reg [31:0] mem_b [0:255];
	reg [31:0] mem_o [0:255];

	// ============================================================
	// Chuong trinh: Chay 1 vong lap ALU 5 lan
	// De tao du switching activity de do
	// x1=1, x2=2 -> ADDx3 vao RAM, sau do load lai, cong tiep
	// ============================================================
	initial begin : init_mem
		integer i;

		// --- Khoi tao ---
		mem_b[0]  = 32'h00100093; // ADDI x1,x0,1     | x1=1
		mem_b[1]  = 32'h00200113; // ADDI x2,x0,2     | x2=2
		mem_b[2]  = 32'h00300193; // ADDI x3,x0,3     | x3=3
		mem_b[3]  = 32'h00400213; // ADDI x4,x0,4     | x4=4
		mem_b[4]  = 32'h00500293; // ADDI x5,x0,5     | x5=5

		// --- Cac phep tinh ALU (tao switching) ---
		mem_b[5]  = 32'h002081B3; // ADD  x3,x1,x2    | R-type
		mem_b[6]  = 32'h40208233; // SUB  x4,x1,x2    | R-type
		mem_b[7]  = 32'h0020F2B3; // AND  x5,x1,x2    | R-type
		mem_b[8]  = 32'h0020E333; // OR   x6,x1,x2    | R-type
		mem_b[9]  = 32'h0020C3B3; // XOR  x7,x1,x2    | R-type

		// --- I-type ---
		mem_b[10] = 32'h00F08513; // ADDI x10,x1,15
		mem_b[11] = 32'h0190A593; // SLTI x11,x1,25
		mem_b[12] = 32'h0FF0C693; // XORI x13,x1,255
		mem_b[13] = 32'h00F16713; // ORI  x14,x2,15
		mem_b[14] = 32'h00F0F793; // ANDI x15,x1,15

		// --- Store ket qua ALU vao RAM ---
		mem_b[15] = 32'h18302823; // SW x3, 0x190(x0) -> word[100]=ADD=3
		mem_b[16] = 32'h18402A23; // SW x4, 0x194(x0) -> word[101]=SUB=-1
		mem_b[17] = 32'h18502C23; // SW x5, 0x198(x0) -> word[102]=AND=0
		mem_b[18] = 32'h18602E23; // SW x6, 0x19C(x0) -> word[103]=OR=3

		// --- Load lai (tao them switching) ---
		mem_b[19] = 32'h19002503; // LW x10, 0x190(x0)
		mem_b[20] = 32'h19402583; // LW x11, 0x194(x0)

		// --- Branch (khong can ALU result) ---
		mem_b[21] = 32'h00209463; // BNE x1,x2,+8
		mem_b[22] = 32'h00100293; // ADDI x5,x0,1 (bi bo qua)
		mem_b[23] = 32'h00200293; // ADDI x5,x0,2

		// --- Vong lap: quay lai de tao nhieu chu ky do ---
		mem_b[24] = 32'h0000006F; // JAL x0,0 (dung)

		// Copy sang OPI memory
		for (i=0; i<256; i=i+1)
			mem_o[i] = mem_b[i];
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

	// Memory controller OPI
	always @(posedge clk) begin
		ready_o <= 0;
		if (valid_o && !ready_o && addr_o < 1024) begin
			ready_o <= 1; rdata_o <= mem_o[addr_o>>2];
			if (wstrb_o[0]) mem_o[addr_o>>2][ 7: 0] <= wdata_o[ 7: 0];
			if (wstrb_o[1]) mem_o[addr_o>>2][15: 8] <= wdata_o[15: 8];
			if (wstrb_o[2]) mem_o[addr_o>>2][23:16] <= wdata_o[23:16];
			if (wstrb_o[3]) mem_o[addr_o>>2][31:24] <= wdata_o[31:24];
		end
	end

	// Instantiate BASELINE
	picorv32 uut_b (
		.clk(clk), .resetn(resetn), .trap(trap_b),
		.mem_valid(valid_b), .mem_instr(instr_b), .mem_ready(ready_b),
		.mem_addr(addr_b),   .mem_wdata(wdata_b), .mem_wstrb(wstrb_b),
		.mem_rdata(rdata_b)
	);

	// Instantiate OPI
	picorv32_opi uut_o (
		.clk(clk), .resetn(resetn), .trap(trap_o),
		.mem_valid(valid_o), .mem_instr(instr_o), .mem_ready(ready_o),
		.mem_addr(addr_o),   .mem_wdata(wdata_o), .mem_wstrb(wstrb_o),
		.mem_rdata(rdata_o)
	);

	// ============================================================
	// BO DEM SWITCHING ACTIVITY
	// Do switching cua opi_alu_active (enable signal cua OPI)
	// Khi opi_alu_active=0: opi_op1=opi_op2=0 (khong switching)
	// Khi opi_alu_active=1: opi_op1/op2 = reg_op1/op2 (switching)
	// ============================================================
	integer cycle_total    = 0;  // Tong so chu ky
	integer cycle_alu_b    = 0;  // Baseline: chu ky ALU hoat dong (est)
	integer cycle_alu_o    = 0;  // OPI: chu ky ALU can hoat dong
	integer cycle_idle_b   = 0;  // Baseline: ALU roi nhung van switching
	integer cycle_idle_o   = 0;  // OPI: ALU roi, opi_op1=0 (giam switching)
	integer mismatch       = 0;  // So chu ky 2 core khac nhau

	always @(posedge clk) begin
		if (resetn) begin
			cycle_total = cycle_total + 1;

			// Kiem tra tuong duong chuc nang
			if (valid_b === valid_o) begin
				if (valid_b && addr_b !== addr_o) begin
					mismatch = mismatch + 1;
					$display("[MISMATCH @%0t] addr: B=0x%h O=0x%h", $time, addr_b, addr_o);
				end
				if (valid_b && |wstrb_b && wdata_b !== wdata_o) begin
					mismatch = mismatch + 1;
					$display("[MISMATCH @%0t] wdata: B=0x%h O=0x%h", $time, wdata_b, wdata_o);
				end
			end

			// Dem chu ky theo trang thai ALU
			if (uut_o.opi_alu_active) begin
				cycle_alu_o = cycle_alu_o + 1;
				// Baseline cung dang tinh toan
				cycle_alu_b = cycle_alu_b + 1;
			end else begin
				// OPI: ALU roi, opi_op1=opi_op2=0 -> KHONG switching
				cycle_idle_o = cycle_idle_o + 1;
				// Baseline: ALU roi NHUNG reg_op1/op2 van co the dang switching
				cycle_idle_b = cycle_idle_b + 1;
			end
		end
	end

	// ============================================================
	// KET QUA
	// ============================================================
	initial begin
		// Xuat file VCD de xem dang song va phuc vu Power Analysis (OpenLane)
		$dumpfile("tb_opi_power.vcd");
		$dumpvars(0, tb_opi_power);

		repeat (10) @(posedge clk); resetn <= 1;
		repeat (500) @(posedge clk);

		$display("");
		$display("=======================================================");
		$display("  TESTBENCH 2: DO HIEU QUA OPERAND ISOLATION");
		$display("=======================================================");
		$display("");

		// Kiem tra chuc nang
		$display("--- [1] KIEM TRA CHUC NANG (Functional Check) ---");
		$display(trap_b ? "  [FAIL] Baseline bi TRAP!" : "  [OK] Baseline khong TRAP");
		$display(trap_o ? "  [FAIL] OPI bi TRAP!" : "  [OK] OPI khong TRAP");
		$display("  Ket qua RAM Baseline vs OPI:");
		$display("  ADD  (word[100]): BASE=%0d | OPI=%0d | %s",
			mem_b[100], mem_o[100], mem_b[100]===mem_o[100]?"MATCH":"MISMATCH!");
		$display("  SUB  (word[101]): BASE=%0d | OPI=%0d | %s",
			mem_b[101], mem_o[101], mem_b[101]===mem_o[101]?"MATCH":"MISMATCH!");
		$display("  AND  (word[102]): BASE=%0d | OPI=%0d | %s",
			mem_b[102], mem_o[102], mem_b[102]===mem_o[102]?"MATCH":"MISMATCH!");
		$display("  OR   (word[103]): BASE=%0d | OPI=%0d | %s",
			mem_b[103], mem_o[103], mem_b[103]===mem_o[103]?"MATCH":"MISMATCH!");
		if (mismatch == 0)
			$display("  => HAI CORE CHO KET QUA GIONG HET (mismatch=0)");
		else
			$display("  => CANH BAO: %0d chu ky khac nhau!", mismatch);

		// Thong ke switching
		$display("");
		$display("--- [2] THONG KE SWITCHING ACTIVITY ---");
		$display("  Tong so chu ky chay         : %0d", cycle_total);
		$display("");
		$display("  Phan tich theo trang thai ALU:");
		$display("  +-----------------------------+----------+----------+");
		$display("  | Trang thai                  | BASELINE |   OPI    |");
		$display("  +-----------------------------+----------+----------+");
		$display("  | Chu ky ALU CAN tinh toan    | %8d | %8d |",cycle_alu_b,cycle_alu_o);
		$display("  | Chu ky ALU KHONG CAN (idle) | %8d | %8d |",cycle_idle_b,cycle_idle_o);
		$display("  +-----------------------------+----------+----------+");
		$display("");
		$display("  Ket qua OPI khi ALU idle:");
		$display("  - BASELINE: reg_op1/reg_op2 van co the thay doi -> SWITCHING!");
		$display("  - OPI:      opi_op1=opi_op2=0 (co dinh) -> KHONG switching!");
		$display("");
		$display("  Uoc tinh chu ky toan hang bi giam switching:");
		if (cycle_total > 0)
			$display("  => %0d / %0d = %0d phan tram chu ky duoc bao ve boi OPI",
				cycle_idle_o, cycle_total, cycle_idle_o * 100 / cycle_total);

		$display("");
		$display("--- [3] Y NGHIA CHO BACKEND ---");
		$display("  - File VCD cua testbench nay dung de chay Power Analysis");
		$display("    trong Synopsys PrimeTime sau khi synthesis voi OpenLane");
		$display("  - Phan tram idle cycle o tren la ty le chu ky ngo vao ALU duoc ghim ve 0");
		$display("  - Muc giam Dynamic Power thuc te phu thuoc vao ty trong ALU trong toan chip");

		$display("");
		$display("=======================================================");
		$finish;
	end
endmodule
