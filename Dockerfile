# Builds a base Docker image for Ubuntu with X Windows and VNC support.
#
# The built image can be found at:
#
#   https://hub.docker.com/r/x11vnc/ubuntu
#
# Authors:
# Xiangmin Jiao <xmjiao@gmail.com>

FROM x11vnc/desktop:16.04
LABEL maintainer Xiangmin Jiao <xmjiao@gmail.com>

ARG DOCKER_LANG=zh_CN
ARG DOCKER_TIMEZONE=Asia/Shanghai
ARG DOCKER_OTHERPACKAGES="fcitx fcitx-config-gtk fcitx-frontend-all \
        fcitx-frontend-gtk3 fcitx-pinyin fcitx-googlepinyin \
        fcitx-ui-classic im-config fcitx-module-dbus fcitx-module-kimpanel \
        fcitx-module-lua fcitx-module-x11 presage fonts-wqy-microhei \
        language-pack-zh-hans language-pack-gnome-zh-hans"

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
        firefox-locale-zh-hans \
        browser-plugin-freshplayer-pepperflash \
        $DOCKER_OTHERPACKAGES && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV XMODIFIERS=@im=fcitx

# Change the default timezone to $DOCKER_TIMEZONE
# Disable forward logging (https://github.com/phusion/baseimage-docker/issues/186)
# Run ldconfig so that /usr/local/lib etc. are in the default
# search path for dynamic linker
RUN echo "$DOCKER_TIMEZONE" > /etc/timezone && \
    ln -s -f /usr/share/zoneinfo/$DOCKER_TIMEZONE /etc/localtime

ADD conf/ $DOCKER_HOME/.config

RUN im-config -n fcitx && \
    echo '@fcitx-autostart' >> $DOCKER_HOME/.config/lxsession/LXDE/autostart && \
    chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME

WORKDIR $DOCKER_HOME

USER root
