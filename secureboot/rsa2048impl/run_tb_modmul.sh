#!/usr/bin/env bash

docker start hdl-dev

docker exec hdl-dev bash -c 'cd /workspaces//learningSystemVerilog/secureboot/rsa2048impl && ghdl -a modmul.vhd && ghdl -a modmul_tb.vhd && ghdl -r modmul_tb --wave=wave.ghw --stop-time=2ms'
