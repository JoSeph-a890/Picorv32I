# PicoRV32I Low-Power RTL Verification

This repository contains the RTL source files and testbench files used for the front-end verification of the PicoRV32I processor core and its low-power modified versions. The verified RTL files are then used separately as input for the OpenLane back-end physical design flow.

## Project Overview

The objective of this project is to study and evaluate low-power design techniques applied to the PicoRV32I RISC-V processor core. The original PicoRV32I design is used as the baseline, while two modified versions are implemented using operand isolation and clock gating techniques.

This repository focuses on storing the source files used for RTL-level verification. It does not include OpenLane configuration files, generated back-end run folders, physical layout files, or final report outputs.

The project flow is summarized as follows:

1. Analyze the original PicoRV32I RTL design
2. Modify the RTL using low-power techniques
3. Verify the RTL designs using QuestaSim
4. Check simulation logs and waveform results
5. Use the verified RTL files as input for OpenLane back-end implementation
6. Compare power, area, and timing results separately after the OpenLane flow

## Design Versions

| Version           | RTL File             | Description                                  |
| ----------------- | -------------------- | -------------------------------------------- |
| Original          | `rtl/picorv32.v`     | Baseline PicoRV32I RTL design                |
| Operand Isolation | `rtl/picorv32_opi.v` | Modified RTL version using operand isolation |
| Clock Gating      | `rtl/picorv32_cg.v`  | Modified RTL version using clock gating      |

## Testbench Files

| Testbench File             | Purpose                                                                        |
| -------------------------- | ------------------------------------------------------------------------------ |
| `tb/tb_rv32i_compliance.v` | Used to verify RV32I functional behavior                                       |
| `tb/tb_opi_power.v`        | Used to test the operand isolation version and generate waveform/activity data |
| `tb/tb_cg_power.v`         | Used to test the clock gating version and generate waveform/activity data      |

## Repository Structure

```text
Picorv32I/
├── rtl/
│   ├── picorv32.v
│   ├── picorv32_cg.v
│   └── picorv32_opi.v
│
├── tb/
│   ├── tb_rv32i_compliance.v
│   ├── tb_opi_power.v
│   └── tb_cg_power.v
│
└── README.md
```

The `rtl/` directory contains the three RTL design versions of the PicoRV32I core. The `tb/` directory contains the testbench files used for front-end simulation and verification.

## Front-End Verification Flow

The front-end verification is performed using QuestaSim / ModelSim. The RTL source files are compiled together with the corresponding testbench files to check syntax correctness, run simulation, inspect logs, and view waveform results.

The general simulation flow is:

```text
RTL source file
      |
      v
Testbench file
      |
      v
Compile using vlog
      |
      v
Run simulation using vsim
      |
      v
Check simulation log
      |
      v
Generate and inspect waveform
```

## Example Simulation Commands

### Original PicoRV32I

Compile the original RTL design with the RV32I compliance testbench:

```bash
vlog rtl/picorv32.v tb/tb_rv32i_compliance.v
```

Run the testbench:

```bash
vsim -c -voptargs="+acc" -do "run -all; quit" work.tb_rv32i_compliance
```

Convert the generated VCD file to WLF format:

```bash
vcd2wlf tb_rv32i_compliance.vcd tb_rv32i_compliance.wlf
```

Open the waveform:

```bash
vsim -view tb_rv32i_compliance.wlf
```

### Operand Isolation Version

Compile and run the operand isolation version:

```bash
vlog rtl/picorv32_opi.v tb/tb_opi_power.v
vsim -c -voptargs="+acc" -do "run -all; quit" work.tb_opi_power
vcd2wlf tb_opi_power.vcd tb_opi_power.wlf
vsim -view tb_opi_power.wlf
```

### Clock Gating Version

Compile and run the clock gating version:

```bash
vlog rtl/picorv32_cg.v tb/tb_cg_power.v
vsim -c -voptargs="+acc" -do "run -all; quit" work.tb_cg_power
vcd2wlf tb_cg_power.vcd tb_cg_power.wlf
vsim -view tb_cg_power.wlf
```

## Back-End Usage

After the front-end verification is completed, only the RTL files in the `rtl/` directory are used as input for the OpenLane back-end flow.

The testbench files are not used in OpenLane because they are only for simulation. OpenLane uses synthesizable RTL files for synthesis and physical design implementation.

The RTL files used for back-end implementation are:

* `rtl/picorv32.v`
* `rtl/picorv32_opi.v`
* `rtl/picorv32_cg.v`

The OpenLane flow is handled separately and includes synthesis, floorplanning, placement, clock tree synthesis, routing, and report extraction.

## Tools

* Verilog HDL
* Antigravity development environment
* QuestaSim
* OpenLane
* Git / GitHub

## Project Scope

This repository stores the RTL source files and testbench files used in the PicoRV32I low-power design project. The RTL files include the original PicoRV32I design, the operand isolation version, and the clock gating version.

The testbench files are used only for front-end simulation and functional verification in QuestaSim. After the front-end verification is completed, the verified RTL files in the `rtl/` directory are used separately as input for the OpenLane back-end flow.

This repository does not include OpenLane configuration files, generated simulation waveforms, log files, or back-end run results.

## Author

Tran Trinh Huy

Le Dang Thanh Son

Graduation Thesis Project

Electronics and Telecommunications Engineering
