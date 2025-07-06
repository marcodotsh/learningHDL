FROM ubuntu:noble

# Install sudo
RUN apt update \
    && apt install -y sudo \
    && rm -rf /var/cache/apt/archives /var/lib/apt/lists/*

# Add ubuntu user to the sudoers file
RUN echo ubuntu ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/ubuntu \
    && chmod 0440 /etc/sudoers.d/ubuntu

# Install apt dependencies
RUN apt update \
    && DEBIAN_FRONTEND=noninteractive apt install -y \
    curl \
    dbus-x11 \
    git \
    gtkwave \

    iverilog \
    jq \
    python3-pip \
    universal-ctags \
    verilator \
    wget \
    ghdl \
    && rm -rf /var/cache/apt/archives /var/lib/apt/lists/*

# Install python dependencies
RUN pip3 install --break-system-packages \
    cocotb \
    cocotb-test \
    flake8 \
    isort \
    pytest \
    yapf

# Install Verible
RUN ARCH=$(uname -m) \
    && if [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi \
    && VERIBLE_RELEASE=$(curl -s -X GET https://api.github.com/repos/chipsalliance/verible/releases/latest | jq -r '.tag_name') && \
    VERIBLE_TAR=verible-$VERIBLE_RELEASE-linux-static-$ARCH.tar.gz \
    && wget https://github.com/chipsalliance/verible/releases/download/$VERIBLE_RELEASE/$VERIBLE_TAR \
    && tar -C /usr/local --strip-components 1 -xf $VERIBLE_TAR \
    && rm $VERIBLE_TAR

# Install Vivado dependencies
RUN dpkg --add-architecture i386 \
    && apt-get update && apt-get install -y \
    build-essential \
    libglib2.0-0 \
    libsm6 \
    libxi6 \
    libxrender1 \
    libxrandr2 \
    libfreetype6 \
    libfontconfig1 \
    locales \
    gawk \
    iproute2 \
    python3 \
    gcc \
    make \
    net-tools \
    libncurses-dev \
    tftpd-hpa \
    zlib1g-dev \
    libssl-dev \
    flex \
    bison \
    libselinux1 \
    gnupg \
    git-core \
    diffstat \
    chrpath \
    socat \
    xterm \
    autoconf \
    libtool \
    rsync \
    texinfo \
    gcc-multilib \
    zlib1g:i386 \
    lsb-release \
    dnsutils \
    bc \
    unzip \
    && rm -rf /var/cache/apt/archives /var/lib/apt/lists/*

# Set up environment for Vivado installation
COPY install_config.txt /tmp/install_config.txt
COPY post-create.sh /tmp/post-create.sh
RUN chmod +x /tmp/post-create.sh

CMD ["sudo", "bash", "-c", "/tmp/post-create.sh"]

USER ubuntu