# Builds a base Docker image for Ubuntu with X Windows and VNC support.
#
# The built image can be found at:
#
#   https://hub.docker.com/r/x11vnc/desktop
#
# Authors:
# Xiangmin Jiao <xmjiao@gmail.com>

FROM ubuntu:22.04
LABEL maintainer Xiangmin Jiao <xmjiao@gmail.com>

ARG DOCKER_LANG=en_US
ARG DOCKER_TIMEZONE=America/New_York

ENV LANG=$DOCKER_LANG.UTF-8 \
    LANGUAGE=$DOCKER_LANG:UTF-8 \
    LC_ALL=$DOCKER_LANG.UTF-8

WORKDIR /tmp

ARG DEBIAN_FRONTEND=noninteractive

# Install some required system tools and packages for X Windows and ssh
# Also remove the message regarding unminimize
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        apt-utils \
        apt-file \
        locales \
        language-pack-en && \
    locale-gen $LANG && \
    dpkg-reconfigure -f noninteractive locales && \
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        curl \
        less \
        vim \
        psmisc \
        runit \
        apt-transport-https ca-certificates \
        software-properties-common \
        man \
        sudo \
        rsync \
        tar \
        net-tools \
        gpg-agent \
        inetutils-ping \
        csh \
        tcsh \
        zsh \
        build-essential \
        libssl-dev \
        git \
        dos2unix \
        dbus-x11 \
        \
        openssh-server \
        python3 \
        python3-distutils \
        python3-tk \
        python3-dbus \
        \
        xserver-xorg-video-dummy \
        lxde \
        x11-xserver-utils \
        xterm \
        gnome-themes-standard \
        gtk2-engines-pixbuf \
        gtk2-engines-murrine \
        libcanberra-gtk-module libcanberra-gtk3-module \
        ttf-ubuntu-font-family \
        xfonts-base xfonts-100dpi xfonts-75dpi xfonts-scalable xfonts-cyrillic \
        libopengl0 mesa-utils libglu1-mesa libgl1-mesa-dri libjpeg8 libjpeg62 \
        xauth \
        x11vnc \
        \
        firefox \
        xpdf && \
    chmod 755 /usr/local/share/zsh/site-functions && \
    apt-get -y autoremove && \
    ssh-keygen -A && \
    ln -s -f /lib64/ld-linux-x86-64.so.2 /lib64/ld-lsb-x86-64.so && \
    perl -p -i -e 's/#?X11Forwarding\s+\w+/X11Forwarding yes/g; \
        s/#?X11UseLocalhost\s+\w+/X11UseLocalhost no/g; \
        s/#?PasswordAuthentication\s+\w+/PasswordAuthentication no/g; \
        s/#?PermitEmptyPasswords\s+\w+/PermitEmptyPasswords no/g' \
        /etc/ssh/sshd_config && \
    rm -f /etc/update-motd.d/??-unminimize && \
    rm -f /etc/xdg/autostart/lxpolkit.desktop && \
    chmod a-x /usr/bin/lxpolkit && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install websokify and noVNC
RUN curl -O https://bootstrap.pypa.io/pip/3.5/get-pip.py && \
    python3 get-pip.py && \
    /usr/bin/python3 -m pip install --upgrade pip && \
    pip3 install --no-cache-dir \
        setuptools && \
    pip3 install -U https://github.com/novnc/websockify/archive/refs/tags/v0.10.0.tar.gz && \
    mkdir /usr/local/noVNC && \
    curl -s -L https://github.com/x11vnc/noVNC/archive/master.tar.gz | \
         tar zxf - -C /usr/local/noVNC --strip-components 1 && \
    rm -rf /tmp/* /var/tmp/*

# Install x11vnc from source
# Install X-related to compile x11vnc from source code.
# https://bugs.launchpad.net/ubuntu/+source/x11vnc/+bug/1686084
# Also, fix issue with Shift-Tab not working
# https://askubuntu.com/questions/839842/vnc-pressing-shift-tab-tab-only
#RUN apt-get update && \
#    apt-get install -y libxtst-dev libssl-dev libjpeg-dev && \
#    \
#    mkdir -p /tmp/x11vnc-0.9.14 && \
#    curl -s -L http://x11vnc.sourceforge.net/dev/x11vnc-0.9.14-dev.tar.gz | \
#        tar zxf - -C /tmp/x11vnc-0.9.14 --strip-components 1 && \
#    cd /tmp/x11vnc-0.9.14 && \
#    ./configure --prefix=/usr/local CFLAGS='-O2 -fno-stack-protector -Wall' && \
#    make && \
#    make install && \
#    perl -e 's/,\s*ISO_Left_Tab//g' -p -i /usr/share/X11/xkb/symbols/pc && \
#    apt-get -y remove libxtst-dev libssl-dev libjpeg-dev && \
#    apt-get -y autoremove && \
#    ldconfig && \
#    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

########################################################
# Customization for user and location
########################################################
# Set up user so that we do not run as root in DOCKER
ENV DOCKER_USER=ubuntu \
    DOCKER_UID=1000 \
    DOCKER_GID=1000 \
    DOCKER_SHELL=/bin/zsh

ENV DOCKER_GROUP=$DOCKER_USER \
    DOCKER_HOME=/home/$DOCKER_USER \
    SHELL=$DOCKER_SHELL


# Change the default timezone to $DOCKER_TIMEZONE
# Run ldconfig so that /usr/local/lib etc. are in the default
# search path for dynamic linker
RUN groupadd -g $DOCKER_GID $DOCKER_GROUP && \
    useradd -m -u $DOCKER_UID -g $DOCKER_GID -s $DOCKER_SHELL -G sudo $DOCKER_USER && \
    echo "$DOCKER_USER:"`openssl rand -base64 12` | chpasswd && \
    echo "$DOCKER_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    echo "$DOCKER_TIMEZONE" > /etc/timezone && \
    ln -s -f /usr/share/zoneinfo/$DOCKER_TIMEZONE /etc/localtime

ADD image/etc /etc
ADD image/usr /usr
ADD image/sbin /sbin
ADD image/home $DOCKER_HOME

RUN mkdir -p $DOCKER_HOME/.config/mozilla && \
    ln -s -f .config/mozilla $DOCKER_HOME/.mozilla && \
    touch $DOCKER_HOME/.sudo_as_admin_successful && \
    mkdir -p $DOCKER_HOME/shared && \
    mkdir -p $DOCKER_HOME/.ssh && \
    mkdir -p $DOCKER_HOME/.log && touch $DOCKER_HOME/.log/vnc.log && \
    chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME

WORKDIR $DOCKER_HOME

ENV DOCKER_CMD=start_vnc

USER root
ENTRYPOINT ["/sbin/my_init", "--", "/sbin/setuser", "ubuntu"]
CMD ["$DOCKER_CMD"]
