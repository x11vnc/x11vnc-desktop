# initialize path using the same convention as bash
# Do not customize path in this file. Set them in
# $DOCKER_HOME/.profile instead.

[ -n "$ZSH_VERSION" ] && emulate sh
    if [ -e "$DOCKER_HOME/.profile" ]; then
        . $DOCKER_HOME/.profile
    elif [ -e "$HOME/.profile" ]; then
        . $HOME/.profile
    fi
[ -n "$ZSH_VERSION" ] && emulate zsh
