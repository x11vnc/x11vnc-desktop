# Builds a base Docker image for Ubuntu with X Windows and VNC support.
#
# The built image can be found at:
#
#   https://hub.docker.com/r/x11vnc/ubuntu
#
# Authors:
# Xiangmin Jiao <xmjiao@gmail.com>

FROM phusion/baseimage:0.9.20
LABEL maintainer Xiangmin Jiao <xmjiao@gmail.com>

WORKDIR /tmp

# Install some required system tools and packages for X Windows
# We install firefox and make --no-remote to be default
RUN apt-get update && \
    apt-get upgrade -y -o Dpkg::Options::="--force-confold" && \
    apt-get install -y --no-install-recommends \
        sudo \
        net-tools \
        \
        openssh-server \
        python-pip \
        python-dev \
        g++ \
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
        \
        meld \
        firefox \
	xpdf && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    sed -i 's/MOZ_APP_NAME "\$@"/MOZ_APP_NAME --no-remote "\$@"/' /usr/bin/firefox
    
# Install websokify and noVNC
RUN pip install -U \
        pip \
        setuptools && \
    pip install -U https://github.com/novnc/websockify/archive/master.tar.gz && \
    mkdir /usr/local/noVNC && \
    curl -s -L https://github.com/novnc/noVNC/archive/stable/v0.6.tar.gz | \
         tar zx -C /usr/local/noVNC --strip-components 1 && \
    rm -rf /tmp/* /var/tmp/*

########################################################
# Customization for user and location
########################################################

ADD image /

# Change the default timezone to America/New_York
RUN echo "America/New_York" > /etc/timezone && \
    ln -s -f /usr/share/zoneinfo/America/New_York /etc/localtime
    
# Set up user so that we do not run as root
ENV DOCKER_USER=x11vnc
ENV DOCKER_GROUP=$DOCKER_USER \
    DOCKER_HOME=/home/$DOCKER_USER \
    HOME=/home/$DOCKER_USER

# Disable forward logging (https://github.com/phusion/baseimage-docker/issues/186)
# Add script to set up permissions of home directory on myinit
# Run ldconfig so that /usr/local/lib etc. are in the default 
# search path for the dynamic linker.
RUN useradd -m -s /bin/bash -G sudo,docker_env $DOCKER_USER && \
    echo "$DOCKER_USER:docker" | chpasswd && \
    echo "$DOCKER_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    touch /etc/service/syslog-forwarder/down && \
    ldconfig

ADD conf/ $DOCKER_HOME/.config

RUN sed -i "s/x11vnc/$DOCKER_USER/" $DOCKER_HOME/.config/pcmanfm/LXDE/desktop-items-0.conf && \
    touch $DOCKER_HOME/.sudo_as_admin_successful && \
    mkdir $DOCKER_HOME/shared && \
    mkdir $DOCKER_HOME/.vnc && \
    mkdir $DOCKER_HOME/.log && touch $DOCKER_HOME/.log/vnc.log && \
    chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME

WORKDIR $DOCKER_HOME

USER root
ENTRYPOINT ["/sbin/my_init","--quiet","--","/sbin/setuser","x11vnc","/bin/bash","-l","-c"]
CMD ["/bin/bash","-i"]
