[ -n "$ZSH_VERSION" ] && emulate sh
. /etc/profile
[ -n "$ZSH_VERSION" ] && emulate zsh

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" -a -z "$(echo $PATH | grep $HOME/bin)" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" -a -z "$(echo $PATH | grep $HOME/.local/bin)" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

# append additional path in Docker container for singularity user
if [ "$USER" != "$DOCKER_USER" -a -e $DOCKER_HOME/.docker_path ]; then
    source $DOCKER_HOME/.docker_path
fi
