transcript on

quit -sim

do compile.do

vsim -coverage tb_bg_opt

do wave.do

run -all

#coverage report -details
coverage report -details -output code_coverage_report.txt
coverage save uart_coverage.ucdb
