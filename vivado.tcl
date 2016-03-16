set srcDir src
set outDir viv

create_project detectinator $outDir -part xc7a100tcsg324-1 -force

add_files -fileset sources_1 -norecurse $srcDir/connected_components.v
add_files -fileset sources_1 -norecurse $srcDir/mem.v
add_files -fileset sources_1 -norecurse $srcDir/sobel.v
add_files -fileset sources_1 -norecurse $srcDir/util.v
add_files -fileset sources_1 -norecurse $srcDir/top.v
add_files -fileset constrs_1 -norecurse $srcDir/timing.xdc
update_compile_order -fileset sources_1

synth_design -rtl -name rtl_1

launch_runs synth_1
wait_on_run synth_1
open_run synth_1 -name netlist_1

write_verilog -mode funcsim $outDir/top_synth.vo -force

launch_runs impl_1
wait_on_run impl_1
open_run impl_1 -name netlist_2

write_verilog -mode funcsim $outDir/top_impl.vo -force
