#!/bin/sh

# syntax check 
#ghdl -s --std=08 rtl/axi_lite_regs_pkg.vhdl
#ghdl -s --std=08 rtl/axi_lite.vhdl
#ghdl -s --std=08 rtl/motor_ctrl.vhdl
#ghdl -s --std=08 rtl/motor_ctrl_top.vhdl

# bench syntax check
#ghdl -s --std=08 tb/tb_top_pkg.vhdl
#ghdl -s --std=08 tb/axi_lite_tb_pkg.vhdl
#ghdl -s --std=08 tb/tests/basic_test.vhdl
#ghdl -s --std=08 tb/tb_top.vhdl

#compile 
ghdl -a --std=08 rtl/axi_lite_regs_pkg.vhdl
ghdl -a --std=08 rtl/axi_lite.vhdl
ghdl -a --std=08 -fpsl rtl/motor_ctrl.vhdl
ghdl -a --std=08 rtl/motor_ctrl_top.vhdl
#ghdl -a --std=08 -fpsl rtl/fifo_sync.vhd

# compile bench 
ghdl -a --std=08 tb/tb_top_pkg.vhdl
ghdl -a --std=08 tb/axi_lite_tb_pkg.vhdl
ghdl -a --std=08 tb/tests/basic_test.vhdl
ghdl -a --std=08 tb/tb_top.vhdl

ghdl -e --std=08 -fpsl tb_top
ghdl -r --std=08 -fpsl tb_top --wave=tb_top.ghw
