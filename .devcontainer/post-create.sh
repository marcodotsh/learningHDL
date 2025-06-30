#!/bin/bash
set -euxo pipefail

MIRROR_IP=
VIVADO_TAR_FILE=Xilinx_Vivado_SDK_2018.3_1207_2324
VIVADO_VERSION=2018.3

if [[ ! -z $MIRROR_IP || -f ${VIVADO_TAR_FILE}.tar.gz ]]
then

    if [ ! -f ${VIVADO_TAR_FILE}.tar.gz ]
    then
        wget ${MIRROR_IP}/${VIVADO_TAR_FILE}.tar.gz -q
    fi
    tar xzf ${VIVADO_TAR_FILE}.tar.gz
    ./${VIVADO_TAR_FILE}/xsetup --agree XilinxEULA,3rdPartyEULA,WebTalkTerms --batch Install --config ./.devcontainer/install_config.txt
    rm -rf ${VIVADO_TAR_FILE}/*
    rmdir ${VIVADO_TAR_FILE}

    echo "source /opt/Xilinx/Vivado/${VIVADO_VERSION}/settings64.sh" >> /root/.profile
    echo "source /opt/Xilinx/Vivado/${VIVADO_VERSION}/settings64.sh" >> /home/ubuntu/.profile

else

    echo "Skipping Vivado installation"

fi