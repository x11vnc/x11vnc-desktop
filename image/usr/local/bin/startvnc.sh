#!/bin/bash

# Start up VNC server and launch xsession and novnc
# It will use the first available display between :0 and :9. VNC will be
# started using port 5900+DISPLAY and the NoVNC will use port 6080+DISPLAY.

# Author: Xiangmin Jiao <xmjiao@gmail.com>
# Copyright Xiangmin Jiao 2017--2022. All rights reserved.

cleanup()
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

trap exit TERM
trap cleanup EXIT

/usr/local/bin/init_vnc && sync

# unset all environment variables related to desktop manager
for var in $(env | cut -d= -f1 | grep -E \
	"^XDG|SESSION|^GTK|XKEYS|^WLS|WINDOWMANAGER|WAYLAND_DISPLAY"); do
    unset $var
done

# Find an available display and set ports for VNC and NoVNC
for i in $(seq 0 9); do
    if [ ! -e /tmp/.X${i}-lock -a ! -e /tmp/.X11-unix/X${i} ]; then
        DISP=$i
        break
    fi
done
if [ -z "$DISP" ]; then
    echo "Cannot find a free DISPLAY port"
    exit
fi

# Start up xdummy with the given screen size
if [ "$1" = "-s" -a -n "$2" ]; then
    RESOLUT=$2
else
    RESOLUT="${RESOLUT:-1440x900}"
fi

cp /etc/X11/xorg.conf $HOME/.config/xorg_X$DISP.conf
if [ -n "$(grep -s $RESOLUT /etc/X11/xorg.conf)" ]; then
    SCREEN_SIZE=`echo $RESOLUT | sed -e "s/x/ /"`
    sed -i -e "s/Virtual 1440 900/Virtual $SCREEN_SIZE/" $HOME/.config/xorg_X$DISP.conf
else
    echo "Warning: Resolution $RESOLUT is not recognized. Valid resolutions are: " \
        $(grep Modeline /etc/X11/xorg.conf | cut -d '"' -f  2| tr '\n' ' ')
fi

VNC_PORT=$((5900 + DISP))
WEB_PORT=$((6080 + DISP))

export XDG_RUNTIME_DIR=$(mktemp -d -t runtime-$USER-XXXXX)
export DISPLAY=:$DISP.0
export LOGFILE=$HOME/.log/Xorg_$DISP.log
export NO_AT_BRIDGE=1
export SESSION_PID=$$

# Start Xorg
mkdir -p $HOME/.log
Xorg -noreset +extension GLX +extension RANDR +extension RENDER \
    -logfile $HOME/.log/Xorg_$DISP.log -config $HOME/.config/xorg_X$DISP.conf \
    :$DISP 2> $HOME/.log/Xorg_X${DISP}_err.log &
XORG_PID=$!

# start ssh-agent if not set by caller and stop if automatically
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval `ssh-agent -s` > /dev/null
fi

# start x11vnc with a stable or a new random password
export VNCPASS=${VNCPASS:-$(openssl rand -base64 6 | sed 's/\//-/')}
mkdir -p $HOME/.vnc && \
x11vnc -storepasswd $VNCPASS ~/.vnc/passwd$DISP > $HOME/.log/x11vnc_X$DISP.log 2>&1

# startup novnc
/usr/local/noVNC/utils/launch.sh --web /usr/local/noVNC \
    --vnc localhost:$VNC_PORT --listen $WEB_PORT > $HOME/.log/novnc_X$DISP.log 2>&1 &
NOVNC_PID=$1

# Error checking
ps $XORG_PID > /dev/null || { cat $HOME/.log/Xorg_X${DISP}_err.log && exit -1; }
ps $NOVNC_PID > /dev/null || { cat $HOME/.log/novnc_X$DISP.log && exit -1; }

echo "Open your web browser with URL:"
echo "    http://localhost:$WEB_PORT/vnc.html?resize=downscale&autoconnect=1&password=$VNCPASS"
echo "or connect your VNC viewer to localhost:$VNC_PORT with password $VNCPASS"

# Start LXDE and set screen size
lxsession -s LXDE -e LXDE > $HOME/.log/lxsession_X$DISP.log 2>&1 &
LXSESSION_PID=$!
ps $LXSESSION_PID > /dev/null || { cat $HOME/.log/lxsession_X$DISP.log && exit -1; }
x11vnc -display :$DISP -rfbport $VNC_PORT -xkb -repeat -skip_dups -forever \
    -shared -rfbauth ~/.vnc/passwd$DISP >> $HOME/.log/x11vnc_X$DISP.log 2>&1 &
X11VNC_PID=$!

sleep 3
# Fix issues with Shift-Tab
xmodmap -e 'keycode 23 = Tab'

# Restart x11vnc if it dies, typically after changing screen resolution
# See /usr/local/bin/lxrandr
while true ; do
    echo $X11VNC_PID > $HOME/.log/x11vnc_X${DISP}_pid
    wait $X11VNC_PID

    x11vnc -display :$DISP -rfbport $VNC_PORT -xkb -repeat -skip_dups -forever \
        -shared -rfbauth ~/.vnc/passwd$DISP >> $HOME/.log/x11vnc_X$DISP.log 2>&1 &
    X11VNC_PID=$!
    echo "X11vnc was restarted probably due to screen-resolution change."
    echo "Please refresh the web browser or reconnect your VNC viewer."
done
