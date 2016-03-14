do base.do

vsim -gui -L secureip -L unisims_ver work.tb work.glbl
run -all

exit
