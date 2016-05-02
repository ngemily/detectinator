project_new top

set_global_assignment -name TOP_LEVEL_ENTITY top
set_global_assignment -name VERILOG_FILE "../src/top.v"
set_global_assignment -name VERILOG_FILE "../src/connected_components.v"
set_global_assignment -name VERILOG_FILE "../src/location_generator.v"
set_global_assignment -name VERILOG_FILE "../src/mem.v"
set_global_assignment -name VERILOG_FILE "../src/sobel.v"
set_global_assignment -name VERILOG_FILE "../src/util.v"
set_global_assignment -name VERILOG_FILE "../src/top.v"
set_global_assignment -name VERILOG_FILE "../src/window_generator.v"

project_close
