# Docker Image for Ubuntu with X11 and VNC

This is a Docker image for Ubuntu with X11 and VNC. It is similar to
[fcwu/docker-ubuntu-vnc-desktop](https://github.com/fcwu/docker-ubuntu-vnc-desktop), but with enhancements on security and features.

 - VNC is protected by a unique random password for each session
 - Desktop runs in a standard user account `x11vnc` instead of the root account
 - Supports dynamic resizing of the desktop and 24-bit true color
 - Supports both Ubuntu 16.04 and 14.04, with very fast launching
 - Auto-starts in full-size resolution and auto-launches web-browser
 - Automatically shares the current work directory from host to Docker image

[![Build Status](https://travis-ci.org/x11vnc/ubuntu-docker.svg?branch=master)](https://travis-ci.org/x11vnc/ubuntu-docker)
[![Docker Image](https://images.microbadger.com/badges/image/x11vnc/ubuntu.svg)](https://microbadger.com/images/x11vnc/ubuntu)

![screenshot](https://raw.github.com/x11vnc/docker-ubuntu-x11vnc/master/screenshots/screenshot.png)

## Usage

### Using Prebuilt Images

To use the images, make sure you have Docker and Python (either 2 or
3) installed.  Download the Python script [`docker_desktop.py`](https://raw.githubusercontent.com/x11vnc/ubuntu-docker/master/docker_desktop.py) and
save it into a working directory and then run the command
```
python docker_desktop.py -p
```

in a terminal on your local computer. It will download the latest
Docker image, start X11 with the native screen resolution of your
local computer, and then automatically open the X11 desktop in your
default web browser. By default, the script launches Ubuntu 16.04. You
can also choose to launch Ubuntu 14.04 using the command
```
python docker_desktop.py -t 14.04
```

To resize the desktop, start `lxterminal` within the desktop and run the `xrandr` command with the `-s <width>x<height>` option. For example, use the command
```
xrandr -s 1920x1080
```
to change the desktop size to 1920x1080.

### Building Your Own Images

To build your own image, run the following commands:
```
git clone https://github.com/x11vnc/ubuntu-docker.git
docker build --rm -t x11vnc/ubuntu ubuntu-docker
```
and then use the `docker_desktop.py` command.

## License

See the LICENSE file for details.

## Related Projects
 - [novnc/noVNC](https://github.com/novnc/noVNC): VNC client using HTML5 (Web Sockets, Canvas)
 - [fcwu/docker-ubuntu-vnc-desktop](https://github.com/fcwu/docker-ubuntu-vnc-desktop): An original but insecure implementation of Ubuntu desktop, without password protection.
 - [phusion/baseimage](https://github.com/phusion/baseimage-docker): A minimal Ubuntu base image modified for Docker-friendliness
