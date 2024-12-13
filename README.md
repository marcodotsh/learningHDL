# Introduction
This repo focuses on creating a devcontainer with complete tools for SystemVerilog HDL.

What's included by default in the devcontainer:
- Icarus Verilog - compile SystemVerilog to later simulate components
- Verilator - execute simulations of components
- Gtkwave - see waveforms of simulations
- cocotb - create simulation testbenches using python
- VScode extensions - SystemVerilog language IDE integration, predefined tasks

# How to install Vivado
Tested version: 2018.3
*Vivado download has to be performed manually due to licencing*
It is possible to optionally install Vivado (I installed WebPack edition 2018.3):
- Download Vivado on a machine, then expose the download directory through HTTP
  - This can be achieved for example with `python -m http.server`
- Set `MIRROR_IP`, `VIVADO_TAR_FILE` and `VIVADO_VERSION` in `.devcontainer/post-create.sh`

## Alternative install
- Download Vivado on local machine, then move the archive inside this project folder
- Set `VIVADO_TAR_FILE` and `VIVADO_VERSION` in `.devcontainer/post-create.sh`

As of now, it has not been automated the process of loading a licence, this will probably need additional steps.
I suggest to use a WebPack edition of Vivado

# Credits
This blog post: https://igorfreire.com.br/2023/06/18/vscode-setup-for-systemverilog-development/
This repository: https://github.com/starwaredesign/vivado-docker