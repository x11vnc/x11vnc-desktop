# Builds a base Docker image for Ubuntu with X Windows and VNC support.
#
# The built image can be found at:
#
#   https://hub.docker.com/r/x11vnc/ubuntu
#
# Authors:
# Xiangmin Jiao <xmjiao@gmail.com>

FROM x11vnc/baseimage:0.9.22
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
        bsdtar \
        net-tools \
        xdotool \
        zsh \
        git \
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
        gnome-themes-standard \
        gtk2-engines-pixbuf \
        gtk2-engines-murrine \
        ttf-ubuntu-font-family \
        xfonts-base xfonts-100dpi xfonts-75dpi xfonts-scalable xfonts-cyrillic \
        mesa-utils \
        libgl1-mesa-dri \
        x11vnc \
        dbus-x11 \
        \
        chromium-browser \
        xpdf && \
    ln -s -f /usr/bin/lxterminal /usr/bin/xterm && \
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
# Disable forward logging (https://github.com/phusion/baseimage-docker/issues/186)
# Run ldconfig so that /usr/local/lib etc. are in the default
# search path for dynamic linker
RUN useradd -m -s $DOCKER_SHELL -G sudo,docker_env $DOCKER_USER && \
    echo "$DOCKER_USER:docker" | chpasswd && \
    echo "$DOCKER_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    echo "$DOCKER_TIMEZONE" > /etc/timezone && \
    ln -s -f /usr/share/zoneinfo/$DOCKER_TIMEZONE /etc/localtime && \
    touch /etc/service/syslog-forwarder/down && \
    ldconfig

ADD image /
ADD conf/ $DOCKER_HOME/.config

RUN touch $DOCKER_HOME/.sudo_as_admin_successful && \
    mkdir -p $DOCKER_HOME/shared && \
    mkdir -p $DOCKER_HOME/.vnc && \
    mkdir -p $DOCKER_HOME/.ssh && \
    mkdir -p $DOCKER_HOME/.log && touch $DOCKER_HOME/.log/vnc.log && \
    ln -s -f .config/zsh/zshrc /home/$DOCKER_USER/.zshrc && \
    ln -s -f .config/zsh/zprofile /home/$DOCKER_USER/.zprofile && \
    echo "[ ! -f $HOME/WELCOME ] || cat $HOME/WELCOME" \
        >> $DOCKER_HOME/.profile && \
    mkdir -p $DOCKER_HOME/.config/git && \
    touch -d '50 years ago' $DOCKER_HOME/.config/git/config && \
    ln -s -f .config/git/config /home/$DOCKER_USER/.gitconfig && \
    chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME

WORKDIR $DOCKER_HOME

USER root
ENTRYPOINT ["/sbin/my_init","--quiet","--","/sbin/setuser","ubuntu","/bin/bash","-l","-c"]
CMD ["$DOCKER_SHELL","-l","-i"]
