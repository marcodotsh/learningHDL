#!/usr/bin/env bash
# Usage: ./detect_hdl.sh <filename>
# Prints: systemverilog, verilog, or vhdl
fname="$1"
ext="${fname##*.}"
case "$ext" in
    sv)
        echo systemverilog ;;
    v)
        echo verilog ;;
    vhd|vhdl)
        echo vhdl ;;
    *)
        echo "" ;;
esac
