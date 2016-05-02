set srcDir "src"
set outDir "viv"

create_project detectinator $outDir -part xc7a100tcsg324-1 -force

add_files -fileset sources_1 -norecurse $srcDir/connected_components.v
add_files -fileset sources_1 -norecurse $srcDir/location_generator.v
add_files -fileset sources_1 -norecurse $srcDir/mem.v
add_files -fileset sources_1 -norecurse $srcDir/sobel.v
add_files -fileset sources_1 -norecurse $srcDir/util.v
add_files -fileset sources_1 -norecurse $srcDir/top.v
add_files -fileset sources_1 -norecurse $srcDir/window_generator.v
add_files -fileset constrs_1 -norecurse $srcDir/timing.xdc

update_compile_order -fileset sources_1
