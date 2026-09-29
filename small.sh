#!/bin/bash

echo "Running GenSmallAndProductive Core + JTAG Test"
echo ""

cd gensmallvexriscv

iverilog -g2012 \
       -o gensmall_jtag \
       VexRiscv.v \
       jtag_idcode_tb.v

vvp gensmall_jtag 
