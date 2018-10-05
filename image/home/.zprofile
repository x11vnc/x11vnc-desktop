# initialize path using the same convention as bash
[ -n "$ZSH_VERSION" ] && emulate sh
. /etc/profile

if [ -d "$DOCKER_HOME/.profile" ] ; then
    . $DOCKER_HOME/.profile
fi
[ -n "$ZSH_VERSION" ] && emulate zsh
