file mkdir out

vlib work

vlog src/connected_components.v
vlog src/location_generator.v
vlog src/mem.v
vlog src/sobel.v
vlog src/util.v

vlog src/top.v
vlog +define+RTL_SIM src/tb.sv
