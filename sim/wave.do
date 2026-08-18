quietly WaveActivateNextPane {} 0

delete wave *

#==================================================
# Top 和 interface 信号
#==================================================

add wave -divider {CLOCK AND RESET}
add wave sim:/tb_uart_top/clk
add wave sim:/tb_uart_top/vif/reset_n

add wave -divider {RX INPUT CONTROL}
add wave sim:/tb_uart_top/vif/loopback_en
add wave sim:/tb_uart_top/vif/rx_driver
add wave sim:/tb_uart_top/vif/rx
add wave sim:/tb_uart_top/vif/busy
add wave sim:/tb_uart_top/vif/tx_done
add wave sim:/tb_uart_top/vif/tx_valid
add wave sim:/tb_uart_top/vif/data


add wave sim:/tb_uart_top/vif/tx_state_dbg
add wave sim:/tb_uart_top/vif/tx_bit_cnt_dbg

add wave sim:/tb_uart_top/u_tx/state
add wave sim:/tb_uart_top/u_tx/bit_cnt


add wave -divider {RX OUTPUT}
add wave -radix hexadecimal sim:/tb_uart_top/vif/rx_data
add wave sim:/tb_uart_top/vif/rx_done
add wave sim:/tb_uart_top/vif/frame_error

#==================================================
# UART RX 内部状态
#==================================================

add wave -divider {UART RX INTERNAL}

add wave -radix unsigned sim:/tb_uart_top/u_rx/state
add wave -radix unsigned sim:/tb_uart_top/u_rx/sample_cnt
add wave -radix unsigned sim:/tb_uart_top/u_rx/bit_cnt_rx
add wave -radix hexadecimal sim:/tb_uart_top/u_rx/shifter




# 自动调整显示
TreeUpdate [SetDefaultTree]
WaveRestoreZoom {0 ps} {100 us}
update