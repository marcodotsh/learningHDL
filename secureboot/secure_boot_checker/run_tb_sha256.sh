#!/bin/env bash
set -euo pipefail

docker start hdl-dev

docker exec hdl-dev bash -c 'cd /workspaces//learningSystemVerilog/secureboot/secure_boot_checker && ghdl -a neorv32_secure_boot_sha256_package.vhd && ghdl -a neorv32_secure_boot_sha256_core.vhd && ghdl -a neorv32_package.vhd && ghdl -a neorv32_bootloader_image.vhd && ghdl -a neorv32_secure_boot_pkg.vhd && ghdl -a neorv32_boot_rom.vhd && ghdl -a neorv32_secure_boot_boot_rom_hasher.vhd && ghdl -a neorv32_secure_boot_sha256_tb.vhd && ghdl -r neorv32_secure_boot_sha256_tb --wave=wave.ghw --stop-time=145us'
