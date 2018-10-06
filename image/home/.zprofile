# initialize path using the same convention as bash
[ -n "$ZSH_VERSION" ] && emulate sh
    if [ -e "$DOCKER_HOME/.profile" ]; then
        . $DOCKER_HOME/.profile
    elif [ -e "$HOME/.profile" ]; then
        . $HOME/.profile
    fi
[ -n "$ZSH_VERSION" ] && emulate zsh
