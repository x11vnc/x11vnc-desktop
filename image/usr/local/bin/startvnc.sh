#!/bin/bash

# Start up VNC server and launch xlsession and novnc

# Author: Xiangmin Jiao <xmjiao@gmail.com>

# Copyright Xiangmin Jiao 2017. All rights reserved.

# Set resolution based on input argument. Use 1440x900 default
SIZE="${1:-1440x900}"

# Start up xdummy with the given size
SIZE1=`echo $SIZE | sed "s/x/ /"`
grep -s -q $SIZE .config/xorg.conf && \
sed -i "s/Virtual 1440 900/Virtual $SIZE1/" $DOCKER_HOME/.config/xorg.conf

Xorg -noreset -logfile $DOCKER_HOME/.log/Xorg.log -config $DOCKER_HOME/.config/xorg.conf :0 2> $DOCKER_HOME/.log/Xorg_err.log &
sleep 0.1

# startup lxsession with proper environment variables
export DISPLAY=:0.0
export HOME=$DOCKER_HOME
export SHELL=/bin/bash
export USER=$DOCKER_USER
export LOGFILE=$DOCKER_USER

/usr/bin/lxsession -s LXDE -e LXDE > $DOCKER_HOME/.log/lxsession.log 2>&1 &

# startup x11vnc with a new password
export VNCPASS=`openssl rand -base64 6 | sed 's/\//-/'`

x11vnc -storepasswd $VNCPASS ~/.vnc/passwd > $DOCKER_HOME/.log/x11vnc.log 2>&1
x11vnc -display :0 -xkb -forever -shared  -usepw >> $DOCKER_HOME/.log/x11vnc.log 2>&1 &

echo "Open your web browser with URL:"
echo "    http://localhost:6080/vnc.html?autoconnect=1&autoscale=0&password=$VNCPASS"

# startup novnc
/usr/local/noVNC/utils/launch.sh --listen 6080 > $DOCKER_HOME/.log/novnc.log 2>&1
