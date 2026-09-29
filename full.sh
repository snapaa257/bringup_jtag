#!/bin/bash

echo "Running GenFull Core + JTAG Test"
echo ""

cd genfullvexriscv

iverilog -g2012 \
        -o genfull_jtag \
	VexRiscv.v \
        jtag_idcode_tb.v

vvp genfull_jtag 
