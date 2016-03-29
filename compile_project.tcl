set origin_dir "viv"

open_project $origin_dir/detectinator.xpr

update_compile_order -fileset sources_1

reset_run synth_1
launch_runs synth_1
wait_on_run synth_1
open_run synth_1 -name netlist_1
write_verilog -mode funcsim $origin_dir/top_synth.vo -force

reset_run impl_1
launch_runs impl_1
wait_on_run impl_1
open_run impl_1 -name netlist_2
write_verilog -mode funcsim $origin_dir/top_impl.vo -force
