FROM ubuntu:16.04

# The Xilinx toolchain version
ARG XILVER=2018.3

# The PetaLinux base. We expect ${PETALINUX_BASE}-installer.run to be the patched installer.
# PetaLinux will be installed in /opt/${PETALINX_BASE}
# File is expected in the "./resources" subdirectory
ARG PETALINUX_BASE=petalinux-v${XILVER}-final

# The PetaLinux runnable installer
ARG PETALINUX_INSTALLER=${PETALINUX_BASE}-installer.run

RUN dpkg --add-architecture i386 && apt-get update && apt-get install -y \
    python3.4 \
    tofrodos \
    iproute2 \
    gawk \
    xvfb \
    gcc-4.8 \
    git \
    make \
    net-tools \
    libncurses5-dev \
    tftpd \
    tftp-hpa \
    zlib1g-dev:i386 \
    libssl-dev \
    flex \
    bison \
    libselinux1 \
    gnupg \
    wget \
    diffstat \
    chrpath \
    socat \
    xterm \
    autoconf \
    libtool \
    tar \
    unzip \
    texinfo \
    zlib1g-dev \
    gcc-multilib \
    build-essential \
    libsdl1.2-dev \
    libglib2.0-dev \
    screen \
    expect \
    locales \
    cpio \
    sudo \
    software-properties-common \
    pax \
    gzip \
    vim \
    libgtk2.0-0 \
    nano \
    tftpd-hpa \
    && update-alternatives --install /usr/bin/python python /usr/bin/python2.7 2 \
    && add-apt-repository ppa:deadsnakes/ppa && apt update \
    && apt-get install -y python3.6 && update-alternatives --install /usr/bin/python python /usr/bin/python3.6 1 \
    && apt-get autoremove --purge && apt-get autoclean && update-alternatives --auto python

# Install the repo tool to handle git submodules (meta layers) comfortably.
ADD https://storage.googleapis.com/git-repo-downloads/repo /usr/local/bin/
RUN chmod 755 /usr/local/bin/repo

RUN echo "%sudo ALL=(ALL:ALL) ALL" >> /etc/sudoers \
    && echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && ln -fs /bin/bash /bin/sh

# Set locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Add user 'petalinux' with password 'petalinux' and give it access to install directory /opt
RUN useradd -m -G dialout,sudo -p '$6$wiu9XEXx$ITRrMySAw1SXesQcP.Bm3Su2CuaByujc6Pb7Ztf4M9ES2ES7laSRwdcbgG96if4slduUxyjqvpEq2I0OhxKCa1' petalinux \
    && chmod +w /opt \
    && chown -R petalinux:petalinux /opt \
    && mkdir /opt/${PETALINUX_BASE} \
    && chmod 755 /opt/${PETALINUX_BASE} \
    && chown petalinux:petalinux /opt/${PETALINUX_BASE}

# Set folder for tftp server
RUN mkdir -p /tftpboot && chmod 666 /tftpboot

# Install under /opt, with user petalinux
WORKDIR /opt
USER petalinux

# The HTTP server to retrieve the files from.
ARG HTTP_SERV=http://172.17.0.1:8000/resources

# Install PetaLinux
RUN echo "" | sudo -S chown -R petalinux:petalinux . \
    && wget -q ${HTTP_SERV}/${PETALINUX_INSTALLER} \
    && chmod a+x ${PETALINUX_INSTALLER} \
    && SKIP_LICENSE=y ./${PETALINUX_FILE}${PETALINUX_INSTALLER} /opt/${PETALINUX_BASE} \
    && rm -f ./${PETALINUX_INSTALLER} \
    && rm -f petalinux_installation_log

# Source settings at login
USER root
RUN echo ". /opt/${PETALINUX_BASE}/settings.sh" >> /etc/profile \
    && echo ". /etc/profile" >> /root/.profile

# If 2018.3, apply perf patch
RUN if [ "$XILVER" = "2018.3" ] ; then \
    sed -i 's/virtual\/kernel\:do\_patch/virtual\/kernel\:do\_shared\_workdir/g' /opt/petalinux-v2018.3-final/components/yocto/source/arm/layers/core/meta/classes/kernelsrc.bbclass ; \
    fi

ENTRYPOINT ["/bin/sh", "-l"]
