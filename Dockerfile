# Builds a base Docker image for Ubuntu with X Windows and VNC support.
#
# The built image can be found at:
#
#   https://hub.docker.com/r/x11vnc/ubuntu
#
# Authors:
# Xiangmin Jiao <xmjiao@gmail.com>

FROM x11vnc/baseimage:17.10
LABEL maintainer Xiangmin Jiao <xmjiao@gmail.com>

ARG DOCKER_LANG=en_US
ARG DOCKER_TIMEZONE=America/New_York

ENV LANG=$DOCKER_LANG.UTF-8 \
    LANGUAGE=$DOCKER_LANG:UTF-8 \
    LC_ALL=$DOCKER_LANG.UTF-8

WORKDIR /tmp

ARG DEBIAN_FRONTEND=noninteractive

# Install some required system tools and packages for X Windows
RUN locale-gen $LANG && \
    dpkg-reconfigure -f noninteractive locales && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        man \
        sudo \
        rsync \
        bsdtar \
        net-tools \
        inetutils-ping \
        zsh \
        build-essential \
        git \
        dos2unix \
        \
        openssh-server \
        g++ \
        python \
        python-tk \
        python3-tk \
        \
        xserver-xorg-video-dummy \
        lxde \
        x11-xserver-utils \
        xterm \
        gnome-themes-standard \
        gtk2-engines-pixbuf \
        gtk2-engines-murrine \
        ttf-ubuntu-font-family \
        xfonts-base xfonts-100dpi xfonts-75dpi xfonts-scalable xfonts-cyrillic \
        mesa-utils \
        libgl1-mesa-dri \
        x11vnc \
        \
        firefox \
        xpdf && \
    apt-get -y autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install websokify and noVNC
RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
    python2 get-pip.py && \
    pip2 install --no-cache-dir \
        setuptools && \
    pip2 install -U https://github.com/novnc/websockify/archive/master.tar.gz && \
    mkdir /usr/local/noVNC && \
    curl -s -L https://github.com/x11vnc/noVNC/archive/master.tar.gz | \
         bsdtar zxf - -C /usr/local/noVNC --strip-components 1 && \
    rm -rf /tmp/* /var/tmp/*

# Install x11vnc from source
# Install x-related to compile x11vnc from source code.
# https://bugs.launchpad.net/ubuntu/+source/x11vnc/+bug/1686084
RUN apt-get update && \
    apt-get install -y libxtst-dev libssl-dev libjpeg-dev && \
    \
    mkdir -p /tmp/x11vnc-0.9.14 && \
    curl -s -L http://x11vnc.sourceforge.net/dev/x11vnc-0.9.14-dev.tar.gz | \
        bsdtar zxf - -C /tmp/x11vnc-0.9.14 --strip-components 1 && \
    cd /tmp/x11vnc-0.9.14 && \
    ./configure --prefix=/usr/local CFLAGS='-O2 -fno-stack-protector -Wall' && \
    make && \
    make install && \
    apt-get -y remove libxtst-dev libssl-dev libjpeg-dev && \
    apt-get -y autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

########################################################
# Customization for user and location
########################################################
# Set up user so that we do not run as root
ENV DOCKER_USER=ubuntu \
    DOCKER_SHELL=/usr/bin/zsh

ENV DOCKER_GROUP=$DOCKER_USER \
    DOCKER_HOME=/home/$DOCKER_USER \
    HOME=/home/$DOCKER_USER

# Change the default timezone to $DOCKER_TIMEZONE
# Run ldconfig so that /usr/local/lib etc. are in the default
# search path for dynamic linker
RUN useradd -m -s $DOCKER_SHELL -G sudo,docker_env $DOCKER_USER && \
    echo "$DOCKER_USER:docker" | chpasswd && \
    echo "$DOCKER_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    echo "$DOCKER_TIMEZONE" > /etc/timezone && \
    ln -s -f /usr/share/zoneinfo/$DOCKER_TIMEZONE /etc/localtime && \
    ldconfig

ADD image/etc /etc
ADD image/usr /usr
ADD image/home $DOCKER_HOME

RUN touch $DOCKER_HOME/.sudo_as_admin_successful && \
    mkdir -p $DOCKER_HOME/shared && \
    mkdir -p $DOCKER_HOME/.ssh && \
    mkdir -p $DOCKER_HOME/.log && touch $DOCKER_HOME/.log/vnc.log && \
    echo "export NO_AT_BRIDGE=1" >> $DOCKER_HOME/.profile && \
    ln -s -f .config/mozilla $HOME/.mozilla && \
    echo "[ ! -f $HOME/WELCOME -o -z \"\$DISPLAY\" ] || cat $HOME/WELCOME" \
        >> $DOCKER_HOME/.profile && \
    chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME

WORKDIR $DOCKER_HOME

USER root
ENTRYPOINT ["/sbin/my_init","--quiet","--","/sbin/setuser","ubuntu","/bin/bash","-c"]
CMD ["$DOCKER_SHELL","-l","-i"]
