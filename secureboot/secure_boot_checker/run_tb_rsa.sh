#!/bin/env bash
set -euo pipefail

docker start hdl-dev

docker exec hdl-dev bash -c 'cd /workspaces//learningSystemVerilog/secureboot/secure_boot_checker && ghdl -a neorv32_secure_boot_serial_adder.vhd && ghdl -a neorv32_secure_boot_mod_mult.vhd && ghdl -a neorv32_secure_boot_rsa.vhd && ghdl -a neorv32_secure_boot_rsa_tb.vhd && ghdl -r neorv32_secure_boot_rsa_tb --stop-time=100ms'
