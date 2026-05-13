add wave sim:/tb_bg/*

add wave sim:/tb_bg/u1/*
add wave sim:/tb_bg/u2/*

configure wave -timelineunits ns
configure wave -namecolwidth 200
configure wave -valuecolwidth 100

run 0
