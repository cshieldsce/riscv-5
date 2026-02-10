# Vivado Project Creation Script for PYNQ-Z2
set project_name "riscv_cpu"
set project_dir "./vivado_project"
set part_number "xc7z020clg400-1"

# Create project
create_project $project_name $project_dir -part $part_number -force

# Set project properties
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

# IMPORTANT: Add riscv_pkg.sv FIRST (must be compiled before other modules)
add_files ../src/riscv_pkg.sv
set_property file_type {SystemVerilog} [get_files ../src/riscv_pkg.sv]

# Add remaining source files
add_files [glob ../src/*.sv]
set_property file_type {SystemVerilog} [get_files *.sv]

# Add memory initialization files
file mkdir ./programs
add_files -fileset utils_1 [glob -nocomplain ./programs/*.mem]
if {[llength [get_files -of_objects [get_filesets utils_1] *.mem]] > 0} {
    set_property file_type {Memory Initialization Files} [get_files -of_objects [get_filesets utils_1] *.mem]
}

# Add Constraints
add_files -fileset constrs_1 ./pynq_z2.xdc

# Set Top Level
set_property top pynq_z2_top [current_fileset]

# ====================================
# CRITICAL: Define SYNTHESIS macro for SystemVerilog
# ====================================
# Use both methods to ensure it works:
set_property verilog_define "SYNTHESIS" [current_fileset]
set_property -name {xsim.compile.xvlog.more_options} -value {-d SYNTHESIS} -objects [get_filesets sim_1]

# Update compile order (ensures riscv_pkg.sv is compiled first)
update_compile_order -fileset sources_1

# ====================================
# Create IP Cores
# ====================================

# 1. Clock Wizard IP (125 MHz -> 10 MHz)
puts "Creating Clock Wizard IP..."
create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name clk_wiz_0
set_property -dict [list \
    CONFIG.PRIM_IN_FREQ {125.000} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {10.000} \
    CONFIG.USE_LOCKED {true} \
    CONFIG.USE_RESET {false} \
    CONFIG.CLKIN1_JITTER_PS {80.0} \
    CONFIG.MMCM_DIVCLK_DIVIDE {1} \
    CONFIG.MMCM_CLKOUT0_DIVIDE_F {100.000} \
    CONFIG.CLKOUT1_JITTER {181.828} \
    CONFIG.CLKOUT1_PHASE_ERROR {104.359} \
] [get_ips clk_wiz_0]

generate_target all [get_ips clk_wiz_0]
create_ip_run [get_ips clk_wiz_0]

# 2. Integrated Logic Analyzer (ILA) IP
puts "Creating ILA IP..."
create_ip -name ila -vendor xilinx.com -library ip -version 6.2 -module_name ila_0
set_property -dict [list \
    CONFIG.C_PROBE0_WIDTH {32} \
    CONFIG.C_PROBE1_WIDTH {32} \
    CONFIG.C_PROBE2_WIDTH {3} \
    CONFIG.C_PROBE3_WIDTH {1} \
    CONFIG.C_PROBE4_WIDTH {32} \
    CONFIG.C_PROBE5_WIDTH {1} \
    CONFIG.C_PROBE6_WIDTH {3} \
    CONFIG.C_PROBE7_WIDTH {32} \
    CONFIG.C_PROBE8_WIDTH {32} \
    CONFIG.C_PROBE9_WIDTH {32} \
    CONFIG.C_PROBE10_WIDTH {5} \
    CONFIG.C_PROBE11_WIDTH {32} \
    CONFIG.C_PROBE12_WIDTH {32} \
    CONFIG.C_PROBE13_WIDTH {1} \
    CONFIG.C_PROBE14_WIDTH {32} \
    CONFIG.C_NUM_OF_PROBES {15} \
    CONFIG.C_EN_STRG_QUAL {1} \
    CONFIG.C_INPUT_PIPE_STAGES {0} \
    CONFIG.C_ADV_TRIGGER {true} \
    CONFIG.ALL_PROBE_SAME_MU_CNT {2} \
] [get_ips ila_0]

generate_target all [get_ips ila_0]
create_ip_run [get_ips ila_0]

# Launch IP synthesis runs
puts "Generating IP cores..."
launch_runs clk_wiz_0_synth_1 ila_0_synth_1
wait_on_run clk_wiz_0_synth_1
wait_on_run ila_0_synth_1

puts "=========================================="
puts "Project created successfully!"
puts "SYNTHESIS macro has been defined"
puts "Memory size: 16KB (4096 words)"
puts ""
puts "Next steps:"
puts "  1. Open project: vivado $project_dir/${project_name}.xpr"
puts "  2. Run Synthesis"
puts "=========================================="
