# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# Note: For best compatability with Singularity images, use $DOCKER_HOME
# instead of $HOME when initializing the path

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$DOCKER_HOME/.bashrc" ]; then
        . "$DOCKER_HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$DOCKER_HOME/bin" -a -z "$(echo $PATH | grep $DOCKER_HOME/bin)" ] ; then
    PATH="$DOCKER_HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$DOCKER_HOME/.local/bin" -a -z "$(echo $PATH | grep $DOCKER_HOME/.local/bin)" ] ; then
    PATH="$DOCKER_HOME/.local/bin:$PATH"
fi

# Set additional environment variables for Docker image
if [ -n "$SINGULARITY_CONTAINER" -a -e $DOCKER_HOME/.docker_envs ]; then
    . $DOCKER_HOME/.docker_envs
fi
