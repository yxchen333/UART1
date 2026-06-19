if {[file exists work]} {
	vdel -all
}

vlib work
vmap work work

vlog ../RTL/*.v
vlog ../tb/*.sv

vopt work.tb_bg -o tb_bg_opt +acc

