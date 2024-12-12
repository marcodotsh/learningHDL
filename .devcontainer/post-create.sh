#!/bin/bash
set -xe
 
apt update
DEBIAN_FRONTEND=noninteractive apt install -y \
    curl \
    dbus-x11 \
    git \
    gtkwave \
    iverilog \
    jq \
    python3-pip \
    universal-ctags \
    verilator \
    wget
pip3 install \
    cocotb \
    cocotb-test \
    flake8 \
    isort \
    pytest \
    yapf
 
# Verible
ARCH=$(uname -m)
if [[ $ARCH == "aarch64" ]]; then
    ARCH="arm64"
fi
DIST_ID=$(grep DISTRIB_ID /etc/lsb-release | cut -d'=' -f2)
DIST_RELEASE=$(grep RELEASE /etc/lsb-release | cut -d'=' -f2)
DIST_CODENAME=$(grep CODENAME /etc/lsb-release | cut -d'=' -f2)
VERIBLE_RELEASE=$(curl -s -X GET https://api.github.com/repos/chipsalliance/verible/releases/latest | jq -r '.tag_name')
VERIBLE_TAR=verible-$VERIBLE_RELEASE-linux-static-$ARCH.tar.gz
if [[ ! -f $VERIBLE_TAR ]]; then
    wget https://github.com/chipsalliance/verible/releases/download/$VERIBLE_RELEASE/$VERIBLE_TAR
fi
if [[ ! -f "/usr/local/bin/verible-verilog-format" ]]; then
    tar -C /usr/local --strip-components 1 -xf $VERIBLE_TAR
fi
rm $VERIBLE_TAR

# Inspired from the Dockerfile at https://github.com/starwaredesign/vivado-docker

MIRROR_IP=
VIVADO_TAR_FILE=Xilinx_Vivado_SDK_2018.3_1207_2324
VIVADO_VERSION=2018.3

if [[ ! -z $MIRROR_IP ]]
then

dpkg --add-architecture i386

apt-get update && apt-get install -y wget build-essential libglib2.0-0 libsm6 libxi6 libxrender1 libxrandr2 libfreetype6 libfontconfig1 locales git gawk iproute2 python3 gcc make net-tools libncurses5-dev tftpd zlib1g-dev libssl-dev flex bison libselinux1 gnupg git-core diffstat chrpath socat xterm autoconf libtool rsync texinfo gcc-multilib zlib1g:i386 lsb-release libtinfo5 dnsutils bc unzip

if [ ! -f ${VIVADO_TAR_FILE}.tar.gz ]
then
wget ${MIRROR_IP}/${VIVADO_TAR_FILE}.tar.gz -q
fi
tar xzf ${VIVADO_TAR_FILE}.tar.gz
./${VIVADO_TAR_FILE}/xsetup --agree XilinxEULA,3rdPartyEULA,WebTalkTerms --batch Install --config ./.devcontainer/install_config.txt
rm -rf ${VIVADO_TAR_FILE}*

echo "source /opt/Xilinx/Vivado/${VIVADO_VERSION}/settings64.sh" >> /root/.profile

else

echo "Skipping Vivado installation"

fi
