if {[file exists work]} {
	vdel -all
}

vlib work
vmap work work

vlog -sv ../tb/common/uart_params_pkg.sv
vlog ../RTL/*.v

# interface 必须先于 package
vlog -sv ../tb/uart_if.sv

vlog -sv ../tb/uart_assertions.sv

# package 按 include 顺序编译所有 class

vlog -sv +incdir+../tb ../tb/uart_pkg.sv

# 最后编译顶层

vlog -sv ../tb/tb_uart_top.sv

vopt work.tb_uart_top -o tb_bg_opt +acc

