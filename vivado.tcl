set srcDir src
set outDir viv

create_project detectinator $outDir -part xc7a100tcsg324-1 -force

add_files -norecurse $srcDir/top.v

update_compile_order -fileset sources_1

synth_design -rtl -name rtl_1

set_property SOURCE_SET sources_1 [get_filesets sim_1]
import_files -fileset sim_1 -norecurse $srcDir/tb.sv

update_compile_order -fileset sim_1

set_property runtime 200ns [get_filesets sim_1]
#launch_xsim -simset sim_1 -mode behavioral
launch_runs synth_1
wait_on_run synth_1
