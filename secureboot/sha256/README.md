# Boot rom hasher

This module is part of a simple secure boot platform, it works by hashing bootloader code read from memory using the sha256 algorithm. It manages padding logic and is able to dispatch the processing of a message block to the sha256 core to parallelize construction of the next block.

## Run the testbench

To run the testbench, analyze each module first. The following one liner does all in one:
```
cd secureboot/sha256
ghdl -a sha_256_pkg.vhdl && ghdl -a sha_256_core.vhdl && ghdl -a neorv32_package.vhd && ghdl -a neorv32_bootloader_image.vhd && ghdl -a neorv32_boot_rom.vhd && ghdl -a neorv32_boot_rom_hasher.vhd && ghdl -a tb_neorv32_boot_rom_hasher.vhd && ghdl -r sha256_tb --wave=wave.ghw --stop-time=126125ns
```

Compare line
```
Computed hash: 8BEAA95CDCD2893FC0A0493F5588221AD992A2BAE8ACED70E37A6330D7F66551
```
with the expected hash to verify correct component functioning