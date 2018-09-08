#!/bin/bash

# Start up VNC server and launch xsession and novnc
# It will use the first available display between :0 and :9. VNC will be 
# started using port 5900+DISPLAY and the NoVNC will use port 6080+DISPLAY.

# Author: Xiangmin Jiao <xmjiao@gmail.com>
# Copyright Xiangmin Jiao 2017--2018. All rights reserved.

err_handle()
{
    if [ -n "$SSH_AGENT_PID" ]; then
        ssh-agent -k > /dev/null
    fi
    rm -f /tmp/.X${DISP}-lock
    pkill -P $$
}

if [ "$1" = "-h" -o "$1" = "--help" ]; then
    if [ -n "$SINGULARITY_NAME" ]; then
        CMD="singularity run $SINGULARITY_NAME"
    else
        CMD=$0
    fi
    echo "Usage:"
    echo
    echo "    $CMD [-s resolution]"
    echo
    echo "where resolution has the format <width>x<height>. The default resolution"
    echo "is 1440x900."
    exit
fi

trap "" INT
trap exit TERM
trap err_handle EXIT

# unset all environment variables related to desktop manager
for var in $(env | cut -d= -f1 | grep -E "^XDG|SESSION|^GTK|XKEYS|WINDOWMANAGER|XAUTHORITY"); do
    unset $var
done

# Start up xdummy with the given size
if [ -n "$2" ]; then
    RESOLUT=$2
else
    RESOLUT="${RESOLUT:-1440x900}"
fi
SCREEN_SIZE=`echo $RESOLUT | sed -e "s/x/ /"`

# Find an available display and set ports for VNC and NoVNC
for i in $(seq 0 9); do
    if [ ! -e /tmp/.X${i}-lock ]; then
        DISP=$i
        break
    fi
done
if [ -z "$DISP" ]; then
    echo "Cannot find a free DISPLAY port"
    exit
fi

VNC_PORT=$((5900 + DISP))
WEB_PORT=$((6080 + DISP))

export DISPLAY=:$DISP.0
export LOGFILE=$HOME/.log/Xorg.log
export NO_AT_BRIDGE=1
export SESSION_PID=$$

# Initialize configurations
/usr/local/bin/init_vnc

mkdir -p $HOME/.config/X11
cp /etc/X11/xorg.conf $HOME/.config/X11
grep -s -q $RESOLUT $HOME/.config/X11/xorg.conf && \
perl -i -p -e "s/Virtual \d+ \d+/Virtual $SCREEN_SIZE/" $HOME/.config/X11/xorg.conf

# Start Xorg
mkdir -p $HOME/.log
Xorg -noreset -logfile $HOME/.log/Xorg.log -config $HOME/.config/X11/xorg.conf :$DISP \
    2> $HOME/.log/Xorg_err.log &
sleep 0.1

# startup lxsession with proper environment variables
if [ -e $HOME/.profile ]; then
    source $HOME/.profile
fi

# start ssh-agent if not set by caller and stop if automatically
if [ -z "$SSH_CONNECTION" ]; then
    eval `ssh-agent -s` > /dev/null
fi

/usr/bin/lxsession -s LXDE -e LXDE > $HOME/.log/lxsession.log 2>&1 &

# startup x11vnc with a new password
export VNCPASS=`openssl rand -base64 6 | sed 's/\//-/'`
mkdir -p $HOME/.vnc && \
x11vnc -storepasswd $VNCPASS ~/.vnc/passwd > $HOME/.log/x11vnc.log 2>&1

# Do not use -repeat option to enable keyboard repeat.
# The user can use “xset r on" twice to re-enable it.
export X11VNC_IDLE_TIMEOUT=2147483647
x11vnc -display :$DISP -rfbport $VNC_PORT -xkb -norepeat 2 -forever -shared -usepw >> $HOME/.log/x11vnc.log 2>&1 &

echo "Open your web browser with URL:"
echo "    http://localhost:$WEB_PORT/vnc.html?resize=downscale&autoconnect=1&password=$VNCPASS"
echo "or connect your VNC viewer to localhost:$VNC_PORT with password $VNCPASS"

# startup novnc
/usr/local/noVNC/utils/launch.sh --web /usr/local/noVNC \
    --vnc localhost:$VNC_PORT --listen $WEB_PORT > $HOME/.log/novnc.log 2>&1
