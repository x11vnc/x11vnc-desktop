# Docker Image for Ubuntu with X11 and VNC

This is a Docker image for Ubuntu with X11 and VNC. It is similar to
[fcwu/docker-ubuntu-vnc-desktop](https://github.com/fcwu/docker-ubuntu-vnc-desktop), but with enhancements on security and features.

 - VNC is protected by a unique random password for each session
 - Desktop runs in a standard user account instead of the root account
 - Supports dynamic resizing of the desktop and 24-bit true color
 - Supports Ubuntu 17.10, 16.04 and 14.04, with very fast launching
 - Support Simplified Chinese (add `-t zh_CN` to the command-line option for `ubuntu_desktop.py`)
 - Auto-starts in full-size resolution and auto-launches web-browser
 - Automatically shares the current work directory from host to Docker image

[![Build Status](https://travis-ci.org/x11vnc/docker-desktop.svg?branch=master)](https://travis-ci.org/x11vnc/docker-desktop)
[![Docker Image](https://images.microbadger.com/badges/image/x11vnc/desktop.svg)](https://microbadger.com/images/x11vnc/desktop)

![screenshot](https://raw.github.com/x11vnc/docker-desktop/master/screenshots/screenshot.png)

## Preparation
Before you start, you need to first install Python and Docker on your computer by following the steps below.

### Installing Python
If you use Linux or Mac, Python is most likely already installed on your computer, so you can skip this step.

If you use Windows, you need to install Python if you have not yet done so. The easiest way is to install `Miniconda`, which you can download at https://repo.continuum.io/miniconda/Miniconda3-latest-Windows-x86_64.exe. You can use the default options during installation.

### Installing Docker
Download the Docker Community Edition for free at https://www.docker.com/community-edition#/download and then run the installer. Note that you need administrator's privilege to install Docker. After installation, make sure you launch Docker before proceeding to the next step.

**Notes for Windows Users**
1. Docker only supports 64-bit Windows 10 Pro or higher. If you have Windows 8 or Windows 10 Home, you need to upgrade your Windows operating system before installing Docker. Note that the older [Docker Toolbox](https://www.docker.com/products/docker-toolbox) supports older versions of Windows, but it should not be used.
2. After installing Docker, you may need to restart your computer to enable virtualization.
3. When you use Docker for the first time, you must change its settings to make the C drive shared. To do this, right-click the Docker icon in the system tray, and then click on `Settings...`. Go to `Shared Drives` tab and check the C drive.

**Notes for Linux Users**
* After you install Docker, make sure you add yourself to the Docker group by running the command:
```
sudo adduser $USER docker
```
Then, log out and log back in before you can use Docker.

## Running the Docker Image
To run the Docker image, first download the script [`ubuntu_desktop.py`](https://raw.githubusercontent.com/x11vnc/docker-desktop/master/ubuntu_desktop.py)
and save it to the working directory where you will store your codes and data. You can download the script using command line: On Windows, start `Windows PowerShell`, use the `cd` command to change to the working directory where you will store your codes and data, and then run the following command:
```
curl https://raw.githubusercontent.com/x11vnc/docker-desktop/master/ubuntu_desktop.py -outfile ubuntu_desktop.py
```
On Linux or Mac, start a terminal, use the `cd` command to change to the working directory, and then run the following command:
```
curl -s -O https://raw.githubusercontent.com/x11vnc/docker-desktop/master/ubuntu_desktop.py
```

After downloading the script, you can start the Docker image using the command
```
python ubuntu_desktop.py -p
```
This will download and run the Docker image and then launch your default web browser to show the desktop environment. The `-p` option is optional, and it instructs the Python script to pull and update the image to the latest version. The work directory by default will be mapped to the current working directory on your host.

To use the Chinese localization, use the command
```
python ubuntu_desktop.py -t zh_CN
```

For additional command-line options, use the command
```
python ubuntu_desktop.py -h
```

To resize the desktop, start `lxterminal` within the desktop and run the `xrandr` command with the `-s <width>x<height>` option. For example, use the command
```
xrandr -s 1920x1080
```
to change the desktop size to 1920x1080.

### Building Your Own Images

To build your own image, run the following commands:
```
git clone https://github.com/x11vnc/docker-desktop.git
docker build --rm -t x11vnc/desktop docker-desktop
```
and then use the `ubuntu_desktop.py` command.

## License

See the LICENSE file for details.

## Related Projects
 - [novnc/noVNC](https://github.com/novnc/noVNC): VNC client using HTML5 (Web Sockets, Canvas)
 - [fcwu/docker-ubuntu-vnc-desktop](https://github.com/fcwu/docker-ubuntu-vnc-desktop): An original but insecure implementation of Ubuntu desktop, without password protection.
 - [phusion/baseimage](https://github.com/phusion/baseimage-docker): A minimal Ubuntu base image modified for Docker-friendliness
